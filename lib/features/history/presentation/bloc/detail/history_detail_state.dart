import 'package:equatable/equatable.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../domain/entities/presence_log.dart';

abstract class HistoryDetailState extends Equatable {
  const HistoryDetailState();

  @override
  List<Object?> get props => [];
}

class HistoryDetailInitial extends HistoryDetailState {}

class HistoryDetailLoaded extends HistoryDetailState {
  final List<PresenceLog> logs;
  final Set<Marker> markers;
  final Set<Polygon> polygons;
  final PresenceLog? selectedLog;
  final CameraPosition initialCameraPosition;

  const HistoryDetailLoaded({
    required this.logs,
    required this.markers,
    this.polygons = const {},
    this.selectedLog,
    required this.initialCameraPosition,
  });

  HistoryDetailLoaded copyWith({
    List<PresenceLog>? logs,
    Set<Marker>? markers,
    Set<Polygon>? polygons,
    PresenceLog? selectedLog,
    CameraPosition? initialCameraPosition,
  }) {
    return HistoryDetailLoaded(
      logs: logs ?? this.logs,
      markers: markers ?? this.markers,
      polygons: polygons ?? this.polygons,
      selectedLog: selectedLog ?? this.selectedLog,
      initialCameraPosition:
          initialCameraPosition ?? this.initialCameraPosition,
    );
  }

  @override
  List<Object?> get props => [
    logs,
    markers,
    polygons,
    selectedLog,
    initialCameraPosition,
  ];
}
