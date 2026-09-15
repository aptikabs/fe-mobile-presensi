import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/network/network_info.dart';
import '../../../../../core/network/pinned_http_client.dart';
import '../../../auth/presentation/bloc/auth/auth_cubit.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../data/repositories/attendance_repository_impl.dart';
import '../../domain/usecases/submit_attendance.dart';
import '../../../../../core/presentation/widgets/custom_toast.dart';
import '../bloc/attendance_cubit.dart';
import '../bloc/attendance_state.dart';

import 'attendance_liveness_page.dart';

class AttendancePage extends StatelessWidget {
  const AttendancePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Access User from AuthCubit to pass to AttendanceCubit
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      return const Scaffold(
        body: Center(child: Text("User not authenticated")),
      );
    }

    // Dependency Injection (Manual for now to avoid global service locator changes)
    return RepositoryProvider(
      create: (context) => AttendanceRepositoryImpl(
        remoteDataSource: AttendanceRemoteDataSourceImpl(
          client: PinnedHttpClient.createClient(),
        ),
        networkInfo: context.read<NetworkInfo>(),
      ),
      child: BlocProvider(
        create: (context) {
          final repository = context.read<AttendanceRepositoryImpl>();
          return AttendanceCubit(
            user: authState.user,
            submitAttendanceUseCase: SubmitAttendance(repository),
          )..initialize();
        },
        child: const AttendanceView(),
      ),
    );
  }
}

class AttendanceView extends StatefulWidget {
  const AttendanceView({super.key});

