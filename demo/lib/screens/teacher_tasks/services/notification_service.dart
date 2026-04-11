import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../models/teacher_task.dart';
import 'teacher_task_query_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;

    const AndroidInitializationSettings androidInit =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    final DarwinInitializationSettings iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    final InitializationSettings settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings);
    _initialized = true;
  }

  NotificationDetails _defaultDetails() {
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'teacher_tasks_channel',
          'Teacher Tasks',
          channelDescription: 'Nudges and reminders for planned tasks',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
        );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails();

    return const NotificationDetails(android: androidDetails, iOS: iosDetails);
  }

  // Sends an immediate nudge about tomorrow's workload.
  Future<void> sendTomorrowNudge({required String teacherId}) async {
    await init();

    final query = TeacherTaskQueryService();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final plannedForDate =
        '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

    // Fetch once and show summary
    late final StreamSubscription<List<TeacherTask>> sub;
    sub = query
        .getPlannedTasksForDate(
          teacherId: teacherId,
          plannedForDate: plannedForDate,
        )
        .listen((tasks) async {
          final total = tasks.length;
          final minutes = tasks.fold(0, (s, t) => s + t.estimatedMinutes);
          final body = total == 0
              ? 'No tasks planned for tomorrow. Consider planning ahead.'
              : 'You have $total task(s) (~${minutes} min) planned tomorrow.';

          await _plugin.show(1001, 'Tomorrow\'s Plan', body, _defaultDetails());
          await sub.cancel();
        });
  }

  // Sends a gentle nudge for tasks due within next 7 days (summary).
  Future<void> sendNext7DaysNudge({required String teacherId}) async {
    await init();

    final query = TeacherTaskQueryService();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 7));

    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    late final StreamSubscription<List<TeacherTask>> sub;
    sub = query
        .getPlannedTasksInRange(
          teacherId: teacherId,
          startDate: fmt(start),
          endDate: fmt(end),
        )
        .listen((tasks) async {
          if (tasks.isEmpty) {
            await _plugin.show(
              1002,
              'Next 7 Days',
              'No planned tasks in the coming week.',
              _defaultDetails(),
            );
            await sub.cancel();
            return;
          }

          // Summarize minutes per day
          final Map<String, int> perDay = {};
          for (final t in tasks) {
            if (t.plannedForDate == null) continue;
            perDay[t.plannedForDate!] =
                (perDay[t.plannedForDate!] ?? 0) + t.estimatedMinutes;
          }
          final days = perDay.keys.toList()..sort();
          final summary = days
              .map((d) => '$d: ${(perDay[d]! / 60).toStringAsFixed(1)}h')
              .take(3) // keep message short
              .join(' • ');

          await _plugin.show(
            1002,
            'Next 7 Days Plan',
            'Top days — $summary',
            _defaultDetails(),
          );
          await sub.cancel();
        });
  }
}
