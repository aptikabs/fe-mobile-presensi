import 'package:flutter/foundation.dart';
import 'package:safe_device/safe_device.dart';
import 'package:security_plus/security_plus.dart';
import '../security/environment_security_service.dart';

enum SecurityThreat { root, emulator, developerMode, unknown }

class SecurityService {
  Future<List<SecurityThreat>> getSecurityThreats() async {
    final threats = <SecurityThreat>[];

    try {
      // Check Root/Jailbreak
      try {
        final isSafeDeviceJailBroken = await SafeDevice.isJailBroken;
        final isSecurityPlusRooted = await SecurityPlus.isRooted;
        if (isSafeDeviceJailBroken || isSecurityPlusRooted) {
          threats.add(SecurityThreat.root);
        }
      } catch (_) {}

      // Check Emulator
      try {
        final isSafeDeviceReal = await SafeDevice.isRealDevice;
        bool isSecurityPlusEmulator = false;
        try {
          isSecurityPlusEmulator = await SecurityPlus.isEmulator;
        } catch (_) {}

        final isNative = await EnvironmentSecurityService.isNativeEmulator();

        if (!isSafeDeviceReal || isSecurityPlusEmulator || isNative) {
          if (!threats.contains(SecurityThreat.emulator)) {
            threats.add(SecurityThreat.emulator);
          }
        }
      } catch (_) {}

      // Check Developer Mode
      try {
        final isSafeDeviceDevMode = await SafeDevice.isDevelopmentModeEnable;
        if (isSafeDeviceDevMode) {
          threats.add(SecurityThreat.developerMode);
        }
      } catch (_) {}
    } catch (e) {
      // Handle errors or ignore
      if (kDebugMode) {
        print("Error checking security: $e");
      }
    }

    return threats;
  }
}
