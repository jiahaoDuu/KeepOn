import 'package:flutter/material.dart';

enum TaskStatus { pending, active, completed, expired }

class KeepOnTask {
  const KeepOnTask({
    required this.id,
    required this.title,
    required this.startTime,
    required this.endTime,
    required this.createdAt,
    this.description,
    this.isCompleted = false,
  });

  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isCompleted;
  final DateTime createdAt;

  Duration remainingAt(DateTime now) => endTime.difference(now);

  TaskStatus statusAt(DateTime now) {
    if (isCompleted) return TaskStatus.completed;
    if (now.isAfter(endTime)) return TaskStatus.expired;
    if (now.isBefore(startTime)) return TaskStatus.pending;
    return TaskStatus.active;
  }

  Color urgencyColorAt(DateTime now) {
    final remaining = endTime.difference(now);
    final days = remaining.inHours <= 0 ? 0 : (remaining.inHours / 24).ceil();
    if (days <= 5) return const Color(0xffd64545);
    if (days <= 15) return const Color(0xffd6a72f);
    return const Color(0xff2f8f63);
  }

  KeepOnTask copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isCompleted,
    DateTime? createdAt,
  }) {
    return KeepOnTask(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory KeepOnTask.fromJson(Map<dynamic, dynamic> json) {
    return KeepOnTask(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      startTime: DateTime.parse(json['startTime'] as String),
      endTime: DateTime.parse(json['endTime'] as String),
      isCompleted: json['isCompleted'] as bool? ?? false,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}
