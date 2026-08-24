import '../repositories/auth_repository.dart';

class RegisterDeviceUseCase {
  final AuthRepository repository;

  RegisterDeviceUseCase(this.repository);

  Future<void> call({
    required String nip,
    required String deviceId,
    required String merek,
    required String model,
    required String fingerprint,
    required String imagePath,
  }) async {
    return await repository.registerDevice(
      nip: nip,
      deviceId: deviceId,
      merek: merek,
      model: model,
      fingerprint: fingerprint,
      imagePath: imagePath,
    );
  }
}
