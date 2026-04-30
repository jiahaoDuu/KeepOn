import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/app_settings.dart';

class SettingsService {
  static const _intervalKey = 'reminder_interval_minutes';
  static const _quietStartKey = 'quiet_start_minutes';
  static const _quietEndKey = 'quiet_end_minutes';
  static const _notificationsKey = 'notifications_enabled';

  late SharedPreferences _preferences;

  Future<void> init() async {
    _preferences = await SharedPreferences.getInstance();
  }

  AppSettings load() {
    return AppSettings(
      reminderInterval: Duration(
        minutes:
            _preferences.getInt(_intervalKey) ??
            AppSettings.defaults.reminderInterval.inMinutes,
      ),
      quietHoursStart: _timeFromMinutes(
        _preferences.getInt(_quietStartKey) ?? 22 * 60,
      ),
      quietHoursEnd: _timeFromMinutes(
        _preferences.getInt(_quietEndKey) ?? 8 * 60,
      ),
      notificationsEnabled:
          _preferences.getBool(_notificationsKey) ??
          AppSettings.defaults.notificationsEnabled,
    );
  }

  Future<void> save(AppSettings settings) async {
    await _preferences.setInt(
      _intervalKey,
      settings.reminderInterval.inMinutes,
    );
    await _preferences.setInt(
      _quietStartKey,
      _minutesFromTime(settings.quietHoursStart),
    );
    await _preferences.setInt(
      _quietEndKey,
      _minutesFromTime(settings.quietHoursEnd),
    );
    await _preferences.setBool(
      _notificationsKey,
      settings.notificationsEnabled,
    );
  }

  static TimeOfDay _timeFromMinutes(int minutes) {
    return TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60);
  }

  static int _minutesFromTime(TimeOfDay time) => time.hour * 60 + time.minute;
}
