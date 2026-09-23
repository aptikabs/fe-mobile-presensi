import 'dart:io';
import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/presentation/widgets/custom_toast.dart';
import '../../../../../core/utils/permission_helper.dart';
import '../bloc/attendance_cubit.dart';
import '../bloc/attendance_state.dart';
import 'package:audioplayers/audioplayers.dart';

enum LivenessStep { start, blink, smile, processing, captured }
enum LivenessPurpose { attendance, deviceRegistration }

class AttendanceLivenessPage extends StatefulWidget {
  final LivenessPurpose purpose;
  final Future<void> Function(XFile image)? onCaptured;

  const AttendanceLivenessPage({
    super.key,
    this.purpose = LivenessPurpose.attendance,
    this.onCaptured,
  });

  @override
  State<AttendanceLivenessPage> createState() => _AttendanceLivenessPageState();
}

class _AttendanceLivenessPageState extends State<AttendanceLivenessPage>
    with SingleTickerProviderStateMixin {
  CameraController? _controller;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;
  XFile? _capturedImage;

  // ML Kit
  late FaceDetector _faceDetector;
  bool _isBusy = false;
  LivenessStep _currentStep = LivenessStep.start;
  String _instructionText = "Posisikan wajah di area scanner";

  // Debouncing
  int _consecutiveSmiles = 0;
  bool _blinkClosedDetected = false;

  // Animation
  late AnimationController _scanController;
  late Animation<double> _scanAnimation;

  // Audio
  late AudioPlayer _audioPlayer;

  @override
  void initState() {
    super.initState();
    _audioPlayer = AudioPlayer();

    // Initialize Face Detector
    final options = FaceDetectorOptions(
      enableClassification: true,
      enableTracking: true,
      performanceMode: FaceDetectorMode.accurate,
    );
    _faceDetector = FaceDetector(options: options);

    // Scanner Animation
    _scanController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _scanAnimation = Tween<double>(begin: 0.1, end: 0.9).animate(
      CurvedAnimation(parent: _scanController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionAndInitialize();
    });
  }

  Future<void> _checkPermissionAndInitialize() async {
    final granted = await PermissionHelper.requestPermission(
      context: context,
      permission: Permission.camera,
      title: 'Izin Kamera',
      content: 'Diperlukan untuk verifikasi wajah.',
      icon: Icons.face_retouching_natural,
    );

    if (granted) {
      if (mounted) {
        setState(() => _isPermissionDenied = false);
        _initializeCamera();
      }
    } else {
      if (mounted) {
        setState(() {
          _isPermissionDenied = true;
          _isCameraInitialized = false;
        });
      }
    }
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          CustomToast.show(
            context,
            'Tidak ada kamera ditemukan',
            isError: true,
          );
        }
        return;
      }

      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
        imageFormatGroup: Platform.isAndroid
            ? ImageFormatGroup.nv21
            : ImageFormatGroup.bgra8888,
      );

      await _controller!.initialize();

      // For portrait mode
      await _controller!.lockCaptureOrientation(DeviceOrientation.portraitUp);

      if (!mounted) return;

      await _controller!.startImageStream(_processCameraImage);

      setState(() {
        _isCameraInitialized = true;
        _currentStep = LivenessStep.start;
      });
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, 'Gagal inisialisasi: $e', isError: true);
      }
    }
  }

  Future<void> _processCameraImage(CameraImage image) async {
    if (_isBusy ||
        _currentStep == LivenessStep.processing ||
        _currentStep == LivenessStep.captured) {
      return;
    }
    _isBusy = true;

    try {
      final inputImage = _inputImageFromCameraImage(image);
      if (inputImage == null) {
        _isBusy = false;
        return;
      }

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isEmpty) {
        if (mounted && _instructionText != "Wajah tidak terdeteksi") {
          setState(() {
            _instructionText = "Wajah tidak terdeteksi";
          });
        }
      } else {
        final face = faces.first;
        if (mounted) {
          _processLivenessLogic(face);
        }
      }
    } catch (e) {
      debugPrint("Error ML: $e");
    } finally {
      _isBusy = false;
    }
  }

  void _processLivenessLogic(Face face) {
    if (_currentStep == LivenessStep.start) {
      setState(() {
        _currentStep = LivenessStep.blink;
        _instructionText = "Langkah 1: Silakan Berkedip";
        _playAudio('audio/kedip.MP3');
      });
    } else if (_currentStep == LivenessStep.blink) {
      final leftOpen = face.leftEyeOpenProbability ?? 1.0;
      final rightOpen = face.rightEyeOpenProbability ?? 1.0;

      if (leftOpen < 0.35 || rightOpen < 0.35) {
        _blinkClosedDetected = true;
        return;
      }

      if (_blinkClosedDetected) {
        _blinkClosedDetected = false;
        setState(() {
          _currentStep = LivenessStep.smile;
          _instructionText = "Langkah 2: Silakan Tersenyum";
          _playAudio('audio/senyum.MP3');
        });
      }
    } else if (_currentStep == LivenessStep.smile) {
      final smileProb = face.smilingProbability ?? 0.0;
      // Threshold lowered to 0.45 (easier to detect smile)
      if (smileProb > 0.45) {
        _consecutiveSmiles++;
        // Reduced to > 1 for faster response (2 consecutive frames)
        if (_consecutiveSmiles > 1) {
          _autoCapture();
        }
      } else {
        _consecutiveSmiles = 0;
      }
    }
  }

  Future<void> _autoCapture() async {
    if (_currentStep == LivenessStep.processing) return;

    await _audioPlayer.stop();

    setState(() {
      _currentStep = LivenessStep.processing;
      _instructionText = "Mengambil Foto...";
    });

    try {
      await _controller!.stopImageStream();
      final XFile image = await _controller!.takePicture();

      if (mounted) {
        setState(() {
          _capturedImage = image;
          _currentStep = LivenessStep.captured;
        });
      }
    } catch (e) {
      if (mounted) {
        CustomToast.show(context, "Error Capture: $e", isError: true);
        _restart();
      }
    }
  }

  Future<void> _restart() async {
    _currentStep = LivenessStep.start;
    _capturedImage = null;
    _consecutiveSmiles = 0;
    _blinkClosedDetected = false;

    // Reset Audio
    await _audioPlayer.stop();
    // Restart Blink Audio
    _playAudio('audio/kedip.MP3');
    _instructionText = "Langkah 1: Silakan Berkedip";
    _currentStep = LivenessStep.blink;

    if (_controller != null && !_controller!.value.isStreamingImages) {
      await _controller!.startImageStream(_processCameraImage);
    }
    setState(() {});
  }

  Future<void> _submit() async {
    _audioPlayer.stop();
    if (_capturedImage == null) return;
    if (widget.purpose == LivenessPurpose.deviceRegistration) {
      final callback = widget.onCaptured;
      if (callback == null) {
        CustomToast.show(
          context,
          'Proses pendaftaran perangkat tidak tersedia.',
          isError: true,
        );
        return;
      }
      await callback(_capturedImage!);
      if (mounted) Navigator.of(context).pop();
    } else {
      await context.read<AttendanceCubit>().submitAttendanceWithImage(
        _capturedImage!,
      );
    }
  }

  Future<void> _playAudio(String path) async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(path));
    } catch (e) {
      debugPrint("Audio Error: $e");
    }
  }

  InputImage? _inputImageFromCameraImage(CameraImage image) {
    final camera = _controller!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation? rotation;
    if (Platform.isIOS) {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation);
    } else if (Platform.isAndroid) {
      var rotationCompensation =
          _orientations[_controller!.value.deviceOrientation];
      if (rotationCompensation == null) return null;
      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation);
    }

    if (rotation == null) return null;

    final format =
        InputImageFormatValue.fromRawValue(image.format.raw) ??
        InputImageFormat.nv21;
    if (image.planes.isEmpty) return null;
    final plane = image.planes.first;

    return InputImage.fromBytes(
      bytes: _concatenatePlanes(image.planes),
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  final _orientations = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  Uint8List _concatenatePlanes(List<Plane> planes) {
    final WriteBuffer allBytes = WriteBuffer();
    for (final Plane plane in planes) {
      allBytes.putUint8List(plane.bytes);
    }
    return allBytes.done().buffer.asUint8List();
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _faceDetector.close();
    if (_controller != null && _controller!.value.isStreamingImages) {
      _controller!.stopImageStream();
    }
    _controller?.dispose();
    _scanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPermissionDenied) {
      return Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Container(
            margin: const EdgeInsets.all(24),
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: AppColors.neutral50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.neutral200,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.videocam_off_rounded,
                    size: 32,
                    color: AppColors.neutral500,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Akses Kamera Ditolak',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: AppColors.neutral800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mohon izinkan akses kamera untuk melanjutkan pendaftaran.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: AppColors.neutral600),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _checkPermissionAndInitialize,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: AppColors.textInverse,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Izinkan Kamera'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: widget.purpose == LivenessPurpose.attendance
            ? BlocConsumer<AttendanceCubit, AttendanceState>(
                listener: (context, state) {
                  if (state is AttendanceLoaded) {
                    if (state.submissionErrorMessage != null) {
                      CustomToast.show(
                        context,
                        state.submissionErrorMessage!,
                        isError: true,
                      );
                    }
                    if (state.submissionSuccessMessage != null) {
                      CustomToast.show(
                        context,
                        "Presensi Berhasil Recorded",
                        isError: false,
                      );
                      // Pop until the first route (usually Dashboard/Home)
                      Navigator.of(context).popUntil((route) => route.isFirst);
                    }
                  }
                },
                builder: (context, state) {
                  final isSubmitting =
                      state is AttendanceLoaded && state.isSubmitting;
                  return _buildLivenessBody(isSubmitting: isSubmitting);
                },
              )
            : _buildLivenessBody(),
      ),
    );
  }

  Widget _buildLivenessBody({bool isSubmitting = false}) {
    if (_currentStep == LivenessStep.captured && _capturedImage != null) {
      return _buildReviewUI(isSubmitting);
    }

    if (!_isCameraInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      fit: StackFit.expand,
      children: [
        CameraPreview(_controller!),
        _buildModernOverlay(),
        _buildBottomCard(),
        Positioned(
          top: 20,
          left: 20,
          child: FloatingActionButton.small(
            backgroundColor: Colors.white24,
            elevation: 0,
            onPressed: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildModernOverlay() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = constraints.biggest;
        final scanTop = size.height * 0.2;
        final scanWidth = size.width * 0.8;
        final scanHeight = scanWidth * 1.3;
        final scanLeft = (size.width - scanWidth) / 2;

        return Stack(
          children: [
            ColorFiltered(
              colorFilter: const ColorFilter.mode(
                Colors.black54,
                BlendMode.srcOut,
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: const BoxDecoration(
                      color: Colors.black,
                      backgroundBlendMode: BlendMode.dstOut,
                    ),
                  ),
                  Positioned(
                    top: scanTop,
                    left: scanLeft,
                    width: scanWidth,
                    height: scanHeight,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Scanner Line
            AnimatedBuilder(
              animation: _scanAnimation,
              builder: (context, child) {
                return Positioned(
                  top: scanTop + (scanHeight * _scanAnimation.value),
                  left: scanLeft,
                  width: scanWidth,
                  child: Container(
                    height: 4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          AppColors.primary500.withAlpha(200),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
            // Corners
            Positioned(
              top: scanTop - 2,
              left: scanLeft - 2,
              width: scanWidth + 4,
              height: scanHeight + 4,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.white30, width: 2),
                  borderRadius: BorderRadius.circular(26),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBottomCard() {
    return Positioned(
      bottom: 30,
      left: 20,
      right: 20,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              border: Border.all(color: Colors.white24),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _instructionText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStepItem(
                      Icons.visibility,
                      "Berkedip",
                      _currentStep == LivenessStep.blink ||
                          _currentStep.index > 1,
                    ),
                    Container(width: 30, height: 2, color: Colors.white24),
                    _buildStepItem(
                      Icons.sentiment_very_satisfied,
                      "Senyum",
                      _currentStep == LivenessStep.smile ||
                          _currentStep.index > 2,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepItem(IconData icon, String label, bool isActive) {
    final color = isActive ? AppColors.success500 : Colors.white24;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isActive ? Colors.white : Colors.white10,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: isActive ? AppColors.success500 : Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildReviewUI(bool isSubmitting) {
    return Column(
      children: [
        Expanded(
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(File(_capturedImage!.path), fit: BoxFit.cover),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                height: 100,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Colors.black.withAlpha(200), Colors.transparent],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.all(24),
          color: Colors.black,
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.check_circle, color: AppColors.success500),
                  SizedBox(width: 8),
                  Text(
                    "Verifikasi Liveness Berhasil",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isSubmitting ? null : _restart,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text("Foto Ulang"),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary500,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 8,
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                            : Text(
                              widget.purpose == LivenessPurpose.deviceRegistration
                                ? "Daftarkan Perangkat"
                                : "Kirim Absen",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
