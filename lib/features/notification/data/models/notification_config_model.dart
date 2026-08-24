import 'package:equatable/equatable.dart';

class NotificationScheduleModel extends Equatable {
  final int hour;
  final int minute;
  final String type;
  final List<String>? days;

  const NotificationScheduleModel({
    required this.hour,
    required this.minute,
    required this.type,
    this.days,
  });

  factory NotificationScheduleModel.fromJson(Map<String, dynamic> json) {
    return NotificationScheduleModel(
      hour: json['hour'] ?? 0,
      minute: json['minute'] ?? 0,
      type: json['type'] ?? 'daily',
      days: json['days'] != null ? List<String>.from(json['days']) : null,
    );
  }

  @override
  List<Object?> get props => [hour, minute, type, days];
}

class NotificationConfigModel extends Equatable {
  final int id;
  final String title;
  final String body;
  final String timezone;
  final NotificationScheduleModel schedule;

  const NotificationConfigModel({
    required this.id,
    required this.title,
    required this.body,
    required this.timezone,
    required this.schedule,
  });

  factory NotificationConfigModel.fromJson(Map<String, dynamic> json) {
    return NotificationConfigModel(
      id: json['id'] ?? 0,
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      timezone: json['timezone'] ?? '',
      schedule: NotificationScheduleModel.fromJson(json['schedule'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [id, title, body, timezone, schedule];
}
