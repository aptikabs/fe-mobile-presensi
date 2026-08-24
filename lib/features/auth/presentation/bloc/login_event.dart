import 'package:equatable/equatable.dart';

abstract class LoginEvent extends Equatable {
  const LoginEvent();

  @override
  List<Object> get props => [];
}

class LoginStarted extends LoginEvent {}

class LoginSubmitted extends LoginEvent {
  final String username;
  final String password;
  final String deviceId;

  const LoginSubmitted({
    required this.username,
    required this.password,
    required this.deviceId,
  });

  @override
  List<Object> get props => [username, password, deviceId];
}

class LoginChangeDeviceSubmitted extends LoginEvent {
  final String nip;
  final String deviceId;
  final String merek;
  final String model;
  final String fingerprint;

  const LoginChangeDeviceSubmitted({
    required this.nip,
    required this.deviceId,
    required this.merek,
    required this.model,
    required this.fingerprint,
  });

  @override
  List<Object> get props => [nip, deviceId, merek, model, fingerprint];
}

class LoginPasswordVisibilityChanged extends LoginEvent {
  final bool isVisible;
  const LoginPasswordVisibilityChanged(this.isVisible);

  @override
  List<Object> get props => [isVisible];
}

class LoginRememberMeChanged extends LoginEvent {
  final bool rememberMe;
  const LoginRememberMeChanged(this.rememberMe);

  @override
  List<Object> get props => [rememberMe];
}

class LoginSecurityCheckSkipped extends LoginEvent {}
