import 'package:equatable/equatable.dart';

enum PageStatus { idle, busy, done }

class ChangeDeviceState extends Equatable {
  final PageStatus status;
  final String nip;
  final String username;
  final String? error;
  final bool obscureText;

  const ChangeDeviceState({
    this.status = PageStatus.idle,
    required this.nip,
    required this.username,
    this.error,
    this.obscureText = true,
  });

  ChangeDeviceState copyWith({
    PageStatus? status,
    String? nip,
    String? username,
    String? error,
    bool? obscureText,
  }) {
    return ChangeDeviceState(
      status: status ?? this.status,
      nip: nip ?? this.nip,
      username: username ?? this.username,
      error: error ?? this.error,
      obscureText: obscureText ?? this.obscureText,
    );
  }

  @override
  List<Object?> get props => [status, nip, username, error, obscureText];
}
