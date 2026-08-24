import 'package:equatable/equatable.dart';

class AttendanceLog extends Equatable {
  final String userId;
  final String date;
  final String timeString; // "10:54:19 | 14:54:33"
  final String count;

  const AttendanceLog({
    required this.userId,
    required this.date,
    required this.timeString,
    required this.count,
  });

  List<String> get times => timeString.split(' | ');

  @override
  List<Object?> get props => [userId, date, timeString, count];
}
