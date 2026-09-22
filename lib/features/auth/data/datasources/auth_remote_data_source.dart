import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:epresensi_mobile/api/urls.dart';
import 'package:http/http.dart' as http;
import '../../../../core/error/auth_exceptions.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthRemoteDataSource {
  Future<UserModel> login({
    required String username,
    required String password,
    required String deviceId,
  });

  Future<void> changeDevice({
    required String nip,
    required String deviceId,
    required String merek,
    required String model,
    required String fingerprint,
  });

  Future<void> registerDevice({
    required String nip,
    required String deviceId,
    required String merek,
    required String model,
    required String fingerprint,
    required String imagePath,
    required List<double> faceEmbedding,
  });

  Future<void> checkUserBlock(String nip);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final http.Client client;
  static const _timeout = Duration(seconds: 30);

  AuthRemoteDataSourceImpl({required this.client});

  String? _extractErrorMessage(Map<String, dynamic>? data) {
    if (data == null) return null;
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
    return null;
  }

  String _getFriendlyErrorMessage(
    int statusCode,
    Map<String, dynamic>? data,
    String? reasonPhrase,
  ) {
    final extractedMsg = _extractErrorMessage(data);
    if (extractedMsg != null && extractedMsg.isNotEmpty) {
      return extractedMsg;
    }

    switch (statusCode) {
      case 400:
        return 'Permintaan login tidak valid. Silakan periksa kembali data yang dimasukkan.';
      case 401:
        return 'Username atau password yang Anda masukkan tidak sesuai.';
      case 403:
        return 'Akses ditolak atau perangkat tidak terdaftar.';
      case 404:
        return 'Layanan login tidak ditemukan (404). Silakan hubungi administrator.';
      case 422:
        return 'Data yang Anda masukkan tidak sesuai atau tidak lengkap.';
      case 500:
      case 502:
      case 503:
      case 504:
        return 'Terjadi kendala pada server (HTTP $statusCode). Silakan coba beberapa saat lagi.';
      default:
        return 'Gagal terhubung ke server (HTTP $statusCode). Silakan coba lagi nanti.';
    }
  }

  @override
  Future<UserModel> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    final url = Uri.parse(Urls.cekPerangkat);
    final request = http.MultipartRequest('POST', url);

    request.fields.addAll({
      "username": username,
      "password": password,
      "kode_unik": deviceId,
    });

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

      // Explicitly handle HTTP 403 Forbidden (Device Mismatch / Cek Perangkat failure)
      if (response.statusCode == 403) {
        final String msg =
            _extractErrorMessage(data) ??
            'Device berbeda atau telah mengalami pembaruan kode unik.';

        if (data != null && data.containsKey('kode')) {
          final int kode = (data['kode'] is int)
              ? data['kode']
              : (int.tryParse(data['kode'].toString()) ?? -1);
          if (kode == 3) {
            throw ContactAdminException(msg);
          } else if (kode == 2) {
            throw UserNotRegisteredException(msg, data: data);
          }
        }
        // Default any 403 status code to DeviceMismatchException
        throw DeviceMismatchException(msg, data: data);
      }

      if (data != null) {
        if (data.containsKey('kode')) {
          final int kode = (data['kode'] is int)
              ? data['kode']
              : (int.tryParse(data['kode'].toString()) ?? -1);
          final String msg = _extractErrorMessage(data) ?? 'Respon dari server';
          switch (kode) {
            case 0:
              if (response.statusCode == 200) {
                return UserModel.fromJson(data);
              }
              break;
            case 1:
              throw DeviceMismatchException(
                _extractErrorMessage(data) ?? 'NIP sama, device beda',
                data: data,
              );
            case 2:
              throw UserNotRegisteredException(
                _extractErrorMessage(data) ?? 'NIP tidak ada',
                data: data,
              );
            case 3:
              throw ContactAdminException(
                _extractErrorMessage(data) ?? 'Hubungi Admin',
              );
            default:
              throw AuthException(msg, kode);
          }
        }

        if (data.containsKey('error')) {
          final errStr = data['error'].toString().trim();
          if (errStr.isNotEmpty) {
            throw AuthException(errStr);
          }
        }
      }

      if (response.statusCode == 200) {
        if (data != null &&
            (data.containsKey('detail_pegawai') ||
                data.containsKey('hasil_login'))) {
          return UserModel.fromJson(data);
        }

        throw AuthException('Format respon dari server tidak sesuai.');
      } else {
        final friendlyMsg = _getFriendlyErrorMessage(
          response.statusCode,
          data,
          response.reasonPhrase,
        );
        throw AuthException(friendlyMsg, response.statusCode);
      }
    } on SocketException {
      throw NetworkException(type: NetworkErrorType.noConnection);
    } on TimeoutException {
      throw NetworkException(type: NetworkErrorType.timeout);
    } on NetworkException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException(
        'Terjadi kesalahan saat memproses login. Silakan coba lagi.',
      );
    }
  }

  @override
  Future<void> changeDevice({
    required String nip,
    required String deviceId,
    required String merek,
    required String model,
    required String fingerprint,
  }) async {
    final url = Uri.parse(Urls.ubahPerangkat);
    final request = http.MultipartRequest('POST', url);

    request.fields.addAll({
      "nip": nip,
      "kode_unik": deviceId,
      "merek": merek,
      "model": model,
      "fingerprint": fingerprint,
    });

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

      final String? serverErrorMsg = (data != null)
          ? (data['error']?.toString().isNotEmpty == true
                ? data['error'].toString()
                : (data['message']?.toString().isNotEmpty == true
                      ? data['message'].toString()
                      : null))
          : null;

      if (data != null) {
        if (data.containsKey('kode')) {
          final int kode = (data['kode'] is int)
              ? data['kode']
              : (int.tryParse(data['kode'].toString()) ?? -1);
          switch (kode) {
            case 0:
              return;
            case 1:
              final String dateAllowed =
                  data['tanggal_boleh'] ?? 'Unknown date';
              throw ChangeDeviceNotAllowedException(
                serverErrorMsg ?? 'Tidak dapat mengubah perangkat saat ini',
                dateAllowed,
              );
            case 2:
              throw ChangeDeviceFailedException(
                serverErrorMsg ??
                    'Perangkat ini sudah terdaftar pada akun lain.',
              );
            default:
              throw AuthException(
                serverErrorMsg ?? 'Kode respons tidak dikenal',
                kode,
              );
          }
        }

        if (serverErrorMsg != null) {
          throw ChangeDeviceFailedException(serverErrorMsg);
        }
      }

      if (response.statusCode == 200) {
        return;
      } else {
        final friendlyMsg = _getFriendlyErrorMessage(
          response.statusCode,
          data,
          response.reasonPhrase,
        );
        throw ChangeDeviceFailedException(friendlyMsg);
      }
    } on SocketException {
      throw NetworkException(type: NetworkErrorType.noConnection);
    } on TimeoutException {
      throw NetworkException(type: NetworkErrorType.timeout);
    } on NetworkException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw ChangeDeviceFailedException(
        'Gagal mengubah perangkat. Silakan coba lagi.',
      );
    }
  }

  @override
  Future<void> registerDevice({
    required String nip,
    required String deviceId,
    required String merek,
    required String model,
    required String fingerprint,
    required String imagePath,
    required List<double> faceEmbedding,
  }) async {
    final url = Uri.parse(Urls.daftarPerangkat);
    final request = http.MultipartRequest('POST', url);

    request.fields.addAll({
      'nip': nip,
      'kode_unik': deviceId,
      'merek': merek,
      'model': model,
      'fingerprint': fingerprint,
      'face_recognition': jsonEncode(faceEmbedding),
    });

    if (imagePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('foto', imagePath));
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
          if (data.containsKey('kode')) {
            final int kode = (data['kode'] is int)
                ? data['kode']
                : (int.tryParse(data['kode'].toString()) ?? -1);
            switch (kode) {
              case 0:
                return;
              case 1:
                throw AuthException(
                  _extractErrorMessage(data) ??
                      'Gagal mendaftar perangkat. Perangkat mungkin sudah terdaftar.',
                );
              default:
                throw AuthException(
                  _extractErrorMessage(data) ?? 'Kode respons tidak dikenal',
                  kode,
                );
            }
          }

          if (data.containsKey('error')) {
            throw AuthException(data['error'].toString());
          }
        }
        return;
      } else {
        final friendlyMsg = _getFriendlyErrorMessage(
          response.statusCode,
          data,
          response.reasonPhrase,
        );
        throw AuthException(friendlyMsg);
      }
    } on SocketException {
      throw NetworkException(type: NetworkErrorType.noConnection);
    } on TimeoutException {
      throw NetworkException(type: NetworkErrorType.timeout);
    } on NetworkException {
      rethrow;
    } on AuthException {
      rethrow;
    } catch (e) {
      throw AuthException('Gagal mendaftar perangkat. Silakan coba lagi.');
    }
  }

  @override
  Future<void> checkUserBlock(String nip) async {
    final url = Uri.parse(Urls.userBlock);
    final request = http.MultipartRequest('POST', url);
    request.fields.addAll({'nip': nip});

    try {
      final streamedResponse = await client.send(request).timeout(_timeout);
      final response = await http.Response.fromStream(streamedResponse);

      // Fail silent/open if network error or non-200.
      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data is Map<String, dynamic>) {
            // "ambil bagian is_blocked dan message saja"
            // Handle both boolean and string for safety
            dynamic isBlockedVal = data['is_blocked'];
            bool isBlocked = false;
            if (isBlockedVal is bool) {
              isBlocked = isBlockedVal;
            } else if (isBlockedVal is String) {
              isBlocked = isBlockedVal.toLowerCase() == 'true';
            }

            if (isBlocked) {
              final String message = data['message'] ?? 'User sedang diblokir.';
              final Map<String, dynamic> exceptionData = {
                'title': 'Akses Ditolak', // Title implied by blocking context
                'subtitle': message,
              };
              throw UserBlockedException(message, data: exceptionData);
            }
          }
        } catch (e) {
          if (e is UserBlockedException) rethrow;
          // Ignore parse errors, proceed as allowed
        }
      }
      // Non-200 status codes: ignore and allow user to proceed
    } catch (e) {
      if (e is UserBlockedException) rethrow;
      // Ignore network errors for block check, proceed as allowed
    }
  }
}
