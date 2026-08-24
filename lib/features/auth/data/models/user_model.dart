import '../../domain/entities/attendance_schedule.dart';
import '../../domain/entities/coordinate.dart';
import '../../domain/entities/employee_detail.dart';
import '../../domain/entities/login_result.dart';
import '../../domain/entities/polygon_point.dart';
import '../../domain/entities/user_entity.dart';

class UserModel extends UserEntity {
  const UserModel({
    required super.detailPegawai,
    required super.kode,
    required super.daftarKordinat,
    required super.result,
    required super.kodeUnik,
    required super.wfaStatus,
    super.token,
    super.faceRecognition,
    super.rawJson,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Parse EmployeeDetail
    final detailJson = json['detail_pegawai'] is Map
        ? json['detail_pegawai']
        : {};
    final detail = EmployeeDetail(
      id: detailJson['id']?.toString() ?? '',
      nip: detailJson['nip']?.toString() ?? '',
      nama: detailJson['nama']?.toString() ?? '',
      email: detailJson['email']?.toString() ?? '',
      jenisKelamin: detailJson['jenis_kelamin']?.toString() ?? '',
      jabatanNama: detailJson['jabatan_nama']?.toString() ?? '',
      // Handle nested objects safely
      unorNama: (detailJson['unor'] != null && detailJson['unor'] is Map)
          ? detailJson['unor']['nama_unor']?.toString() ?? ''
          : '',
      unorIndukNama:
          (detailJson['unor_induk'] != null && detailJson['unor_induk'] is Map)
              ? detailJson['unor_induk']['nama_unor']?.toString() ?? ''
              : '',
      unorId: (detailJson['unor'] != null && detailJson['unor'] is Map)
          ? detailJson['unor']['id']?.toString() ?? ''
          : '',
    );

    // Parse Coordinates
    final List<Coordinate> coordinates = [];
    if (json['daftar_kordinat'] != null && json['daftar_kordinat'] is List) {
      for (var item in json['daftar_kordinat']) {
        if (item is Map) {
          final List<PolygonPoint> polygonPoints = [];
          if (item['polygon_points'] != null &&
              item['polygon_points'] is List) {
            for (var p in item['polygon_points']) {
              if (p is Map) {
                polygonPoints.add(
                  PolygonPoint(
                    id: p['id'] is int
                        ? p['id']
                        : (int.tryParse(p['id']?.toString() ?? '') ?? 0),
                    latitude: p['latitude']?.toString() ?? '',
                    longitude: p['longitude']?.toString() ?? '',
                    urutan: p['urutan'] is int
                        ? p['urutan']
                        : (int.tryParse(p['urutan']?.toString() ?? '') ?? 0),
                  ),
                );
              }
            }
          }

          coordinates.add(
            Coordinate(
              id: item['id'] is int
                  ? item['id']
                  : (int.tryParse(item['id']?.toString() ?? '') ?? 0),
              namaTempat: item['nama_tempat']?.toString() ?? '',
              latitude: item['latitude']?.toString() ?? '',
              longitude: item['longitude']?.toString() ?? '',
              alamat: item['alamat']?.toString() ?? '',
              polygonPoints: polygonPoints,
            ),
          );
        }
      }
    }

    // Parse LoginResult
    final resultJson = json['hasil_login'] is Map ? json['hasil_login'] : {};
    AttendanceSchedule? schedule;
    if (resultJson['jadwal_absen'] != null &&
        resultJson['jadwal_absen'] is Map) {
      final scheduleJson = resultJson['jadwal_absen'];
      schedule = AttendanceSchedule(
        id: scheduleJson['id'] is int
            ? scheduleJson['id']
            : (int.tryParse(scheduleJson['id']?.toString() ?? '') ?? 0),
        tipe: scheduleJson['tipe']?.toString() ?? '',
        masukJam: scheduleJson['masuk_jam']?.toString() ?? '',
        masukBatas: scheduleJson['masuk_batas']?.toString() ?? '',
        pulangJam: scheduleJson['pulang_jam']?.toString() ?? '',
        pulangBatas: scheduleJson['pulang_batas']?.toString() ?? '',
      );
    }

    final result = LoginResult(
      nama: resultJson['nama']?.toString() ?? '',
      username: resultJson['username']?.toString() ?? '',
      nip: resultJson['nip']?.toString() ?? '',
      unorId: resultJson['unor_id']?.toString() ?? '',
      idMesin: resultJson['id_mesin'] is int
          ? resultJson['id_mesin']
          : (int.tryParse(resultJson['id_mesin']?.toString() ?? '') ?? 0),
      tipeAbsensi: resultJson['tipe_absensi']?.toString() ?? '',
      jadwalAbsen: schedule,
    );

    final int kode = json['kode'] is int
        ? json['kode']
        : (int.tryParse(json['kode']?.toString() ?? '') ?? 0);

    final int wfaStatus = json['wfa_status'] is int
        ? json['wfa_status']
        : (int.tryParse(json['wfa_status']?.toString() ?? '') ?? 0);

    final String? extractedToken = (json['token'] ??
            json['hasil_login']?['token'] ??
            json['access_token'] ??
            json['data']?['token'])
        ?.toString();

    return UserModel(
      detailPegawai: detail,
      kode: kode,
      daftarKordinat: coordinates,
      result: result,
      kodeUnik: json['kode_unik']?.toString() ?? '',
      wfaStatus: wfaStatus,
      token: extractedToken,
      faceRecognition: json['face_recognition'] is List
          ? json['face_recognition'] as List
          : null,
      rawJson: json,
    );
  }

  UserModel copyWithToken(String newToken) {
    return UserModel(
      detailPegawai: detailPegawai,
      kode: kode,
      daftarKordinat: daftarKordinat,
      result: result,
      kodeUnik: kodeUnik,
      wfaStatus: wfaStatus,
      token: newToken,
      faceRecognition: faceRecognition,
      rawJson: rawJson != null
          ? (Map<String, dynamic>.from(rawJson!)..['token'] = newToken)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = (rawJson != null && rawJson!.isNotEmpty)
        ? Map<String, dynamic>.from(rawJson!)
        : <String, dynamic>{
            'detail_pegawai': {
              'id': detailPegawai.id,
              'nip': detailPegawai.nip,
              'nama': detailPegawai.nama,
              'email': detailPegawai.email,
              'jenis_kelamin': detailPegawai.jenisKelamin,
              'jabatan_nama': detailPegawai.jabatanNama,
              'unor': {
                'nama_unor': detailPegawai.unorNama,
                'id': detailPegawai.unorId,
              },
              'unor_induk': {'nama_unor': detailPegawai.unorIndukNama},
            },
            'kode': kode,
            'daftar_kordinat': daftarKordinat
                .map(
                  (c) => {
                    'id': c.id,
                    'nama_tempat': c.namaTempat,
                    'latitude': c.latitude,
                    'longitude': c.longitude,
                    'alamat': c.alamat,
                    'polygon_points': c.polygonPoints
                        .map(
                          (p) => {
                            'id': p.id,
                            'latitude': p.latitude,
                            'longitude': p.longitude,
                            'urutan': p.urutan,
                          },
                        )
                        .toList(),
                  },
                )
                .toList(),
            'hasil_login': {
              'nama': result.nama,
              'username': result.username,
              'nip': result.nip,
              'unor_id': result.unorId,
              'id_mesin': result.idMesin,
              'tipe_absensi': result.tipeAbsensi,
              'jadwal_absen': result.jadwalAbsen == null
                  ? null
                  : {
                      'id': result.jadwalAbsen!.id,
                      'tipe': result.jadwalAbsen!.tipe,
                      'masuk_jam': result.jadwalAbsen!.masukJam,
                      'masuk_batas': result.jadwalAbsen!.masukBatas,
                      'pulang_jam': result.jadwalAbsen!.pulangJam,
                      'pulang_batas': result.jadwalAbsen!.pulangBatas,
                    },
            },
            'kode_unik': kodeUnik,
            'wfa_status': wfaStatus,
            'face_recognition': faceRecognition,
          };

    if (token != null && token!.isNotEmpty) {
      map['token'] = token;
    }
    return map;
  }
}
