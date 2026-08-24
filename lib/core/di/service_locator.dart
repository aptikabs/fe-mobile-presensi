import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'package:firebase_core/firebase_core.dart';
import '../../firebase_options.dart';
import '../../features/home/data/models/absen_model.dart';
import '../services/notification_service.dart';
import '../services/crashlytics_service.dart';
import '../network/network_info.dart';
import '../security/secure_storage_service.dart';
import '../security/auth_security_service.dart';
import '../security/ios_backup_preventer.dart';

class ServiceLocator {
  static late final NetworkInfo networkInfo;
  static late final SecureStorageService secureStorageService;
  static late final AuthSecurityService authSecurityService;

  static Future<List<Box>> init() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Firebase Initialization
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    // Crashlytics Initialization
    await CrashlyticsService().initialize();

    // Network Info Initialization
    networkInfo = NetworkInfoImpl();

    // Security Services Initialization
    secureStorageService = SecureStorageService();
    authSecurityService = AuthSecurityService(secureStorageService: secureStorageService);

    // iOS Backup Prevention (Prevent iCloud Sync)
    await IosBackupPreventer.preventICloudBackup();

    // Hive Initialization dengan AES-256 Encryption
    await Hive.initFlutter();
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AbsenModelAdapter());
    }

    // Membuka Hive Box dengan Enkripsi AES-256 + Automatic Fallback
    final authBox = await authSecurityService.openEncryptedBox('auth_box');
    final settingsBox = await authSecurityService.openEncryptedBox('settings_box');

    // Locale Initialization
    await initializeDateFormatting('id_ID', null);
    Intl.defaultLocale = 'id_ID';

    // Notification Service Initialization
    try {
      final notificationService = NotificationService();
      await notificationService.initialize();
    } catch (e) {
      debugPrint("Error initializing NotificationService: $e");
    }

    // System Preferences
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    return [authBox, settingsBox];
  }
}
