import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../models/task.dart';
import '../providers/task_provider.dart';
import 'settings_screen.dart';
import 'task_edit_screen.dart';

class TaskListScreen extends ConsumerWidget {
  const TaskListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(taskControllerProvider);
    final now = ref.watch(nowProvider).value ?? DateTime.now();
    final visibleTasks = appState.visibleTasks(now);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar.large(
            pinned: true,
            title: const Text('KeepOn'),
            actions: [
              IconButton(
                tooltip: 'Settings',
                icon: const Icon(Icons.tune_outlined),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const SettingsScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: _AwarenessPanel(tasks: visibleTasks, now: now),
            ),
          ),
          if (visibleTasks.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: _EmptyState(onCreate: () => _openEditor(context)),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
              sliver: SliverList.separated(
                itemCount: visibleTasks.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final task = visibleTasks[index];
                  return _TaskCard(task: task, now: now);
                },
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openEditor(context),
        icon: const Icon(Icons.add_task_outlined),
        label: const Text('New task'),
      ),
    );
  }

  void _openEditor(BuildContext context, [KeepOnTask? task]) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => TaskEditScreen(task: task)));
  }
}

class _AwarenessPanel extends StatelessWidget {
  const _AwarenessPanel({required this.tasks, required this.now});

  final List<KeepOnTask> tasks;
  final DateTime now;

  @override
  Widget build(BuildContext context) {
    final active = tasks
        .where((task) => task.statusAt(now) == TaskStatus.active)
        .length;
    final pending = tasks
        .where((task) => task.statusAt(now) == TaskStatus.pending)
        .length;
    final urgent = tasks.where((task) {
      return task.endTime.difference(now).inDays <= 5;
    }).length;
    final nextTask = tasks.isEmpty ? null : tasks.first;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xff12342e),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xffffc857),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.notifications_active,
                  color: Color(0xff12342e),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nextTask == null ? 'Nothing is pressing' : 'Next focus',
                      style: Theme.of(context).textTheme.labelLarge?.copyWith(
                        color: const Color(0xffcde7df),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      nextTask == null
                          ? 'Create a task to start the reminder loop.'
                          : nextTask.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          if (nextTask != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                minHeight: 9,
                value: _progress(nextTask, now),
                color: nextTask.urgencyColorAt(now),
                backgroundColor: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              '${_remainingLabel(nextTask, now)} remaining • due ${DateFormat('MMM d, HH:mm').format(nextTask.endTime)}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: const Color(0xffdcece7)),
            ),
            const SizedBox(height: 18),
          ],
          Row(
            children: [
              Expanded(
                child: _Metric(label: 'Active', value: active.toString()),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(label: 'Pending', value: pending.toString()),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _Metric(label: 'Urgent', value: urgent.toString()),
              ),
            ],
          ),
        ],
      ),
    );
  }

  double _progress(KeepOnTask task, DateTime now) {
    final total = task.endTime.difference(task.startTime).inSeconds;
    final elapsed = now.difference(task.startTime).inSeconds;
    if (total <= 0) return 1;
    return (elapsed / total).clamp(0, 1);
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.11),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: const Color(0xffcde7df)),
          ),
        ],
      ),
    );
  }
}

class _TaskCard extends ConsumerWidget {
  const _TaskCard({required this.task, required this.now});

  final KeepOnTask task;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(taskControllerProvider.notifier);
    final status = task.statusAt(now);
    final urgency = task.urgencyColorAt(now);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(builder: (_) => TaskEditScreen(task: task)),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: urgency.withValues(alpha: 0.55),
              width: 1.4,
            ),
          ),
          child: Column(
            children: [
              Container(
                height: 7,
                decoration: BoxDecoration(
                  color: urgency,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Transform.scale(
                      scale: 1.08,
                      child: Checkbox(
                        value: task.isCompleted,
                        onChanged: (_) => controller.toggleCompleted(task),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  task.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w800),
                                ),
                              ),
                              _StatusPill(status: status, color: urgency),
                            ],
                          ),
                          if (task.description?.isNotEmpty == true) ...[
                            const SizedBox(height: 6),
                            Text(
                              task.description!,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Colors.black.withValues(alpha: 0.62),
                                  ),
                            ),
                          ],
                          const SizedBox(height: 14),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: LinearProgressIndicator(
                              minHeight: 8,
                              value: _progress(task, now),
                              color: urgency,
                              backgroundColor: const Color(0xffedf1ee),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _InfoChip(
                                icon: Icons.timer_outlined,
                                label: _remainingLabel(task, now),
                              ),
                              _InfoChip(
                                icon: Icons.alarm_outlined,
                                label: DateFormat(
                                  'MMM d, HH:mm',
                                ).format(task.endTime),
                              ),
                              _InfoChip(
                                icon: Icons.play_circle_outline,
                                label: DateFormat(
                                  'MMM d, HH:mm',
                                ).format(task.startTime),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Task actions',
                      icon: const Icon(Icons.more_vert),
                      onSelected: (value) {
                        if (value == 'delete') controller.deleteTask(task);
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _progress(KeepOnTask task, DateTime now) {
    final total = max(1, task.endTime.difference(task.startTime).inSeconds);
    final elapsed = now.difference(task.startTime).inSeconds;
    return (elapsed / total).clamp(0, 1);
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status, required this.color});

  final TaskStatus status;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      TaskStatus.pending => 'Pending',
      TaskStatus.active => 'Active',
      TaskStatus.completed => 'Done',
      TaskStatus.expired => 'Expired',
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xfff0f3ef),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: const Color(0xff3f5550)),
          const SizedBox(width: 6),
          Text(label, style: Theme.of(context).textTheme.labelMedium),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset('assets/app_icon.png', width: 84, height: 84),
            const SizedBox(height: 18),
            Text(
              'No active tasks',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'Create a task and KeepOn will keep reminding you until it is done or expired.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onCreate,
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('Create task'),
            ),
          ],
        ),
      ),
    );
  }
}

String _remainingLabel(KeepOnTask task, DateTime now) {
  if (now.isBefore(task.startTime)) return 'Starts soon';
  final remaining = task.remainingAt(now);
  if (remaining.inDays > 0) return '${remaining.inDays}d left';
  if (remaining.inHours > 0) return '${remaining.inHours}h left';
  return '${remaining.inMinutes.clamp(0, 999)}m left';
}
