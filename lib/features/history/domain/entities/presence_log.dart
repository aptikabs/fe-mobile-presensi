import 'package:equatable/equatable.dart';

class PresenceLog extends Equatable {
  final int id;
  final String waktu;
  final String tanggal;
  final String jam;
  final String latitude;
  final String longitude;
  final String lokasiFoto;
  final double jarakKordinatMeter;
  final String lokasiFotoUrl;

  const PresenceLog({
    required this.id,
    required this.waktu,
    required this.tanggal,
    required this.jam,
    required this.latitude,
    required this.longitude,
    required this.lokasiFoto,
    required this.jarakKordinatMeter,
    required this.lokasiFotoUrl,
  });

  @override
  List<Object?> get props => [
    id,
    waktu,
    tanggal,
    jam,
    latitude,
    longitude,
    lokasiFoto,
    jarakKordinatMeter,
    lokasiFotoUrl,
  ];
}
