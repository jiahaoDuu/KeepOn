import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_settings.dart';
import '../providers/task_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  static const _intervals = [
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
    Duration(hours: 2),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(taskControllerProvider);
    final settings = appState.settings;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xff12342e),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_active,
                  color: Color(0xffffc857),
                  size: 32,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Control how often KeepOn nudges you, and when it stays quiet.',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Card(
            child: SwitchListTile(
              secondary: const Icon(Icons.notifications_active_outlined),
              title: const Text('Notifications'),
              subtitle: const Text('Repeated local reminders for active tasks'),
              value: settings.notificationsEnabled,
              onChanged: (value) =>
                  _update(ref, settings.copyWith(notificationsEnabled: value)),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.repeat_outlined),
              title: const Text('Reminder interval'),
              subtitle: Text(_durationLabel(settings.reminderInterval)),
              trailing: DropdownButton<Duration>(
                value: settings.reminderInterval,
                items: _intervals
                    .map(
                      (interval) => DropdownMenuItem(
                        value: interval,
                        child: Text(_durationLabel(interval)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  _update(ref, settings.copyWith(reminderInterval: value));
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.bedtime_outlined),
                  title: const Text('Quiet hours start'),
                  subtitle: Text(settings.quietHoursStart.format(context)),
                  trailing: const Icon(Icons.schedule_outlined),
                  onTap: () => _pickQuietTime(
                    context: context,
                    ref: ref,
                    settings: settings,
                    isStart: true,
                  ),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.wb_sunny_outlined),
                  title: const Text('Quiet hours end'),
                  subtitle: Text(settings.quietHoursEnd.format(context)),
                  trailing: const Icon(Icons.schedule_outlined),
                  onTap: () => _pickQuietTime(
                    context: context,
                    ref: ref,
                    settings: settings,
                    isStart: false,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sensors_outlined),
              title: const Text('Context adaptation'),
              subtitle: Text(
                appState.isStationary
                    ? 'Device is stationary; reminder interval is reduced.'
                    : 'Motion sensing is active.',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickQuietTime({
    required BuildContext context,
    required WidgetRef ref,
    required AppSettings settings,
    required bool isStart,
  }) async {
    final selected = await showTimePicker(
      context: context,
      initialTime: isStart ? settings.quietHoursStart : settings.quietHoursEnd,
    );
    if (selected == null) return;

    _update(
      ref,
      isStart
          ? settings.copyWith(quietHoursStart: selected)
          : settings.copyWith(quietHoursEnd: selected),
    );
  }

  void _update(WidgetRef ref, AppSettings settings) {
    ref.read(taskControllerProvider.notifier).updateSettings(settings);
  }

  static String _durationLabel(Duration duration) {
    if (duration.inHours >= 1 && duration.inMinutes % 60 == 0) {
      return '${duration.inHours} hour${duration.inHours == 1 ? '' : 's'}';
    }
    return '${duration.inMinutes} minutes';
  }
}
