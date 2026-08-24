import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'app/app.dart';
import 'app/app_providers.dart';
import 'core/di/service_locator.dart';
import 'core/network/pinned_http_client.dart';
import 'core/security/environment_security_service.dart';
import 'features/security/presentation/pages/security_violation_page.dart';
import 'firebase_options.dart';

void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Audit Keamanan Perangkat di Awal Eksekusi (Khusus Pemblokiran Emulator)
      final auditResult = await EnvironmentSecurityService.auditEnvironment();

      if (!auditResult.isSecure) {
        runApp(
          MaterialApp(
            debugShowCheckedModeBanner: false,
            home: SecurityViolationPage(
              deviceDetails: auditResult.deviceDetails,
            ),
          ),
        );
        return;
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Inisialisasi ServiceLocator (Hive Encrypted Box + Keystore + iOS Backup)
      final boxes = await ServiceLocator.init();
      final authBox = boxes[0];
      final settingsBox = boxes[1];

      final client = PinnedHttpClient.createClient();
      final networkInfo = ServiceLocator.networkInfo;

      FlutterError.onError = (errorDetails) {
        FirebaseCrashlytics.instance.recordFlutterError(errorDetails);
      };

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };

      runApp(
        MultiRepositoryProvider(
          providers: AppProviders.getRepositories(authBox, client, networkInfo),
          child: MultiBlocProvider(
            providers: AppProviders.getBlocs(settingsBox, networkInfo),
            child: const App(),
          ),
        ),
      );
    },
    (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    },
  );
}
