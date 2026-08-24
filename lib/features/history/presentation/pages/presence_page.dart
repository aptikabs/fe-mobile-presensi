import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import 'package:go_router/go_router.dart';
import '../../../../../app/router/app_routes_names.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/attendance_schedule.dart';
import '../../../auth/presentation/bloc/auth/auth_cubit.dart';

import '../bloc/history/history_cubit.dart';
import '../bloc/history/history_state.dart';
import '../../domain/entities/presence_log.dart';
import '../widgets/bottom_sheet_date_picker.dart';

class PresencePage extends StatelessWidget {
  const PresencePage({super.key});

  @override
  Widget build(BuildContext context) {
    return const PresenceView();
  }
}

class PresenceView extends StatefulWidget {
  const PresenceView({super.key});

  @override
  State<PresenceView> createState() => _PresenceViewState();
}

class _PresenceViewState extends State<PresenceView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocBuilder<HistoryCubit, HistoryState>(
        builder: (context, state) {
          // Loading State dengan Skeleton
          if (state is HistoryLoading) {
            return _buildSkeletonLoading();
          }

          // Error State
          if (state is HistoryError) {
            return _buildErrorState(context, state.message);
          }

          // Loaded State
          if (state is HistoryLoaded) {
            final filteredHistory = state.history;

            return RefreshIndicator(
              onRefresh: () async => _refreshData(),
              color: AppColors.primary500,
              backgroundColor: Colors.white,
              strokeWidth: 3,
              displacement: 40,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  // Header dengan Filter Card
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildModernFilterCard(context, state),

                          const SizedBox(height: 16),
                          if (filteredHistory.any(
                            (l) => l.tanggal.startsWith(
                              DateFormat('yyyy-MM-dd').format(DateTime.now()),
                            ),
                          )) ...[
                            _buildTodayHistory(
                              context,
                              filteredHistory,
                            ), // Show only if today has data
                          ],
                          const SizedBox(height: 8),
                          _buildSimpleStats(filteredHistory),
                          const SizedBox(height: 24),
                          const Text(
                            "Riwayat Absensi",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.neutral900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // List Content
                  if (filteredHistory.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _buildEnhancedEmptyState(context),
                    )
                  else
                    _buildTimelineList(context, filteredHistory),

                  const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
                ],
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildModernFilterCard(BuildContext context, HistoryLoaded state) {
    return Material(
      elevation: 0,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: () => _pickDateRange(context),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, AppColors.primary50],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.primary100),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary500.withAlpha(20),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primary500, AppColors.primary700],
                  ),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.date_range_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Periode Riwayat',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.black54,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "${_formatDateFilter(state.startDate)} - ${_formatDateFilter(state.endDate)}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.keyboard_arrow_right_rounded,
                color: AppColors.primary500,
                size: 28,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSimpleStats(List<PresenceLog> history) {
    final totalDays = history
        .map((e) => e.tanggal.split(' ').first)
        .toSet()
        .length;
    final totalLogs = history.length;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.neutral100),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(20),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildMinimalStatItem(
              'Hari Aktif',
              '$totalDays',
              Icons.calendar_today_rounded,
              AppColors.primary500,
            ),
          ),
          Container(height: 40, width: 1, color: AppColors.neutral200),
          Expanded(
            child: _buildMinimalStatItem(
              'Total Presensi',
              '$totalLogs',
              Icons.fingerprint_rounded,
              AppColors.success500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMinimalStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.neutral900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayHistory(BuildContext context, List<PresenceLog> history) {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final todayLogs = history
        .where((log) => log.tanggal.startsWith(todayStr))
        .toList();
    todayLogs.sort((a, b) => a.jam.compareTo(b.jam));

    final schedule = _getSchedule(context);

    return TodayHistoryCard(logs: todayLogs, schedule: schedule);
  }

  Widget _buildTimelineList(BuildContext context, List<PresenceLog> history) {
    final grouped = <String, List<PresenceLog>>{};
    for (var log in history) {
      final date = log.tanggal.split(' ').first;
      grouped.putIfAbsent(date, () => []).add(log);
    }

    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));
    final schedule = _getSchedule(context);

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate((context, index) {
          final dateKey = sortedKeys[index];
          final logs = grouped[dateKey]!
            ..sort((a, b) => a.jam.compareTo(b.jam));
          final dateDt = DateTime.parse(dateKey);

          return _buildTimelineItem(
            context,
            dateDt,
            logs,
            schedule,
            index,
            sortedKeys.length,
          );
        }, childCount: sortedKeys.length),
      ),
    );
  }

  Widget _buildTimelineItem(
    BuildContext context,
    DateTime date,
    List<PresenceLog> logs,
    AttendanceSchedule? schedule,
    int index,
    int totalItems,
  ) {
    Map<String, dynamic>? checkInStatus;
    Map<String, dynamic>? checkOutStatus;
    PresenceLog? checkIn;
    PresenceLog? checkOut;
    int otherCount = 0;

    for (var log in logs) {
      final status = _getAttendanceStatus(log.jam, schedule);
      final type = status['type'];

      if (type == 'Datang' && checkIn == null) {
        checkIn = log;
        checkInStatus = status;
      } else if (type == 'Pulang' && checkOut == null) {
        checkOut = log;
        checkOutStatus = status;
      } else if (type != 'Datang' && type != 'Pulang') {
        otherCount++;
      }
    }
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline Ornament
          Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.primary500,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary500.withAlpha(102),
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  width: 2,
                  color: index == totalItems - 1
                      ? Colors.transparent
                      : AppColors.neutral200,
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Content Card
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.neutral100),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(12),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () {
                    context.pushNamed(AppRouteNames.historyDetail, extra: logs);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                DateFormat(
                                  'EEEE, dd MMM yyyy',
                                  'id_ID',
                                ).format(date),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.neutral900,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Absen Masuk
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.success50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.login_rounded,
                                      color: AppColors.success600,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Absen Masuk',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.neutral500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 4,
                                          runSpacing: 2,
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                checkIn != null
                                                    ? _formatTimeDisplay(
                                                        checkIn.jam,
                                                      )
                                                    : '--:--',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: checkIn != null
                                                      ? AppColors.neutral900
                                                      : AppColors.neutral300,
                                                ),
                                              ),
                                            ),
                                            if (checkIn != null &&
                                                checkInStatus?['isLate'] ==
                                                    true)
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.danger50,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Telat',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    color: AppColors.danger500,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            // Absen Pulang
                            Expanded(
                              child: Row(
                                children: [
                                  Container(
                                    width: 28,
                                    height: 28,
                                    decoration: BoxDecoration(
                                      color: AppColors.danger50,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Icon(
                                      Icons.logout_rounded,
                                      color: AppColors.danger600,
                                      size: 14,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Absen Pulang',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: AppColors.neutral500,
                                            fontWeight: FontWeight.w500,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Wrap(
                                          crossAxisAlignment:
                                              WrapCrossAlignment.center,
                                          spacing: 4,
                                          runSpacing: 2,
                                          children: [
                                            FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Text(
                                                checkOut != null
                                                    ? _formatTimeDisplay(
                                                        checkOut.jam,
                                                      )
                                                    : '--:--',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  color: checkOut != null
                                                      ? AppColors.neutral900
                                                      : AppColors.neutral300,
                                                ),
                                              ),
                                            ),
                                            if (checkOut != null &&
                                                checkOutStatus?['status'] ==
                                                    'Pulang Cepat')
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 4,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: AppColors.warning100,
                                                  borderRadius:
                                                      BorderRadius.circular(4),
                                                ),
                                                child: const Text(
                                                  'Pulang Cepat',
                                                  style: TextStyle(
                                                    fontSize: 8,
                                                    color: AppColors.warning600,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // Lainnya
                        if (otherCount > 0) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.neutral50,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: AppColors.neutral100,
                                width: 1,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.more_horiz_rounded,
                                  size: 16,
                                  color: AppColors.neutral600,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '+$otherCount Aktivitas Lainnya',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.neutral700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonLoading() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            height: 120,
          ),
        );
      },
    );
  }

  Widget _buildEnhancedEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: AppColors.neutral100,
                borderRadius: BorderRadius.circular(75),
              ),
              child: Icon(
                Icons.history_toggle_off_rounded,
                size: 80,
                color: AppColors.neutral300,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Belum Ada Data Presensi',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppColors.neutral900,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Pilih rentang tanggal untuk melihat riwayat presensi Anda',
                style: TextStyle(fontSize: 14, color: AppColors.neutral500),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _pickDateRange(context),
              icon: const Icon(Icons.date_range_rounded),
              label: const Text('Pilih Tanggal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary500,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              child: Icon(
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
              onPressed: _refreshData,
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

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final second = parts.length > 2 ? int.parse(parts[2]) : 0;
      return DateTime(now.year, now.month, now.day, hour, minute, second);
    } catch (_) {
      return now;
    }
  }

  Map<String, dynamic> _getAttendanceStatus(
    String timeStr,
    AttendanceSchedule? schedule,
  ) {
    if (schedule == null) {
      return {'type': 'Presensi', 'isLate': false, 'status': 'Normal'};
    }

    try {
      final time = _parseTime(timeStr);

      // Schedule times
      final masuk = _parseTime(schedule.masukJam);
      final masukBatas = _parseTime(schedule.masukBatas);
      final pulang = _parseTime(schedule.pulangJam);
      final pulangBatas = _parseTime(schedule.pulangBatas);

      // Tolerances (1 hour)
      final tolerance = const Duration(hours: 1);
      final masukStart = masuk.subtract(tolerance);
      final masukEnd = masukBatas.add(tolerance);
      final pulangStart = pulang.subtract(tolerance);
      final pulangEnd = pulangBatas.add(tolerance);

      // Check Masuk Window
      if (time.isAfter(masukStart) && time.isBefore(masukEnd)) {
        final isLate = time.isAfter(masukBatas);
        return {
          'type': 'Datang',
          'isLate': isLate,
          'status': isLate ? 'Telat' : 'Tepat Waktu',
        };
      }

      // Check Pulang Window
      if (time.isAfter(pulangStart) && time.isBefore(pulangEnd)) {
        final isEarly = time.isBefore(pulang);
        return {
          'type': 'Pulang',
          'isLate': false, // "Late" usually implies bad.
          'status': isEarly ? 'Pulang Cepat' : 'Tepat Waktu',
        };
      }

      return {'type': 'Lainnya', 'isLate': false, 'status': 'Diluar Jam'};
    } catch (_) {
      return {'type': 'Absen', 'isLate': false, 'status': '-'};
    }
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final historyCubit = context.read<HistoryCubit>();
    final state = historyCubit.state;

    DateTime? currentStart;
    DateTime? currentEnd;

    if (state is HistoryLoaded) {
      if (state.startDate.isNotEmpty && state.endDate.isNotEmpty) {
        try {
          currentStart = DateTime.parse(state.startDate);
          currentEnd = DateTime.parse(state.endDate);
        } catch (_) {}
      }
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BottomSheetDatePicker(
        initialStartDate: currentStart,
        initialEndDate: currentEnd,
        onApply: (startDate, endDate) {
          final startStr = DateFormat('yyyy-MM-dd').format(startDate);
          final endStr = DateFormat('yyyy-MM-dd').format(endDate);

          historyCubit.loadHistory(
            nip: _getNip(context),
            startDate: startStr,
            endDate: endStr,
            token: _getToken(context),
          );
        },
      ),
    );
  }

  Future<void> _refreshData() async {
    final cubit = context.read<HistoryCubit>();
    final authCubit = context.read<AuthCubit>();
    final nip = _getNip(context);

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

    if (cubit.state is HistoryLoaded) {
      final state = cubit.state as HistoryLoaded;
      cubit.loadHistory(
        nip: nip,
        startDate: state.startDate,
        endDate: state.endDate,
        token: newToken,
      );
    } else {
      cubit.loadHistory(nip: nip, token: newToken);
    }
  }

  String _formatTimeDisplay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return timeStr;
    } catch (_) {
      return timeStr;
    }
  }

  AttendanceSchedule? _getSchedule(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.result.jadwalAbsen;
    }
    return null;
  }

  String _formatDateFilter(String dateStr) {
    try {
      return DateFormat('dd MMM yyyy', 'id_ID').format(DateTime.parse(dateStr));
    } catch (_) {
      return dateStr;
    }
  }

  String _getNip(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.detailPegawai.nip;
    }
    return '';
  }

  String? _getToken(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      return authState.user.token;
    }
    return null;
  }
}

