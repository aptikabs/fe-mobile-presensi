import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../../../../../core/error/failures.dart';
import '../../../domain/usecases/get_history.dart';
import 'history_state.dart';

class HistoryCubit extends Cubit<HistoryState> {
  final GetHistory getHistory;

  HistoryCubit({required this.getHistory}) : super(HistoryInitial());

  Future<void> loadHistory({
    required String nip,
    String? startDate,
    String? endDate,
    String? token,
  }) async {
    emit(HistoryLoading());

    final now = DateTime.now();
    final format = DateFormat('yyyy-MM-dd');

    // Default: Start of current month to Today
    final start = startDate ?? format.format(DateTime(now.year, now.month, 1));
    final end = endDate ?? format.format(now);

    final result = await getHistory(
      nip: nip,
      startDate: start,
      endDate: end,
      token: token,
    );

    result.fold(
      (failure) {
        if (failure is ServerFailure) {
          emit(HistoryError(failure.message));
        } else {
          emit(HistoryError(failure.toString()));
        }
      },
      (data) =>
          emit(HistoryLoaded(history: data, startDate: start, endDate: end)),
    );
  }
}
