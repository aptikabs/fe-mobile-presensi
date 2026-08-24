import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:safe_device/safe_device.dart';

class GPSSnapshotService {
  Future<Map<String, dynamic>> captureSnapshot({
    required Position position,
    bool? isMockLocation,
  }) async {
    // 1. Device State & Security Assessment
    bool safeDeviceMock = await SafeDevice.isMockLocation;
    bool isJailBroken = await SafeDevice.isJailBroken;
    bool isRealDevice = await SafeDevice.isRealDevice;
    bool isDevMode = await SafeDevice.isDevelopmentModeEnable;
    bool finalMockLocation = isMockLocation ?? (safeDeviceMock || position.isMocked);
    bool speedAnomaly = position.speed > 50; // > 50 m/s (~180 km/h)

    final List<String> fraudReasons = [];
    if (finalMockLocation) fraudReasons.add('mock_location');
    if (isJailBroken) fraudReasons.add('rooted');
    if (!isRealDevice) fraudReasons.add('emulator');
    if (isDevMode) fraudReasons.add('developer_mode');
    if (speedAnomaly) fraudReasons.add('speed_anomaly');

    bool isFraud = fraudReasons.isNotEmpty;

    // 2. Environment
    final connectivityResult = await Connectivity().checkConnectivity();
    String networkType = 'unknown';
    if (connectivityResult.contains(ConnectivityResult.mobile)) {
      networkType = 'mobile';
    } else if (connectivityResult.contains(ConnectivityResult.wifi)) {
      networkType = 'wifi';
    } else if (connectivityResult.contains(ConnectivityResult.none)) {
      networkType = 'none';
    }

    // 3. Raw Device Info
    final deviceInfo = DeviceInfoPlugin();
    Map<String, dynamic> rawInfo = {};
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      rawInfo = {
        'android_api_level': androidInfo.version.sdkInt,
        'manufacturer': androidInfo.manufacturer,
        'model': androidInfo.model,
        'brand': androidInfo.brand,
        'device': androidInfo.device,
      };
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      rawInfo = {
        'system_name': iosInfo.systemName,
        'system_version': iosInfo.systemVersion,
        'model': iosInfo.model,
        'name': iosInfo.name,
      };
    }

    return {
      "is_fraud": isFraud,
      "fraud_reasons": fraudReasons,
      "location": {
        "lat": position.latitude,
        "lng": position.longitude,
        "accuracy": position.accuracy,
        "altitude": position.altitude,
        "speed": position.speed,
        "bearing": position.heading, // heading is bearing
        "timestamp": position.timestamp.millisecondsSinceEpoch,
      },
      "device_state": {
        "is_mock_location": finalMockLocation,
        "is_emulator": !isRealDevice,
        "is_rooted": isJailBroken,
        "developer_mode": isDevMode,
      },
      "source": {
        "provider": "fused", // Default for geolocator on Android
        "is_mocked": finalMockLocation,
      },
      "environment": {
        "timezone": DateTime.now().timeZoneName,
        "network_type": networkType,
      },
      "consistency_check": {
        "speed_anomaly": speedAnomaly,
      },
      "raw": rawInfo,
    };
  }
}
