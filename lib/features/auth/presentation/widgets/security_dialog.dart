import 'dart:io';
import 'package:flutter/material.dart';
import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/presentation/widgets/custom_dialog.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/security_service.dart';

class SecurityDialog extends StatelessWidget {
  final List<SecurityThreat> threats;

  const SecurityDialog({super.key, required this.threats});

  Future<void> _openDeveloperSettings() async {
    if (Platform.isAndroid) {
      try {
        const intent = AndroidIntent(
          action: 'android.settings.APPLICATION_DEVELOPMENT_SETTINGS',
          flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
        );
        await intent.launch();
      } catch (e) {
        // Fallback to general settings
        try {
          const intent = AndroidIntent(
            action: 'android.settings.SETTINGS',
            flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
          );
          await intent.launch();
        } catch (e) {
          openAppSettings(); // Last resort
        }
      }
    } else {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    // Content Logic
    String title = 'Keamanan Perangkat';
    String content = '';

    bool hasRoot = threats.contains(SecurityThreat.root);
    bool hasEmulator = threats.contains(SecurityThreat.emulator);
    bool hasDevMode = threats.contains(SecurityThreat.developerMode);

    if (hasRoot) {
      content +=
          'Perangkat Anda terdeteksi telah di-root/jailbreak. Penggunaan aplikasi dibatasi demi keamanan data Anda.\n';
    }
    if (hasEmulator) {
      content += 'Penggunaan emulator tidak diizinkan.\n';
    }
    if (hasDevMode) {
      content +=
          'Mode Pengembang (Developer option) aktif. Mohon matikan untuk melanjutkan.\n';
    }

    if (content.isEmpty) {
      content = 'Terdeteksi masalah keamanan pada perangkat Anda.';
    }

    // Determine Mode
    // If Dev Mode (and user wants 2 options: Settings or Continue)
    // If Root/Emulator is PRESENT, typically we BLOCK.
    // But if we follow "custom dialog ... sesuai kondisi", we might need different buttons.
    // However, the user specifically asked: "jika development mode ... cuman dua opsi saja pengaturan atau lanjutkan"

    // I will prioritize the Dev Mode request.
    // Use CustomDialog.

    if (hasDevMode && !hasRoot && !hasEmulator) {
      return CustomDialog(
        title: title,
        content: content,
        icon: Icons.warning_amber_rounded,
        iconColor: AppColors.danger500,
        primaryButtonText: 'Pengaturan',
        onPrimaryPressed: () {
          _openDeveloperSettings();
        },
        secondaryButtonText: 'Lanjutkan',
        onSecondaryPressed: () {
          Navigator.pop(context, false); // Return true to skip
        },
      );
    } else {
      // Root or Emulator or Mixed
      return CustomDialog(
        title: title,
        content: content,
        icon: Icons.gpp_bad_rounded,
        iconColor: AppColors.danger500,
        primaryButtonText: 'Tutup',
        onPrimaryPressed: () {
          Navigator.pop(context, false);
        },
        // No "Lanjutkan" for heavy threats usually, unless user wants it?
        // I'll stick to safe blocking for Root/Emulator as implied by "CustomDialog" usually being informational or blocking.
      );
    }
  }
}
