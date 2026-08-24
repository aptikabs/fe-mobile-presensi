import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../core/utils/device_utils.dart';
import '../../../domain/usecases/register_device_usecase.dart';
import 'register_device_state.dart';

enum FaceRecognitionMode { low, medium, high }

class RegisterDeviceCubit extends Cubit<RegisterDeviceState> {
  final RegisterDeviceUseCase registerDeviceUseCase;
  final String nip;

  RegisterDeviceCubit({required this.registerDeviceUseCase, required this.nip})
    : super(const RegisterDeviceState());

  Future<void> submit({
    required XFile image,
    required FaceRecognitionMode mode,
  }) async {
    if (isClosed) return;

    emit(state.copyWith(status: PageStatus.busy, error: null));

    try {
      final deviceInfo = await DeviceUtils.getDeviceInfo();

      await registerDeviceUseCase(
        nip: nip,
        deviceId: deviceInfo['kode_unik'] ?? '',
        merek: deviceInfo['merek'] ?? '',
        model: deviceInfo['model'] ?? '',
        fingerprint: deviceInfo['fingerprint'] ?? '',
        imagePath: image.path,
      );

      if (isClosed) return;

      // Code 0 (Success) assumed if no exception
      emit(
        state.copyWith(
          status: PageStatus.done,
          error: null,
          successMessage: 'Perangkat berhasil didaftarkan',
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: PageStatus.done,
          error: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }
}
