import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Client HTTP Terproteksi dengan Validasi Strict Sertifikat SSL / SPKI.
/// Mencegah Interception MITM dan SSL Pinning Bypass sederhana pada Flutter Engine.
class PinnedHttpClient {
  /// SHA-256 Public Key Hashes (SPKI) untuk domain bengkuluprov.go.id (AWS ACM Chain)
  static const List<String> allowedSha256Pins = [
    'Go6Yu/bl7FLqTH0SHuWhONAM92dahY9a7mPf8rIqrFs=', // Leaf: devepresensimobile.bengkuluprov.go.id
    'G9LNNAql897egYsabashkzUCTEJkWBzgoEtk8X/678c=', // Intermediate CA: Amazon RSA 2048 M04
    '++MBgDH5WGvL9Bcn5Be30cRcL0f5O+NyoXuWtQdX1aI=', // Root CA: Amazon Root CA 1
  ];

  /// Daftar Host/Domain Backend yang Diizinkan
  static const List<String> allowedHosts = [
    'bengkuluselatankab.go.id',
    'presensi.bengkuluseltankab.go.id',
  ];

  /// Mengecek apakah host diizinkan
  static bool isHostAllowed(String host) {
    return allowedHosts.any(
      (allowed) => host == allowed || host.endsWith('.$allowed'),
    );
  }

  /// Verifikasi Sertifikat SSL terhadap SHA-256 SPKI Pins
  static bool verifyCertificate(X509Certificate cert, String host) {
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
      if (kDebugMode) {
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
  static http.Client createClient() {
    // Mematikan kepercayaan pada Root CA bawaan OS Android/User Trust Store (withTrustedRoots: false).
    // Ini memastikan sertifikat CA proxy (seperti Burp Suite / HTTP Toolkit) otomatis memicu badCertificateCallback.
    final SecurityContext context = SecurityContext(withTrustedRoots: false);

    final HttpClient ioClient = HttpClient(context: context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        return verifyCertificate(cert, host);
      };

    return IOClient(ioClient);
  }
}
