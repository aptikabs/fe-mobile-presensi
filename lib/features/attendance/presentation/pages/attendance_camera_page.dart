import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/presentation/widgets/custom_toast.dart';
import '../../../../../core/utils/permission_helper.dart';
import '../bloc/attendance_cubit.dart';
import '../bloc/attendance_state.dart';

class AttendanceCameraPage extends StatefulWidget {
  const AttendanceCameraPage({super.key});

  @override
  State<AttendanceCameraPage> createState() => _AttendanceCameraPageState();
}

class _AttendanceCameraPageState extends State<AttendanceCameraPage> {
  CameraController? _controller;
  XFile? _capturedImage;
  bool _isCameraInitialized = false;
  bool _isPermissionDenied = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkPermissionAndInitialize();
    });
  }

  Future<void> _checkPermissionAndInitialize() async {
    final granted = await PermissionHelper.requestPermission(
      context: context,
      permission: Permission.camera,
      title: 'Izin Kamera Diperlukan',
      content:
          'Aplikasi memerlukan izin kamera untuk mengambil foto sebagai bukti presensi.',
      icon: Icons.camera_alt_rounded,
    );

    if (granted) {
      if (mounted) {
        setState(() {
          _isPermissionDenied = false;
        });
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

      // Use front camera if available, otherwise first
      final camera = cameras.firstWhere(
        (cam) => cam.lensDirection == CameraLensDirection.front,
        orElse: () => cameras.first,
      );

      _controller = CameraController(
        camera,
        ResolutionPreset.medium,
        enableAudio: false,
      );

      await _controller!.initialize();
      if (!mounted) return;
      setState(() {
        _isCameraInitialized = true;
      });
    } catch (e) {
      if (!mounted) return;
      CustomToast.show(context, 'Gagal inisialisasi kamera: $e', isError: true);
    }
  }

  Future<void> _takePicture() async {
    if (!_isCameraInitialized || _controller == null) return;

    try {
      final XFile image = await _controller!.takePicture();
      if (!mounted) return;
      setState(() {
        _capturedImage = image;
      });
    } catch (e) {
      if (!mounted) return;
      CustomToast.show(context, 'Gagal mengambil foto: $e', isError: true);
    }
  }

  void _retakePicture() {
    setState(() {
      _capturedImage = null;
    });
  }

  void _submit() {
    if (_capturedImage == null) return;
    context.read<AttendanceCubit>().submitAttendanceWithImage(_capturedImage!);
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: BlocConsumer<AttendanceCubit, AttendanceState>(
          listenWhen: (previous, current) {
            if (previous is AttendanceLoaded && current is AttendanceLoaded) {
              return previous.submissionSuccessMessage !=
                      current.submissionSuccessMessage ||
                  previous.submissionErrorMessage !=
                      current.submissionErrorMessage;
            }
            return false;
          },
          listener: (context, state) {
            if (state is AttendanceLoaded) {
              if (state.submissionSuccessMessage != null ||
                  state.submissionErrorMessage != null) {
                // Return to main page to show result dialog
                Navigator.of(context).pop();
              }
            }
          },
          builder: (context, state) {
            final isSubmitting =
                state is AttendanceLoaded && state.isSubmitting;

            if (_isPermissionDenied) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.videocam_off_rounded,
                        size: 48,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Akses Kamera Ditolak',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Mohon izinkan akses kamera untuk melanjutkan presensi.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _checkPermissionAndInitialize,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary500,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Izinkan Kamera'),
                      ),
                      const SizedBox(height: 16),
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Kembali',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            if (!_isCameraInitialized) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary500),
              );
            }

            return Column(
              children: [
                // Header / Back Button
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Text(
                          'Ambil Foto Presensi',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      const SizedBox(width: 48), // Balance for back button
                    ],
                  ),
                ),

                // Camera Area
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[900],
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Center(
                          child: AspectRatio(
                            aspectRatio: 3 / 4,
                            child: _capturedImage != null
                                ? Image.file(
                                    File(_capturedImage!.path),
                                    fit: BoxFit.cover,
                                  )
                                : CameraPreview(_controller!),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // Controls
                SafeArea(
                  bottom: true,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    child: _capturedImage == null
                        ? Center(
                            child: GestureDetector(
                              onTap: _takePicture,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  border: Border.all(
                                    color: AppColors.primary500,
                                    width: 4,
                                  ),
                                ),
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: AppColors.primary500,
                                  size: 32,
                                ),
                              ),
                            ),
                          )
                        : Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: isSubmitting
                                          ? null
                                          : _retakePicture,
                                      icon: const Icon(Icons.refresh),
                                      label: const Text('Foto Ulang'),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: Colors.white,
                                        side: const BorderSide(
                                          color: Colors.white,
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: isSubmitting ? null : _submit,
                                      icon: isSubmitting
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                color: Colors.white,
                                                strokeWidth: 2,
                                              ),
                                            )
                                          : const Icon(Icons.check),
                                      label: Text(
                                        isSubmitting
                                            ? 'Mengirim...'
                                            : 'Kirim Presensi',
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.success500,
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(16),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
