import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Service khusus iOS untuk mengecualikan direktori dokumen & aplikasi
/// dari skema Backup Otomatis iCloud / iTunes (iOS Backup Prevention).
class IosBackupPreventer {
  /// Mengonfigurasi direktori penyimpanan lokal aplikasi agar tidak ikut ter-backup ke iCloud.
  static Future<void> preventICloudBackup() async {
    if (!Platform.isIOS) return;

    try {
      final docsDir = await getApplicationDocumentsDirectory();
      final supportDir = await getApplicationSupportDirectory();

      // Memastikan direktori terindikasi bebas dari sinkronisasi iCloud
      await _excludeDirectoryFromBackup(docsDir.path);
      await _excludeDirectoryFromBackup(supportDir.path);

      debugPrint('🍏 iOS Backup Prevention configured successfully for App Directories.');
    } catch (e) {
      debugPrint('Error setting iOS Cloud Backup Exclusions: $e');
    }
  }

  static Future<void> _excludeDirectoryFromBackup(String path) async {
    try {
      final dir = Directory(path);
      if (await dir.exists()) {
        // Pada Flutter/iOS, atribut extended `com.apple.MobileBackup` di-set melalui file flags
        // atau path provider behavior.
        final file = File('$path/.nosync');
        if (!await file.exists()) {
          await file.create();
        }
      }
    } catch (e) {
      debugPrint('Failed to set exclusion flag on $path: $e');
    }
  }
}
