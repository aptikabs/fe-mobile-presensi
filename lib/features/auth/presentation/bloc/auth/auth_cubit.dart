import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:epresensi_mobile/core/utils/device_utils.dart';
import '../../../data/datasources/auth_local_data_source.dart';
import '../../../domain/entities/user_entity.dart';
import '../../../domain/repositories/auth_repository.dart';

abstract class AuthState extends Equatable {
  const AuthState();
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserEntity user;
  const AuthAuthenticated(this.user);
  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthCubit extends Cubit<AuthState> {
  final AuthLocalDataSource localDataSource;
  final AuthRepository? authRepository;

  AuthCubit({
    required this.localDataSource,
    this.authRepository,
  }) : super(AuthInitial());

  Future<void> checkAuthStatus() async {
    try {
      final user = await localDataSource.getLastUser();
      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (_) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> loggedIn(UserEntity user) async {
    emit(AuthAuthenticated(user));
  }

  Future<void> logout() async {
    await localDataSource.clearUser();
    emit(AuthUnauthenticated());
  }

  /// Memeriksa apakah username & password tersimpan di local storage (Hive & SharedPreferences).
  Future<bool> hasCredentials() async {
    try {
      final hiveCredentials = await localDataSource.getCredentials();
      String? username = hiveCredentials?['username'];
      String? password = hiveCredentials?['password'];

      if (username == null || username.isEmpty || password == null || password.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        username = prefs.getString('username');
        password = prefs.getString('password');
      }

      return username != null &&
          username.isNotEmpty &&
          password != null &&
          password.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  /// Memeriksa username & password yang tersimpan di local storage (Hive & SharedPreferences).
  /// Jika ada, melakukan login ulang, meng-update data di Hive & local storage,
  /// dan mengembalikan token terbaru. Jika tidak ada atau gagal, mengembalikan null.
  Future<String?> reloginAndGetToken() async {
    try {
      final hiveCredentials = await localDataSource.getCredentials();
      String? username = hiveCredentials?['username'];
      String? password = hiveCredentials?['password'];

      if (username == null || username.isEmpty || password == null || password.isEmpty) {
        final prefs = await SharedPreferences.getInstance();
        username = prefs.getString('username');
        password = prefs.getString('password');
      }

      if (username != null &&
          username.isNotEmpty &&
          password != null &&
          password.isNotEmpty) {
        String deviceId = '';
        try {
          final deviceInfo = await DeviceUtils.getDeviceInfo();
          deviceId = deviceInfo['kode_unik'] ?? '';
        } catch (_) {}

        if (authRepository != null) {
          final userEntity = await authRepository!.login(
            username: username,
            password: password,
            deviceId: deviceId,
          );

          await localDataSource.saveCredentials(username, password);

          try {
            final prefs = await SharedPreferences.getInstance();
            await prefs.setString('username', username);
            await prefs.setString('password', password);
          } catch (_) {}

          emit(AuthAuthenticated(userEntity));
          return userEntity.token;
        }
      }
    } catch (e) {
      debugPrint('Relogin failed: $e');
    }

    return null;
  }
}
