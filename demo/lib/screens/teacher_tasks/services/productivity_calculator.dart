import '../models/teacher_task.dart';
import '../models/productivity.dart';

/// Computes productivity metrics for tasks planned after [fromDate].
/// Only considers manually planned tasks with a plannedForDate.
ProductivityMetrics calculateProductivity(
  List<TeacherTask> tasks,
  DateTime fromDate,
) {
  final filteredTasks = tasks.where((task) {
    if (task.planningType != 'manual') return false;
    if (task.plannedForDate == null) return false;

    final plannedDate = DateTime.parse(task.plannedForDate!);
    return plannedDate.isAfter(fromDate) ||
        plannedDate.isAtSameMomentAs(fromDate);
  }).toList();

  final totalTasks = filteredTasks.length;

  final completedTasks = filteredTasks
      .where((t) => t.status == 'completed')
      .length;

  final completionRate = totalTasks == 0 ? 0.0 : completedTasks / totalTasks;

  // --- On-time completion ---
  int onTimeEligible = 0;
  int onTimeCompleted = 0;
  for (final task in filteredTasks) {
    if (task.status != 'completed') continue;
    final deadline = _resolveDeadline(task);
    if (deadline == null) continue;
    onTimeEligible++;
    final completion = task.completedAt?.toDate() ?? DateTime.now();
    if (!completion.isAfter(deadline)) {
      onTimeCompleted++;
    }
  }

  final onTimeRate = onTimeEligible == 0
      ? 0.0
      : onTimeCompleted / onTimeEligible;

  // --- Time efficiency ---
  final efficiencyTasks = filteredTasks
      .where((t) => t.status == 'completed')
      .toList();

  final estimatedMinutes = efficiencyTasks.fold(
    0,
    (acc, t) => acc + t.estimatedMinutes,
  );

  final actualMinutes = efficiencyTasks.fold(0, (acc, t) {
    final actual = t.actualMinutes;
    if (actual <= 0) {
      return acc + t.estimatedMinutes;
    }
    return acc + actual;
  });

  final efficiency = estimatedMinutes == 0
      ? 0.0
      : actualMinutes / estimatedMinutes;

  // --- Productivity Score (0-100) ---
  final productivityScore = calculateProductivityScore(
    completionRate: completionRate,
    onTimeRate: onTimeRate,
    efficiency: efficiency,
  );

  // --- Task type distribution ---
  final tasksByType = <String, int>{};
  for (final task in filteredTasks) {
    tasksByType[task.taskType] = (tasksByType[task.taskType] ?? 0) + 1;
  }

  // --- Average daily minutes ---
  final daySet = <String>{};
  for (final task in filteredTasks) {
    if (task.plannedForDate != null) daySet.add(task.plannedForDate!);
  }
  final totalActual = filteredTasks.fold(0, (acc, t) {
    final a = t.actualMinutes;
    return acc + (a > 0 ? a : t.estimatedMinutes);
  });
  final avgDailyMinutes = daySet.isEmpty ? 0.0 : totalActual / daySet.length;

  // --- Streak calculation ---
  final streaks = calculateStreak(tasks);

  return ProductivityMetrics(
    totalTasks: totalTasks,
    completedTasks: completedTasks,
    completionRate: completionRate,
    onTimeCompleted: onTimeCompleted,
    onTimeRate: onTimeRate,
    estimatedMinutes: estimatedMinutes,
    actualMinutes: actualMinutes,
    efficiency: efficiency,
    productivityScore: productivityScore,
    currentStreak: streaks['current']!,
    longestStreak: streaks['longest']!,
    tasksByType: tasksByType,
    avgDailyMinutes: avgDailyMinutes,
  );
}

/// Composite productivity score (0-100).
/// Weights: Completion 40%, On-time 30%, Efficiency 30%.
double calculateProductivityScore({
  required double completionRate,
  required double onTimeRate,
  required double efficiency,
}) {
  // Efficiency is actual/estimated — ideal is 1.0 (100%).
  // If > 1.0 means tasks took longer than estimated (less efficient).
  // Convert to a 0-1 scale where 1.0 = perfect, 0.0 = very slow.
  final efficiencyNorm = efficiency <= 0
      ? 0.0
      : efficiency <= 1.0
          ? efficiency         // under or at estimate = good
          : (2.0 - efficiency).clamp(0.0, 1.0); // over estimate penalised

  final score = (completionRate * 0.40 +
          onTimeRate * 0.30 +
          efficiencyNorm * 0.30) *
      100;
  return score.clamp(0, 100);
}

/// Calculate current and longest streak of consecutive productive days.
/// A "productive day" = at least 1 task completed on that planned date.
Map<String, int> calculateStreak(List<TeacherTask> tasks) {
  // Collect all planned dates where at least one task was completed
  final completedDates = <String>{};
  for (final task in tasks) {
    if (task.planningType != 'manual') continue;
    if (task.status != 'completed') continue;
    if (task.plannedForDate == null) continue;
    completedDates.add(task.plannedForDate!);
  }

  if (completedDates.isEmpty) {
    return {'current': 0, 'longest': 0};
  }

  final sortedDates = completedDates.toList()..sort();
  final parsedDates = sortedDates.map((d) => DateTime.parse(d)).toList();

  int currentStreak = 1;
  int longestStreak = 1;
  int tempStreak = 1;

  for (int i = 1; i < parsedDates.length; i++) {
    final diff = parsedDates[i].difference(parsedDates[i - 1]).inDays;
    if (diff == 1) {
      tempStreak++;
    } else {
      tempStreak = 1;
    }
    if (tempStreak > longestStreak) longestStreak = tempStreak;
  }

  // Current streak = consecutive days ending at today or yesterday
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final yesterday = today.subtract(const Duration(days: 1));

  currentStreak = 0;
  for (int i = parsedDates.length - 1; i >= 0; i--) {
    final d = parsedDates[i];
    final dayD = DateTime(d.year, d.month, d.day);
    final expectedDay = today.subtract(Duration(days: currentStreak));

    if (dayD == expectedDay || (currentStreak == 0 && dayD == yesterday)) {
      currentStreak++;
    } else {
      break;
    }
  }

  return {'current': currentStreak, 'longest': longestStreak};
}

/// Detect days planned with more than [thresholdMinutes].
List<String> detectOverplannedDays(
  Map<String, int> minutesPerDay, {
  int thresholdMinutes = 360,
}) {
  return minutesPerDay.entries
      .where((e) => e.value > thresholdMinutes)
      .map((e) => e.key)
      .toList();
}

/// Counts tasks that missed their deadline.
int countMissedDeadlines(List<TeacherTask> tasks) {
  return tasksMissedDeadlines(tasks).length;
}

List<TeacherTask> tasksMissedDeadlines(List<TeacherTask> tasks) {
  return tasks.where((t) {
    if (t.planningType != 'manual') return false;
    if (t.dueDate == null) return false;

    final due = t.dueDate!.toDate();

    if (t.completedAt == null) {
      return DateTime.now().isAfter(due);
    }

    return t.completedAt!.toDate().isAfter(due);
  }).toList();
}

DateTime? _resolveDeadline(TeacherTask task) {
  if (task.dueDate != null) return task.dueDate!.toDate();
  if (task.plannedForDate != null) {
    final planned = DateTime.parse(task.plannedForDate!);
    return DateTime(planned.year, planned.month, planned.day, 23, 59, 59);
  }
  return null;
}