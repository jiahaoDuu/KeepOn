import 'package:flutter/material.dart';

class AppSettings {
  const AppSettings({
    required this.reminderInterval,
    required this.quietHoursStart,
    required this.quietHoursEnd,
    required this.notificationsEnabled,
  });

  final Duration reminderInterval;
  final TimeOfDay quietHoursStart;
  final TimeOfDay quietHoursEnd;
  final bool notificationsEnabled;

  static const defaults = AppSettings(
    reminderInterval: Duration(minutes: 15),
    quietHoursStart: TimeOfDay(hour: 22, minute: 0),
    quietHoursEnd: TimeOfDay(hour: 8, minute: 0),
    notificationsEnabled: true,
  );

  AppSettings copyWith({
    Duration? reminderInterval,
    TimeOfDay? quietHoursStart,
    TimeOfDay? quietHoursEnd,
    bool? notificationsEnabled,
  }) {
    return AppSettings(
      reminderInterval: reminderInterval ?? this.reminderInterval,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    );
  }
}
