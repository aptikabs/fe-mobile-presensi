import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';

import '../../../../../core/constants/app_colors.dart';
import '../../../auth/domain/entities/coordinate.dart';
import '../../../auth/presentation/bloc/auth/auth_cubit.dart';
import '../../domain/entities/presence_log.dart';
import '../bloc/detail/history_detail_cubit.dart';
import '../bloc/detail/history_detail_state.dart';

class HistoryDetailPage extends StatelessWidget {
  final List<PresenceLog> logs;

  const HistoryDetailPage({super.key, required this.logs});

  @override
  Widget build(BuildContext context) {
    final authState = context.read<AuthCubit>().state;
    final coordinates = authState is AuthAuthenticated
        ? authState.user.daftarKordinat
        : <Coordinate>[];

    return BlocProvider(
      create: (_) => HistoryDetailCubit()..init(logs, coordinates),
      child: const HistoryDetailView(),
    );
  }
}

class HistoryDetailView extends StatefulWidget {
  const HistoryDetailView({super.key});

  @override
  State<HistoryDetailView> createState() => _HistoryDetailViewState();
}

class _HistoryDetailViewState extends State<HistoryDetailView> {
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: BlocConsumer<HistoryDetailCubit, HistoryDetailState>(
        listener: (context, state) {
          if (state is HistoryDetailLoaded && state.selectedLog != null) {
            _animateToLog(state.selectedLog!);
          }
        },
        builder: (context, state) {
          if (state is HistoryDetailLoaded) {
            return CustomScrollView(
              slivers: [
                _buildSliverAppBar(context, state),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSummaryCard(state.logs),
                        const SizedBox(height: 24),
                        const Text(
                          "Detail Aktivitas",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.neutral900,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildActivityList(
                          context,
                          state.logs,
                          state.selectedLog,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          }
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, HistoryDetailLoaded state) {
    return SliverAppBar(
      expandedHeight: 300,
      pinned: true,
      backgroundColor: Colors.white,
      elevation: 0,
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(25),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.neutral900),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: state.initialCameraPosition,
              markers: state.markers,
              polygons: state.polygons,
              onMapCreated: (controller) => _mapController = controller,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
              myLocationButtonEnabled: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryCard(List<PresenceLog> logs) {
    if (logs.isEmpty) return const SizedBox.shrink();

    // Sort logs just in case
    final sortedLogs = List<PresenceLog>.from(logs)
      ..sort((a, b) => a.jam.compareTo(b.jam));

    final dateStr = DateFormat(
      'EEEE, dd MMMM yyyy',
      'id_ID',
    ).format(DateTime.parse(sortedLogs.first.tanggal.split(' ').first));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_today_rounded,
                  color: AppColors.primary500,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tanggal Presensi',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral500,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateStr,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.neutral900,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Divider(height: 1, color: AppColors.neutral100),
          const SizedBox(height: 20),
          Row(
            children: [
              _buildStatItem(
                'Total Log',
                '${logs.length}x',
                Icons.history_rounded,
                AppColors.secondary500,
              ),
              Container(width: 1, height: 40, color: AppColors.neutral200),
              _buildStatItem(
                'Datang',
                _findFirstTime(logs),
                Icons.login_rounded,
                AppColors.success500,
              ),
              Container(width: 1, height: 40, color: AppColors.neutral200),
              _buildStatItem(
                'Pulang',
                _findLastTime(logs),
                Icons.logout_rounded,
                AppColors.danger500,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: AppColors.neutral900,
              ),
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
            ),
          ),
        ],
      ),
    );
  }

  String _findFirstTime(List<PresenceLog> logs) {
    if (logs.isEmpty) return '--:--';
    return logs.first.jam; // Assumed sorted
  }

  String _findLastTime(List<PresenceLog> logs) {
    if (logs.isEmpty) return '--:--';
    // If only 1 log, last time might be same as first?
    // Or if type logic exists. Assuming last in sorted list.
    return logs.length > 1 ? logs.last.jam : '--:--';
  }

  Widget _buildActivityList(
    BuildContext context,
    List<PresenceLog> logs,
    PresenceLog? selectedLog,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.all(0),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: logs.length,
      separatorBuilder: (context, index) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final log = logs[index];
        final isSelected = selectedLog?.id == log.id;

        return InkWell(
          onTap: () {
            context.read<HistoryDetailCubit>().selectLog(log);
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.primary500 : AppColors.neutral100,
                width: isSelected ? 2 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primary500.withAlpha(25)
                      : Colors.black.withAlpha(12),
                  blurRadius: isSelected ? 12 : 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    Hero(
                      tag: 'log_photo_${log.id}',
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: AppColors.neutral100,
                          image: log.lokasiFotoUrl.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(log.lokasiFotoUrl),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: log.lokasiFotoUrl.isEmpty
                            ? const Icon(
                                Icons.image_not_supported_rounded,
                                color: AppColors.neutral400,
                              )
                            : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
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
                                    DateFormat(
                                      'yyyy-MM-dd',
                                    ).format(DateTime.parse(log.waktu)),
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.primary600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  log.jam,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.neutral900,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              const Icon(
                                Icons.location_on_rounded,
                                size: 14,
                                color: AppColors.neutral500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  '${log.latitude}, ${log.longitude}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.neutral600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (log.jarakKordinatMeter > 0)
                            Row(
                              children: [
                                const Icon(
                                  Icons.share_location_rounded,
                                  size: 14,
                                  color: AppColors.warning500,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    'Jarak: ${log.jarakKordinatMeter.toStringAsFixed(0)}m dari titik pusat',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.neutral600,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _animateToLog(PresenceLog log) {
    if (_mapController == null) return;

    final lat = double.tryParse(log.latitude);
    final lng = double.tryParse(log.longitude);

    if (lat != null && lng != null) {
      _mapController!.animateCamera(
        CameraUpdate.newCameraPosition(
          CameraPosition(target: LatLng(lat, lng), zoom: 18, tilt: 45),
        ),
      );
    }
  }
}
