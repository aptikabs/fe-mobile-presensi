import 'package:flutter_test/flutter_test.dart';
import 'package:epresensi_mobile/features/history/data/models/presence_log_model.dart';
import 'package:epresensi_mobile/features/history/data/models/attendance_log_model.dart';

void main() {
  group('PresenceLogModel.fromJson', () {
    test('should parse 200 response log item successfully', () {
      final json = {
        "id": 6232482,
        "waktu": "2026-02-12 14:59:29",
        "tanggal": "2026-02-12",
        "jam": "14:59:29",
        "latitude": "-3.793142",
        "longitude": "102.270584",
        "lokasi_foto": "2026/02/196512101987032009-2026-02-12-14-59-29.jpg",
        "jarak_kordinat_meter": 18.06,
        "lokasi_foto_url": "https://devcdn.bengkuluprov.go.id/2026/02/test.jpg"
      };

      final result = PresenceLogModel.fromJson(json);

      expect(result.id, 6232482);
      expect(result.waktu, "2026-02-12 14:59:29");
      expect(result.tanggal, "2026-02-12");
      expect(result.jam, "14:59:29");
      expect(result.latitude, "-3.793142");
      expect(result.longitude, "102.270584");
      expect(result.jarakKordinatMeter, 18.06);
      expect(result.lokasiFotoUrl, contains("test.jpg"));
    });

    test('should parse safely when id is string, jarak is int, or fields missing', () {
      final json = {
        "id": "6232482",
        "waktu": "2026-02-12 14:59:29",
        "tanggal": "2026-02-12",
        "jam": "14:59:29",
        "latitude": null,
        "longitude": null,
        "lokasi_foto": null,
        "jarak_kordinat_meter": 0,
        "lokasi_foto_url": null
      };

      final result = PresenceLogModel.fromJson(json);

      expect(result.id, 6232482);
      expect(result.jarakKordinatMeter, 0.0);
      expect(result.latitude, '');
      expect(result.lokasiFotoUrl, '');
    });
  });

  group('AttendanceLogModel.fromJson', () {
    test('should parse 200 response batas item successfully', () {
      final json = {
        "log_data_user_id": "13217",
        "log_data_tanggal": "2026-08-12",
        "log_data_jam": "14:41:01",
        "log_data_jumlah": "1x"
      };

      final result = AttendanceLogModel.fromJson(json);

      expect(result.userId, "13217");
      expect(result.date, "2026-08-12");
      expect(result.timeString, "14:41:01");
      expect(result.count, "1x");
    });
  });
}
