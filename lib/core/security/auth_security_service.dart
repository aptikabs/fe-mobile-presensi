import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'secure_storage_service.dart';

/// Service khusus untuk menangani Keamanan Enkripsi Database Hive,
/// Manajemen Sesi (Logout), dan Data Purging (Pembersihan Total Data).
class AuthSecurityService {
  final SecureStorageService _secureStorageService;

  AuthSecurityService({SecureStorageService? secureStorageService})
      : _secureStorageService = secureStorageService ?? SecureStorageService();

  /// Membuka Hive Box dengan Enkripsi AES-256 (`HiveAesCipher`).
  /// Memiliki mekanisme automatic fallback & reset jika box sebelumnya belum terenkripsi
  /// atau kunci enkripsi mengalami corrupt/mismatch.
  Future<Box<T>> openEncryptedBox<T>(
    String boxName, {
    List<int>? cipherKey,
  }) async {
    final key = cipherKey ?? await _secureStorageService.getOrCreateHiveEncryptionKey();
    final cipher = HiveAesCipher(key);

    try {
      // Mencoba membuka box dengan enkripsi AES-256
      return await Hive.openBox<T>(boxName, encryptionCipher: cipher);
    } catch (e) {
      debugPrint('🚨 Warning: Gagal membuka encrypted box "$boxName": $e');
      debugPrint('🔄 Melakukan reset database tak terenkripsi/corrupt demi keamanan...');

      // Jika box sebelumnya disimpan tanpa enkripsi (plain-text) atau kunci tidak cocok,
      // Hapus file fisik database dari disk untuk mencegah kelemahan data leakage.
      try {
        if (Hive.isBoxOpen(boxName)) {
          await Hive.box(boxName).close();
        }
        await Hive.deleteBoxFromDisk(boxName);
      } catch (deleteError) {
        debugPrint('Gagal menghapus box dari disk: $deleteError');
      }

      // Re-open box baru yang sudah terenkripsi AES-256
      return await Hive.openBox<T>(boxName, encryptionCipher: cipher);
    }
  }

  /// Fungsi Logout: Menghapus data sensitif di memori (`box.clear()`).
  /// Menghapus kredensial, token PII, NIP, Nama, Unit Kerja, dan Device ID.
  Future<void> logout(List<Box> boxes) async {
    for (final box in boxes) {
      if (box.isOpen) {
        await box.clear();
      }
    }
    debugPrint('🔒 Logout berhasil: Memori & isi Hive Box sensitif telah dibersihkan.');
  }

  /// Data Purging: Menghapus seluruh isi box + file database fisik dari lokal storage.
  /// Dipanggil saat Sesi Kedaluwarsa, Deteksi Root/Jailbreak, atau Reset Aplikasi.
  Future<void> purgeAllData(List<String> boxNames) async {
    for (final boxName in boxNames) {
      try {
        if (Hive.isBoxOpen(boxName)) {
          final box = Hive.box(boxName);
          await box.clear();
          await box.close();
        }
        await Hive.deleteBoxFromDisk(boxName);
        debugPrint('🗑️ Database fisik "$boxName" telah dihapus dari storage lokal.');
      } catch (e) {
        debugPrint('Gagal menghapus file fisik box "$boxName": $e');
      }
    }

    // Bersihkan juga kunci enkripsi di Keystore / Keychain
    await _secureStorageService.clearAll();
    debugPrint('💥 Purge Data Selesai: Seluruh storage sensitif dan Secure Storage berhasil dibersihkan.');
  }
}
