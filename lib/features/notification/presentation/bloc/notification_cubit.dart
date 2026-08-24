import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import '../../../../../core/services/notification_service.dart';
import '../../domain/usecases/get_notification_config_usecase.dart';

abstract class NotificationState {}

class NotificationInitial extends NotificationState {}

class NotificationLoading extends NotificationState {}

class NotificationSuccess extends NotificationState {}

class NotificationFailure extends NotificationState {}

class NotificationCubit extends Cubit<NotificationState> {
  final GetNotificationConfigsUseCase getNotificationConfigs;
  final NotificationService notificationService;
  final Box settingsBox;

  NotificationCubit({
    required this.getNotificationConfigs,
    required this.notificationService,
    required this.settingsBox,
  }) : super(NotificationInitial()) {
    _loadSettings();
  }

  bool _isNotificationEnabled = true;
  bool get isNotificationEnabled => _isNotificationEnabled;

  void _loadSettings() {
    _isNotificationEnabled = settingsBox.get(
      'is_notification_enabled',
      defaultValue: true,
    );
  }

  Future<void> toggleNotification(bool isEnabled) async {
    _isNotificationEnabled = isEnabled;
    await settingsBox.put('is_notification_enabled', isEnabled);
    if (isEnabled) {
      scheduleNotifications();
    } else {
      await notificationService.cancelAll();
      emit(NotificationSuccess()); // Re-emit to update UI if needed
    }
  }

  Future<void> scheduleNotifications() async {
    if (!_isNotificationEnabled) return;

    try {
      emit(NotificationLoading());

      final result = await getNotificationConfigs();

      result.fold(
        (failure) {
          emit(NotificationFailure());
        },
        (configs) async {
          try {
            debugPrint("Fetched ${configs.length} notification configs");
            await notificationService.cancelAll();

            for (final config in configs) {
              final schedule = config.schedule;

              if (schedule.type == 'daily') {
                await notificationService.scheduleNotification(
                  id: config.id,
                  title: config.title,
                  body: config.body,
                  hour: schedule.hour,
                  minute: schedule.minute,
                  repeats: true,
                  timezone: config.timezone,
                );
              } else if (schedule.type == 'weekly' && schedule.days != null) {
                for (final dayStr in schedule.days!) {
                  final day = int.tryParse(dayStr);
                  if (day != null) {
                    final uniqueId = config.id * 100 + day;

                    await notificationService.scheduleNotification(
                      id: uniqueId,
                      title: config.title,
                      body: config.body,
                      hour: schedule.hour,
                      minute: schedule.minute,
                      repeats: true,
                      timezone: config.timezone,
                      weekday: day,
                    );
                  }
                }
              }
            }
            emit(NotificationSuccess());
            debugPrint(
              "All notifications processed and emitted NotificationSuccess",
            );
          } catch (e) {
            debugPrint("Error during notification scheduling loop: $e");
            // Still emit success to avoid blocking the UI flow
            emit(NotificationSuccess());
          }
        },
      );
    } catch (e) {
      debugPrint("Error in scheduleNotifications: $e");
      emit(NotificationFailure());
    }
  }
}
