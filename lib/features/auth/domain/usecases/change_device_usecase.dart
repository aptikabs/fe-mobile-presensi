import '../repositories/auth_repository.dart';

class ChangeDeviceUseCase {
  final AuthRepository repository;

  ChangeDeviceUseCase(this.repository);

  Future<void> call({
    required String nip,
    required String deviceId,
    required String merek,
    required String model,
    required String fingerprint,
  }) async {
    return await repository.changeDevice(
      nip: nip,
      deviceId: deviceId,
      merek: merek,
      model: model,
      fingerprint: fingerprint,
    );
  }
}
