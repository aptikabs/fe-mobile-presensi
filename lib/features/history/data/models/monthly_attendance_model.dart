import '../../domain/entities/monthly_attendance.dart';

class MonthlyAttendanceModel extends MonthlyAttendance {
  const MonthlyAttendanceModel({
    required super.absensiNip,
    required super.absensiChecktime,
    super.absensiMasuk,
    super.absensiTerlambat,
    super.absensiSelisihTerlambat,
    super.absensiIstirahat,
    super.absensiTelatSiang,
    super.absensiSelisihTelatSiang,
    super.absensiPulangCepat,
    super.absensiSelisihPulangCepat,
    super.absensiPulang,
    required super.absensiStatus,
    super.keteranganSubJenis,
    super.refJenisKeterangan,
  });

  factory MonthlyAttendanceModel.fromJson(Map<String, dynamic> json) {
    return MonthlyAttendanceModel(
      absensiNip: json['absensi_nip'] ?? '',
      absensiChecktime: json['absensi_checktime'] ?? '',
      absensiMasuk: json['absensi_masuk'],
      absensiTerlambat: json['absensi_terlambat'],
      absensiSelisihTerlambat: json['absensi_selisih_terlambat'],
      absensiIstirahat: json['absensi_istirahat'],
      absensiTelatSiang: json['absensi_telat_siang'],
      absensiSelisihTelatSiang: json['absensi_selisih_telat_siang'],
      absensiPulangCepat: json['absensi_pulang_cepat'],
      absensiSelisihPulangCepat: json['absensi_selisih_pulang_cepat'],
      absensiPulang: json['absensi_pulang'],
      absensiStatus: json['absensi_status'] ?? '0',
      keteranganSubJenis: json['keterangan_sub_jenis'],
      refJenisKeterangan: json['ref_jenis_keterangan'],
    );
  }
}
