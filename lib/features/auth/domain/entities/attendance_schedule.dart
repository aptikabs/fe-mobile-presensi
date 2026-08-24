import 'package:equatable/equatable.dart';

class AttendanceSchedule extends Equatable {
  final int id;
  final String tipe;
  final String masukJam;
  final String masukBatas;
  final String pulangJam;
  final String pulangBatas;

  const AttendanceSchedule({
    required this.id,
    required this.tipe,
    required this.masukJam,
    required this.masukBatas,
    required this.pulangJam,
    required this.pulangBatas,
  });

  @override
  List<Object?> get props => [
    id,
    tipe,
    masukJam,
    masukBatas,
    pulangJam,
    pulangBatas,
  ];
}
