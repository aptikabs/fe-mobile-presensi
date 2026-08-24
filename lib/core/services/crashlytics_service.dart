import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class CrashlyticsService {
  static final CrashlyticsService _instance = CrashlyticsService._internal();
  factory CrashlyticsService() => _instance;
  CrashlyticsService._internal();

  FirebaseCrashlytics get _crashlytics => FirebaseCrashlytics.instance;

  /// Initialize Crashlytics settings
  Future<void> initialize() async {
    if (kDebugMode) {
      // Force enable Crashlytics for testing during debug mode
      // Remember to set this back to false before production if you don't want debug crashes.
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
    } else {
      // Enable collection in release builds
      await _crashlytics.setCrashlyticsCollectionEnabled(true);
    }
  }

  /// Sets the user identifier for this session.
  Future<void> setUserIdentifier(String identifier) async {
    await _crashlytics.setUserIdentifier(identifier);
  }

  /// Logs a custom message to be included in the next crash report.
  Future<void> log(String message) async {
    await _crashlytics.log(message);
  }

  /// Records a non-fatal error.
  Future<void> recordError(dynamic exception, StackTrace? stack, {dynamic reason, bool fatal = false}) async {
    await _crashlytics.recordError(exception, stack, reason: reason, fatal: fatal);
  }

  /// Records a Flutter error.
  Future<void> recordFlutterError(FlutterErrorDetails details) async {
    await _crashlytics.recordFlutterError(details);
  }

  /// Force a crash for testing purposes (Release build only)
  void forceCrash() {
    _crashlytics.crash();
  }
}
