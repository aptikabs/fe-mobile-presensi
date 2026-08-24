import '../../domain/entities/presence_log.dart';

class PresenceLogModel extends PresenceLog {
  const PresenceLogModel({
    required super.id,
    required super.waktu,
    required super.tanggal,
    required super.jam,
    required super.latitude,
    required super.longitude,
    required super.lokasiFoto,
    required super.jarakKordinatMeter,
    required super.lokasiFotoUrl,
  });

  factory PresenceLogModel.fromJson(Map<String, dynamic> json) {
    final int id = json['id'] is int
        ? json['id']
        : (int.tryParse(json['id']?.toString() ?? '') ?? 0);

    final double jarak = json['jarak_kordinat_meter'] is num
        ? (json['jarak_kordinat_meter'] as num).toDouble()
        : (double.tryParse(json['jarak_kordinat_meter']?.toString() ?? '') ?? 0.0);

    return PresenceLogModel(
      id: id,
      waktu: json['waktu']?.toString() ?? '',
      tanggal: json['tanggal']?.toString() ?? '',
      jam: json['jam']?.toString() ?? '',
      latitude: json['latitude']?.toString() ?? '',
      longitude: json['longitude']?.toString() ?? '',
      lokasiFoto: json['lokasi_foto']?.toString() ?? '',
      jarakKordinatMeter: jarak,
      lokasiFotoUrl: json['lokasi_foto_url']?.toString() ?? '',
    );
  }
}
