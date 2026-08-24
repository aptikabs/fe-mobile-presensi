import 'package:epresensi_mobile/app/router/app_routes_names.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_analytics/firebase_analytics.dart';

import '../../features/auth/presentation/page/login/login_page.dart';
import '../../features/auth/presentation/page/register/register_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/banner/presentation/page/banner_page.dart';
import '../../features/banner/presentation/page/banner_detail_page.dart';
import '../../features/banner/domain/entities/banner.dart';
import '../../features/history/presentation/pages/history_detail_page.dart';
import '../../features/history/domain/entities/presence_log.dart';
import '../../core/presentation/pages/webview_page.dart';
import '../../features/profile/presentation/pages/about_page.dart';
import '../../features/attendance/presentation/pages/attendance_page.dart';

import '../../features/splash/presentation/pages/splash_page.dart';

class AppRoutes {
  static final GoRouter router = GoRouter(
    initialLocation: AppRouteNames.splash,
    observers: [
      FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
    ],
    routes: [
      GoRoute(
        path: AppRouteNames.splash,
        name: AppRouteNames.splash,
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: AppRouteNames.login,
        name: AppRouteNames.login,
        builder: (BuildContext context, GoRouterState state) {
          return const LoginPage();
        },
      ),
      GoRoute(
        path: AppRouteNames.home,
        name: AppRouteNames.home,
        builder: (BuildContext context, GoRouterState state) {
          return const DashboardPage();
        },
      ),
      GoRoute(
        path: AppRouteNames.register,
        name: AppRouteNames.register,
        builder: (context, state) {
          final extra = state.extra as Map<String, dynamic>?;
          final nip = extra?['nip'] as String? ?? '';
          return RegisterPage(nip: nip);
        },
      ),
      GoRoute(
        path: AppRouteNames.banner,
        name: AppRouteNames.banner,
        builder: (context, state) => const BannerPage(),
      ),
      GoRoute(
        path: AppRouteNames.bannerDetail,
        name: AppRouteNames.bannerDetail,
        builder: (context, state) {
          final banner = state.extra as BannerEntity;
          return BannerDetailPage(banner: banner);
        },
      ),
      GoRoute(
        path: AppRouteNames.historyDetail,
        name: AppRouteNames.historyDetail,
        builder: (context, state) {
          final logs = state.extra as List<PresenceLog>;
          return HistoryDetailPage(logs: logs);
        },
      ),
      GoRoute(
        path: AppRouteNames.webview,
        name: AppRouteNames.webview,
        builder: (context, state) {
          final extras = state.extra as Map<String, dynamic>;
          return WebViewPage(
            title: extras['title'] as String,
            url: extras['url'] as String,
          );
        },
      ),
      GoRoute(
        path: AppRouteNames.about,
        name: AppRouteNames.about,
        builder: (context, state) => const AboutPage(),
      ),
      GoRoute(
        path: AppRouteNames.attendance,
        name: AppRouteNames.attendance,
        builder: (context, state) => const AttendancePage(),
      ),
    ],
  );
}
