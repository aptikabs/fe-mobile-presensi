import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../../auth/domain/entities/coordinate.dart';
import '../../../domain/entities/presence_log.dart';
import 'history_detail_state.dart';

class HistoryDetailCubit extends Cubit<HistoryDetailState> {
  HistoryDetailCubit() : super(HistoryDetailInitial());

  void init(List<PresenceLog> logs, List<Coordinate> coordinates) {
    if (logs.isEmpty) {
      // Default to Monas if no logs/corrupt data
      emit(
        const HistoryDetailLoaded(
          logs: [],
          markers: {},
          polygons: {},
          initialCameraPosition: CameraPosition(
            target: LatLng(-6.175392, 106.827153),
            zoom: 14,
          ),
        ),
      );
      return;
    }

    // Sort logs by time
    logs.sort((a, b) => a.jam.compareTo(b.jam));

    final markers = _createMarkers(logs);
    final polygons = _createPolygons(coordinates);

    // Find initial camera position (focus on first Check In / Datang usually first log)
    // Or center of all points? Let's focus on the first log.
    final firstLog = logs.first;
    final initialLat = double.tryParse(firstLog.latitude) ?? -6.175392;
    final initialLng = double.tryParse(firstLog.longitude) ?? 106.827153;

    emit(
      HistoryDetailLoaded(
        logs: logs,
        markers: markers,
        polygons: polygons,
        selectedLog: null,
        initialCameraPosition: CameraPosition(
          target: LatLng(initialLat, initialLng),
          zoom: 15,
        ),
      ),
    );
  }

  Set<Polygon> _createPolygons(List<Coordinate> coordinates) {
    final polygons = <Polygon>{};
    for (var coord in coordinates) {
      if (coord.polygonPoints.isNotEmpty) {
        final points = coord.polygonPoints.map((p) {
          return LatLng(
            double.tryParse(p.latitude) ?? 0.0,
            double.tryParse(p.longitude) ?? 0.0,
          );
        }).toList();

        polygons.add(
          Polygon(
            polygonId: PolygonId(coord.id.toString()),
            points: points,
            fillColor: Colors.blue.withAlpha(70),
            strokeColor: Colors.blue,
            strokeWidth: 2,
          ),
        );
      }
    }
    return polygons;
  }

  void selectLog(PresenceLog log) {
    if (state is HistoryDetailLoaded) {
      final currentState = state as HistoryDetailLoaded;
      emit(currentState.copyWith(selectedLog: log));
    }
  }

  Set<Marker> _createMarkers(List<PresenceLog> logs) {
    return logs.map((log) {
      final lat = double.tryParse(log.latitude) ?? 0.0;
      final lng = double.tryParse(log.longitude) ?? 0.0;

      // We can customize markers based on type if needed, but for now simple markers
      return Marker(
        markerId: MarkerId(log.id.toString()),
        position: LatLng(lat, lng),
        infoWindow: InfoWindow(title: log.jam, snippet: log.waktu),
        onTap: () {
          selectLog(log);
        },
      );
    }).toSet();
  }
}
