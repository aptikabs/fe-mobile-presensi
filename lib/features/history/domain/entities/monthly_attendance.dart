import 'package:equatable/equatable.dart';

class MonthlyAttendance extends Equatable {
  final String absensiNip;
  final String absensiChecktime;
  final String? absensiMasuk;
  final String? absensiTerlambat;
  final String? absensiSelisihTerlambat;
  final String? absensiIstirahat;
  final String? absensiTelatSiang;
  final String? absensiSelisihTelatSiang;
  final String? absensiPulangCepat;
  final String? absensiSelisihPulangCepat;
  final String? absensiPulang;
  final String absensiStatus;
  final String? keteranganSubJenis;
  final String? refJenisKeterangan;

  const MonthlyAttendance({
    required this.absensiNip,
    required this.absensiChecktime,
    this.absensiMasuk,
    this.absensiTerlambat,
    this.absensiSelisihTerlambat,
    this.absensiIstirahat,
    this.absensiTelatSiang,
    this.absensiSelisihTelatSiang,
    this.absensiPulangCepat,
    this.absensiSelisihPulangCepat,
    this.absensiPulang,
    required this.absensiStatus,
    this.keteranganSubJenis,
    this.refJenisKeterangan,
  });

  @override
  List<Object?> get props => [
    absensiNip,
    absensiChecktime,
    absensiMasuk,
    absensiTerlambat,
    absensiSelisihTerlambat,
    absensiIstirahat,
    absensiTelatSiang,
    absensiSelisihTelatSiang,
    absensiPulangCepat,
    absensiSelisihPulangCepat,
    absensiPulang,
    absensiStatus,
    keteranganSubJenis,
    refJenisKeterangan,
  ];
}
