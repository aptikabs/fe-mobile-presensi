import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:epresensi_mobile/features/history/data/datasources/history_remote_data_source.dart';
import 'package:epresensi_mobile/core/error/exceptions.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late HistoryRemoteDataSourceImpl dataSource;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerFallbackValue(http.Request('POST', Uri.parse('https://example.com')));
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    dataSource = HistoryRemoteDataSourceImpl(client: mockHttpClient);
  });

  group('HistoryRemoteDataSourceImpl - getHistory & getAttendanceLogs', () {
    test('getHistory returns list of PresenceLog on 200 OK', () async {
      final jsonResponse = '''
      {
        "data": [
          {
            "id": 6232482,
            "waktu": "2026-02-12 14:59:29",
            "tanggal": "2026-02-12",
            "jam": "14:59:29",
            "latitude": "-3.793142",
            "longitude": "102.270584",
            "lokasi_foto": "2026/02/196512101987032009-2026-02-12-14-59-29.jpg",
            "jarak_kordinat_meter": 18.06,
            "lokasi_foto_url": "https://devcdn.bengkuluprov.go.id/2026/02/test.jpg"
          }
        ]
      }
      ''';

      when(() => mockHttpClient.send(any())).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(jsonResponse.codeUnits),
          200,
        );
      });

      final result = await dataSource.getHistory(
        '196512101987032009',
        '2025-10-01',
        '2026-02-20',
        token: 'test_token',
      );

      expect(result.length, 1);
      expect(result.first.id, 6232482);
    });

    test('getAttendanceLogs returns list of AttendanceLogModel on 200 OK', () async {
      final jsonResponse = '''
      {
        "mobile": [
          {
            "log_data_user_id": "13217",
            "log_data_tanggal": "2026-08-12",
            "log_data_jam": "14:41:01",
            "log_data_jumlah": "1x"
          }
        ],
        "fingerprint": [],
        "kode": 0
      }
      ''';

      when(() => mockHttpClient.send(any())).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(jsonResponse.codeUnits),
          200,
        );
      });

      final result = await dataSource.getAttendanceLogs(
        '196512101987032009',
        12,
        2025,
        token: 'test_token',
      );

      expect(result.length, 1);
      expect(result.first.userId, "13217");
      expect(result.first.count, "1x");
    });

    test('throws friendly ServerException on HTTP 401 Unauthorized', () async {
      when(() => mockHttpClient.send(any())).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value('{"message": "Unauthenticated"}'.codeUnits),
          401,
        );
      });

      expect(
        () => dataSource.getHistory(
          '196512101987032009',
          '2025-10-01',
          '2026-02-20',
          token: 'invalid_token',
        ),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Unauthenticated',
          ),
        ),
      );
    });

    test('throws friendly ServerException on HTTP 500 Server Error', () async {
      when(() => mockHttpClient.send(any())).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value('<html>Internal Error</html>'.codeUnits),
          500,
        );
      });

      expect(
        () => dataSource.getHistory(
          '196512101987032009',
          '2025-10-01',
          '2026-02-20',
        ),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            contains('Terjadi kendala pada server (HTTP 500)'),
          ),
        ),
      );
    });
  });
}
