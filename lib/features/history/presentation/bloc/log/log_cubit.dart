import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/usecases/get_attendance_logs.dart';
import 'log_state.dart';

class LogCubit extends Cubit<LogState> {
  final GetAttendanceLogs getAttendanceLogs;

  LogCubit({required this.getAttendanceLogs}) : super(LogInitial());

  Future<void> loadLogs({
    required String nip,
    required int month,
    required int year,
    String? token,
    int type = 1,
  }) async {
    emit(LogLoading());

    final result = await getAttendanceLogs(
      nip: nip,
      month: month,
      year: year,
      token: token,
      type: type,
    );

    result.fold((failure) {
      if (failure is ServerFailure) {
        emit(LogError(failure.message));
      } else {
        emit(LogError(failure.toString()));
      }
    }, (data) => emit(LogLoaded(logs: data, month: month, year: year)));
  }
}
