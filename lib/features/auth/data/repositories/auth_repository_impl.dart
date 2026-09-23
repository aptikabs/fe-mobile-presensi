import 'dart:convert';

import '../../../../core/error/exceptions.dart';
import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';
import '../datasources/auth_local_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;
  final AuthLocalDataSource localDataSource;
  final NetworkInfo networkInfo;
  final SecureStorageService? secureStorageService;

  AuthRepositoryImpl({
    required this.remoteDataSource,
    required this.localDataSource,
    required this.networkInfo,
    this.secureStorageService,
  });

  @override
  Future<UserEntity> login({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NetworkException(type: NetworkErrorType.noConnection);
    }

    final userModel = await remoteDataSource.login(
      username: username,
      password: password,
      deviceId: deviceId,
    );
    final embedding = userModel.faceRecognition;
    if (embedding != null && embedding.isNotEmpty) {
      await secureStorageService?.saveFaceEmbedding(jsonEncode(embedding));
    } else {
      await secureStorageService?.deleteFaceEmbedding();
    }
    await localDataSource.cacheUser(userModel);
    await localDataSource.saveCredentials(username, password);
    return userModel;
  }

  @override
  Future<void> changeDevice({
    required String nip,
    required String deviceId,
    required String merek,
    required String model,
    required String fingerprint,
  }) async {
    if (!await networkInfo.isConnected) {
      throw NetworkException(type: NetworkErrorType.noConnection);
    }

    await remoteDataSource.changeDevice(
      nip: nip,
      deviceId: deviceId,
      merek: merek,
      model: model,
      fingerprint: fingerprint,
    );
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
    if (!await networkInfo.isConnected) {
      throw NetworkException(type: NetworkErrorType.noConnection);
    }

    await remoteDataSource.registerDevice(
      nip: nip,
      deviceId: deviceId,
      merek: merek,
      model: model,
      fingerprint: fingerprint,
      imagePath: imagePath,
      faceEmbedding: faceEmbedding,
    );
  }

  @override
  Future<void> checkUserBlock(String nip) async {
    // checkUserBlock is fail-open (doesn't block on network errors)
    // so no pre-flight check needed here
    await remoteDataSource.checkUserBlock(nip);
  }
}
