import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../core/services/version_check_service.dart';
import '../../../../../core/constants/app_colors.dart';
// import '../../../../../core/services/notification_service.dart';

import '../../../../../app/router/app_routes_names.dart';
import '../../../../../core/error/auth_exceptions.dart';
import '../../../../../core/presentation/widgets/custom_dialog.dart';
import '../../../../../core/presentation/widgets/custom_toast.dart';
import '../../../domain/usecases/login_usecase.dart';
import '../../../domain/repositories/auth_repository.dart';
import '../../bloc/auth/auth_cubit.dart';
import '../../bloc/login_bloc.dart';
import '../../bloc/login_event.dart';
import '../../bloc/login_state.dart';
import '../../widgets/change_device_dialog.dart';
import '../../widgets/login/login_form.dart';
import '../../widgets/login/login_header.dart';
import '../../../../../core/services/security_service.dart';
import '../../widgets/security_dialog.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Use RepositoryProvider to get the instance
    final repository = context.read<AuthRepository>();
    final loginUseCase = LoginUseCase(repository);
    final securityService = SecurityService();

    return BlocProvider(
      create: (context) => LoginBloc(
        loginUseCase: loginUseCase,
        securityService: securityService,
      )..add(LoginStarted()),
      child: BlocListener<LoginBloc, LoginState>(
        listener: (context, state) {
          // Logic handled in _LoginView
        },
        child: const _LoginView(),
      ),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkVersion();
    });
  }

  Future<void> _checkVersion() async {
    final service = VersionCheckService();
    final result = await service.checkVersion();

    if (!mounted) return;

    if (result.type != UpdateType.none) {
      final isMandatory = result.type == UpdateType.mandatory;

      showDialog(
        context: context,
        barrierDismissible: !isMandatory,
        builder: (context) => PopScope(
          canPop: !isMandatory,
          child: CustomDialog(
            title: isMandatory ? 'Update Diperlukan' : 'Update Tersedia',
            content: isMandatory
                ? 'Versi aplikasi Anda sudah usang. Mohon update ke versi terbaru (${result.latestVersion}) untuk melanjutkan.'
                : 'Versi terbaru (${result.latestVersion}) tersedia. Update sekarang untuk mendapatkan fitur terbaru.',
            icon: Icons.system_update_rounded,
            iconColor: isMandatory ? AppColors.danger500 : AppColors.primary500,
            primaryButtonText: 'Update Sekarang',
            onPrimaryPressed: () {
              if (result.storeUrl != null) {
                launchUrl(
                  Uri.parse(result.storeUrl!),
                  mode: LaunchMode.externalApplication,
                );
              }
            },
            secondaryButtonText: isMandatory ? null : 'Nanti',
            onSecondaryPressed: isMandatory
                ? null
                : () => Navigator.pop(context),
          ),
        ),
      );
    }
  }

  void _handleLoginFailure(BuildContext context, LoginState state) {
    FocusScope.of(context).unfocus();

    // Handle network errors with a specific dialog
    if (state.isNetworkError) {
      showDialog(
        context: context,
        builder: (context) => CustomDialog(
          title: 'Koneksi Bermasalah',
          content: state.errorMessage ??
              'Tidak ada koneksi internet. Periksa jaringan Anda dan coba lagi.',
          icon: Icons.wifi_off_rounded,
          iconColor: AppColors.warning500,
          primaryButtonText: 'Coba Lagi',
          onPrimaryPressed: () {
            Navigator.pop(context);
          },
          secondaryButtonText: 'Tutup',
          onSecondaryPressed: () => Navigator.pop(context),
        ),
      );
      return;
    }

    if (state.error is DeviceMismatchException) {
      final error = state.error as DeviceMismatchException;
      final data = error.data;
      final int kode = data?['kode'] is int
          ? data!['kode']
          : (int.tryParse(data?['kode']?.toString() ?? '') ?? 1);

      final dynamic bolehUbahRaw =
          data?['boleh_ubah_perangkat'] ?? data?['ijin_ganti_perangkat'];
      bool isAllowedToChange = true;
      if (kode == 3) {
        isAllowedToChange = false;
      } else if (bolehUbahRaw != null) {
        if (bolehUbahRaw == 0 ||
            bolehUbahRaw == false ||
            bolehUbahRaw == '0' ||
            bolehUbahRaw == 'false') {
          isAllowedToChange = false;
        }
      }

      if (!isAllowedToChange) {
        _showContactAdminDialog(context, error.message);
      } else {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => ChangeDeviceDialog(state: state),
        ).then((result) {
          if (!context.mounted) return;
          if (result == true) {
            CustomToast.show(
              context,
              'Perangkat berhasil diubah. Sedang login...',
            );
            context.read<LoginBloc>().add(
                  LoginSubmitted(
                    username: state.username,
                    password: state.password,
                    deviceId: '',
                  ),
                );
          }
        });
      }
    } else if (state.error is UserNotRegisteredException) {
      final error = state.error as UserNotRegisteredException;
      String nip = state.username;
      final data = error.data;
      if (data != null) {
        if (data['detail_pegawai'] != null &&
            data['detail_pegawai']['nip'] != null) {
          nip = data['detail_pegawai']['nip'];
        } else if (data['hasil_login'] != null &&
            data['hasil_login']['nip'] != null) {
          nip = data['hasil_login']['nip'];
        } else if (data['nip'] != null) {
          nip = data['nip'];
        }
      }

      context.push(AppRouteNames.register, extra: {'nip': nip});
    } else if (state.error is UserBlockedException) {
      final error = state.error as UserBlockedException;
      final data = error.data;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => PopScope(
          canPop: false,
          child: CustomDialog(
            title: data?['title'] ?? 'Diblokir',
            content: data?['subtitle'] ?? error.message,
            icon: Icons.block_rounded,
            iconColor: Colors.red,
            primaryButtonText: null,
          ),
        ),
      );
    } else if (state.error is ContactAdminException) {
      _showContactAdminDialog(context, state.error?.message);
    } else {
      final msg = state.errorMessage ?? state.error?.message;
      if (msg != null && msg.isNotEmpty) {
        CustomToast.show(context, msg, isError: true);
      }
    }
  }

  void _showContactAdminDialog(BuildContext context, [String? message]) {
    showDialog(
      context: context,
      builder: (context) => CustomDialog(
        title: 'Akses Ditolak',
        content: (message != null && message.isNotEmpty)
            ? message
            : 'Kode perangkat terdeteksi ada perubahan. Silakan hubungi Diskominfotik Provinsi Bengkulu untuk ubah perangkat.',
        icon: Icons.block,
        iconColor: Colors.red,
        primaryButtonText: 'Tutup',
        onPrimaryPressed: () => Navigator.pop(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<LoginBloc, LoginState>(
      listenWhen: (previous, current) =>
          previous.status != current.status ||
          previous.changeDeviceSuccess != current.changeDeviceSuccess,
      listener: (context, state) {
        if (state.status == LoginStatus.success) {
          CustomToast.show(context, 'Login Berhasil!');

          // Update Global Auth State
          if (state.response != null) {
            context.read<AuthCubit>().loggedIn(state.response!);
          }

          context.go(AppRouteNames.home);
        } else if (state.status == LoginStatus.securityFailure) {
          showDialog<bool>(
            context: context,
            barrierDismissible: false,
            builder: (context) =>
                SecurityDialog(threats: state.securityThreats),
          ).then((shouldSkip) {
            if (shouldSkip == true && context.mounted) {
              context.read<LoginBloc>().add(LoginSecurityCheckSkipped());
            }
          });
        } else if (state.status == LoginStatus.failure) {
          _handleLoginFailure(context, state);
        }
      },
      child: Scaffold(
        // Tes Notifikasi
        // floatingActionButton: FloatingActionButton(
        //   onPressed: () {
        //     context.read<NotificationService>().showNotification(
        //       id: 99,
        //       title: "Test Notifikasi",
        //       body: "Ini adalah contoh notifikasi untuk cek desain dan suara.",
        //     );
        //   },
        //   backgroundColor: AppColors.primary500,
        //   child: const Icon(
        //     Icons.notifications_active_rounded,
        //     color: Colors.white,
        //   ),
        // ),
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false,
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24.0,
                  right: 24.0,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 24.0,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        LoginHeader(),
                        SizedBox(height: 40),
                        LoginForm(),
                        SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
