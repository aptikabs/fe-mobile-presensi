import 'package:equatable/equatable.dart';
import 'exceptions.dart';

abstract class Failure extends Equatable {
  const Failure([List properties = const <dynamic>[]]);
}

class ServerFailure extends Failure {
  final String message;

  const ServerFailure(this.message);

  @override
  List<Object> get props => [message];
}

class NetworkFailure extends Failure {
  final String message;
  final NetworkErrorType type;

  const NetworkFailure(
    this.message, {
    this.type = NetworkErrorType.noConnection,
  });

  @override
  List<Object> get props => [message, type];
}
