import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safe_device/safe_device.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../../core/utils/location_utils.dart';

import '../../../../core/services/gps_snapshot_service.dart';
import '../../../../core/services/face_recognition_service.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/security/environment_security_service.dart';

import '../../../auth/domain/entities/user_entity.dart';
import '../../../../core/error/failures.dart';
import '../../domain/usecases/submit_attendance.dart';
import 'attendance_state.dart';

class AttendanceCubit extends Cubit<AttendanceState> {
  static final double faceMatchThreshold =
      double.tryParse(const String.fromEnvironment('FACE_MATCH_THRESHOLD')) ??
      0.65;
  final UserEntity user;
  final SubmitAttendance submitAttendanceUseCase;
  final GPSSnapshotService gpsSnapshotService;
  final FaceRecognitionService faceRecognitionService;
  final SecureStorageService secureStorageService;
  StreamSubscription<Position>? _positionStreamSubscription;

  AttendanceCubit({
    required this.user,
    required this.submitAttendanceUseCase,
    GPSSnapshotService? gpsSnapshotService,
    FaceRecognitionService? faceRecognitionService,
    SecureStorageService? secureStorageService,
  }) : gpsSnapshotService = gpsSnapshotService ?? GPSSnapshotService(),
       faceRecognitionService =
           faceRecognitionService ?? FaceRecognitionService(),
       secureStorageService = secureStorageService ?? SecureStorageService(),
       super(AttendanceInitial());

  @override
  void emit(AttendanceState state) {
    if (isClosed) return;
    super.emit(state);
  }

