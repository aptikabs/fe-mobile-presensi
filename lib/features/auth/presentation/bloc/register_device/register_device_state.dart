import 'package:equatable/equatable.dart';

enum PageStatus { idle, busy, done }

class RegisterDeviceState extends Equatable {
  final PageStatus status;
  final String? error;
  final String? successMessage;

  const RegisterDeviceState({
    this.status = PageStatus.idle,
    this.error,
    this.successMessage,
  });

  RegisterDeviceState copyWith({
    PageStatus? status,
    String? error,
    String? successMessage,
  }) {
    return RegisterDeviceState(
      status: status ?? this.status,
      error: error,
      successMessage: successMessage,
    );
  }

  @override
  List<Object?> get props => [status, error, successMessage];
}
