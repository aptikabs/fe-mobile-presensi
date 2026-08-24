import 'package:equatable/equatable.dart';

class NotificationSchedule extends Equatable {
  final int hour;
  final int minute;
  final String type;
  final List<String>? days;

  const NotificationSchedule({
    required this.hour,
    required this.minute,
    required this.type,
    this.days,
  });

  @override
  List<Object?> get props => [hour, minute, type, days];
}

class NotificationConfig extends Equatable {
  final int id;
  final String title;
  final String body;
  final String timezone;
  final NotificationSchedule schedule;

  const NotificationConfig({
    required this.id,
    required this.title,
    required this.body,
    required this.timezone,
    required this.schedule,
  });

  @override
  List<Object?> get props => [id, title, body, timezone, schedule];
}
