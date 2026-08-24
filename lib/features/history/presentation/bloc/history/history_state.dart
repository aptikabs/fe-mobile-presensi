import 'package:equatable/equatable.dart';
import '../../../domain/entities/presence_log.dart';

abstract class HistoryState extends Equatable {
  const HistoryState();

  @override
  List<Object> get props => [];
}

class HistoryInitial extends HistoryState {}

class HistoryLoading extends HistoryState {}

class HistoryLoaded extends HistoryState {
  final List<PresenceLog> history;
  final String startDate;
  final String endDate;

  const HistoryLoaded({
    required this.history,
    required this.startDate,
    required this.endDate,
  });

  @override
  List<Object> get props => [history, startDate, endDate];
}

class HistoryError extends HistoryState {
  final String message;

  const HistoryError(this.message);

  @override
  List<Object> get props => [message];
}
