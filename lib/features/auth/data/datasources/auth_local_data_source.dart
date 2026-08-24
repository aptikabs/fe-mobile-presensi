import 'dart:convert';
import 'package:hive/hive.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_model.dart';

abstract class AuthLocalDataSource {
  Future<void> cacheUser(UserModel user);
  Future<UserModel?> getLastUser();
  Future<void> clearUser();
  Future<void> saveCredentials(String username, String password);
  Future<Map<String, String>?> getCredentials();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  final Box box;
  static const String cachedUserKey = 'CACHED_USER';
  static const String rawResponseKey = 'RAW_LOGIN_RESPONSE';
  static const String tokenKey = 'AUTH_TOKEN';
  static const String usernameKey = 'SAVED_USERNAME';
  static const String passwordKey = 'SAVED_PASSWORD';

  AuthLocalDataSourceImpl({required this.box});

  @override
  Future<void> cacheUser(UserModel user) async {
    try {
      final jsonMap = user.toJson();
      final jsonString = json.encode(jsonMap);
      await box.put(cachedUserKey, jsonString);
      await box.put(rawResponseKey, jsonString);
      if (user.token != null && user.token!.isNotEmpty) {
        await box.put(tokenKey, user.token);
      }
    } catch (e) {
      throw CacheException('Gagal menyimpan sesi pengguna');
    }
  }

  @override
  Future<UserModel?> getLastUser() async {
    try {
      final jsonString = box.get(cachedUserKey);
      if (jsonString != null) {
        final user = UserModel.fromJson(json.decode(jsonString));
        final savedToken = box.get(tokenKey) as String?;
        if ((user.token == null || user.token!.isEmpty) &&
            savedToken != null &&
            savedToken.isNotEmpty) {
          return user.copyWithToken(savedToken);
        }
        return user;
      }
      return null;
    } catch (e) {
      throw CacheException('Gagal memuat sesi pengguna');
    }
  }

  @override
  Future<void> clearUser() async {
    try {
      await box.delete(cachedUserKey);
      await box.delete(rawResponseKey);
      await box.delete(tokenKey);
      await box.delete(usernameKey);
      await box.delete(passwordKey);
    } catch (e) {
      throw CacheException('Gagal menghapus sesi pengguna');
    }
  }

  @override
  Future<void> saveCredentials(String username, String password) async {
    try {
      await box.put(usernameKey, username);
      await box.put(passwordKey, password);
    } catch (e) {
      // ignore
    }
  }

  @override
  Future<Map<String, String>?> getCredentials() async {
    try {
      final username = box.get(usernameKey) as String?;
      final password = box.get(passwordKey) as String?;
      if (username != null &&
          username.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        return {'username': username, 'password': password};
      }
    } catch (e) {
      // ignore
    }
    return null;
  }
}
