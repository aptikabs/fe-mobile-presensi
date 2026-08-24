import 'package:equatable/equatable.dart';
import '../../../domain/entities/attendance_log.dart';

abstract class LogState extends Equatable {
  const LogState();

  @override
  List<Object> get props => [];
}

class LogInitial extends LogState {}

class LogLoading extends LogState {}

class LogLoaded extends LogState {
  final List<AttendanceLog> logs;
  final int month;
  final int year;

  const LogLoaded({
    required this.logs,
    required this.month,
    required this.year,
  });

  @override
  List<Object> get props => [logs, month, year];
}

class LogError extends LogState {
  final String message;

  const LogError(this.message);

  @override
  List<Object> get props => [message];
}
