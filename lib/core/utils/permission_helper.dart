import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../presentation/widgets/permission_explanation_dialog.dart';
import 'lifecycle_config.dart';

class PermissionHelper {
  static Future<bool> requestPermission({
    required BuildContext context,
    required Permission permission,
    required String title,
    required String content,
    required IconData icon,
  }) async {
    // Check Status
    final status = await permission.status;

    if (status.isGranted) {
      return true;
    }

    if (status.isPermanentlyDenied) {
      // Show Settings Dialog
      if (context.mounted) {
        _showSettingsDialog(context, title);
      }
      return false;
    }

    // Show Explanation Dialog
    if (context.mounted) {
      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (context) => PermissionExplanationDialog(
          title: title,
          content: content,
          icon: icon,
          onAllow: () => Navigator.pop(context, true),
          onDeny: () => Navigator.pop(context, false),
        ),
      );

      if (shouldRequest == true) {
        LifecycleConfig.ignoreBackgroundLogout = true;
        final result = await permission.request();
        Future.delayed(const Duration(milliseconds: 500), () {
          LifecycleConfig.ignoreBackgroundLogout = false;
        });
        return result.isGranted;
      }
    }

    return false;
  }

  static void _showSettingsDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Izin Diperlukan'),
        content: Text(
          'Izin untuk $title telah ditolak secara permanen. Mohon aktifkan izin melalui Pengaturan Aplikasi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              LifecycleConfig.ignoreBackgroundLogout = true;
              openAppSettings().then((_) {
                Future.delayed(const Duration(milliseconds: 500), () {
                  LifecycleConfig.ignoreBackgroundLogout = false;
                });
              });
              Navigator.pop(context);
            },
            child: const Text('Buka Pengaturan'),
          ),
        ],
      ),
    );
  }
}
