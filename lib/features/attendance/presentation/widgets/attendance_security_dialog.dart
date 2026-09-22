import 'dart:io';

import 'package:android_intent_plus/android_intent.dart';
import 'package:android_intent_plus/flag.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../app/router/app_routes_names.dart';
import '../../../../core/constants/app_colors.dart';

Future<void> showAttendanceSecurityDialog(
  BuildContext context,
  String message, {
  bool isDeveloperMode = false,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: const Icon(
        Icons.error_outline,
        color: AppColors.error,
        size: 60,
      ),
      content: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 16),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            Navigator.of(dialogContext).pop();
            if (isDeveloperMode) {
              await _openDeveloperSettings();
            }
            if (context.mounted) {
              context.go(AppRouteNames.home);
            }
          },
          child: Text(
            isDeveloperMode ? 'Pengaturan' : 'OK',
            style: const TextStyle(color: AppColors.primary500),
          ),
        ),
      ],
    ),
  );
}

Future<void> _openDeveloperSettings() async {
  if (!Platform.isAndroid) {
    await openAppSettings();
    return;
  }

  try {
    const intent = AndroidIntent(
      action: 'android.settings.APPLICATION_DEVELOPMENT_SETTINGS',
      flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
    );
    await intent.launch();
  } catch (_) {
    try {
      const intent = AndroidIntent(
        action: 'android.settings.SETTINGS',
        flags: <int>[Flag.FLAG_ACTIVITY_NEW_TASK],
      );
      await intent.launch();
    } catch (_) {
      await openAppSettings();
    }
  }
}
