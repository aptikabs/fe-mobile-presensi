import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:epresensi_mobile/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:epresensi_mobile/features/auth/data/models/user_model.dart';

class MockBox extends Mock implements Box {}

void main() {
  late AuthLocalDataSourceImpl dataSource;
  late MockBox mockBox;

  setUp(() {
    mockBox = MockBox();
    dataSource = AuthLocalDataSourceImpl(box: mockBox);
  });

  group('AuthLocalDataSourceImpl', () {
    final sampleJson = {
      "detail_pegawai": {
        "id": "A8ACA7D26C8F3912E040640A040269BB",
        "nip": "196512101987032009",
        "nama": "IRMA ARTATI, S.Sos",
        "email": "irmaartati@gmail.com",
        "jenis_kelamin": "P",
        "jabatan_nama": "Pengawas Teknologi Informasi",
        "unor": {
          "id": "8ae4828859d211720159d5155505212f",
          "nama_unor": "Seksi Pengembangan Aplikasi"
        },
        "unor_induk": {
          "id": "8ae4828859d211720159d50fe0eb1e67",
          "nama_unor": "Dinas Komunikasi, Informatika dan Statistik Provinsi Bengkulu"
        }
      },
      "kode": 0,
      "daftar_kordinat": [],
      "hasil_login": {
        "id": "3bbd703d-cc9f-447b-b9e2-569a2233bcf7",
        "nama": "IRMA ARTATI S.SOS",
        "username": "irmaartati",
        "nip": "196512101987032009",
        "unor_id": "8ae4828859d211720159d50fe0eb1e67",
        "id_mesin": 13217,
        "tipe_absensi": "A"
      },
      "kode_unik": "12345",
      "wfa_status": 1,
      "token": "test_jwt_token"
    };

    final tUserModel = UserModel.fromJson(sampleJson);

    test('cacheUser should store user JSON, raw response, and token to box', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});

      await dataSource.cacheUser(tUserModel);

      final expectedJsonString = json.encode(sampleJson);
      verify(() => mockBox.put(AuthLocalDataSourceImpl.cachedUserKey, expectedJsonString)).called(1);
      verify(() => mockBox.put(AuthLocalDataSourceImpl.rawResponseKey, expectedJsonString)).called(1);
      verify(() => mockBox.put(AuthLocalDataSourceImpl.tokenKey, 'test_jwt_token')).called(1);
    });

    test('getLastUser should retrieve and parse UserModel from box', () async {
      final jsonString = json.encode(sampleJson);
      when(() => mockBox.get(AuthLocalDataSourceImpl.cachedUserKey)).thenReturn(jsonString);

      final result = await dataSource.getLastUser();

      expect(result, isNotNull);
      expect(result?.detailPegawai.nip, '196512101987032009');
      expect(result?.token, 'test_jwt_token');
    });

    test('clearUser should remove cachedUser, rawResponse, and token from box', () async {
      when(() => mockBox.delete(any())).thenAnswer((_) async {});

      await dataSource.clearUser();

      verify(() => mockBox.delete(AuthLocalDataSourceImpl.cachedUserKey)).called(1);
      verify(() => mockBox.delete(AuthLocalDataSourceImpl.rawResponseKey)).called(1);
      verify(() => mockBox.delete(AuthLocalDataSourceImpl.tokenKey)).called(1);
    });

    test('saveCredentials and getCredentials should write and read credentials', () async {
      when(() => mockBox.put(any(), any())).thenAnswer((_) async {});
      await dataSource.saveCredentials('testuser', 'testpass');
      verify(() => mockBox.put(AuthLocalDataSourceImpl.usernameKey, 'testuser')).called(1);
      verify(() => mockBox.put(AuthLocalDataSourceImpl.passwordKey, 'testpass')).called(1);

      when(() => mockBox.get(AuthLocalDataSourceImpl.usernameKey)).thenReturn('testuser');
      when(() => mockBox.get(AuthLocalDataSourceImpl.passwordKey)).thenReturn('testpass');
      final creds = await dataSource.getCredentials();
      expect(creds, {'username': 'testuser', 'password': 'testpass'});
    });
  });
}
