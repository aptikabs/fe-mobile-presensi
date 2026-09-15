import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Client HTTP Terproteksi dengan Validasi Strict Sertifikat SSL / SPKI.
/// Mencegah Interception MITM dan SSL Pinning Bypass sederhana pada Flutter Engine.
class PinnedHttpClient {
  /// SHA-256 hash sertifikat DER yang dihitung oleh verifyCertificate.
  static const List<String> allowedSha256Pins = [
    'WT+/NYmOE4tylr2g1BqgoSHHiz2/qvFfS3iBMZehB/M=',
    'MQUyULNS33Kn7V0Q2AwbFQJi1nn7i/UqChTQQl4wxbQ=',
    '70bOP4TfziAt+s1w7MrFVdHaHGYvFG7Mat4CMidxqls=',
    'ByY50LFA1b/64WrZw/bMYIYEBiH1HuYabUaokVwHz3Y=',
  ];

  /// Daftar Host/Domain Backend yang Diizinkan
  static const List<String> allowedHosts = [
    'bengkuluselatankab.go.id',
    'presensi.bengkuluselatankab.go.id',
  ];

  /// Mengecek apakah host diizinkan
  static bool isHostAllowed(String host) {
    return allowedHosts.any(
      (allowed) => host == allowed || host.endsWith('.$allowed'),
    );
  }

  /// Verifikasi Sertifikat SSL terhadap SHA-256 SPKI Pins
  static bool verifyCertificate(
    X509Certificate cert,
    String host, {
    bool allowDebugBypass = kDebugMode,
  }) {
    if (!isHostAllowed(host)) {
      debugPrint('⛔ SSL Pinning Failure: Host tidak diizinkan "$host"');
      return false;
    }

    try {
      final certDerBytes = cert.der;
      final sha256Digest = sha256.convert(certDerBytes);
      final base64Hash = base64.encode(sha256Digest.bytes);

      // Verifikasi terhadap SHA-256 Pins
      final bool isPinnedMatch = allowedSha256Pins.contains(base64Hash);

      if (isPinnedMatch) {
        debugPrint('✅ SSL Certificate Verified untuk host "$host"');
        return true;
      }

      // Jika pada kDebugMode dan pin tidak cocok (misal cert staging berubah), izinkan log peringatan
      if (allowDebugBypass) {
        debugPrint(
          '⚠️ [DEBUG MODE] Certificate Hash ($base64Hash) tidak ada di allowedSha256Pins.',
        );
        return true;
      }

      debugPrint(
        '⛔ SSL Pinning / Certificate SPKI Validation Failure for host: $host',
      );
      debugPrint('   Calculated Certificate Hash: $base64Hash');
      return false;
    } catch (e) {
      debugPrint('Error validating SSL certificate: $e');
      return false;
    }
  }

  /// Membuat instance http.Client terproteksi
  static http.Client createClient({bool? allowDebugBypass}) {
    // Mematikan kepercayaan pada Root CA bawaan OS Android/User Trust Store (withTrustedRoots: false).
    // Ini memastikan sertifikat CA proxy (seperti Burp Suite / HTTP Toolkit) otomatis memicu badCertificateCallback.
    final shouldBypassPin = allowDebugBypass ?? kDebugMode;
    final SecurityContext context = SecurityContext(withTrustedRoots: false);

    final HttpClient ioClient = HttpClient(context: context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return verifyCertificate(cert, host, allowDebugBypass: shouldBypassPin);
      };

    final client = IOClient(ioClient);
    return shouldBypassPin ? DebugHttpClient(client) : client;
  }
}

class DebugHttpClient extends http.BaseClient {
  final http.Client _inner;

  DebugHttpClient(this._inner);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    debugPrint('--- API REQUEST ---');
    debugPrint('${request.method} ${request.url}');
    debugPrint('Headers: ${_redactMap(request.headers)}');
    debugPrint('Body: ${_requestBody(request)}');

    final response = await _inner.send(request);
    final responseBytes = <int>[];
    final responseStream = response.stream.transform(
      StreamTransformer<List<int>, List<int>>.fromHandlers(
        handleData: (chunk, sink) {
          responseBytes.addAll(chunk);
          sink.add(chunk);
        },
        handleDone: (sink) {
          final body = utf8.decode(responseBytes, allowMalformed: true);
          debugPrint('--- API RESPONSE ---');
          debugPrint('${response.statusCode} ${request.url}');
          debugPrint('Headers: ${_redactMap(response.headers)}');
          debugPrint('Body: ${_truncate(body)}');
          sink.close();
        },
      ),
    );

    return http.StreamedResponse(
      http.ByteStream(responseStream),
      response.statusCode,
      contentLength: response.contentLength,
      request: response.request,
      headers: response.headers,
      isRedirect: response.isRedirect,
      persistentConnection: response.persistentConnection,
      reasonPhrase: response.reasonPhrase,
    );
  }

  @override
  void close() {
    _inner.close();
  }

  static String _requestBody(http.BaseRequest request) {
    if (request is http.Request) return _truncate(request.body);
    if (request is http.MultipartRequest) {
      final fields = <String, dynamic>{...request.fields};
      for (final key in fields.keys.toList()) {
        if (_isSensitiveKey(key)) fields[key] = '***';
      }
      return 'fields: $fields, files: ${request.files.map((file) => file.field).toList()}';
    }
    return '(streamed body)';
  }

  static Map<String, String> _redactMap(Map<String, String> values) {
    return values.map(
      (key, value) => MapEntry(key, _isSensitiveKey(key) ? '***' : value),
    );
  }

  static bool _isSensitiveKey(String key) {
    final normalized = key.toLowerCase();
    return normalized.contains('authorization') ||
        normalized.contains('password') ||
        normalized.contains('token') ||
        normalized.contains('secret');
  }

  static String _truncate(String value) {
    const maxLength = 10000;
    return value.length <= maxLength
        ? value
        : '${value.substring(0, maxLength)}... [truncated]';
  }
}
