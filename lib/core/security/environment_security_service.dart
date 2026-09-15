import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:safe_device/safe_device.dart';
import 'package:security_plus/security_plus.dart';

/// Hasil audit lingkungan perangkat
class EnvironmentAuditResult {
  final bool
  isSecure; // false jika isEmulator == true atau isFridaDetected == true
  final bool isEmulator;
  final bool isJailBroken;
  final bool isDevMode;
  final bool isMockLocation;
  final bool isFridaDetected;
  final Map<String, String> deviceDetails;

  EnvironmentAuditResult({
    required this.isSecure,
    required this.isEmulator,
    required this.isJailBroken,
    required this.isDevMode,
    required this.isMockLocation,
    required this.isFridaDetected,
    required this.deviceDetails,
  });
}

/// Service untuk melakukan audit keamanan lingkungan perangkat (Environment Security).
/// Memeriksa status Root, Jailbreak, Developer Mode, Mock Location, Frida/Instrumentation, dan Untrusted Emulator.
class EnvironmentSecurityService {
  static const MethodChannel _nativeChannel = MethodChannel(
    'epresensi/native_security',
  );

  /// Memeriksa atribut hardware & file pipe QEMU native di Android
  static Future<bool> isNativeEmulator() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? isEmulator = await _nativeChannel
          .invokeMethod<bool>('isEmulator')
          .timeout(const Duration(seconds: 1));
      return isEmulator ?? false;
    } catch (e) {
      debugPrint('Error checking native emulator: $e');
      return kReleaseMode; // Fail-closed in release mode if check is tampered
    }
  }

  /// Memeriksa indikasi Frida / instrumentation / TracerPid native di Android
  static Future<bool> isNativeFridaDetected() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? isFrida = await _nativeChannel
          .invokeMethod<bool>('isFridaDetected')
          .timeout(const Duration(seconds: 1));
      return isFrida ?? false;
    } catch (e) {
      debugPrint('Error checking native Frida: $e');
      return kReleaseMode; // Fail-closed in release mode
    }
  }

  /// Memeriksa status Root via native binary checks
  static Future<bool> isNativeRooted() async {
    if (!Platform.isAndroid) return false;
    try {
      final bool? isRooted = await _nativeChannel
          .invokeMethod<bool>('isRootedNative')
          .timeout(const Duration(seconds: 1));
      return isRooted ?? false;
    } catch (e) {
      debugPrint('Error checking native Root: $e');
      return false;
    }
  }

  /// Mengambil rincian informasi perangkat untuk ditampilkan saat terjadi blokir emulator
  static Future<Map<String, String>> getDeviceDetails() async {
    final Map<String, String> details = {};
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        details['Model'] = androidInfo.model;
        details['Merek'] = androidInfo.brand;
        details['Manufaktur'] = androidInfo.manufacturer;
        details['Hardware'] = androidInfo.hardware;
        details['Device'] = androidInfo.device;
        details['Fingerprint'] = androidInfo.fingerprint;
        details['Fisik'] = androidInfo.isPhysicalDevice
            ? 'Ya'
            : 'Bukan (Virtual/Emulator)';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        details['Model'] = iosInfo.model;
        details['Nama Perangkat'] = iosInfo.name;
        details['Sistem'] = '${iosInfo.systemName} ${iosInfo.systemVersion}';
        details['Arsitektur'] = iosInfo.utsname.machine;
        details['Fisik'] = iosInfo.isPhysicalDevice
            ? 'Ya'
            : 'Bukan (iOS Simulator)';
      }
    } catch (e) {
      debugPrint('Error fetching device details for security violation: $e');
    }
    return details;
  }

  /// Melakukan audit lingkungan secara menyeluruh.
  /// Hanya `isEmulator == true` atau `isFridaDetected == true` yang memblokir keamanan (`isSecure = false`).
  /// Root, Mock Location, dan DevMode dicatat sebagai indikasi/peringatan
  /// agar tetap terkirim sebagai telemetry (GPS Snapshot) saat absensi.
  static Future<EnvironmentAuditResult> auditEnvironment() async {
    try {
      bool isJailBroken = false;
      try {
        isJailBroken = await SafeDevice.isJailBroken.timeout(
          const Duration(seconds: 2),
        );
      } catch (e) {
        debugPrint('SafeDevice.isJailBroken error: $e');
      }

      bool nativeRooted = false;
      if (Platform.isAndroid) {
        nativeRooted = await isNativeRooted();
      }
      isJailBroken = isJailBroken || nativeRooted;

      bool isRealDevice = true;
      try {
        isRealDevice = await SafeDevice.isRealDevice.timeout(
          const Duration(seconds: 2),
        );
      } catch (e) {
        debugPrint('SafeDevice.isRealDevice error: $e');
      }

      bool isDevMode = false;
      if (Platform.isAndroid) {
        try {
          isDevMode = await SafeDevice.isDevelopmentModeEnable.timeout(
            const Duration(seconds: 2),
          );
        } catch (e) {
          debugPrint('SafeDevice.isDevelopmentModeEnable error: $e');
        }
      }

      bool isMockLocation = false;
      if (Platform.isAndroid) {
        try {
          isMockLocation = await SafeDevice.isMockLocation.timeout(
            const Duration(seconds: 2),
          );
        } catch (e) {
          debugPrint('SafeDevice.isMockLocation error: $e');
        }
      }

      bool isSecurityPlusEmulator = false;
      try {
        isSecurityPlusEmulator = await SecurityPlus.isEmulator.timeout(
          const Duration(seconds: 2),
        );
      } catch (_) {}

      bool nativeEmulator = false;
      if (Platform.isAndroid) {
        nativeEmulator = await isNativeEmulator();
      }

      bool isFridaDetected = false;
      if (Platform.isAndroid) {
        isFridaDetected = await isNativeFridaDetected();
      }

      final isEmulator =
          !isRealDevice || isSecurityPlusEmulator || nativeEmulator;

      final deviceDetails = await getDeviceDetails();

      debugPrint('--- ENVIRONMENT SECURITY AUDIT ---');
      debugPrint('Is Jailbroken/Rooted: $isJailBroken (Native: $nativeRooted)');
      debugPrint('Is Developer Mode Enabled: $isDevMode');
      debugPrint('Is Real Device: $isRealDevice');
      debugPrint('Is Native Android Emulator: $nativeEmulator');
      debugPrint('Is Emulator (Combined): $isEmulator');
      debugPrint('Is Frida Detected: $isFridaDetected');
      debugPrint('Is Mock Location: $isMockLocation');
      debugPrint('Device Details: $deviceDetails');

      if (isJailBroken) {
        debugPrint(
          '⚠️ Log Warning: Perangkat ter-Root/Jailbreak (Data dikirim via GPS Snapshot).',
        );
      }

      if (isDevMode) {
        debugPrint(
          '⚠️ Log Warning: Developer Mode / USB Debugging aktif (Data dikirim via GPS Snapshot).',
        );
      }

      if (isMockLocation) {
        debugPrint(
          '⚠️ Log Warning: Mock Location / Fake GPS terdeteksi (Data dikirim via GPS Snapshot).',
        );
      }

      if (isEmulator) {
        debugPrint(
          '⛔ Access Denied: Perangkat terdeteksi Emulator (Bukan Real Device).',
        );
      }

      if (isFridaDetected) {
        debugPrint(
          '⛔ Access Denied: Terdeteksi Frida / Instrumentation / Debugger!',
        );
      }

      final bool isSecure =
          !isEmulator &&
          !isFridaDetected &&
          !isJailBroken &&
          !isDevMode &&
          !isMockLocation;

      return EnvironmentAuditResult(
        isSecure: isSecure,
        isEmulator: isEmulator,
        isJailBroken: isJailBroken,
        isDevMode: isDevMode,
        isMockLocation: isMockLocation,
        isFridaDetected: isFridaDetected,
        deviceDetails: deviceDetails,
      );
    } catch (e) {
      debugPrint('Error performing environment security audit: $e');
      // Fail-closed in release mode (block access on unhandled tampering error)
      return EnvironmentAuditResult(
        isSecure: !kReleaseMode,
        isEmulator: kReleaseMode,
        isJailBroken: false,
        isDevMode: false,
        isMockLocation: false,
        isFridaDetected: kReleaseMode,
        deviceDetails: {},
      );
    }
  }

  static Future<bool> isEnvironmentSecure() async {
    final result = await auditEnvironment();
    return result.isSecure;
  }
}
