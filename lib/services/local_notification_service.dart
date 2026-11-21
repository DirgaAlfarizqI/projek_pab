import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_models.dart';

class LocalNotificationService {
  static final LocalNotificationService _instance =
      LocalNotificationService._internal();
  factory LocalNotificationService() => _instance;
  LocalNotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _isInitialized = false;

  bool get _isSupportedMobile =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;

  Future<void> initialize() async {
    if (_isInitialized || !_isSupportedMobile) return;
    try {
      tz.initializeTimeZones();
      try {
        tz.setLocalLocation(tz.getLocation('Asia/Jakarta'));
      } catch (_) {}

      const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
      const initSettings = InitializationSettings(android: androidInit);

      await _plugin.initialize(settings: initSettings);
      _isInitialized = true;
    } catch (_) {
      // Aman pada lingkungan unit test / desktop yang belum mendukung plugin native
    }
  }

  Future<bool> requestPermissions() async {
    if (!_isSupportedMobile) return false;
    await initialize();
    try {
      final androidPlugin = _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >();
      if (androidPlugin != null) {
        final notifGranted = await androidPlugin
            .requestNotificationsPermission();
        await androidPlugin.requestExactAlarmsPermission();
        return notifGranted ?? true;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  int _baseNotificationId(String reminderId) {
    return (reminderId.hashCode.abs() % 100000) * 10;
  }

  Future<void> cancelReminderNotifications(String reminderId) async {
    if (!_isInitialized || !_isSupportedMobile) return;
    final baseId = _baseNotificationId(reminderId);
    try {
      for (int i = 0; i < 8; i++) {
        await _plugin.cancel(id: baseId + i);
      }
    } catch (_) {}
  }

  Future<void> scheduleReminder(
    ScheduledReminderModel reminder, {
    String? plotName,
  }) async {
    if (!_isSupportedMobile) return;
    await initialize();
    if (!_isInitialized) return;

    await cancelReminderNotifications(reminder.id);
    if (!reminder.isEnabled) return;

    final baseId = _baseNotificationId(reminder.id);
    final nextTime = reminder.nextOccurrence;
    if (!nextTime.isAfter(DateTime.now())) return;

    final title = 'Pengingat ${reminder.activityType}';
    final plotLabel = (plotName != null && plotName.isNotEmpty)
        ? ' di $plotName'
        : '';
    final body = reminder.notes.trim().isNotEmpty
        ? 'Jadwal ${reminder.activityType}$plotLabel: ${reminder.notes}'
        : 'Waktunya kegiatan ${reminder.activityType}$plotLabel pada lahan jagung Anda.';

    const androidDetails = AndroidNotificationDetails(
      'tanijagung_reminders_channel',
      'Pengingat Jadwal Pertanian',
      channelDescription:
          'Notifikasi pengingat jadwal penyiraman dan pemupukan lahan jagung',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);

    try {
      if (reminder.repeatType == 'Harian') {
        await _plugin.zonedSchedule(
          id: baseId,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(nextTime, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.time,
        );
      } else if (reminder.repeatType == 'Mingguan') {
        await _plugin.zonedSchedule(
          id: baseId,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(nextTime, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        );
      } else if (reminder.repeatType == 'Interval Hari') {
        final step = reminder.intervalDays < 1 ? 1 : reminder.intervalDays;
        for (int i = 0; i < 8; i++) {
          final occ = nextTime.add(Duration(days: step * i));
          await _plugin.zonedSchedule(
            id: baseId + i,
            title: title,
            body: body,
            scheduledDate: tz.TZDateTime.from(occ, tz.local),
            notificationDetails: details,
            androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          );
        }
      } else {
        await _plugin.zonedSchedule(
          id: baseId,
          title: title,
          body: body,
          scheduledDate: tz.TZDateTime.from(nextTime, tz.local),
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        );
      }
    } catch (_) {}
  }

  Future<void> syncAllUserReminders(
    List<ScheduledReminderModel> reminders,
    String? Function(String? plotId) plotNameResolver,
  ) async {
    if (!_isSupportedMobile) return;
    await initialize();
    if (!_isInitialized) return;
    for (final r in reminders) {
      if (r.isEnabled) {
        await scheduleReminder(r, plotName: plotNameResolver(r.plotId));
      } else {
        await cancelReminderNotifications(r.id);
      }
    }
  }
}
