import 'package:flutter/foundation.dart';
import '../models/teacher_task.dart';

class DailyWorkload {
  final int totalTasks;
  final int completedTasks;
  final int pendingTasks;
  final int estimatedMinutes;
  final int actualMinutes;

  DailyWorkload({
    required this.totalTasks,
    required this.completedTasks,
    required this.pendingTasks,
    required this.estimatedMinutes,
    required this.actualMinutes,
  });
}

class WeeklyWorkload {
  final int totalMinutes;
  final int completedMinutes;
  final Map<String, int> minutesPerDay;

  WeeklyWorkload({
    required this.totalMinutes,
    required this.completedMinutes,
    required this.minutesPerDay,
  });
}

DailyWorkload calculateDailyWorkload(List<TeacherTask> tasks, DateTime date) {
  // Compare using local timezone to avoid UTC/local day mismatches.
  final target = date.toLocal();
  final sameDayTasks = tasks.where((task) {
    final due = task.dueDate;
    if (due == null) return false;
    final taskDate = due.toDate().toLocal();
    return taskDate.year == target.year &&
        taskDate.month == target.month &&
        taskDate.day == target.day;
  }).toList();

  final totalTasks = sameDayTasks.length;
  final completedTasks = sameDayTasks
      .where((t) => t.status == 'completed')
      .length;

  final estimatedMinutes = sameDayTasks.fold(
    0,
    (sum, t) => sum + t.estimatedMinutes,
  );

  final actualMinutes = sameDayTasks.fold(0, (sum, t) => sum + t.actualMinutes);

  return DailyWorkload(
    totalTasks: totalTasks,
    completedTasks: completedTasks,
    pendingTasks: totalTasks - completedTasks,
    estimatedMinutes: estimatedMinutes,
    actualMinutes: actualMinutes,
  );
}

WeeklyWorkload calculateWeeklyWorkload(
  List<TeacherTask> tasks,
  DateTime weekStart, // usually Monday
) {
  final weekEnd = weekStart.add(const Duration(days: 7));

  final plannedTasks = tasks.where((t) {
    if (t.planningType != 'manual') return false;
    if (t.plannedForDate == null) return false;

    final date = DateTime.parse(t.plannedForDate!);
    return !date.isBefore(weekStart) && date.isBefore(weekEnd);
  }).toList();

  int totalMinutes = 0;
  int completedMinutes = 0;
  final Map<String, int> perDay = {};

  for (final t in plannedTasks) {
    totalMinutes += t.estimatedMinutes;

    perDay[t.plannedForDate!] =
        (perDay[t.plannedForDate!] ?? 0) + t.estimatedMinutes;

    if (t.status == 'completed') {
      completedMinutes += t.estimatedMinutes;
    }
  }

  return WeeklyWorkload(
    totalMinutes: totalMinutes,
    completedMinutes: completedMinutes,
    minutesPerDay: perDay,
  );
}
