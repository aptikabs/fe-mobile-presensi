import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/error/auth_exceptions.dart';
import '../../../../core/presentation/widgets/custom_dialog.dart';
import '../../../../core/presentation/widgets/custom_toast.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/change_device_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../bloc/change_device/change_device_cubit.dart';
import '../bloc/change_device/change_device_state.dart';
import '../bloc/login_state.dart';

class ChangeDeviceDialog extends StatelessWidget {
  final LoginState state;

  const ChangeDeviceDialog({super.key, required this.state});

  @override
  Widget build(BuildContext context) {
    // Resolve NIP from LoginState error data
    String nip = state.username;
    if (state.error is DeviceMismatchException) {
      final data = (state.error as DeviceMismatchException).data;
      if (data != null) {
        if (data['nip'] != null && data['nip'].toString().isNotEmpty) {
          nip = data['nip'].toString();
        } else if (data['detail_pegawai'] != null &&
            data['detail_pegawai']['nip'] != null) {
          nip = data['detail_pegawai']['nip'].toString();
        } else if (data['hasil_login'] != null &&
            data['hasil_login']['nip'] != null) {
          nip = data['hasil_login']['nip'].toString();
        }
      }
    }

    // DI for Cubit (Simplified for this context, ideally provided upstream)
    final repository = context.read<AuthRepository>();
    final changeDeviceUseCase = ChangeDeviceUseCase(repository);
    final loginUseCase = LoginUseCase(repository);

    return BlocProvider(
      create: (context) => ChangeDeviceCubit(
        changeDeviceUseCase: changeDeviceUseCase,
        loginUseCase: loginUseCase,
        nip: nip,
        username: state.username,
      ),
      child: const _ChangeDeviceDialogView(),
    );
  }
}

class _ChangeDeviceDialogView extends StatefulWidget {
  const _ChangeDeviceDialogView();

  @override
  State<_ChangeDeviceDialogView> createState() =>
      _ChangeDeviceDialogViewState();
}

class _ChangeDeviceDialogViewState extends State<_ChangeDeviceDialogView> {
  final _passwordController = TextEditingController();

  Future<void> _handleConfirm(BuildContext context) async {
    final password = _passwordController.text;
    context.read<ChangeDeviceCubit>().submit(password);
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ChangeDeviceCubit, ChangeDeviceState>(
      listener: (context, state) {
        if (state.status == PageStatus.done) {
          if (state.error != null) {
            showDialog(
              context: context,
              builder: (dialogContext) => CustomDialog(
                title: 'Akses Ditolak',
                content: state.error!,
                icon: Icons.block_rounded,
                iconColor: Colors.red,
                primaryButtonText: 'Tutup',
                onPrimaryPressed: () => Navigator.pop(dialogContext),
              ),
            );
          } else {
            // Success
            Navigator.pop(context, true); // Return true to indicate success
          }
        } else if (state.error != null && state.status != PageStatus.done) {
          // Handle simple validation errors (like empty password)
          CustomToast.show(context, state.error!, isError: true);
        }
      },
      child: Dialog(
        elevation: 0,
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withAlpha(50),
                blurRadius: 10,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primary100,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.phonelink_erase_rounded,
                    size: 48,
                    color: AppColors.primary500,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Konfirmasi Ganti Perangkat',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary800,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Masukkan password Anda',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, height: 1.5),
                ),
                const SizedBox(height: 24),
                BlocBuilder<ChangeDeviceCubit, ChangeDeviceState>(
                  builder: (context, state) {
                    return TextField(
                      controller: _passwordController,
                      obscureText: state.obscureText,
                      onChanged: (value) {
                        // Optional: could add logic here
                      },
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Masukkan password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          icon: Icon(
                            state.obscureText
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                          ),
                          onPressed: () {
                            context
                                .read<ChangeDeviceCubit>()
                                .toggleObscurePassword();
                          },
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Colors.grey.shade50,
                      ),
                    );
                  },
                ),
                const SizedBox(height: 32),
                Row(
                  children: [
                    Expanded(
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          foregroundColor: Colors.grey[700],
                        ),
                        child: const Text(
                          'Batal',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: BlocBuilder<ChangeDeviceCubit, ChangeDeviceState>(
                        builder: (context, state) {
                          return ElevatedButton(
                            onPressed: state.status == PageStatus.busy
                                ? null
                                : () => _handleConfirm(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary500,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: state.status == PageStatus.busy
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Text(
                                    'Konfirmasi',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                          );
                        },
                      ),
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

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
