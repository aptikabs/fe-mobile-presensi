import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';
import 'package:epresensi_mobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:epresensi_mobile/core/error/auth_exceptions.dart';

class MockHttpClient extends Mock implements http.Client {}

void main() {
  // ignore: unused_local_variable
  late AuthRemoteDataSourceImpl dataSource;
  late MockHttpClient mockHttpClient;

  setUpAll(() {
    registerFallbackValue(
      http.Request('POST', Uri.parse('https://example.com')),
    );
  });

  setUp(() {
    mockHttpClient = MockHttpClient();
    dataSource = AuthRemoteDataSourceImpl(client: mockHttpClient);
  });

  group('AuthRemoteDataSourceImpl - Non-200 Response Handling', () {
    test(
      'throws friendly AuthException on HTTP 401 with JSON message',
      () async {
        final client = MockHttpClient();
        final ds = AuthRemoteDataSourceImpl(client: client);

        when(() => client.send(any())).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(
              '{"message": "Username atau password salah"}'.codeUnits,
            ),
            401,
          );
        });

        expect(
          () => ds.login(
            username: 'irmaartati',
            password: 'wrongpassword',
            deviceId: '12345',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'Username atau password salah',
            ),
          ),
        );
      },
    );

    test(
      'throws friendly default AuthException on HTTP 401 without body',
      () async {
        final client = MockHttpClient();
        final ds = AuthRemoteDataSourceImpl(client: client);

        when(() => client.send(any())).thenAnswer((_) async {
          return http.StreamedResponse(Stream.value(''.codeUnits), 401);
        });

        expect(
          () => ds.login(
            username: 'irmaartati',
            password: 'wrongpassword',
            deviceId: '12345',
          ),
          throwsA(
            isA<AuthException>().having(
              (e) => e.message,
              'message',
              'Username atau password yang Anda masukkan tidak sesuai.',
            ),
          ),
        );
      },
    );

    test('throws friendly AuthException on HTTP 500 server error', () async {
      final client = MockHttpClient();
      final ds = AuthRemoteDataSourceImpl(client: client);

      when(() => client.send(any())).thenAnswer((_) async {
        return http.StreamedResponse(
          Stream.value(
            '<html><body>500 Internal Server Error</body></html>'.codeUnits,
          ),
          500,
        );
      });

      expect(
        () => ds.login(
          username: 'irmaartati',
          password: 'Kominfo@123',
          deviceId: '12345',
        ),
        throwsA(
          isA<AuthException>().having(
            (e) => e.message,
            'message',
            contains('Terjadi kendala pada server (HTTP 500)'),
          ),
        ),
      );
    });

    test(
      'throws DeviceMismatchException on HTTP 403 when device mismatch',
      () async {
        final client = MockHttpClient();
        final ds = AuthRemoteDataSourceImpl(client: client);

        when(() => client.send(any())).thenAnswer((_) async {
          return http.StreamedResponse(
            Stream.value(
              '{"kode": 1, "error": "Kode unik perangkat berbeda"}'.codeUnits,
            ),
            403,
          );
        });

        expect(
          () => ds.login(
            username: 'irmaartati',
            password: 'Kominfo@123',
            deviceId: '99999',
          ),
          throwsA(
            isA<DeviceMismatchException>().having(
              (e) => e.message,
              'message',
              'Kode unik perangkat berbeda',
            ),
          ),
        );
      },
    );
  });
}
