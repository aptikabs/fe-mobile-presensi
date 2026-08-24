import 'package:dartz/dartz.dart';
import '../../../../../core/error/exceptions.dart';
import '../../../../../core/error/failures.dart';
import '../../domain/entities/presence_log.dart';
import '../../domain/entities/attendance_log.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_remote_data_source.dart';
import '../../../../../core/network/network_info.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  HistoryRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
  Future<Either<Failure, List<PresenceLog>>> getHistory(
    String nip,
    String startDate,
    String endDate, {
    String? token,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(
        'Tidak ada koneksi internet. Periksa jaringan Anda dan coba lagi.',
      ));
    }

    try {
      final result = await remoteDataSource.getHistory(
        nip,
        startDate,
        endDate,
        token: token,
      );
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, type: e.type));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      final rawMsg = e.toString().replaceFirst('Exception: ', '').trim();
      final msg = rawMsg.isNotEmpty
          ? rawMsg
          : 'Terjadi kesalahan saat memuat riwayat presensi.';
      return Left(ServerFailure(msg));
    }
  }

  @override
  Future<Either<Failure, List<AttendanceLog>>> getAttendanceLogs(
    String nip,
    int month,
    int year, {
    String? token,
    int type = 1,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(NetworkFailure(
        'Tidak ada koneksi internet. Periksa jaringan Anda dan coba lagi.',
      ));
    }

    try {
      final result = await remoteDataSource.getAttendanceLogs(
        nip,
        month,
        year,
        token: token,
        type: type,
      );
      return Right(result);
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, type: e.type));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      final rawMsg = e.toString().replaceFirst('Exception: ', '').trim();
      final msg = rawMsg.isNotEmpty
          ? rawMsg
          : 'Terjadi kesalahan saat memuat batas presensi.';
      return Left(ServerFailure(msg));
    }
  }
}
