import 'dart:async';
import 'package:flutter/material.dart';
import 'teacher_task_query_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

/// Simple notification service using Firebase Cloud Messaging.
/// This stub logs messages and can be extended to show SnackBars or push notifications.
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    await _messaging.requestPermission();
    _initialized = true;
  }

  Future<void> _showMessage(String title, String body) async {
    debugPrint('Notification: $title – $body');
    // In a real app, display a SnackBar or use FCM to send a push notification.
  }

  // Sends an immediate nudge about tomorrow's workload.
  Future<void> sendTomorrowNudge({required String teacherId}) async {
    await init();
    final query = TeacherTaskQueryService();
    final now = DateTime.now();
    final tomorrow = now.add(const Duration(days: 1));
    final plannedForDate = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';
    final tasks = await query.getPlannedTasksForDate(
        teacherId: teacherId, plannedForDate: plannedForDate).first;
    final total = tasks.length;
    final minutes = tasks.fold(0, (s, t) => s + t.estimatedMinutes);
    final body = total == 0
        ? 'No tasks planned for tomorrow. Consider planning ahead.'
        : 'You have $total task(s) (~$minutes min) planned tomorrow.';
    await _showMessage("Tomorrow's Plan", body);
  }

  // Sends a gentle nudge for tasks due within the next 7 days (summary).
  Future<void> sendNext7DaysNudge({required String teacherId}) async {
    await init();
    final query = TeacherTaskQueryService();
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final end = start.add(const Duration(days: 7));
    String fmt(DateTime d) =>
        '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    final tasks = await query
        .getPlannedTasksInRange(
            teacherId: teacherId, startDate: fmt(start), endDate: fmt(end))
        .first;
    if (tasks.isEmpty) {
      await _showMessage('Next 7 Days', 'No planned tasks in the coming week.');
      return;
    }
    final Map<String, int> perDay = {};
    for (final t in tasks) {
      if (t.plannedForDate == null) continue;
      perDay[t.plannedForDate!] = (perDay[t.plannedForDate!] ?? 0) + t.estimatedMinutes;
    }
    final days = perDay.keys.toList()..sort();
    final summary = days
        .map((d) => '$d: ${(perDay[d]! / 60).toStringAsFixed(1)}h')
        .take(3)
        .join(' • ');
    await _showMessage('Next 7 Days Plan', 'Top days — $summary');
  }
}
