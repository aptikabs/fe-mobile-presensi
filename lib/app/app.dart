import 'package:epresensi_mobile/app/router/app_routes.dart';
import 'package:epresensi_mobile/app/router/app_routes_names.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'dart:ui';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../features/auth/presentation/bloc/auth/auth_cubit.dart';
import '../../core/presentation/widgets/no_connection_banner.dart';
import '../../core/utils/lifecycle_config.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> with WidgetsBindingObserver {
  bool _isObscured = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Enforce Portrait Mode
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // Reset orientation preference if needed (optional)
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Selalu paksa logout jika aplikasi di-terminate (dimatikan penuh)
    if (state == AppLifecycleState.detached) {
      context.read<AuthCubit>().logout();
      return;
    }

    if (LifecycleConfig.ignoreBackgroundLogout) return;

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background or inactive (e.g. app switcher)
      setState(() {
        _isObscured = true;
      });

      // Clear local data (logout) as requested
      // "menghapus data di local untuk cek-perangkat"
      // This implies we clear the session so they must re-verify.
      context.read<AuthCubit>().logout();
    } else if (state == AppLifecycleState.resumed) {
      // App came back to foreground
      setState(() {
        _isObscured = false;
      });

      // Redirect to Login Page explicitly as data is cleared
      AppRoutes.router.go(AppRouteNames.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Membara Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      routerConfig: AppRoutes.router,
      builder: (context, child) {
        return Stack(
          children: [
            if (child != null) child,
            // Global no-connection banner
            const Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: NoConnectionBanner(),
            ),
            if (_isObscured)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(color: Colors.white.withAlpha(128)),
                ),
              ),
          ],
        );
      },
    );
  }
}
