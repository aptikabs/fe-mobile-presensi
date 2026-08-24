import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    as fln;
import 'package:flutter/material.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();

  factory NotificationService() {
    return _instance;
  }

  NotificationService._internal();

  final fln.FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      fln.FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    tz.initializeTimeZones();

    // Android initialization
    const fln.AndroidInitializationSettings initializationSettingsAndroid =
        fln.AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    final fln.DarwinInitializationSettings initializationSettingsDarwin =
        fln.DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
          defaultPresentAlert: true,
          defaultPresentBadge: true,
          defaultPresentSound: true,
        );

    final fln.InitializationSettings initializationSettings =
        fln.InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
    debugPrint("NotificationService initialized successfully");
  }

  Future<void> requestPermission() async {
    await flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);

    final androidPlugin = flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
          fln.AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();

    // Check and request exact alarm permission for Android 12+
    try {
      final bool? granted = await androidPlugin?.requestExactAlarmsPermission();
      debugPrint("Exact alarm permission granted: $granted");
    } catch (e) {
      debugPrint("Error requesting exact alarm permission: $e");
    }
  }

  fln.NotificationDetails _getNotificationDetails(String title, String body) {
    // Style Information for Big Text
    final fln.BigTextStyleInformation bigTextStyleInformation =
        fln.BigTextStyleInformation(
          body,
          htmlFormatBigText: true,
          contentTitle: title,
          htmlFormatContentTitle: true,
        );

    final fln.AndroidNotificationDetails androidPlatformChannelSpecifics =
        fln.AndroidNotificationDetails(
          'basic_channel',
          'Notifikasi E-Presensi',
          channelDescription: 'Channel notifikasi utama aplikasi E-Presensi',
          importance: fln.Importance.max,
          priority: fln.Priority.high,
          styleInformation: bigTextStyleInformation,
          color: const Color(0xFFD64045), // AppColors.primary500
          largeIcon: const fln.DrawableResourceAndroidBitmap(
            '@mipmap/ic_launcher',
          ),
        );

    const fln.DarwinNotificationDetails iOSPlatformChannelSpecifics =
        fln.DarwinNotificationDetails();

    return fln.NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );
  }

  Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required bool repeats,
    String? timezone,
    int? weekday, // 1 = Monday, 7 = Sunday
  }) async {
    try {
      // Get location based on timezone or default to Asia/Jakarta
      final locationName = timezone ?? 'Asia/Jakarta';
      final location = tz.getLocation(locationName);

      // Get current local time in the specified location
      final now = tz.TZDateTime.now(location);

      // Construct scheduled time
      tz.TZDateTime scheduledDate = tz.TZDateTime(
        location,
        now.year,
        now.month,
        now.day,
        hour,
        minute,
      );

      // If scheduled time is in past, add 1 day (for daily)
      if (scheduledDate.isBefore(now)) {
        scheduledDate = scheduledDate.add(const Duration(days: 1));
      }

      // Logic for weekly
      if (weekday != null) {
        // Find next occurrence of weekday
        while (scheduledDate.weekday != weekday) {
          scheduledDate = scheduledDate.add(const Duration(days: 1));
        }
      }

      await flutterLocalNotificationsPlugin.zonedSchedule(
        id,
        title,
        body,
        scheduledDate,
        _getNotificationDetails(title, body),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: weekday != null
            ? fln.DateTimeComponents.dayOfWeekAndTime
            : (repeats ? fln.DateTimeComponents.time : null),
      );
      debugPrint(
        "Notification scheduled successfully: id=$id, title=$title, time=$hour:$minute, timezone=$locationName, scheduledDate=$scheduledDate",
      );
    } catch (e) {
      debugPrint("Error scheduling notification: $e");
    }
  }

  Future<void> showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await flutterLocalNotificationsPlugin.show(
      id,
      title,
      body,
      _getNotificationDetails(title, body),
    );
  }

  Future<void> cancelAll() async {
    await flutterLocalNotificationsPlugin.cancelAll();
  }

  Future<void> testNotification() async {
    debugPrint("Triggering test notification (immediate)");
    await showNotification(
      id: 999,
      title: 'Tes Notifikasi (Immediate)',
      body: 'Jika Anda melihat ini, maka sistem notifikasi dasar berfungsi! 🥳',
    );
  }

  Future<void> scheduleTestNotification() async {
    debugPrint("Triggering schedule test (10 seconds from now)");
    final location = tz.getLocation('Asia/Jakarta');
    final now = tz.TZDateTime.now(location);
    final scheduledDate = now.add(const Duration(seconds: 10));

    try {
      await flutterLocalNotificationsPlugin.zonedSchedule(
        888,
        'Tes Jadwal (10 detik)',
        'Ini adalah notifikasi yang terjadwal. Jika muncul, berarti zonedSchedule berfungsi!',
        scheduledDate,
        _getNotificationDetails('Tes Jadwal', 'Isi'),
        androidScheduleMode: fln.AndroidScheduleMode.exactAllowWhileIdle,
      );
      debugPrint("Scheduled test notification for: $scheduledDate");
    } catch (e) {
      debugPrint("Error scheduling test notification: $e");
    }
  }
}
