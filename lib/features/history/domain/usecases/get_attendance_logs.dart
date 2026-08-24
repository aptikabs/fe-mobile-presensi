import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../../domain/repositories/history_repository.dart';
import '../entities/attendance_log.dart';

class GetAttendanceLogs {
  final HistoryRepository repository;

  GetAttendanceLogs(this.repository);

  Future<Either<Failure, List<AttendanceLog>>> call({
    required String nip,
    required int month,
    required int year,
    String? token,
    int type = 1,
  }) async {
    return await repository.getAttendanceLogs(
      nip,
      month,
      year,
      token: token,
      type: type,
    );
  }
}
