import 'package:equatable/equatable.dart';
import 'polygon_point.dart';

class Coordinate extends Equatable {
  final int id;
  final String namaTempat;
  final String latitude;
  final String longitude;
  final String alamat;
  final List<PolygonPoint> polygonPoints;

  const Coordinate({
    required this.id,
    required this.namaTempat,
    required this.latitude,
    required this.longitude,
    required this.alamat,
    this.polygonPoints = const [],
  });

  @override
  List<Object?> get props => [
    id,
    namaTempat,
    latitude,
    longitude,
    alamat,
    polygonPoints,
  ];
}
