import 'package:epresensi_mobile/api/urls.dart';
import 'package:epresensi_mobile/core/constants/app_colors.dart';
import 'package:epresensi_mobile/features/auth/presentation/bloc/auth/auth_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:epresensi_mobile/core/presentation/widgets/custom_toast.dart';

import 'package:epresensi_mobile/app/router/app_routes_names.dart';
import '../../../notification/presentation/bloc/notification_cubit.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(
          'Profile',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.neutral900,
          ),
        ),
        backgroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, state) {
          if (state is AuthAuthenticated) {
            final user = state.user;
            final detail = user.detailPegawai;

            return SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Profile Header
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(10),
                          blurRadius: 20,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primary50,
                            border: Border.all(
                              color: AppColors.primary100,
                              width: 2,
                            ),
                          ),
                          child: Center(
                            child: Image.asset(
                              'assets/logo/logo_pemprov_bengkulu.webp',
                              fit: BoxFit.contain,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          detail.nama,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          detail.jabatanNama,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppColors.neutral500,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        Divider(color: AppColors.neutral100),
                        const SizedBox(height: 16),
                        _buildInfoRow('NIP', detail.nip),
                        const SizedBox(height: 12),
                        _buildInfoRow('Unit Induk', detail.unorIndukNama),
                        const SizedBox(height: 12),
                        _buildInfoRow('Unit Kerja', detail.unorNama),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Actions
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(5),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Builder(
                          builder: (context) {
                            final cubit = context.watch<NotificationCubit>();
                            return _buildActionItem(
                              context,
                              icon: cubit.isNotificationEnabled
                                  ? Icons.notifications_active_outlined
                                  : Icons.notifications_off_outlined,
                              title: 'Notifikasi',
                              trailing: Switch(
                                value: cubit.isNotificationEnabled,
                                onChanged: (value) {
                                  cubit.toggleNotification(value);
                                },
                                activeThumbColor: AppColors.primary500,
                              ),
                              onTap: () {
                                cubit.toggleNotification(
                                  !cubit.isNotificationEnabled,
                                );
                              },
                            );
                          },
                        ),
                        Divider(height: 1, color: AppColors.neutral100),
                        _buildActionItem(
                          context,
                          icon: Icons.info_outline_rounded,
                          title: 'Tentang Aplikasi',
                          onTap: () {
                            context.pushNamed(AppRouteNames.about);
                          },
                        ),
                        Divider(height: 1, color: AppColors.neutral100),

                        // Notification Toggle
                        _buildActionItem(
                          context,
                          icon: Icons.privacy_tip_outlined,
                          title: 'Kebijakan Privasi',
                          onTap: () {
                            context.pushNamed(
                              AppRouteNames.webview,
                              extra: {
                                'title': 'Kebijakan Privasi',
                                'url': Urls.privacy,
                              },
                            );
                          },
                        ),
                        Divider(height: 1, color: AppColors.neutral100),
                        _buildActionItem(
                          context,
                          icon: Icons.description_outlined,
                          title: 'Syarat dan Ketentuan',
                          onTap: () {
                            context.pushNamed(
                              AppRouteNames.webview,
                              extra: {
                                'title': 'Syarat dan Ketentuan',
                                'url': Urls.terms,
                              },
                            );
                          },
                        ),
                        Divider(height: 1, color: AppColors.neutral100),

                        _buildActionItem(
                          context,
                          icon: Icons.lock_outline_rounded,
                          title: 'Ubah Password',
                          onTap: () {
                            CustomToast.show(
                              context,
                              'Fitur Ubah Password segera hadir',
                              isError: true,
                            );
                          },
                        ),
                        Divider(height: 1, color: AppColors.neutral100),
                        _buildActionItem(
                          context,
                          icon: Icons.logout_rounded,
                          title: 'Keluar',
                          titleColor: AppColors.danger500,
                          iconColor: AppColors.danger500,
                          onTap: () {
                            _showLogoutDialog(context);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 42),
                  Column(
                    children: [
                      SizedBox(
                        width: 200,
                        child: Image.asset(
                          'assets/logo/logo_pemprov_bkl_text.png',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 80),
                ],
              ),
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isStatus = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.neutral500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        const Text(
          ':  ',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.neutral400,
            fontWeight: FontWeight.w500,
          ),
        ),
        Expanded(
          child: isStatus
              ? Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.success50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.success600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                )
              : Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.neutral900,
                    fontWeight: FontWeight.w600,
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildActionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? titleColor,
    Widget? trailing,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(
          20,
        ), // This might need refinement if it clips corners oddly for middle items, but good enough for now.
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? AppColors.neutral600, size: 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: titleColor ?? AppColors.neutral900,
                  ),
                ),
              ),
              trailing ??
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.neutral400,
                    size: 24,
                  ),
            ],
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konfirmasi Log Out'),
        content: const Text('Apakah anda yakin ingin keluar dari aplikasi?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: AppColors.neutral500),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await context.read<AuthCubit>().logout();
              if (context.mounted) {
                context.goNamed(AppRouteNames.login);
              }
            },
            child: const Text(
              'Ya, Keluar',
              style: TextStyle(color: AppColors.danger500),
            ),
          ),
        ],
      ),
    );
  }
}
