import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  LoginUseCase(this.repository);

  Future<UserEntity> call({
    required String username,
    required String password,
    required String deviceId,
  }) async {
    return await repository.login(
      username: username,
      password: password,
      deviceId: deviceId,
    );
  }

  Future<void> checkUserBlock(String nip) async {
    await repository.checkUserBlock(nip);
  }
}
