import '../../domain/entities/attendance_log.dart';

class AttendanceLogModel extends AttendanceLog {
  const AttendanceLogModel({
    required super.userId,
    required super.date,
    required super.timeString,
    required super.count,
  });

  factory AttendanceLogModel.fromJson(Map<String, dynamic> json) {
    return AttendanceLogModel(
      userId: json['log_data_user_id']?.toString() ?? '',
      date: json['log_data_tanggal']?.toString() ?? '',
      timeString: json['log_data_jam']?.toString() ?? '',
      count: json['log_data_jumlah']?.toString() ?? '',
    );
  }
}
