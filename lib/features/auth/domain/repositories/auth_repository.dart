import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> login({
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
  });

  Future<void> checkUserBlock(String nip);
}
