import 'package:flutter_test/flutter_test.dart';
import 'package:epresensi_mobile/features/auth/data/models/user_model.dart';

void main() {
  group('UserModel.fromJson', () {
    test('should parse 200 response JSON successfully', () {
      final jsonResponse = {
        "detail_pegawai": {
          "id": "A8ACA7D26C8F3912E040640A040269BB",
          "nip": "196512101987032009",
          "nama": "IRMA ARTATI, S.Sos",
          "email": "irmaartati@gmail.com",
          "jenis_kelamin": "P",
          "golongan": {
            "nama": "III/d",
            "nama_pangkat": "Penata Tingkat I",
            "tmt_golongan": "01-04-2015"
          },
          "jenis_jabatan": {
            "id": "4",
            "nama": "FUNGSIONAL_UMUM"
          },
          "jabatan_id": "ff8080814b571e31014b5cb618c26447",
          "jabatan_nama": "Pengawas Teknologi Informasi",
          "tmt_jabatan": "04-01-2019",
          "masa_kerja": {
            "tahun": "23",
            "bulan": "1"
          },
          "unor": {
            "id": "8ae4828859d211720159d5155505212f",
            "nama_unor": "Seksi Pengembangan Aplikasi"
          },
          "unor_induk": {
            "id": "8ae4828859d211720159d50fe0eb1e67",
            "nama_unor": "Dinas Komunikasi, Informatika dan Statistik Provinsi Bengkulu"
          },
          "hukuman_disiplin": {
            "id": null,
            "tmt_hukuman_disiplin": null,
            "tmt_akhir_hukuman_disiplin": null
          },
          "is_penyetaraan": null,
          "kedudukan_hukum_id": "99",
          "kedudukan_hukum_nama": "Pensiun"
        },
        "kode": 0,
        "daftar_kordinat": [
          {
            "id": 3,
            "unor": "8ae4828859d211720159d50fe0eb1e67",
            "nama_tempat": "Fingerprint Dekat E-GOV",
            "latitude": "-3.792982",
            "longitude": "102.270556",
            "alamat": "JL. Basuki Rahmat No. 06 Sawah Lebar Baru, Ratu Agung, Kota Bengkulu. 38223",
            "deskripsi": "",
            "disetujui": 1,
            "created_at": "2021-06-21T09:16:30.000000Z",
            "updated_at": "2021-06-21T09:17:27.000000Z",
            "polygon_points": [
              {
                "id": 1,
                "kordinat_id": 3,
                "kordinat_type": "App\\Models\\KordinatOPD",
                "latitude": "-3.793045848211363",
                "longitude": "102.27042204414505",
                "urutan": 1,
                "created_at": "2026-03-04T04:46:20.000000Z",
                "updated_at": "2026-03-04T04:46:20.000000Z"
              }
            ]
          }
        ],
        "hasil_login": {
          "id": "3bbd703d-cc9f-447b-b9e2-569a2233bcf7",
          "nama": "IRMA ARTATI S.SOS",
          "username": "irmaartati",
          "nip": "196512101987032009",
          "unor_id": "8ae4828859d211720159d50fe0eb1e67",
          "id_mesin": 13217,
          "tipe_absensi": "A",
          "status_wfa": 0,
          "status_hari_kerja": "WFO",
          "mode_kerja": [],
          "jadwal_absen": {
            "id": 1,
            "tipe": "A",
            "masuk_jam": "06:45:00",
            "masuk_batas": "07:45:00",
            "pulang_jam": "16:15:00",
            "pulang_batas": "20:00:00"
          }
        },
        "kode_unik": "12345",
        "face_recognition": [-0.021449, 0.02372],
        "wfa_status": 1,
        "token": "eyJ0eX..."
      };

      final result = UserModel.fromJson(jsonResponse);

      expect(result.kode, 0);
      expect(result.kodeUnik, '12345');
      expect(result.wfaStatus, 1);
      expect(result.token, 'eyJ0eX...');
      expect(result.detailPegawai.nip, '196512101987032009');
      expect(result.detailPegawai.nama, 'IRMA ARTATI, S.Sos');
      expect(result.detailPegawai.unorNama, 'Seksi Pengembangan Aplikasi');
      expect(result.detailPegawai.unorIndukNama, 'Dinas Komunikasi, Informatika dan Statistik Provinsi Bengkulu');
      expect(result.result.idMesin, 13217);
      expect(result.result.tipeAbsensi, 'A');
      expect(result.result.jadwalAbsen?.masukJam, '06:45:00');
      expect(result.daftarKordinat.length, 1);
      expect(result.daftarKordinat.first.namaTempat, 'Fingerprint Dekat E-GOV');
      expect(result.daftarKordinat.first.polygonPoints.length, 1);
      expect(result.daftarKordinat.first.polygonPoints.first.urutan, 1);
    });

    test('should parse safely when types are numeric strings or missing', () {
      final jsonResponse = {
        "detail_pegawai": null,
        "kode": "0",
        "daftar_kordinat": [
          {
            "id": "3",
            "nama_tempat": "Fingerprint",
            "polygon_points": [
              {
                "id": "10",
                "urutan": "2"
              }
            ]
          }
        ],
        "hasil_login": {
          "id_mesin": "9999",
          "jadwal_absen": {
            "id": "5"
          }
        },
        "kode_unik": 12345,
        "wfa_status": "1"
      };

      final result = UserModel.fromJson(jsonResponse);

      expect(result.kode, 0);
      expect(result.kodeUnik, '12345');
      expect(result.wfaStatus, 1);
      expect(result.result.idMesin, 9999);
      expect(result.result.jadwalAbsen?.id, 5);
      expect(result.daftarKordinat.first.id, 3);
      expect(result.daftarKordinat.first.polygonPoints.first.id, 10);
      expect(result.daftarKordinat.first.polygonPoints.first.urutan, 2);
    });

    test('should extract token from nested fields if top-level token is null', () {
      final jsonResponse = {
        "kode": 0,
        "hasil_login": {
          "token": "token_in_hasil_login"
        }
      };

      final result = UserModel.fromJson(jsonResponse);
      expect(result.token, 'token_in_hasil_login');
    });

    test('toJson should preserve token even if initialized with rawJson lacking top-level token', () {
      final dummyUser = UserModel.fromJson({});
      final model = UserModel(
        detailPegawai: dummyUser.detailPegawai,
        kode: 0,
        daftarKordinat: const [],
        result: dummyUser.result,
        kodeUnik: '123',
        wfaStatus: 1,
        token: 'my_custom_token',
        rawJson: {'kode': 0},
      );

      final jsonMap = model.toJson();
      expect(jsonMap['token'], 'my_custom_token');
    });
  });
}