  Future<void> initialize() async {
    emit(AttendanceLoading());

    try {
      // Check location permission first
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        emit(
          const AttendanceError(
            'Layanan lokasi tidak aktif. Mohon aktifkan GPS Anda.',
          ),
        );
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        emit(AttendancePermissionRequired());
        return;
      }

      final securityAudit = await EnvironmentSecurityService.auditEnvironment();
      if (!securityAudit.isSecure) {
        final reasons = <String>[];
        if (securityAudit.isMockLocation) {
          reasons.add('mock location atau GPS palsu');
        }
        if (securityAudit.isDevMode) {
          reasons.add('Developer Mode/USB Debugging');
        }
        if (securityAudit.isJailBroken) {
          reasons.add('root/jailbreak');
        }
        if (securityAudit.isEmulator) reasons.add('emulator');
        if (securityAudit.isFridaDetected) {
          reasons.add('instrumentasi tidak tepercaya');
        }

        emit(
          AttendanceSecurityBlocked(
            'Akses fitur absen diblokir karena terdeteksi: '
            '${reasons.join(', ')}. Matikan indikator tersebut lalu coba lagi.',
            isDeveloperMode: securityAudit.isDevMode,
          ),
        );
        return;
      }

      // Load Face Recognition Model
      await faceRecognitionService.loadModel();

      await _loadMapData();
    } catch (e) {
      emit(AttendanceError('Failed to initialize attendance: $e'));
    }
  }

  Future<void> requestLocationPermission() async {
    emit(AttendanceLoading());
    LocationPermission permission = await Geolocator.requestPermission();

    if (permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always) {
      await _loadMapData();
    } else {
      emit(AttendancePermissionRequired());
    }
  }

  // Camera Permission Logic
  Future<void> checkCameraPermission() async {
    final status = await Permission.camera.status;
    if (status.isGranted) {
      // Proceed to take photo
      await takePhotoAndSubmit();
    } else {
      // Need permission
      // If previously denied, show custom dialog flow handled by UI state
      if (state is AttendanceLoaded) {
        // Save current loaded state if we want to restore?
        // For now, simpler to emit CameraPermissionRequired.
        // But we assume the UI handles "CameraPermissionRequired" by showing a card.
        emit(AttendanceCameraPermissionRequired());
      }
    }
  }

  Future<void> requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isGranted) {
      // Restore map or proceed?
      // Requirement: card custom dialog first.
      // If granted, we should probably go back to Map (Loaded) THEN user clicks Presensi again?
      // OR directly launch camera?
      // Let's go back to Loaded (Map) and let user click again or auto-launch.
      // Better ux: Auto launch camera?
      // Let's just reload map data to return to "AttendanceLoaded" state.
      await _loadMapData();
    } else {
      emit(AttendanceCameraPermissionRequired());
    }
  }

  Future<void> submitAttendanceWithImage(XFile photo) async {
    if (state is! AttendanceLoaded) return;
    final loadedState = state as AttendanceLoaded;
    if (loadedState.isLibur) return;

    // Fake GPS can be enabled after the initial environment audit.
    if (kReleaseMode && loadedState.currentPosition != null) {
      bool isMockLocation = loadedState.currentPosition!.isMocked;
      try {
        isMockLocation = isMockLocation || await SafeDevice.isMockLocation;
      } catch (e) {
        debugPrint('Mock location check failed: $e');
        isMockLocation = true;
      }

      if (isMockLocation) {
        emit(
          loadedState.copyWith(
            isSubmitting: false,
            submissionErrorMessage:
                'Presensi ditolak karena lokasi palsu atau mock location terdeteksi.',
          ),
        );
        return;
      }
    }

    List<double> currentEmbedding;
    try {
      final storedTemplate = await secureStorageService.readFaceEmbedding();
      if (storedTemplate == null || storedTemplate.isEmpty) {
        emit(
          loadedState.copyWith(
            submissionErrorMessage:
                'Template wajah belum tersedia. Silakan login kembali.',
          ),
        );
        return;
      }
      final decodedTemplate = jsonDecode(storedTemplate);
      if (decodedTemplate is! List) throw const FormatException();
      final registeredEmbedding = decodedTemplate
          .map((value) => double.tryParse(value.toString()))
          .whereType<double>()
          .toList(growable: false);
      currentEmbedding = await faceRecognitionService.generateEmbedding(
        photo.path,
      );
      final similarity = faceRecognitionService.cosineSimilarity(
        currentEmbedding,
        registeredEmbedding,
      );
      if (similarity < faceMatchThreshold) {
        emit(
          loadedState.copyWith(
            submissionErrorMessage:
                'Wajah tidak cocok dengan perangkat terdaftar. Silakan ulangi.',
          ),
        );
        return;
      }
    } catch (_) {
      emit(
        loadedState.copyWith(
          submissionErrorMessage:
              'Wajah tidak cocok dengan perangkat terdaftar. Silakan ulangi.',
        ),
      );
      return;
    }

    // Emit submitting state
    emit(
      loadedState.copyWith(
        isSubmitting: true,
        submissionErrorMessage: null,
        submissionSuccessMessage: null,
      ),
    );

    // Get Device Info
    final deviceInfo = DeviceInfoPlugin();
    String merek = 'Unknown';
    String model = 'Unknown';
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      merek = androidInfo.brand;
      model = androidInfo.model;
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      merek = 'Apple';
      model = iosInfo.model;
    }

    try {
      // Capture GPS Snapshot
      Map<String, dynamic> gpsSnapshot = {};

      if (loadedState.currentPosition != null) {
        gpsSnapshot = await gpsSnapshotService.captureSnapshot(
          position: loadedState.currentPosition!,
        );
      }

      // Generate Face Embedding (with fallback if model fails to load)
      final faceRecognitionStr = jsonEncode(currentEmbedding);

      final pos = loadedState.currentPosition;
      final String accuracyStr = pos?.accuracy.toString() ?? '0';
      final String providerStr =
          gpsSnapshot['source']?['provider']?.toString() ?? 'fused';
      final String timestampDeviceStr =
          (pos?.timestamp.millisecondsSinceEpoch ??
                  DateTime.now().millisecondsSinceEpoch)
              .toString();
      final String isMockLocStr =
          (gpsSnapshot['device_state']?['is_mock_location'] == true).toString();

      final params = SubmitAttendanceParams(
        nip: user.detailPegawai.nip,
        unorId: user.result.unorId, // Use UnorID from hasil_login (LoginResult)
        kodeUnik: user.kodeUnik,
        idMesin: user.result.idMesin.toString(),
        tipeAbsen: user.result.tipeAbsensi.isNotEmpty
            ? user.result.tipeAbsensi
            : 'B',
        latitude: pos?.latitude.toString() ?? '',
        longitude: pos?.longitude.toString() ?? '',
        accuracy: accuracyStr,
        provider: providerStr,
        timestampDevice: timestampDeviceStr,
        isMockLocation: isMockLocStr,
        jarak: loadedState.distanceToNearest?.toStringAsFixed(2) ?? '0',
        radius: loadedState.radiusToNearest?.toStringAsFixed(2) ?? '0',
        merek: merek,
        model: model,
        imagePath: await _compressImage(File(photo.path)),
        gpsSnapshot: gpsSnapshot,
        faceRecognition: faceRecognitionStr,
        token: user.token ?? '',
      );

      // Submit
      final result = await submitAttendanceUseCase(params);

      result.fold(
        (failure) {
          // Extract message
          String msg = 'Gagal melakukan absensi';
          if (failure is NetworkFailure) {
            msg = failure.message;
          } else if (failure is ServerFailure) {
            msg = failure.message;
          } else if (failure.props.isNotEmpty) {
            msg = failure.props.first.toString();
          }
          emit(
            loadedState.copyWith(
              isSubmitting: false,
              submissionErrorMessage: msg,
            ),
          );
        },
        (successMessage) {
          emit(
            loadedState.copyWith(
              isSubmitting: false,
              submissionSuccessMessage: successMessage,
            ),
          );
        },
      );
    } catch (e) {
      emit(
        loadedState.copyWith(
          isSubmitting: false,
          submissionErrorMessage: e.toString(),
        ),
      );
    }
  }

  Future<String> _compressImage(File file) async {
    final int sizeInBytes = await file.length();
    final double sizeInMb = sizeInBytes / (1024 * 1024);

    if (sizeInMb <= 5) {
      return file.path;
    }

    // Compress
    final String targetPath =
        '${file.parent.path}/${DateTime.now().millisecondsSinceEpoch}_compressed.jpg';

    var result = await FlutterImageCompress.compressAndGetFile(
      file.absolute.path,
      targetPath,
      quality: 70, // Start with 70% quality
    );

    if (result == null) return file.path;

    return result.path;
  }

  Future<void> takePhotoAndSubmit() async {
    if (state is! AttendanceLoaded) return;

    try {
      final picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 600,
        imageQuality: 50,
      );

      if (photo == null) return; // User cancelled

      await submitAttendanceWithImage(photo);
    } catch (e) {
      final loadedState = state as AttendanceLoaded;
      emit(
        loadedState.copyWith(
          isSubmitting: false,
          submissionErrorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> _loadMapData() async {
    final rawScheduleType = user.result.jadwalAbsen?.tipe.trim().toLowerCase();
    final scheduleType = rawScheduleType == null || rawScheduleType.isEmpty
        ? null
        : rawScheduleType;
    final isLibur = scheduleType == 'lbr';
    final isWfa =
        !isLibur &&
        (scheduleType == 'wfh' ||
            (scheduleType == null && user.wfaStatus == 1));

    // prepare markers and circles
    final circles = <Circle>{};
    final polygons = <Polygon>{};

    // Markers removed as per user request, only circles

    for (var coord in user.daftarKordinat) {
      final double? lat = double.tryParse(coord.latitude);
      final double? lng = double.tryParse(coord.longitude);

      if (lat != null && lng != null) {
        final position = LatLng(lat, lng);

        circles.add(
          Circle(
            circleId: CircleId(coord.id.toString()),
            center: position,
            radius: coord.radiusMeter,
            fillColor: Colors.green.withAlpha(70),
            strokeColor: Colors.green,
            strokeWidth: 2,
          ),
        );

        if (coord.polygonPoints.isNotEmpty) {
          final points = coord.polygonPoints.map((p) {
            return LatLng(
              double.tryParse(p.latitude) ?? 0.0,
              double.tryParse(p.longitude) ?? 0.0,
            );
          }).toList();

          polygons.add(
            Polygon(
              polygonId: PolygonId(coord.id.toString()),
              points: points,
              fillColor: Colors.blue.withAlpha(70),
              strokeColor: Colors.blue,
              strokeWidth: 2,
            ),
          );
        }
      }
    }

    emit(
      AttendanceLoaded(
        isWfa: isWfa,
        isLibur: isLibur,
        circles: circles,
        polygons: polygons,
        isInsideRadius: isWfa || isLibur,
      ),
    );

    _startLocationTracking();
  }

  Future<void> _startLocationTracking() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (state is AttendanceLoaded) {
        emit(
          (state as AttendanceLoaded).copyWith(
            errorMessage: 'Layanan lokasi tidak aktif',
          ),
        );
      }
      return;
    }

    if (state is AttendanceLoaded) {
      emit((state as AttendanceLoaded).copyWith(isLoadingLocation: true));
    }

    try {
      final position = await Geolocator.getCurrentPosition();
      _updateLocation(position);
    } catch (_) {}

    _positionStreamSubscription =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.bestForNavigation,
            distanceFilter: 5,
          ),
        ).listen(
          (Position position) {
            _updateLocation(position);
          },
          onError: (e) {
            if (state is AttendanceLoaded) {
              emit(
                (state as AttendanceLoaded).copyWith(
                  errorMessage: 'Error tracking location: $e',
                ),
              );
            }
          },
        );
  }

  void _updateLocation(Position position) {
    if (state is! AttendanceLoaded) return;

    final loadedState = state as AttendanceLoaded;
    final LatLng currentLatLng = LatLng(position.latitude, position.longitude);

    bool inside = false;
    double minDistance = double.infinity;
    double? radiusToNearest;
    String? nearestPlace;

    if (user.daftarKordinat.isNotEmpty) {
      for (var coord in user.daftarKordinat) {
        final double? lat = double.tryParse(coord.latitude);
        final double? lng = double.tryParse(coord.longitude);

        if (lat != null && lng != null) {
          final center = LatLng(lat, lng);
          final distance = LocationUtils.calculateDistance(
            currentLatLng.latitude,
            currentLatLng.longitude,
            center.latitude,
            center.longitude,
          );

          if (distance < minDistance) {
            minDistance = distance;
            radiusToNearest = coord.radiusMeter;
            nearestPlace = coord.namaTempat;
          }

          // Check Polygon if exists
          if (coord.polygonPoints.isNotEmpty) {
            final polygonPoints = coord.polygonPoints.map((p) {
              return LatLng(
                double.tryParse(p.latitude) ?? 0.0,
                double.tryParse(p.longitude) ?? 0.0,
              );
            }).toList();

            if (LocationUtils.isPointInPolygon(currentLatLng, polygonPoints)) {
              inside = true;
            }
          }

          // Fallback to Radius if not already inside a polygon
          if (!inside) {
            if (LocationUtils.isWithinRadius(
              currentLatLng,
              center,
              coord.radiusMeter,
            )) {
              inside = true;
            }
          }
        }
      }

      emit(
        loadedState.copyWith(
          currentPosition: position,
          isInsideRadius: inside,
          isLoadingLocation: false,
          errorMessage: null,
          distanceToNearest: minDistance == double.infinity
              ? null
              : minDistance,
          radiusToNearest: radiusToNearest,
          nearestPlaceName: nearestPlace,
        ),
      );
      return;
    }

    emit(
      loadedState.copyWith(
        currentPosition: position,
        isInsideRadius: inside,
        isLoadingLocation: false,
        errorMessage: null,
      ),
    );
  }

  @override
  Future<void> close() async {
    await _positionStreamSubscription?.cancel();
    _positionStreamSubscription = null;
    return super.close();
  }
}
