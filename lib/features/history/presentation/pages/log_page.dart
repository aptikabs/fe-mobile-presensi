import 'package:epresensi_mobile/app/router/app_routes_names.dart';
import 'package:epresensi_mobile/core/constants/app_colors.dart';
import 'package:epresensi_mobile/features/auth/presentation/bloc/auth/auth_cubit.dart';
import 'package:epresensi_mobile/features/history/domain/entities/attendance_log.dart';
import 'package:epresensi_mobile/features/history/presentation/bloc/log/log_cubit.dart';
import 'package:epresensi_mobile/features/history/presentation/bloc/log/log_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

class LogPage extends StatefulWidget {
  const LogPage({super.key});

  @override
  State<LogPage> createState() => _LogPageState();
}

class _LogPageState extends State<LogPage> {
  final DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    if (authState is AuthAuthenticated) {
      final hasCreds = await authCubit.hasCredentials();
      if (!hasCreds) {
        await authCubit.logout();
        if (mounted) {
          context.goNamed(AppRouteNames.login);
        }
        return;
      }

      final newToken = await authCubit.reloginAndGetToken();
      if (newToken == null) {
        await authCubit.logout();
        if (mounted) {
          context.goNamed(AppRouteNames.login);
        }
        return;
      }

      final currentNip = authCubit.state is AuthAuthenticated
          ? (authCubit.state as AuthAuthenticated).user.detailPegawai.nip
          : authState.user.detailPegawai.nip;

      if (!mounted) return;
      context.read<LogCubit>().loadLogs(
        nip: currentNip,
        month: _selectedDate.month,
        year: _selectedDate.year,
        token: newToken,
      );
    } else {
      await authCubit.logout();
      if (mounted) {
        context.goNamed(AppRouteNames.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // Log List
          Expanded(
            child: BlocBuilder<LogCubit, LogState>(
              builder: (context, state) {
                if (state is LogLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is LogError) {
                  return _buildErrorState(context, state.message);
                } else if (state is LogLoaded) {
                  if (state.logs.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(20),
                    itemCount: state.logs.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final item = state.logs[index];
                      return _buildLogItem(item);
                    },
                  );
                }
                return _buildEmptyState();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(BuildContext context, String message) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppColors.danger50,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 60,
                color: AppColors.danger500,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Terjadi Kesalahan',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                message,
                style: const TextStyle(fontSize: 14, color: AppColors.neutral500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadLogs,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Coba Lagi'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.neutral50,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 48,
                color: AppColors.neutral300,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Belum ada data absensi',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Data absensi bulan ini masih kosong',
              style: TextStyle(color: AppColors.neutral500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLogItem(AttendanceLog log) {
    // Parsing date
    DateTime? date;
    try {
      date = DateTime.parse(log.date);
    } catch (_) {}

    final dateStr = date != null
        ? DateFormat('EEE, dd MMM yyyy', 'id_ID').format(date)
        : log.date;

    // Times are pipe separated: "10:54:19 | 14:54:33 | 15:36:20"
    final times = log.times;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: AppColors.neutral100),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  dateStr,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.neutral900,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    log.count,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary600,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Divider(height: 1, color: AppColors.neutral100),
          const SizedBox(height: 12),
          if (times.isEmpty)
            const Text(
              'Tidak ada data',
              style: TextStyle(
                fontStyle: FontStyle.italic,
                color: AppColors.neutral400,
              ),
            )
          else
            Column(
              children: List.generate(times.length, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: AppColors.primary50,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${index + 1}',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Absen Ke-${index + 1}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.neutral500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          times[index],
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
        ],
      ),
    );
  }
}
