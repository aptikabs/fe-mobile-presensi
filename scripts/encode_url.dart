import 'package:flutter/foundation.dart';

void main(List<String> args) {
  if (args.isEmpty) {
    debugPrint('Guna: dart scripts/encode_url.dart <URL_BARU>');
    debugPrint(
      'Contoh: dart scripts/encode_url.dart https://api.epresensi.bengkuluprov.go.id/api',
    );
    return;
  }

  final url = args.first;
  const key = 0x57; // Key XOR
  final bytes = url.codeUnits.map((c) => c ^ key).toList();

  debugPrint('\n=== HASIL OBFUSKASI URL ===');
  debugPrint('URL Original : $url');
  debugPrint('XOR Key      : 0x57');
  debugPrint('\nCopy-paste kode berikut ke lib/api/urls.dart:\n');
  debugPrint('  static final String baseUrl = _d(');
  debugPrint('    const $bytes,');
  debugPrint('    0x57,');
  debugPrint('  );');
  debugPrint('============================\n');
}
