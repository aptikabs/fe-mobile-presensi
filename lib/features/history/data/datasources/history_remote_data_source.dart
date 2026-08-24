import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:epresensi_mobile/api/urls.dart';
import 'package:http/http.dart' as http;
import '../../../../../core/error/exceptions.dart';
import '../models/presence_log_model.dart';
import '../../domain/entities/presence_log.dart';
import '../models/attendance_log_model.dart';

abstract class HistoryRemoteDataSource {
  Future<List<PresenceLog>> getHistory(
    String nip,
    String startDate,
    String endDate, {
    String? token,
  });

  Future<List<AttendanceLogModel>> getAttendanceLogs(
    String nip,
    int month,
    int year, {
    String? token,
    int type = 1,
  });
}

class HistoryRemoteDataSourceImpl implements HistoryRemoteDataSource {
  final http.Client client;
  static const _timeout = Duration(seconds: 30);

  HistoryRemoteDataSourceImpl({required this.client});

  String _extractErrorMessage(Map<String, dynamic>? data) {
    if (data == null) return '';
    if (data['error'] != null && data['error'].toString().trim().isNotEmpty) {
      return data['error'].toString().trim();
    }
    if (data['message'] != null && data['message'].toString().trim().isNotEmpty) {
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
      } else if (data['errors'] is List && (data['errors'] as List).isNotEmpty) {
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
        return 'Permintaan data riwayat tidak valid.';
      case 401:
        return 'Sesi login Anda telah berakhir. Silakan login kembali.';
      case 403:
        return 'Akses ditolak. Anda tidak memiliki izin untuk mengakses data riwayat ini.';
      case 404:
        return 'Layanan data riwayat tidak ditemukan (404). Silakan hubungi administrator.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Terjadi kendala pada server (HTTP $statusCode). Silakan coba beberapa saat lagi.';
      default:
        return 'Gagal memuat data riwayat (HTTP $statusCode). Silakan coba lagi nanti.';
    }
  }

  @override
  Future<List<PresenceLog>> getHistory(
    String nip,
    String startDate,
    String endDate, {
    String? token,
  }) async {
    final request = http.MultipartRequest('POST', Uri.parse(Urls.history));

    request.fields.addAll({'nip': nip, 'awal': startDate, 'akhir': endDate});

    if (token != null && token.isNotEmpty) {
      request.fields['token'] = token;
      request.headers['Authorization'] = 'Bearer $token';
    }

    try {
      final streamedResponse = await client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic>? jsonMap;
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          jsonMap = decoded;
        }
      } catch (_) {}

      if (response.statusCode == 200) {
        if (jsonMap != null && jsonMap['data'] is List) {
          final List<dynamic> data = jsonMap['data'];
          return data
              .whereType<Map<String, dynamic>>()
              .map((e) => PresenceLogModel.fromJson(e))
              .toList();
        }
        return [];
      } else {
        final friendlyMsg = _getFriendlyErrorMessage(
          response.statusCode,
          jsonMap,
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
        message: 'Gagal memuat riwayat presensi. Silakan coba lagi.',
      );
    }
  }

  @override
  Future<List<AttendanceLogModel>> getAttendanceLogs(
    String nip,
    int month,
    int year, {
    String? token,
    int type = 1,
  }) async {
    final url = '${Urls.monthlyHistory}/$nip/$month/$year/$type';
    final request = http.Request('GET', Uri.parse(url));

    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    try {
      final streamedResponse = await client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      Map<String, dynamic>? jsonMap;
      try {
        final decoded = json.decode(response.body);
        if (decoded is Map<String, dynamic>) {
          jsonMap = decoded;
        }
      } catch (_) {}

      if (response.statusCode == 200) {
        if (jsonMap != null && jsonMap['mobile'] is List) {
          final List<dynamic> data = jsonMap['mobile'];
          return data
              .whereType<Map<String, dynamic>>()
              .map((e) => AttendanceLogModel.fromJson(e))
              .toList();
        }
        return [];
      } else {
        final friendlyMsg = _getFriendlyErrorMessage(
          response.statusCode,
          jsonMap,
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
        message: 'Gagal memuat batas presensi. Silakan coba lagi.',
      );
    }
  }
}
