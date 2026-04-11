class ProductivityMetrics {
  final int totalTasks;
  final int completedTasks;
  final double completionRate;

  final int onTimeCompleted;
  final double onTimeRate;

  final int estimatedMinutes;
  final int actualMinutes;
  final double efficiency;

  // --- Enhanced fields ---
  final double productivityScore; // 0-100 composite
  final int currentStreak;        // consecutive productive days
  final int longestStreak;
  final Map<String, int> tasksByType;   // task type → count
  final double avgDailyMinutes;         // average actual minutes per day

  ProductivityMetrics({
    required this.totalTasks,
    required this.completedTasks,
    required this.completionRate,
    required this.onTimeCompleted,
    required this.onTimeRate,
    required this.estimatedMinutes,
    required this.actualMinutes,
    required this.efficiency,
    this.productivityScore = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.tasksByType = const {},
    this.avgDailyMinutes = 0,
  });
}