import 'package:dartz/dartz.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../data/datasources/attendance_remote_datasource.dart';
import '../../domain/repositories/attendance_repository.dart';

class AttendanceRepositoryImpl implements AttendanceRepository {
  final AttendanceRemoteDataSource remoteDataSource;
  final NetworkInfo networkInfo;

  AttendanceRepositoryImpl({
    required this.remoteDataSource,
    required this.networkInfo,
  });

  @override
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
    required String radius,
    required String merek,
    required String model,
    required String imagePath,
    required Map<String, dynamic> gpsSnapshot,
    required String faceRecognition,
    required String token,
  }) async {
    if (!await networkInfo.isConnected) {
      return const Left(
        NetworkFailure(
          'Tidak ada koneksi internet. Periksa jaringan Anda dan coba lagi.',
        ),
      );
    }

    try {
      final result = await remoteDataSource.submitAttendance(
        nip: nip,
        unorId: unorId,
        kodeUnik: kodeUnik,
        idMesin: idMesin,
        tipeAbsen: tipeAbsen,
        latitude: latitude,
        longitude: longitude,
        accuracy: accuracy,
        provider: provider,
        timestampDevice: timestampDevice,
        isMockLocation: isMockLocation,
        jarak: jarak,
        radius: radius,
        merek: merek,
        model: model,
        imagePath: imagePath,
        gpsSnapshot: gpsSnapshot,
        faceRecognition: faceRecognition,
        token: token,
      );

      final int kode = result['kode'] is int
          ? result['kode']
          : (int.tryParse(result['kode']?.toString() ?? '') ?? 1);

      if (kode == 0) {
        return const Right('Absensi Berhasil');
      } else if (kode == -1) {
        final String msg =
            result['error']?.toString() ??
            result['message']?.toString() ??
            'Wajah tidak sesuai database. Silakan coba lagi.';
        return Left(ServerFailure(msg));
      } else {
        final String msg =
            result['error']?.toString() ??
            result['message']?.toString() ??
            'Gagal melakukan absensi (Kode $kode)';
        return Left(ServerFailure(msg));
      }
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message, type: e.type));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message));
    } catch (e) {
      final rawMsg = e.toString().replaceFirst('Exception: ', '').trim();
      final msg = rawMsg.isNotEmpty
          ? rawMsg
          : 'Terjadi kesalahan saat melakukan absensi.';
      return Left(ServerFailure(msg));
    }
  }
}