  @override
  State<AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<AttendanceView> {
  GoogleMapController? _mapController;
  bool _hasInitialZoomed = false;
  bool _isLoadingDialogShown = false;

  void _showLoading(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.white),
      ),
    );
  }

  void _showResultDialog(BuildContext context, bool isSuccess, String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Icon(
          isSuccess ? Icons.check_circle_outline : Icons.error_outline,
          color: isSuccess ? AppColors.success : AppColors.error,
          size: 60,
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // Close dialog
              if (isSuccess) {
                // Navigate away or reset? Default to back for now
                Navigator.pop(context);
              }
            },
            child: const Text(
              "OK",
              style: TextStyle(color: AppColors.primary500),
            ),
          ),
        ],
      ),
    );
  }

  void _goToCurrentLocation(LatLng position) {
    _mapController?.animateCamera(CameraUpdate.newLatLngZoom(position, 14));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: const Text(
          'Presensi',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.textPrimary),
      ),
      body: BlocListener<AttendanceCubit, AttendanceState>(
        listenWhen: (previous, current) {
          if (previous is AttendanceLoaded && current is AttendanceLoaded) {
            return previous.isLoadingLocation != current.isLoadingLocation;
          }
          return false;
        },
        listener: (context, state) {
          if (state is AttendanceLoaded) {
            if (state.isLoadingLocation) {
              CustomToast.show(
                context,
                "Sedang mencari lokasi...",
                duration: const Duration(seconds: 4),
              );
            } else {
              // Loading finished
              if (state.currentPosition != null) {
                CustomToast.show(context, "Lokasi ditemukan", isError: false);
              }
            }
          }
        },
        child: BlocConsumer<AttendanceCubit, AttendanceState>(
          listenWhen: (previous, current) {
            if (previous is AttendanceLoaded && current is AttendanceLoaded) {
              return previous.isSubmitting != current.isSubmitting ||
                  previous.submissionSuccessMessage !=
                      current.submissionSuccessMessage ||
                  previous.submissionErrorMessage !=
                      current.submissionErrorMessage ||
                  previous.currentPosition != current.currentPosition;
            }
            return true;
          },
          listener: (context, state) {
            if (state is AttendanceSecurityBlocked) {
              _showResultDialog(context, false, state.message);
              return;
            }

            if (state is AttendanceLoaded) {
              if (state.errorMessage != null && !state.isLoadingLocation) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(state.errorMessage!),
                    backgroundColor: AppColors.error,
                  ),
                );
              }

              // Submission Handling
              if (state.isSubmitting) {
                final isCurrent = ModalRoute.of(context)?.isCurrent ?? false;
                if (isCurrent) {
                  _showLoading(context);
                  _isLoadingDialogShown = true;
                }
              } else {
                if (_isLoadingDialogShown) {
                  Navigator.of(context, rootNavigator: true).pop();
                  _isLoadingDialogShown = false;
                }
              }

              if (state.submissionSuccessMessage != null ||
                  state.submissionErrorMessage != null) {
                if (state.submissionSuccessMessage != null) {
                  _showResultDialog(
                    context,
                    true,
                    state.submissionSuccessMessage!,
                  );
                } else if (state.submissionErrorMessage != null) {
                  _showResultDialog(
                    context,
                    false,
                    state.submissionErrorMessage!,
                  );
                }
              }

              // Auto Zoom Logic
              if (state.currentPosition != null && _mapController != null) {
                final latLng = LatLng(
                  state.currentPosition!.latitude,
                  state.currentPosition!.longitude,
                );
                if (!_hasInitialZoomed) {
                  _mapController!.animateCamera(
                    CameraUpdate.newLatLngZoom(latLng, 20),
                  );
                  _hasInitialZoomed = true;
                }
              }
            }
          },
          builder: (context, state) {
            if (state is AttendanceLoading) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary500),
              );
            }

            if (state is AttendanceError) {
              return Center(
                child: Text(
                  state.message,
                  style: const TextStyle(color: AppColors.error),
                ),
              );
            }

            // LOCATION PERMISSION CARD
            if (state is AttendancePermissionRequired) {
              return _buildPermissionCard(
                context,
                Icons.location_on_rounded,
                "Izin Lokasi Diperlukan",
                "Aplikasi memerlukan lokasi untuk memvalidasi presensi.",
                () =>
                    context.read<AttendanceCubit>().requestLocationPermission(),
              );
            }

            // CAMERA PERMISSION CARD
            if (state is AttendanceCameraPermissionRequired) {
              return _buildPermissionCard(
                context,
                Icons.camera_alt_rounded,
                "Izin Kamera Diperlukan",
                "Aplikasi memerlukan kamera untuk mengambil foto presensi.",
                () => context.read<AttendanceCubit>().requestCameraPermission(),
              );
            }

            if (state is AttendanceLoaded) {
              return Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: const CameraPosition(
                      target: LatLng(
                        -3.792982,
                        102.270556,
                      ), // Diskominfotik Default
                      zoom: 14,
                    ),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: false,
                    zoomControlsEnabled: false,
                    circles: state.circles,
                    polygons: state.polygons,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (state.currentPosition != null) {
                        _mapController!.animateCamera(
                          CameraUpdate.newLatLngZoom(
                            LatLng(
                              state.currentPosition!.latitude,
                              state.currentPosition!.longitude,
                            ),
                            18,
                          ),
                        );
                        _hasInitialZoomed = true;
                      }
                    },
                  ),
                  Positioned(
                    top: MediaQuery.of(context).padding.top,
                    right: 20.0,
                    child: FloatingActionButton(
                      heroTag: "fab_location",
                      backgroundColor: Colors.white,
                      elevation: 4,
                      onPressed: () {
                        if (state.currentPosition != null) {
                          _goToCurrentLocation(
                            LatLng(
                              state.currentPosition!.latitude,
                              state.currentPosition!.longitude,
                            ),
                          );
                        } else {
                          context
                              .read<AttendanceCubit>()
                              .initialize(); // Re-request location
                        }
                      },
                      child: const Icon(
                        Icons.my_location,
                        color: AppColors.primary500,
                      ),
                    ),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: _buildBottomPanel(context, state),
                  ),
                ],
              );
            }
            return const SizedBox();
          },
        ),
      ),
    );
  }

  Widget _buildPermissionCard(
    BuildContext context,
    IconData icon,
    String title,
    String desc,
    VoidCallback onAllow,
  ) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Card(
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondary100,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: AppColors.secondary500),
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  desc,
                  style: const TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: onAllow,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.buttonPrimary,
                      foregroundColor: AppColors.textInverse,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text("Izinkan"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomPanel(BuildContext context, AttendanceLoaded state) {
    final distanceInfo = state.distanceToNearest != null
        ? '${state.distanceToNearest!.toStringAsFixed(0)} Meter'
        : '-';

    final placeName = state.nearestPlaceName ?? 'Lokasi Tidak Diketahui';

    final bool canPresensi =
        !state.isLoadingLocation &&
        state.currentPosition != null &&
        (state.isWfa || state.isInsideRadius);

    final Color statusColor = canPresensi
        ? AppColors.success500
        : AppColors.error;

    final String buttonText;
    if (canPresensi) {
      buttonText = "Lanjutkan Presensi";
    } else if (state.isLoadingLocation || state.currentPosition == null) {
      buttonText = "Memeriksa Lokasi...";
    } else {
      buttonText = "Di Luar Radius Kantor";
    }

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        bottom: true,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.neutral300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.location_on, color: statusColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        placeName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Jarak dari kantor: $distanceInfo",
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutral200),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildInfoItem(Icons.near_me, "Jarak", distanceInfo),
                  Container(width: 1, height: 24, color: AppColors.neutral300),
                  _buildInfoItem(Icons.speed, "Akurasi", "High"),
                ],
              ),
            ),
            const SizedBox(height: 24),
            if (!state.isWfa && !state.isInsideRadius)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.error.withValues(alpha: 0.5),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.error,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        "Anda berada di luar radius kantor",
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: canPresensi
                    ? () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BlocProvider.value(
                              value: context.read<AttendanceCubit>(),
                              child: const AttendanceLivenessPage(),
                            ),
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  disabledBackgroundColor: AppColors.neutral300,
                  foregroundColor: AppColors.textInverse,
                  disabledForegroundColor: AppColors.neutral500,
                  elevation: canPresensi ? 4 : 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  buttonText,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textSecondary,
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