class TodayHistoryCard extends StatefulWidget {
  final List<PresenceLog> logs;
  final AttendanceSchedule? schedule;

  const TodayHistoryCard({super.key, required this.logs, this.schedule});

  @override
  State<TodayHistoryCard> createState() => _TodayHistoryCardState();
}

class _TodayHistoryCardState extends State<TodayHistoryCard> {
  bool _isExpanded = false;

  void _toggleExpand() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  DateTime _parseTime(String timeStr) {
    final now = DateTime.now();
    try {
      final parts = timeStr.split(':');
      final hour = int.parse(parts[0]);
      final minute = int.parse(parts[1]);
      final second = parts.length > 2 ? int.parse(parts[2]) : 0;
      return DateTime(now.year, now.month, now.day, hour, minute, second);
    } catch (_) {
      return now;
    }
  }

  String _getAttendanceType(String timeStr, AttendanceSchedule? schedule) {
    if (schedule == null) return 'Presensi';
    try {
      final time = _parseTime(timeStr);
      final masuk = _parseTime(schedule.masukJam);
      final masukBatas = _parseTime(schedule.masukBatas);
      final pulang = _parseTime(schedule.pulangJam);
      final pulangBatas = _parseTime(schedule.pulangBatas);

      final tolerance = const Duration(hours: 1);
      final masukStart = masuk.subtract(tolerance);
      final masukEnd = masukBatas.add(tolerance);
      final pulangStart = pulang.subtract(tolerance);
      final pulangEnd = pulangBatas.add(tolerance);

      if (time.isAfter(masukStart) && time.isBefore(masukEnd)) {
        return 'Datang';
      }
      if (time.isAfter(pulangStart) && time.isBefore(pulangEnd)) {
        return 'Pulang';
      }
      return 'Lainnya';
    } catch (_) {
      return 'Absen';
    }
  }

