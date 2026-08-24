import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';

abstract class AttendanceRepository {
  Future<Either<Failure, String>> submitAttendance({
    required String nip,
    required String unorId,
    required String kodeUnik,
    required String idMesin,
    required String tipeAbsen,
    required String latitude,
    required String longitude,
    required String accuracy,
    required String provider,
    required String timestampDevice,
    required String isMockLocation,
    required String jarak,
    required String merek,
    required String model,
    required String imagePath,
    required Map<String, dynamic> gpsSnapshot,
    required String faceRecognition,
    required String token,
  });
}
