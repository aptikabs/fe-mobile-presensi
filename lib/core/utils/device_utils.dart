import 'dart:io';

import 'package:android_id/android_id.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceUtils {
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static const _androidIdPlugin = AndroidId();

  static Future<Map<String, String>> getDeviceInfo() async {
    String deviceId = '';
    String merek = '';
    String model = '';
    String fingerprint = '';

    try {
      if (kIsWeb) {
        deviceId = 'web-client';
        merek = 'Web';
        model = 'Browser';
        fingerprint = 'web-fingerprint';
      } else {
        if (Platform.isAndroid) {
          final androidInfo = await _deviceInfo.androidInfo;
          final ssaId = await _androidIdPlugin.getId();
          
          // Gunakan SSAID (dari android_id) sebagai prioritas utama.
          // Jika SSAID null atau kosong (kasus langka pada beberapa emulator/ROM custom),
          // gunakan androidInfo.id (Build ID) sebagai fallback agar deviceId tidak kosong.
          deviceId = (ssaId != null && ssaId.isNotEmpty) ? ssaId : androidInfo.id;
          
          merek = androidInfo.brand;
          model = androidInfo.model;
          fingerprint = androidInfo.fingerprint;
        } else if (Platform.isIOS) {
          final iosInfo = await _deviceInfo.iosInfo;
          
          // Gunakan identifierForVendor (IDFV). Jika null (kasus sangat langka saat booting),
          // gunakan model sebagai fallback agar deviceId tidak kosong.
          deviceId = iosInfo.identifierForVendor ?? iosInfo.model;
          
          merek = 'Apple';
          model = iosInfo.model;
          fingerprint = '${iosInfo.systemName} ${iosInfo.systemVersion}';
        }
      }
    } catch (e) {
      debugPrint('Error getting device info: $e');
    }

    return {
      'kode_unik': deviceId,
      'merek': merek,
      'model': model,
      'fingerprint': fingerprint,
    };
  }
}
