import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../models/app_settings.dart';
import '../models/task.dart';

class NotificationService {
  static const _channelId = 'keepon_reminders';
  static const _channelName = 'KeepOn reminders';
  static const _maxScheduledPerTask = 512;

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  Future<void> init() async {
    tz_data.initializeTimeZones();
    await _configureLocalTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: darwin);
    await _plugin.initialize(settings: settings);

    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  Future<void> scheduleTaskReminders({
    required KeepOnTask task,
    required AppSettings settings,
    double intervalMultiplier = 1,
  }) async {
    await cancelTaskReminders(task.id);

    if (!settings.notificationsEnabled ||
        task.isCompleted ||
        DateTime.now().isAfter(task.endTime)) {
      return;
    }

    final interval = settings.reminderInterval * intervalMultiplier;
    var next = DateTime.now().isBefore(task.startTime)
        ? task.startTime
        : DateTime.now().add(const Duration(seconds: 5));

    var scheduled = 0;
    while (next.isBefore(task.endTime) && scheduled < _maxScheduledPerTask) {
      final validTime = _nextAllowedTime(next, settings);
      if (validTime.isAfter(task.endTime)) break;

      await _plugin.zonedSchedule(
        id: _notificationId(task.id, scheduled),
        title: 'Task: ${task.title}',
        body:
            '${_formatRemaining(task.endTime.difference(validTime))} remaining',
        scheduledDate: tz.TZDateTime.from(validTime, tz.local),
        notificationDetails: _details(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: task.id,
      );

      scheduled += 1;
      next = validTime.add(interval);
    }
  }

  Future<void> cancelTaskReminders(String taskId) async {
    for (var index = 0; index < _maxScheduledPerTask; index += 1) {
      await _plugin.cancel(id: _notificationId(taskId, index));
    }
  }

  Future<void> rescheduleAll({
    required List<KeepOnTask> tasks,
    required AppSettings settings,
    double intervalMultiplier = 1,
  }) async {
    for (final task in tasks) {
      await scheduleTaskReminders(
        task: task,
        settings: settings,
        intervalMultiplier: intervalMultiplier,
      );
    }
  }

  NotificationDetails _details() {
    const android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Persistent reminders for unfinished KeepOn tasks.',
      importance: Importance.high,
      priority: Priority.high,
      visibility: NotificationVisibility.public,
      category: AndroidNotificationCategory.reminder,
    );
    const darwin = DarwinNotificationDetails();
    return const NotificationDetails(android: android, iOS: darwin);
  }

  DateTime _nextAllowedTime(DateTime candidate, AppSettings settings) {
    if (!_isInQuietHours(candidate, settings)) return candidate;

    final end = settings.quietHoursEnd;
    var next = DateTime(
      candidate.year,
      candidate.month,
      candidate.day,
      end.hour,
      end.minute,
    );
    if (!next.isAfter(candidate)) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  bool _isInQuietHours(DateTime time, AppSettings settings) {
    final start = _minutes(settings.quietHoursStart);
    final end = _minutes(settings.quietHoursEnd);
    final current = time.hour * 60 + time.minute;
    if (start == end) return false;
    if (start < end) return current >= start && current < end;
    return current >= start || current < end;
  }

  int _notificationId(String taskId, int index) {
    final base = taskId.codeUnits.fold<int>(0, (sum, unit) {
      return (sum * 31 + unit) & 0x3fffffff;
    });
    return min(0x7fffffff, base + index);
  }

  int _minutes(TimeOfDay time) => time.hour * 60 + time.minute;

  String _formatRemaining(Duration duration) {
    if (duration.inDays >= 1) {
      return '${duration.inDays} day${duration.inDays == 1 ? '' : 's'}';
    }
    if (duration.inHours >= 1) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    }
    final minutes = max(1, duration.inMinutes);
    return '$minutes minute${minutes == 1 ? '' : 's'}';
  }

  Future<void> _configureLocalTimeZone() async {
    try {
      final timezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }
}
