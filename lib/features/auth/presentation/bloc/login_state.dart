import 'package:equatable/equatable.dart';
import '../../../../core/error/auth_exceptions.dart';
import '../../../../core/services/security_service.dart';
import '../../domain/entities/user_entity.dart';

enum LoginStatus { initial, loading, success, failure, securityFailure }

class LoginState extends Equatable {
  final LoginStatus status;
  final String username;
  final String password;
  final bool isPasswordVisible;
  final bool rememberMe;
  final UserEntity? response;
  final String? errorMessage;
  final AuthException? error;
  final bool changeDeviceSuccess;
  final List<SecurityThreat> securityThreats;
  final bool isNetworkError;

  const LoginState({
    this.status = LoginStatus.initial,
    this.username = '',
    this.password = '',
    this.isPasswordVisible = false,
    this.rememberMe = false,
    this.response,
    this.errorMessage,
    this.error,
    this.changeDeviceSuccess = false,
    this.securityThreats = const [],
    this.isNetworkError = false,
  });

  LoginState copyWith({
    LoginStatus? status,
    String? username,
    String? password,
    bool? isPasswordVisible,
    bool? rememberMe,
    UserEntity? response,
    String? errorMessage,
    AuthException? error,
    bool? changeDeviceSuccess,
    List<SecurityThreat>? securityThreats,
    bool? isNetworkError,
  }) {
    return LoginState(
      status: status ?? this.status,
      username: username ?? this.username,
      password: password ?? this.password,
      isPasswordVisible: isPasswordVisible ?? this.isPasswordVisible,
      rememberMe: rememberMe ?? this.rememberMe,
      response: response ?? this.response,
      errorMessage: errorMessage ?? this.errorMessage,
      error: error ?? this.error,
      changeDeviceSuccess: changeDeviceSuccess ?? false,
      securityThreats: securityThreats ?? this.securityThreats,
      isNetworkError: isNetworkError ?? false,
    );
  }

  @override
  List<Object?> get props => [
    status,
    username,
    password,
    isPasswordVisible,
    rememberMe,
    response,
    errorMessage,
    error,
    changeDeviceSuccess,
    securityThreats,
    isNetworkError,
  ];
}
