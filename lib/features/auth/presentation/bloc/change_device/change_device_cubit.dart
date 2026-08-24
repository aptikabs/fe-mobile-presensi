import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../core/utils/device_utils.dart';
import '../../../../../../core/error/auth_exceptions.dart';
import '../../../domain/usecases/change_device_usecase.dart';
import '../../../domain/usecases/login_usecase.dart';
import 'change_device_state.dart';

class ChangeDeviceCubit extends Cubit<ChangeDeviceState> {
  final ChangeDeviceUseCase changeDeviceUseCase;
  final LoginUseCase loginUseCase;

  ChangeDeviceCubit({
    required this.changeDeviceUseCase,
    required this.loginUseCase,
    required String nip,
    required String username,
  }) : super(ChangeDeviceState(nip: nip, username: username));

  void toggleObscurePassword() {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(obscureText: !state.obscureText));
  }

  Future<void> submit(String password) async {
    if (isClosed) {
      return;
    }

    if (password.isEmpty) {
      emit(state.copyWith(error: 'Isi kata sandi'));
      return;
    }

    emit(state.copyWith(status: PageStatus.busy, error: null));

    try {
      final deviceInfo = await DeviceUtils.getDeviceInfo();
      final deviceId = deviceInfo['kode_unik'] ?? '';

      // 1. Validate Password using LoginUseCase
      try {
        await loginUseCase(
          username: state.username,
          password: password,
          deviceId: deviceId,
        );
      } on DeviceMismatchException {
        // Code 1: Password correct, but device mismatch. This is expected.
        // Proceed to change device.
      } on ChangeDeviceNotAllowedException {
        //Should not happen on login, but if it does, it's an error
        if (!isClosed) {
          emit(
            state.copyWith(
              status: PageStatus.done,
              error:
                  'Tidak dapat validasi: Change Device Not Allowed during login check',
            ),
          );
        }
        return;
      } on UserNotRegisteredException {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: PageStatus.done,
              error: 'NIP tidak terdaftar',
            ),
          );
        }
        return;
      } on ContactAdminException {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: PageStatus.done,
              error: 'Akun diblokir, hubungi admin',
            ),
          );
        }
        return;
      } on AuthException catch (e) {
        // Generic AuthException usually means Login Failed (wrong password)
        if (!isClosed) {
          emit(
            state.copyWith(
              status: PageStatus.done,
              error: 'Kata sandi salah atau login gagal: ${e.message}',
            ),
          );
        }
        return;
      } catch (e) {
        if (!isClosed) {
          emit(
            state.copyWith(
              status: PageStatus.done,
              error: 'Gagal validasi login: $e',
            ),
          );
        }
        return;
      }

      // 2. Change Device
      await changeDeviceUseCase(
        nip: state.nip,
        deviceId: deviceId,
        merek: deviceInfo['merek'] ?? '',
        model: deviceInfo['model'] ?? '',
        fingerprint: deviceInfo['fingerprint'] ?? '',
      );

      if (isClosed) {
        return;
      }
      emit(state.copyWith(status: PageStatus.done, error: null));
    } on ChangeDeviceNotAllowedException catch (e) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: PageStatus.done,
          error: 'Tanggal diijinkan mengubah perangkat ${e.dateAllowed}',
        ),
      );
    } on ChangeDeviceFailedException catch (e) {
      if (isClosed) {
        return;
      }
      emit(state.copyWith(status: PageStatus.done, error: e.message));
    } catch (e) {
      if (isClosed) {
        return;
      }
      emit(
        state.copyWith(
          status: PageStatus.done,
          error: e.toString().replaceAll('Exception: ', ''),
        ),
      );
    }
  }
}