  String _getAttendanceTypeLabel(String type) {
    if (type.contains('Datang')) return 'PAGI';
    if (type.contains('Pulang')) return 'PULANG';
    if (type.contains('Lainnya')) return 'ABSEN';
    return type.toUpperCase();
  }

  String _formatTimeDisplay(String timeStr) {
    try {
      final parts = timeStr.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return timeStr;
    } catch (_) {
      return timeStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.logs.isEmpty) return const SizedBox.shrink();

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _toggleExpand,
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary200),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary500,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.today_rounded,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Absen Hari ini',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary100,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${widget.logs.length} Data Absen Terekam',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary700,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    _isExpanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.primary500,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedCrossFade(
          firstChild: const SizedBox.shrink(),
          secondChild: Container(
            margin: const EdgeInsets.only(top: 8),
            child: ListView.separated(
              padding: const EdgeInsets.all(0),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: widget.logs.length,
              separatorBuilder: (context, index) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final log = widget.logs[index];
                final type = _getAttendanceType(log.jam, widget.schedule);
                final isMasuk = type.contains('Datang');

                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.neutral100),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(5),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isMasuk
                              ? AppColors.success50
                              : AppColors.danger50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isMasuk
                                ? AppColors.success100
                                : AppColors.danger100,
                          ),
                        ),
                        child: Icon(
                          isMasuk ? Icons.login_rounded : Icons.logout_rounded,
                          color: isMasuk
                              ? AppColors.success600
                              : AppColors.danger600,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Absensi #${index + 1}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: AppColors.neutral900,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 4),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.success50,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  _getAttendanceTypeLabel(type),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.success700,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.success50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.success200),
                          ),
                          child: Text(
                            _formatTimeDisplay(log.jam),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.success700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          crossFadeState: _isExpanded
              ? CrossFadeState.showSecond
              : CrossFadeState.showFirst,
          duration: const Duration(milliseconds: 300),
        ),
      ],
    );
  }
}
