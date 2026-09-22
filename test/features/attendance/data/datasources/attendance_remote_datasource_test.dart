import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:epresensi_mobile/features/attendance/data/datasources/attendance_remote_datasource.dart';
import 'package:epresensi_mobile/core/error/exceptions.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  late AttendanceRemoteDataSourceImpl dataSource;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerFallbackValue(
      http.Request('POST', Uri.parse('https://example.com')),
    );
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    dataSource = AttendanceRemoteDataSourceImpl(client: mockHttpClient);
  });

  group('AttendanceRemoteDataSourceImpl - submitAttendance', () {
    test(
      'returns decoded map when HTTP status is 200 OK with kode 0',
      () async {
        when(() => mockHttpClient.send(any())).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value('{"kode": 0}'.codeUnits),
            200,
          );
        });

        final result = await dataSource.submitAttendance(
          nip: '196512101987032009',
          unorId: '8ae4828859d211720159d50fe0eb1e67',
          kodeUnik: 'PKQ1',
          idMesin: '13217',
          tipeAbsen: 'B',
          latitude: '-3.793129',
          longitude: '102.270928',
          accuracy: '5',
          provider: 'fused',
          timestampDevice: '1785472862000',
          isMockLocation: 'false',
          jarak: '13.98',
          radius: '20',
          merek: 'asus',
          model: 'ASUS_X00TD',
          imagePath: '',
          gpsSnapshot: {},
          faceRecognition: '[]',
          token: 'test_token',
        );

        expect(result['kode'], 0);
        final captured = verify(
          () => mockHttpClient.send(captureAny()),
        ).captured;
        final request = captured.single as http.MultipartRequest;
        expect(request.fields['radius_meter'], '20');
      },
    );

    test('throws friendly ServerException on HTTP 401 Unauthorized', () async {
      when(() => mockHttpClient.send(any())).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value('{"message": "Sesi login telah berakhir"}'.codeUnits),
          401,
        );
      });

      expect(
        () => dataSource.submitAttendance(
          nip: '196512101987032009',
          unorId: '8ae4828859d211720159d50fe0eb1e67',
          kodeUnik: 'PKQ1',
          idMesin: '13217',
          tipeAbsen: 'B',
          latitude: '-3.793129',
          longitude: '102.270928',
          accuracy: '5',
          provider: 'fused',
          timestampDevice: '1785472862000',
          isMockLocation: 'false',
          jarak: '13.98',
          radius: '20',
          merek: 'asus',
          model: 'ASUS_X00TD',
          imagePath: '',
          gpsSnapshot: {},
          faceRecognition: '[]',
          token: 'test_token',
        ),
        throwsA(
          isA<ServerException>().having(
            (e) => e.message,
            'message',
            'Sesi login telah berakhir',
          ),
        ),
      );
    });

    test(
      'throws friendly ServerException on HTTP 500 Internal Server Error',
      () async {
        when(() => mockHttpClient.send(any())).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value('<html>500 Server Error</html>'.codeUnits),
            500,
          );
        });

        expect(
          () => dataSource.submitAttendance(
            nip: '196512101987032009',
            unorId: '8ae4828859d211720159d50fe0eb1e67',
            kodeUnik: 'PKQ1',
            idMesin: '13217',
            tipeAbsen: 'B',
            latitude: '-3.793129',
            longitude: '102.270928',
            accuracy: '5',
            provider: 'fused',
            timestampDevice: '1785472862000',
            isMockLocation: 'false',
            jarak: '13.98',
            radius: '20',
            merek: 'asus',
            model: 'ASUS_X00TD',
            imagePath: '',
            gpsSnapshot: {},
            faceRecognition: '[]',
            token: 'test_token',
          ),
          throwsA(
            isA<ServerException>().having(
              (e) => e.message,
              'message',
              contains('Terjadi kendala pada server presensi (HTTP 500)'),
            ),
          ),
        );
      },
    );
  });
}
