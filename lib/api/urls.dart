class Urls {
  // Helper dekripsi string XOR runtime (mencegah plain-text string scraping pada biner Dart)
  static String _d(List<int> bytes, int key) {
    return String.fromCharCodes(bytes.map((b) => b ^ key));
  }

  // DEV Base URL (Obfuscated XOR): 
  static final String _devBaseUrl = _d(
    const [63, 35, 35, 39, 36, 109, 120, 120, 51, 50, 33, 50, 39, 37, 50, 36, 50, 57, 36, 62, 58, 56, 53, 62, 59, 50, 121, 53, 50, 57, 48, 60, 34, 59, 34, 39, 37, 56, 33, 121, 48, 56, 121, 62],
    0x57,
  );

  // PROD Base URL (Obfuscated XOR): 
  static final String _prodBaseUrl = _d(
    const [63, 35, 35, 39, 36, 109, 120, 120, 50, 39, 37, 50, 36, 50, 57, 36, 62, 58, 56, 53, 62, 59, 50, 121, 53, 50, 57, 48, 60, 34, 59, 34, 39, 37, 56, 33, 121, 48, 56, 121, 62],
    0x57,
  );

  // Selector Environment:
  // Gunakan --dart-define=ENV=dev untuk DEV, --dart-define=ENV=prod (atau default) untuk PROD.
  static String get baseUrl => const String.fromEnvironment('ENV') == 'dev'
      ? _devBaseUrl
      : (const String.fromEnvironment('BASE_URL').isNotEmpty
          ? const String.fromEnvironment('BASE_URL')
          : _prodBaseUrl);

  // AUTH
  static String get cekPerangkat => '$baseUrl/cek-perangkat';
  static String get ubahPerangkat => '$baseUrl/ubah-perangkat';
  static String get daftarPerangkat => '$baseUrl/daftar-perangkat';

  // ABSEN
  static String get absen => '$baseUrl/presensi/simpan';

  // BANNER
  static String get banner => '$baseUrl/v3/banners';

  // HISTORY
  static String get history => '$baseUrl/presensi/riwayat/range';
  static String get monthlyHistory => '$baseUrl/presensi/batas';

  // WEB VIEW (Obfuscated XOR runtime)
  static final String privacy = _d(
    const [63, 35, 35, 39, 36, 109, 120, 120, 50, 39, 37, 50, 36, 50, 57, 36, 62, 58, 56, 53, 62, 59, 50, 121, 53, 50, 57, 48, 60, 34, 59, 34, 39, 37, 56, 33, 121, 48, 56, 121, 62, 51, 120, 36, 35, 56, 37, 54, 48, 50, 120, 39, 37, 62, 33, 54, 52, 46, 121, 63, 35, 58, 59],
    0x57,
  );
  static final String terms = _d(
    const [63, 35, 35, 39, 36, 109, 120, 120, 50, 39, 37, 50, 36, 50, 57, 36, 62, 58, 56, 53, 62, 59, 50, 121, 53, 50, 57, 48, 60, 34, 59, 34, 39, 37, 56, 33, 121, 48, 56, 121, 62, 51, 120, 36, 35, 56, 37, 54, 48, 50, 120, 35, 50, 37, 58, 36, 121, 63, 35, 58, 59],
    0x57,
  );

  // App Config
  static String get versionMobile => '$baseUrl/v3/version-mobile';
  static String get notification => '$baseUrl/v3/notifications';

  // user
  static String get userBlock => '$baseUrl/v3/users-block/check';
}
