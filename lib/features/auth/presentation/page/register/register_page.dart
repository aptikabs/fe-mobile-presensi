import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../../app/router/app_routes_names.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../../../core/presentation/widgets/custom_toast.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../../domain/usecases/register_device_usecase.dart';
import '../../bloc/register_device/register_device_cubit.dart';
import '../../bloc/register_device/register_device_state.dart';
import '../../widgets/register/register_device_form.dart';

class RegisterPage extends StatelessWidget {
  final String nip;
  const RegisterPage({super.key, this.nip = ''});

  @override
  Widget build(BuildContext context) {
    final repository = context.read<AuthRepository>();
    final registerDeviceUseCase = RegisterDeviceUseCase(repository);
    return BlocProvider(
      create: (context) => RegisterDeviceCubit(
        registerDeviceUseCase: registerDeviceUseCase,
        nip: nip,
      ),
      child: const _RegisterView(),
    );
  }
}

class _RegisterView extends StatelessWidget {
  const _RegisterView();

  void _handleFailure(BuildContext context, String message) {
    CustomToast.show(context, message, isError: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.neutral50,
      appBar: AppBar(
        title: const Text(
          'Pendaftaran Absensi',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 4),
                const Text(
                  'Verifikasi Wajah',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Mendaftarkan perangkat.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Card(
                  elevation: 8,
                  shadowColor: AppColors.shadow.withAlpha(20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(24),
                  ),
                  color: AppColors.surface,
                  child: Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: BlocListener<RegisterDeviceCubit, RegisterDeviceState>(
                      listener: (context, state) {
                        if (state.status == PageStatus.done) {
                          if (state.error == null) {
                            CustomToast.show(
                              context,
                              state.successMessage ??
                                  'Berhasil mendaftar perangkat. Silakan login.',
                            );
                            context.go(AppRouteNames.login);
                          } else {
                            _handleFailure(context, state.error!);
                          }
                        }
                      },
                      child: const RegisterDeviceForm(),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // Footer or Help Text
                const Text(
                  'Pastikan wajah terlihat jelas dan pencahayaan cukup.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
