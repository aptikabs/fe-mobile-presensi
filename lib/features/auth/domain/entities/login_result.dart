import 'package:equatable/equatable.dart';
import 'attendance_schedule.dart';

class LoginResult extends Equatable {
  final String nama;
  final String username;
  final String nip;
  final String unorId;
  final int idMesin;
  final String tipeAbsensi;
  final AttendanceSchedule? jadwalAbsen;

  const LoginResult({
    required this.nama,
    required this.username,
    required this.nip,
    required this.unorId,
    required this.idMesin,
    required this.tipeAbsensi,
    this.jadwalAbsen,
  });

  @override
  List<Object?> get props => [
    nama,
    username,
    nip,
    unorId,
    idMesin,
    tipeAbsensi,
    jadwalAbsen,
  ];
}
