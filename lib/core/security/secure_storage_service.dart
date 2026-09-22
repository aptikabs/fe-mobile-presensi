import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

/// Service untuk mengelola encryption key 256-bit secara aman
/// menggunakan Hardware-backed Storage (Android Keystore / iOS Keychain).
class SecureStorageService {
  static const String _hiveKeyAlias = 'hive_encryption_key_v1';
  static const String faceEmbeddingKey = 'registered_face_embedding_v1';

  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
    : _storage =
          storage ??
          const FlutterSecureStorage(
            aOptions: AndroidOptions(encryptedSharedPreferences: true),
            iOptions: IOSOptions(
              accessibility: KeychainAccessibility.first_unlock,
              synchronizable: false,
            ),
          );

  /// Mengambil atau membuat Encryption Key 256-bit (32 bytes) baru untuk Hive AES Cipher.
  /// Kunci disimpan di KeyStore/Keychain dalam format Base64.
  Future<List<int>> getOrCreateHiveEncryptionKey() async {
    try {
      final existingKeyBase64 = await _storage.read(key: _hiveKeyAlias);

      if (existingKeyBase64 != null && existingKeyBase64.isNotEmpty) {
        final decodedKey = base64Decode(existingKeyBase64);
        if (decodedKey.length == 32) {
          return decodedKey;
        }
      }

      // Kunci belum ada atau invalid: Buat kunci aman 256-bit (32 bytes) baru
      final newKeyBytes = Hive.generateSecureKey();
      final newKeyBase64 = base64Encode(newKeyBytes);

      await _storage.write(key: _hiveKeyAlias, value: newKeyBase64);
      return newKeyBytes;
    } catch (e) {
      debugPrint('Error accessing SecureStorage for Hive Key: $e');
      // Jika terjadi kesalahan akses Keystore/Keychain, re-generate key aman
      final fallbackKey = Hive.generateSecureKey();
      try {
        await _storage.write(
          key: _hiveKeyAlias,
          value: base64Encode(fallbackKey),
        );
      } catch (_) {}
      return fallbackKey;
    }
  }

  /// Menghapus encryption key dari Secure Storage (saat purge total data).
  Future<void> clearEncryptionKey() async {
    try {
      await _storage.delete(key: _hiveKeyAlias);
    } catch (e) {
      debugPrint('Error deleting encryption key from SecureStorage: $e');
    }
  }

  /// Menghapus seluruh isi Secure Storage
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      debugPrint('Error clearing SecureStorage: $e');
    }
  }

  Future<void> saveFaceEmbedding(String value) async {
    await _storage.write(key: faceEmbeddingKey, value: value);
  }

  Future<String?> readFaceEmbedding() async {
    return _storage.read(key: faceEmbeddingKey);
  }

  Future<void> deleteFaceEmbedding() async {
    await _storage.delete(key: faceEmbeddingKey);
  }
}
