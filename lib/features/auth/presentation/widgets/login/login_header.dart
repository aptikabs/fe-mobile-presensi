import 'package:flutter/material.dart';

import '../../../../../core/constants/app_colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 40),
        Card(
          elevation: 0,
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.neutral200),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Image.asset(
              'assets/logo/logo_v3.png',
              height: 80,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Icons.lock_person_rounded,
                  size: 80,
                  color: AppColors.primary500,
                );
              },
            ),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          'E-Presensi Mobile',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Pemerintah Provinsi Bengkulu',
          textAlign: TextAlign.center,
          style: Theme.of(
            context,
          ).textTheme.bodyLarge?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
