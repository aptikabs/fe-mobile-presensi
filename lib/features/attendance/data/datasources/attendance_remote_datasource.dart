import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:epresensi_mobile/api/urls.dart';
import 'package:http/http.dart' as http;
import '../../../../core/error/exceptions.dart';

abstract class AttendanceRemoteDataSource {
  Future<Map<String, dynamic>> submitAttendance({
    required String nip,
    required String unorId,
    required String kodeUnik,
    required String idMesin,
    required String tipeAbsen,
    required String latitude,
    required String longitude,
    required String accuracy,
    required String provider,
    required String timestampDevice,
    required String isMockLocation,
    required String jarak,
    required String radius,
    required String merek,
    required String model,
    required String imagePath,
    required Map<String, dynamic> gpsSnapshot,
    required String faceRecognition,
    required String token,
  });
}

class AttendanceRemoteDataSourceImpl implements AttendanceRemoteDataSource {
  final http.Client client;
  // Longer timeout for attendance since it uploads photo
  static const _timeout = Duration(seconds: 60);

  AttendanceRemoteDataSourceImpl({required this.client});

  String _extractErrorMessage(Map<String, dynamic>? data) {
    if (data == null) return '';
    if (data['error'] != null && data['error'].toString().trim().isNotEmpty) {
      return data['error'].toString().trim();
    }
    if (data['message'] != null &&
        data['message'].toString().trim().isNotEmpty) {
      return data['message'].toString().trim();
    }
    if (data['errors'] != null) {
      if (data['errors'] is Map) {
        final map = data['errors'] as Map;
        if (map.isNotEmpty) {
          final firstVal = map.values.first;
          if (firstVal is List && firstVal.isNotEmpty) {
            return firstVal.first.toString();
          } else if (firstVal != null) {
            return firstVal.toString();
          }
        }
      } else if (data['errors'] is List &&
          (data['errors'] as List).isNotEmpty) {
        return (data['errors'] as List).first.toString();
      }
    }
    return '';
  }

  String _getFriendlyErrorMessage(
    int statusCode,
    Map<String, dynamic>? data,
    String? reasonPhrase,
  ) {
    final extractedMsg = _extractErrorMessage(data);
    if (extractedMsg.isNotEmpty) {
      return extractedMsg;
    }

    switch (statusCode) {
      case 400:
        return 'Permintaan presensi tidak valid. Silakan periksa kembali data lokasi Anda.';
      case 401:
        return 'Sesi login Anda telah berakhir. Silakan login kembali.';
      case 403:
        return 'Akses ditolak. Anda tidak memiliki izin untuk melakukan presensi.';
      case 404:
        return 'Layanan presensi tidak ditemukan (404). Silakan hubungi administrator.';
      case 422:
        return 'Data presensi tidak sesuai atau tidak lengkap.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Terjadi kendala pada server presensi (HTTP $statusCode). Silakan coba beberapa saat lagi.';
      default:
        return 'Gagal melakukan presensi (HTTP $statusCode). Silakan coba lagi nanti.';
    }
  }

  @override
  Future<Map<String, dynamic>> submitAttendance({
    required String nip,
    required String unorId,
    required String kodeUnik,
    required String idMesin,
    required String tipeAbsen,
    required String latitude,
    required String longitude,
    required String accuracy,
    required String provider,
    required String timestampDevice,
    required String isMockLocation,
    required String jarak,
    required String radius,
    required String merek,
    required String model,
    required String imagePath,
    required Map<String, dynamic> gpsSnapshot,
    required String faceRecognition,
    required String token,
  }) async {
    final uri = Uri.parse(Urls.absen);
    var request = http.MultipartRequest('POST', uri);

    request.fields.addAll({
      'nip': nip,
      'unor_id': unorId,
      'kode_unik': kodeUnik,
      'id_mesin': idMesin,
      'tipe_absen': tipeAbsen,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'provider': provider,
      'timestamp_device': timestampDevice,
      'is_mock_location': isMockLocation,
      'jarak_kordinat_meter': jarak,
      'radius_meter': radius,
      'merek': merek,
      'model': model,
      'gps_snapshot': json.encode(gpsSnapshot),
      'face_recognition': faceRecognition,
    });

    if (token.isNotEmpty) {
      request.fields['token'] = token;
      request.headers['Authorization'] = 'Bearer $token';
    }

    if (imagePath.isNotEmpty) {
      request.files.add(
        await http.MultipartFile.fromPath('foto_pegawai', imagePath),
      );
    }

    try {
      final streamedResponse = await client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic>? data;
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          data = decoded;
        }
      } catch (_) {}

      if (response.statusCode == 200) {
        if (data != null) {
          return data;
        }
        throw ServerException(
          message: 'Respon dari server presensi tidak valid.',
        );
      } else {
        final friendlyMsg = _getFriendlyErrorMessage(
          response.statusCode,
          data,
          response.reasonPhrase,
        );
        throw ServerException(message: friendlyMsg);
      }
    } on SocketException {
      throw NetworkException(type: NetworkErrorType.noConnection);
    } on TimeoutException {
      throw NetworkException(type: NetworkErrorType.timeout);
    } on NetworkException {
      rethrow;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw NetworkException(
        type: NetworkErrorType.unknown,
        message: 'Terjadi kesalahan saat mengirim presensi. Silakan coba lagi.',
      );
    }
  }
}
