import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import '../../../../core/error/failures.dart';
import '../repositories/attendance_repository.dart';

class SubmitAttendance {
  final AttendanceRepository repository;

  SubmitAttendance(this.repository);

  Future<Either<Failure, String>> call(SubmitAttendanceParams params) async {
    return await repository.submitAttendance(
      nip: params.nip,
      unorId: params.unorId,
      kodeUnik: params.kodeUnik,
      idMesin: params.idMesin,
      tipeAbsen: params.tipeAbsen,
      latitude: params.latitude,
      longitude: params.longitude,
      accuracy: params.accuracy,
      provider: params.provider,
      timestampDevice: params.timestampDevice,
      isMockLocation: params.isMockLocation,
      jarak: params.jarak,
      radius: params.radius,
      merek: params.merek,
      model: params.model,
      imagePath: params.imagePath,
      gpsSnapshot: params.gpsSnapshot,
      faceRecognition: params.faceRecognition,
      token: params.token,
    );
  }
}

class SubmitAttendanceParams extends Equatable {
  final String nip;
  final String unorId;
  final String kodeUnik;
  final String idMesin;
  final String tipeAbsen;
  final String latitude;
  final String longitude;
  final String accuracy;
  final String provider;
  final String timestampDevice;
  final String isMockLocation;
  final String jarak;
  final String radius;
  final String merek;
  final String model;
  final String imagePath;
  final Map<String, dynamic> gpsSnapshot;
  final String faceRecognition;
  final String token;

  const SubmitAttendanceParams({
    required this.nip,
    required this.unorId,
    required this.kodeUnik,
    required this.idMesin,
    required this.tipeAbsen,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required String? provider,
    required this.timestampDevice,
    required this.isMockLocation,
    required this.jarak,
    required this.radius,
    required this.merek,
    required this.model,
    required this.imagePath,
    required this.gpsSnapshot,
    required this.faceRecognition,
    required this.token,
  }) : provider = provider ?? 'fused';

  @override
  List<Object> get props => [
    nip,
    unorId,
    kodeUnik,
    idMesin,
    tipeAbsen,
    latitude,
    longitude,
    accuracy,
    provider,
    timestampDevice,
    isMockLocation,
    jarak,
    radius,
    merek,
    model,
    imagePath,
    gpsSnapshot,
    faceRecognition,
    token,
  ];
}
