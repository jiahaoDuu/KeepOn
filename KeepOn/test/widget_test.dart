import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:keepon/models/task.dart';

void main() {
  test('task status changes with time and completion', () {
    final now = DateTime(2026, 1, 1, 12);
    final task = KeepOnTask(
      id: 'task-1',
      title: 'Finish report',
      startTime: now.subtract(const Duration(hours: 1)),
      endTime: now.add(const Duration(hours: 1)),
      createdAt: now,
    );

    expect(task.statusAt(now), TaskStatus.active);
    expect(
      task.statusAt(now.add(const Duration(hours: 2))),
      TaskStatus.expired,
    );
    expect(
      task.copyWith(isCompleted: true).statusAt(now),
      TaskStatus.completed,
    );
  });

  test('urgency colors follow remaining-day thresholds', () {
    final now = DateTime(2026, 1, 1);
    final soon = KeepOnTask(
      id: 'soon',
      title: 'Soon',
      startTime: now,
      endTime: now.add(const Duration(days: 5)),
      createdAt: now,
    );
    final later = soon.copyWith(
      id: 'later',
      endTime: now.add(const Duration(days: 20)),
    );

    expect(soon.urgencyColorAt(now), const Color(0xffd64545));
    expect(later.urgencyColorAt(now), const Color(0xff2f8f63));
  });
}
