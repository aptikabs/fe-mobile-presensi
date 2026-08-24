import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:camera/camera.dart';

import 'package:permission_handler/permission_handler.dart';
import '../../../../../core/utils/permission_helper.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/presentation/widgets/custom_toast.dart';
import '../../bloc/register_device/register_device_cubit.dart';
import '../../bloc/register_device/register_device_state.dart';

class RegisterDeviceForm extends StatefulWidget {
  const RegisterDeviceForm({super.key});

  @override
  State<RegisterDeviceForm> createState() => _RegisterDeviceFormState();
}

class _RegisterDeviceFormState extends State<RegisterDeviceForm> {
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
          'Aplikasi memerlukan izin kamera untuk mengambil foto wajah Anda sebagai syarat pendaftaran perangkat.',
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
    final cameras = await availableCameras();
    if (cameras.isEmpty) return;

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

    try {
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

  Future<void> _submit() async {
    if (_capturedImage == null) {
      CustomToast.show(
        context,
        'Harap ambil foto terlebih dahulu',
        isError: true,
      );
      return;
    }

    context.read<RegisterDeviceCubit>().submit(
      image: _capturedImage!,
      mode: FaceRecognitionMode.medium,
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_isPermissionDenied) {
      return Container(
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
      );
    }

    if (!_isCameraInitialized) {
      return const SizedBox(
        height: 300,
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary500),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Camera Preview Container
        Center(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 400),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow.withAlpha(50),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: AspectRatio(
                aspectRatio: 3 / 4,
                child: _capturedImage != null
                    ? Image.file(File(_capturedImage!.path), fit: BoxFit.cover)
                    : CameraPreview(_controller!),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),

        // Action Buttons
        if (_capturedImage == null)
          Center(
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _takePicture,
                icon: const Icon(Icons.camera_alt_rounded),
                label: const Text('Ambil Foto Wajah'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.buttonPrimary,
                  foregroundColor: AppColors.textInverse,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                  shadowColor: AppColors.primary500.withAlpha(60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          )
        else
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _retakePicture,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Foto Ulang'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    foregroundColor: AppColors.textSecondary,
                    side: const BorderSide(color: AppColors.neutral300),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),

        const SizedBox(height: 16),

        // Submit Button (only visible if image taken)
        BlocBuilder<RegisterDeviceCubit, RegisterDeviceState>(
          builder: (context, state) {
            final isBusy = state.status == PageStatus.busy;

            if (_capturedImage == null) return const SizedBox.shrink();

            return SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isBusy ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.success500, // Green for action
                  foregroundColor: AppColors.textInverse,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 4,
                  shadowColor: AppColors.success500.withAlpha(60),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  disabledBackgroundColor: AppColors.neutral300,
                ),
                child: isBusy
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Daftar Perangkat',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            );
          },
        ),
      ],
    );
  }
}
