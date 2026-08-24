import 'package:equatable/equatable.dart';

import 'coordinate.dart';
import 'employee_detail.dart';
import 'login_result.dart';

class UserEntity extends Equatable {
  final EmployeeDetail detailPegawai;
  final int kode;
  final List<Coordinate> daftarKordinat;
  final LoginResult result;
  final String kodeUnik;
  final int wfaStatus;
  final String? token;
  final List<dynamic>? faceRecognition;
  final Map<String, dynamic>? rawJson;

  const UserEntity({
    required this.detailPegawai,
    required this.kode,
    required this.daftarKordinat,
    required this.result,
    required this.kodeUnik,
    required this.wfaStatus,
    this.token,
    this.faceRecognition,
    this.rawJson,
  });

  @override
  List<Object?> get props => [
        detailPegawai,
        kode,
        daftarKordinat,
        result,
        kodeUnik,
        wfaStatus,
        token,
        faceRecognition,
        rawJson,
      ];
}
