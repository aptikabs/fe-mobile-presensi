import 'package:dartz/dartz.dart';
import '../../../../../core/error/failures.dart';
import '../entities/presence_log.dart';
import '../entities/attendance_log.dart';

abstract class HistoryRepository {
  Future<Either<Failure, List<PresenceLog>>> getHistory(
    String nip,
    String startDate,
    String endDate, {
    String? token,
  });

  Future<Either<Failure, List<AttendanceLog>>> getAttendanceLogs(
    String nip,
    int month,
    int year, {
    String? token,
    int type = 1,
  });
}
