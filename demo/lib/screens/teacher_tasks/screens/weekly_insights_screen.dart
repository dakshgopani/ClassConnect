import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/teacher_task.dart';
import '../services/workload_calculator.dart';
import '../services/productivity_calculator.dart';
import '../models/productivity.dart';

class WeeklyInsightsScreen extends StatelessWidget {
  final List<TeacherTask> tasks;

  const WeeklyInsightsScreen({super.key, required this.tasks});

  DateTime _weekStart() {
    final now = DateTime.now();
    return now.subtract(Duration(days: now.weekday - 1));
  }

  @override
  Widget build(BuildContext context) {
    final weekStart = _weekStart();

    final weeklyWorkload = calculateWeeklyWorkload(tasks, weekStart);

    final productivity = calculateProductivity(tasks, weekStart);

    final missedDeadlineTasks = tasksMissedDeadlines(tasks);

    final overloadedEntries =
        weeklyWorkload.minutesPerDay.entries
            .where((entry) => entry.value > 360)
            .toList()
          ..sort((a, b) => a.key.compareTo(b.key));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        centerTitle: true,
        // This replaces the default back arrow
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ), // Modern rounded back icon
          color: Colors.white, // Matching your Cyan accent
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Weekly Insights',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: _summaryCard(weeklyWorkload, productivity),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _workloadChart(weeklyWorkload),
            ),
          ),
          if (overloadedEntries.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: _burnoutWarning(overloadedEntries),
              ),
            ),
          if (missedDeadlineTasks.isNotEmpty)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: _deadlineWarning(missedDeadlineTasks),
              ),
            ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // --------------------------------------------------
  // SUMMARY CARD
  // --------------------------------------------------
  Widget _summaryCard(WeeklyWorkload w, ProductivityMetrics p) {
    String fmt(int min) => '${(min / 60).floor()}h ${min % 60}m';

    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1E1E1E), Color(0xFF12304E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.45),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Weekly energy',
                  style: TextStyle(
                    fontSize: 20,
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Builder(
                  builder: (_) {
                    final hasTasks = p.totalTasks > 0;
                    final completionRatio = hasTasks
                        ? p.completedTasks / p.totalTasks
                        : 0;
                    final bool underHalf = completionRatio < 0.5;
                    final Color chipColor = underHalf
                        ? Colors.redAccent
                        : Colors.cyanAccent;
                    final Color chipTextColor = underHalf
                        ? Colors.white
                        : Colors.black;

                    return Chip(
                      backgroundColor: chipColor,
                      label: Text(
                        '${p.completedTasks}/${p.totalTasks} done',
                        style: TextStyle(
                          color: chipTextColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Planned ${fmt(w.totalMinutes)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      Text(
                        'Completed ${fmt(w.completedMinutes)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 10),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: p.completionRate),
                        duration: const Duration(milliseconds: 600),
                        builder: (context, value, _) => LinearProgressIndicator(
                          value: value.clamp(0.0, 1.0),
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            Colors.cyanAccent,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Completion ${(p.completionRate * 100).toStringAsFixed(0)}%',
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${(p.onTimeRate * 100).toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'On-time',
                          style: TextStyle(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // BAR CHART (Simple, Native)
  // --------------------------------------------------
  Widget _workloadChart(WeeklyWorkload w) {
    final days = w.minutesPerDay.keys.toList()..sort();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.35),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.timeline, color: Colors.cyanAccent),
                SizedBox(width: 8),
                Text(
                  'Workload by day',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...days.map((d) {
              final minutes = w.minutesPerDay[d]!;
              final hours = minutes / 60;
              final ratio = (hours / 8).clamp(0.0, 1.0);
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            d,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Text(
                          '${hours.toStringAsFixed(1)}h',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: ratio,
                        minHeight: 10,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          ratio > 0.9 ? Colors.redAccent : Colors.cyanAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // BURNOUT WARNING
  // --------------------------------------------------
  Widget _burnoutWarning(List<MapEntry<String, int>> days) {
    Color colorForMinutes(int minutes) =>
        minutes >= 480 ? Colors.red : Colors.orange;

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.orange.withOpacity(0.4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: const [
                Icon(Icons.local_fire_department, color: Colors.orange),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Potential burnout hotspots',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: days.map((entry) {
                final hours = entry.value / 60;
                final color = colorForMinutes(entry.value);
                return Chip(
                  avatar: Icon(Icons.warning, color: color, size: 18),
                  label: Text(
                    '${entry.key} • ${hours.toStringAsFixed(1)}h',
                    style: const TextStyle(color: Colors.white),
                  ),
                  backgroundColor: color.withOpacity(0.18),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tip: Cap daily planned work to ~6h or move tasks earlier in the week.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }

  // --------------------------------------------------
  // DEADLINE WARNING
  // --------------------------------------------------
  Widget _deadlineWarning(List<TeacherTask> lateTasks) {
    final formatter = DateFormat('MMM d');
    final items = [...lateTasks]
      ..sort((a, b) => a.dueDate!.toDate().compareTo(b.dueDate!.toDate()));

    String fmtDate(DateTime date) => formatter.format(date);

    return Card(
      color: const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.red.withOpacity(0.35)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.event_busy, color: Colors.red),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '${lateTasks.length} task(s) missed their deadline',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...items.take(4).map((task) {
              final due = task.dueDate?.toDate();
              final completion = task.completedAt?.toDate();
              final statusText = completion == null
                  ? 'Still pending'
                  : 'Completed ${fmtDate(completion)}';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFF262626),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Due ${due != null ? fmtDate(due) : 'unknown'} • $statusText',
                      style: const TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              );
            }),
            if (lateTasks.length > 4)
              Text(
                '+${lateTasks.length - 4} more tasks overdue',
                style: const TextStyle(
                  fontStyle: FontStyle.italic,
                  color: Colors.white70,
                ),
              ),
            const SizedBox(height: 8),
            const Text(
              'Tip: Re-plan these tasks or notify stakeholders to reset expectations.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
