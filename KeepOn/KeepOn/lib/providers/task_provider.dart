import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../models/app_settings.dart';
import '../models/task.dart';
import '../services/notification_service.dart';
import '../services/sensor_service.dart';
import '../services/settings_service.dart';
import '../services/storage_service.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError();
});

final settingsServiceProvider = Provider<SettingsService>((ref) {
  throw UnimplementedError();
});

final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError();
});

final sensorServiceProvider = Provider<SensorService>((ref) {
  throw UnimplementedError();
});

final nowProvider = StreamProvider<DateTime>((ref) async* {
  yield DateTime.now();
  yield* Stream.periodic(const Duration(seconds: 30), (_) => DateTime.now());
});

final taskControllerProvider = NotifierProvider<TaskController, AppState>(
  TaskController.new,
);

class AppState {
  const AppState({
    required this.tasks,
    required this.settings,
    required this.isStationary,
  });

  final List<KeepOnTask> tasks;
  final AppSettings settings;
  final bool isStationary;

  List<KeepOnTask> visibleTasks(DateTime now) {
    return tasks.where((task) {
      final status = task.statusAt(now);
      return status != TaskStatus.completed && status != TaskStatus.expired;
    }).toList();
  }

  AppState copyWith({
    List<KeepOnTask>? tasks,
    AppSettings? settings,
    bool? isStationary,
  }) {
    return AppState(
      tasks: tasks ?? this.tasks,
      settings: settings ?? this.settings,
      isStationary: isStationary ?? this.isStationary,
    );
  }
}

class TaskController extends Notifier<AppState> {
  final _uuid = const Uuid();

  late StorageService _storage;
  late SettingsService _settingsService;
  late NotificationService _notificationService;
  late SensorService _sensorService;

  @override
  AppState build() {
    _storage = ref.watch(storageServiceProvider);
    _settingsService = ref.watch(settingsServiceProvider);
    _notificationService = ref.watch(notificationServiceProvider);
    _sensorService = ref.watch(sensorServiceProvider);

    void sensorListener() {
      state = state.copyWith(isStationary: _sensorService.isStationary);
      _rescheduleActiveTasks();
    }

    _sensorService.addListener(sensorListener);
    ref.onDispose(() => _sensorService.removeListener(sensorListener));

    final initialState = AppState(
      tasks: _storage.loadTasks(),
      settings: _settingsService.load(),
      isStationary: _sensorService.isStationary,
    );
    Future.microtask(_rescheduleActiveTasks);
    return initialState;
  }

  Future<void> addTask({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final task = KeepOnTask(
      id: _uuid.v4(),
      title: title.trim(),
      description: description?.trim().isEmpty == true
          ? null
          : description?.trim(),
      startTime: startTime,
      endTime: endTime,
      createdAt: DateTime.now(),
    );
    final tasks = [...state.tasks, task]
      ..sort((a, b) => a.endTime.compareTo(b.endTime));
    state = state.copyWith(tasks: tasks);
    await _storage.saveTask(task);
    _scheduleInBackground(task);
  }

  Future<void> updateTask(KeepOnTask task) async {
    final tasks = [
      for (final item in state.tasks)
        if (item.id == task.id) task else item,
    ]..sort((a, b) => a.endTime.compareTo(b.endTime));
    state = state.copyWith(tasks: tasks);
    await _storage.saveTask(task);
    _scheduleInBackground(task);
  }

  Future<void> deleteTask(KeepOnTask task) async {
    state = state.copyWith(
      tasks: state.tasks.where((item) => item.id != task.id).toList(),
    );
    await _storage.deleteTask(task.id);
    await _notificationService.cancelTaskReminders(task.id);
  }

  Future<void> toggleCompleted(KeepOnTask task) async {
    final updated = task.copyWith(isCompleted: !task.isCompleted);
    await updateTask(updated);
    if (updated.isCompleted) {
      await _notificationService.cancelTaskReminders(updated.id);
    }
  }

  Future<void> updateSettings(AppSettings settings) async {
    state = state.copyWith(settings: settings);
    await _settingsService.save(settings);
    await _rescheduleActiveTasks();
  }

  Future<void> _schedule(KeepOnTask task) {
    return _notificationService.scheduleTaskReminders(
      task: task,
      settings: state.settings,
      intervalMultiplier: _sensorService.reminderFrequencyMultiplier,
    );
  }

  void _scheduleInBackground(KeepOnTask task) {
    unawaited(_schedule(task));
  }

  Future<void> _rescheduleActiveTasks() {
    return _notificationService.rescheduleAll(
      tasks: state.tasks,
      settings: state.settings,
      intervalMultiplier: _sensorService.reminderFrequencyMultiplier,
    );
  }
}
