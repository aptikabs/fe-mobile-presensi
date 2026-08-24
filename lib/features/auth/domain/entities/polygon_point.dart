import 'package:equatable/equatable.dart';

class PolygonPoint extends Equatable {
  final int id;
  final String latitude;
  final String longitude;
  final int urutan;

  const PolygonPoint({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.urutan,
  });

  @override
  List<Object?> get props => [id, latitude, longitude, urutan];
}
