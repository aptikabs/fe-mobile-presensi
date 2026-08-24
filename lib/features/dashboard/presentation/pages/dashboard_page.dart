import 'package:flutter/material.dart';
import '../../../activity/presentation/pages/activity_page.dart';
import '../../../history/presentation/pages/history_page.dart';
import '../../../home/presentation/page/home_page.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../widgets/custom_bottom_navbar.dart';

import '../../../notification/presentation/bloc/notification_cubit.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router/app_routes_names.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/utils/permission_helper.dart';
import '../../../auth/presentation/bloc/auth/auth_cubit.dart';
import '../../../history/presentation/bloc/history/history_cubit.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const HistoryPage(),
    const SizedBox.shrink(), // Placeholder, attendance is pushed as a separate route
    const ActivityPage(),
    const ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  void _initNotifications() async {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Check notification permission using Primer Flow
      final isGranted = await PermissionHelper.requestPermission(
        context: context,
        permission: Permission.notification,
        title: 'Izin Notifikasi',
        content:
            'Aplikasi memerlukan izin notifikasi untuk mengingatkan jadwal absen Anda agar tidak terlambat.',
        icon: Icons.notifications_active_rounded,
      );

      if (isGranted && mounted) {
        context.read<NotificationCubit>().scheduleNotifications();
      }
    });
  }

  void _onTap(int index) {
    if (index == 2) {
      context.pushNamed(AppRouteNames.attendance);
    } else {
      if (index == 1) {
        final authState = context.read<AuthCubit>().state;
        if (authState is AuthAuthenticated) {
          context.read<HistoryCubit>().loadHistory(
            nip: authState.user.detailPegawai.nip,
            token: authState.user.token,
          );
        }
      }
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Content
          Padding(
            padding: EdgeInsets.only(
              bottom: 80 + MediaQuery.of(context).padding.bottom,
            ), // Leave space for navbar
            child: IndexedStack(index: _currentIndex, children: _pages),
          ),

          // Custom Bottom Navigation Bar
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: CustomBottomNavBar(
              currentIndex: _currentIndex,
              onTap: _onTap,
            ),
          ),
        ],
      ),
    );
  }
}
