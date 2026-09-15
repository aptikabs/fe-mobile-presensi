import 'package:epresensi_mobile/app/router/app_routes_names.dart';
import 'package:epresensi_mobile/core/constants/app_colors.dart';
import 'package:epresensi_mobile/features/auth/presentation/bloc/auth/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:permission_handler/permission_handler.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with WidgetsBindingObserver {
  bool _isChecking = true;
  bool _permissionsGranted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissions();
    }
  }

  Future<void> _checkPermissions() async {
    // Check initial status
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;

    final isGranted =
        cameraStatus.isGranted &&
        (locationStatus.isGranted || locationStatus.isLimited);

    if (isGranted) {
      if (mounted) {
        setState(() {
          _permissionsGranted = true;
          _isChecking = false;
        });
        _proceedToApp();
      }
    } else {
      // If not granted, we show the permission request UI
      if (mounted) {
        setState(() {
          _permissionsGranted = false;
          _isChecking = false;
        });
      }
    }
  }

  Future<void> _requestPermissions() async {
    final cameraStatus = await Permission.camera.status;
    final locationStatus = await Permission.location.status;

    if (cameraStatus.isPermanentlyDenied ||
        locationStatus.isPermanentlyDenied) {
      openAppSettings();
      return;
    }

    setState(() => _isChecking = true);

    Map<Permission, PermissionStatus> statuses = await [
      Permission.camera,
      Permission.location,
    ].request();

    final camera = statuses[Permission.camera];
    final location = statuses[Permission.location];

    final isGranted =
        camera == PermissionStatus.granted &&
        (location == PermissionStatus.granted ||
            location == PermissionStatus.limited);

    if (isGranted) {
      if (mounted) {
        setState(() {
          _permissionsGranted = true;
          _isChecking = false;
        });
        _proceedToApp();
      }
    } else {
      if (mounted) {
        setState(() {
          _permissionsGranted = false;
          _isChecking = false;
        });

        // If newly denied permanently, show a hint
        if (camera == PermissionStatus.permanentlyDenied ||
            location == PermissionStatus.permanentlyDenied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Izin ditolak secara permanen. Mohon aktifkan di Pengaturan.',
                ),
              ),
            );
          }
        }
      }
    }
  }

  bool _proceedExecuting = false;
  Future<void> _proceedToApp() async {
    if (_proceedExecuting) return;
    _proceedExecuting = true;

    // Short delay for splash effect
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;

    final authCubit = context.read<AuthCubit>();
    await authCubit.checkAuthStatus();

    if (!mounted) return;

    final state = authCubit.state;
    if (state is AuthAuthenticated) {
      context.go(AppRouteNames.home);
    } else {
      context.go(AppRouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image
          // Image.asset('assets/images/backgroud.png', fit: BoxFit.cover),
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                Image.asset('assets/logo/logo_app_launcher.webp', width: 200),
                const SizedBox(height: 20),

                const Text(
                  'MEMBARA',
                  style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),

                const SizedBox(height: 6),

                const SizedBox(
                  width: 300,
                  child: Text(
                  'Manajemen Elektronik Monitoring Berbasis Absensi dan Rekam Aparatur',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  ),  
                ),
              ),
                // Show permission UI only if needed, otherwise just the splash
                if (!_isChecking && !_permissionsGranted) ...[
                  const SizedBox(height: 32),
                  Container(
                    padding: const EdgeInsets.all(24),
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text(
                          'Izin Diperlukan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Aplikasi memerlukan akses Kamera dan Lokasi. Mohon izinkan akses.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.neutral600),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _requestPermissions,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: const Text('Izinkan Akses'),
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () => openAppSettings(),
                          child: const Text(
                            'Buka Pengaturan',
                            style: TextStyle(color: AppColors.neutral500),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_isChecking) ...[
                  // Optional: Simple loader if checking takes time
                  const SizedBox(height: 32),
                  const CircularProgressIndicator(color: AppColors.primary500),
                ],
              ],
            ),
          ),

          // Branding at bottom
          Positioned(
            bottom: 1,
            left: 0,
            right: 0,
            child: Column(
              children: [
                 Center(
                  child: Image.asset(
                    'assets/images/branding.webp', height: 200,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}