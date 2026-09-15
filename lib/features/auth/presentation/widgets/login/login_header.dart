import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';

class LoginHeader extends StatelessWidget {
  const LoginHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Logo
        Image.asset(
          'assets/logo/logo_v3.webp',
          height: 200,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.verified_user_rounded,
              size: 120,
              color: AppColors.primary500,
            );
          },
        ),

        const SizedBox(height: 20),

        // App name
        RichText(
          textAlign: TextAlign.center,
          text: TextSpan(
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0.2,
            ),
            children: const [
              TextSpan(
                text: 'MEMBARA',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                ),
              ),
              TextSpan(
                text: ' Mobile',
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 6),

        // Institution
        Text(
          'Pemerintah Kabupaten Bengkulu Selatan',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}