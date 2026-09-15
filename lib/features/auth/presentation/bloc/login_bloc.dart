import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/error/auth_exceptions.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/utils/device_utils.dart';
import '../../../../core/services/security_service.dart';
import '../../domain/usecases/login_usecase.dart';
import 'login_event.dart';
import 'login_state.dart';

class LoginBloc extends Bloc<LoginEvent, LoginState> {
  final LoginUseCase loginUseCase;
  final SecurityService securityService;

  LoginBloc({required this.loginUseCase, required this.securityService})
    : super(const LoginState()) {
    on<LoginStarted>(_onStarted);
    on<LoginSubmitted>(_onSubmitted);
    on<LoginPasswordVisibilityChanged>(_onPasswordVisibilityChanged);
    on<LoginRememberMeChanged>(_onRememberMeChanged);
    on<LoginSecurityCheckSkipped>(_onSecurityCheckSkipped);
  }

  Future<void> _onSecurityCheckSkipped(
    LoginSecurityCheckSkipped event,
    Emitter<LoginState> emit,
  ) async {
    // If check already passed or wasn't needed, do nothing.
    // If coming from failure, we assume user skipped the warning.
    // Reset status to initial so user can interact with the form.
    emit(state.copyWith(status: LoginStatus.initial));
  }

  Future<void> _onStarted(LoginStarted event, Emitter<LoginState> emit) async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool('remember_me') ?? false;
    final username = rememberMe ? prefs.getString('username') ?? '' : '';
    final password = rememberMe ? prefs.getString('password') ?? '' : '';

    emit(
      state.copyWith(
        rememberMe: rememberMe,
        username: username,
        password: password,
      ),
    );

  }

  Future<void> _onSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    // Validation
    if (event.username.isEmpty || event.password.isEmpty) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          errorMessage: 'Username atau password tidak boleh kosong',
        ),
      );
      return;
    }

    emit(
      LoginState(
        status: LoginStatus.loading,
        username: event.username,
        password: event.password,
        isPasswordVisible: state.isPasswordVisible,
        rememberMe: state.rememberMe,
        response: null,
        errorMessage: null,
        error: null,
        changeDeviceSuccess: false,
        securityThreats: state.securityThreats,
        isNetworkError: false,
      ),
    );

    // If deviceId is not provided (e.g. re-login), fetch it.
    String deviceId = event.deviceId;
    if (deviceId.isEmpty) {
      try {
        final deviceInfo = await DeviceUtils.getDeviceInfo();
        deviceId = deviceInfo['kode_unik'] ?? '';
      } catch (e) {
        // Fallback or handle error?
      }
    }

    try {
      // 2. Cek Perangkat (Login)
      final response = await loginUseCase(
        username: event.username,
        password: event.password,
        deviceId: deviceId,
      );

      // Handle Credentials & Remember Me
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('username', event.username);
      await prefs.setString('password', event.password);
      if (state.rememberMe) {
        await prefs.setBool('remember_me', true);
      } else {
        await prefs.remove('remember_me');
      }

      // 3. Check User Block
      // Use NIP from login response to check block status
      final String nip = response.result.nip;
      await loginUseCase.checkUserBlock(nip);

      emit(state.copyWith(status: LoginStatus.success, response: response));
    } on NetworkException catch (e) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          error: AuthException(e.message),
          errorMessage: e.message,
          isNetworkError: true,
        ),
      );
    } on AuthException catch (e) {
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          error: e,
          errorMessage: e.message,
        ),
      );
    } catch (e) {
      final rawMsg = e.toString().replaceFirst('Exception: ', '').trim();
      final msg = rawMsg.isNotEmpty
          ? rawMsg
          : 'Username atau password tidak sesuai';
      emit(
        state.copyWith(
          status: LoginStatus.failure,
          error: AuthException(msg),
          errorMessage: msg,
        ),
      );
    }
  }

  void _onPasswordVisibilityChanged(
    LoginPasswordVisibilityChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(isPasswordVisible: event.isVisible));
  }

  void _onRememberMeChanged(
    LoginRememberMeChanged event,
    Emitter<LoginState> emit,
  ) {
    emit(state.copyWith(rememberMe: event.rememberMe));
  }
}
