import 'package:hive_flutter/hive_flutter.dart';

import '../models/task.dart';

class StorageService {
  static const _taskBoxName = 'tasks';
  late final Box<Map> _taskBox;

  Future<void> init() async {
    await Hive.initFlutter();
    _taskBox = await Hive.openBox<Map>(_taskBoxName);
  }

  List<KeepOnTask> loadTasks() {
    return _taskBox.values.map((value) => KeepOnTask.fromJson(value)).toList()
      ..sort((a, b) => a.endTime.compareTo(b.endTime));
  }

  Future<void> saveTask(KeepOnTask task) async {
    await _taskBox.put(task.id, task.toJson());
  }

  Future<void> deleteTask(String id) async {
    await _taskBox.delete(id);
  }
}
