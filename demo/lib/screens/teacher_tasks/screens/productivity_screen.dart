import 'package:flutter/material.dart';
import '../models/productivity.dart';
import '../models/teacher_task.dart';
import '../services/productivity_calculator.dart';
import '../services/teacher_task_query_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ProductivityScreen extends StatelessWidget {
  ProductivityScreen({super.key, required this.tasks});

  final List<TeacherTask> tasks;
  static final TeacherTaskQueryService _queryService =
      TeacherTaskQueryService();
  final _db = FirebaseFirestore.instance;

  String get teacherId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Teacher not logged in');
    }
    return user.uid;
  }

  static const _backgroundGradient = Color(0xFFF4F8FF);

  String _formatDate(DateTime date) {
    String pad(int value) => value.toString().padLeft(2, '0');
    return '${date.year}-${pad(date.month)}-${pad(date.day)}';
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final rangeStart = now.subtract(const Duration(days: 30));

    return Scaffold(
      backgroundColor: _backgroundGradient,
      appBar: AppBar(
        title: const Text(
          'My Productivity',
          style: TextStyle(
            color: Color(0xFF0D1B3D),
            fontWeight: FontWeight.bold,
          ),
        ),
        elevation: 0,
        backgroundColor: const Color(0xFFF4F8FF), // Matching your theme
        centerTitle: true,
        // This replaces the default back arrow
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
          ), // Modern rounded back icon
          color: Color(0xFF0D1B3D), // Dark text color
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        iconTheme: const IconThemeData(color: Color(0xFF0D1B3D)),
      ),
      body: Container(
        color: _backgroundGradient,
        child: StreamBuilder<List<TeacherTask>>(
          stream: _queryService.getPlannedTasksInRange(
            teacherId: teacherId,
            startDate: _formatDate(rangeStart),
            endDate: _formatDate(now),
          ),
          initialData: tasks,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return const Center(
                child: Text(
                  'Unable to load productivity data right now.',
                  style: TextStyle(color: Color(0xFF0D1B3D)),
                ),
              );
            }

            final data = snapshot.data ?? tasks;

            if (snapshot.connectionState == ConnectionState.waiting &&
                data.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (data.isEmpty) {
              return const Center(
                child: Text(
                  'Plan a few tasks to see your productivity trends.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF0D1B3D),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }

            final weekly = calculateProductivity(
              data,
              now.subtract(const Duration(days: 7)),
            );
            final monthly = calculateProductivity(
              data,
              now.subtract(const Duration(days: 30)),
            );

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 32),
              children: [
                _heroSection(weekly, monthly),
                const SizedBox(height: 18),
                _sectionHeader('Focus snapshot'),
                const SizedBox(height: 8),
                _quickStatsRow(weekly),
                const SizedBox(height: 20),
                _sectionHeader('Trend cards'),
                const SizedBox(height: 8),
                _trendCard('Last 7 days', weekly, Colors.deepPurple),
                const SizedBox(height: 12),
                _trendCard('Last 30 days', monthly, Colors.orangeAccent),
                const SizedBox(height: 20),
                _insightsList(weekly, monthly),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _heroSection(ProductivityMetrics weekly, ProductivityMetrics monthly) {
    final completion = (weekly.completionRate * 100).clamp(0, 100).toDouble();
    final onTime = (weekly.onTimeRate * 100).clamp(0, 100).toDouble();
    final efficiency = (weekly.efficiency * 100).clamp(0, 200).toDouble();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF8E54E9), Color(0xFF4776E6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withOpacity(0.25),
            blurRadius: 30,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Momentum check',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${weekly.totalTasks} tasks completed in the last week',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          _heroStat('Completion', completion, Icons.task_alt),
          const SizedBox(height: 10),
          _heroStat('On time', onTime, Icons.schedule_rounded),
          const SizedBox(height: 10),
          _heroStat('Efficiency', efficiency, Icons.flash_on),
          const SizedBox(height: 18),
          Wrap(
            spacing: 10,
            runSpacing: 8,
            children: [
              _pill('${weekly.onTimeCompleted} on-time', Icons.timelapse),
              _pill('${monthly.totalTasks} tasks in 30d', Icons.calendar_today),
            ],
          ),
        ],
      ),
    );
  }

  Widget _heroStat(String label, double value, IconData icon) {
    final normalized = (value / 100).clamp(0, 1).toDouble();
    return Row(
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: Color(0xFF2E6BFF).withOpacity(0.1),
          child: Icon(icon, color: Color(0xFF2E6BFF)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(label, style: const TextStyle(color: Color(0xFF5C6B8C))),
                  Text(
                    '${value.toStringAsFixed(0)}%',
                    style: const TextStyle(
                      color: Color(0xFF0D1B3D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: normalized,
                  minHeight: 6,
                  backgroundColor: Color(0xFF8DA6D8).withOpacity(0.2),
                  valueColor: const AlwaysStoppedAnimation(Color(0xFF2E6BFF)),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _pill(String label, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Color(0xFFF0F4FF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Color(0xFF2E6BFF), size: 16),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(color: Color(0xFF0D1B3D))),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    );
  }

  Widget _quickStatsRow(ProductivityMetrics metrics) {
    final completion = (metrics.completionRate * 100).clamp(0, 100);
    final onTime = (metrics.onTimeRate * 100).clamp(0, 100);
    final efficiency = (metrics.efficiency * 100).clamp(0, 200);

    return Row(
      children: [
        Expanded(
          child: _miniStat(
            'Completion',
            '${completion.toStringAsFixed(0)}%',
            Colors.deepPurple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat(
            'On-time',
            '${onTime.toStringAsFixed(0)}%',
            Colors.teal,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _miniStat(
            'Efficiency',
            '${efficiency.toStringAsFixed(0)}%',
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: Colors.black54)),
        ],
      ),
    );
  }

  Widget _trendCard(String label, ProductivityMetrics metrics, Color accent) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 24,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '${metrics.totalTasks} tasks',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _metricRow('Completion', metrics.completionRate, accent),
          const SizedBox(height: 10),
          _metricRow('On-time', metrics.onTimeRate, Colors.teal),
          const SizedBox(height: 10),
          _metricRow('Efficiency', metrics.efficiency, Colors.orange),
          const SizedBox(height: 12),
          Text(
            '${metrics.onTimeCompleted} on-time · ${(metrics.efficiency * 100).toStringAsFixed(0)}% effort efficiency',
            style: const TextStyle(color: Colors.black54, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _metricRow(String label, double ratio, Color color) {
    final pct = (ratio * 100).clamp(0, 200).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$pct%', style: TextStyle(color: color)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: (ratio).clamp(0, 1.5),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation(color),
          ),
        ),
      ],
    );
  }

  Widget _insightsList(
    ProductivityMetrics weekly,
    ProductivityMetrics monthly,
  ) {
    final delta = ((weekly.completionRate - monthly.completionRate) * 100)
        .toStringAsFixed(1);
    final trendingUp = (double.tryParse(delta) ?? 0) >= 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Insights'),
        const SizedBox(height: 12),
        _insightTile(
          title: 'Momentum ${trendingUp ? 'up' : 'down'}',
          subtitle: 'Completion shifted $delta pts vs your 30-day baseline.',
          icon: trendingUp ? Icons.trending_up : Icons.trending_down,
          color: trendingUp ? Colors.green : Colors.redAccent,
        ),
        const SizedBox(height: 8),
        _insightTile(
          title: 'On-time habits',
          subtitle:
              'You delivered ${weekly.onTimeCompleted} tasks on time this week.',
          icon: Icons.schedule_rounded,
          color: Colors.blueAccent,
        ),
        const SizedBox(height: 8),
        _insightTile(
          title: 'Time efficiency',
          subtitle:
              'Efficiency is ${(weekly.efficiency * 100).toStringAsFixed(0)}% across planned minutes.',
          icon: Icons.bolt,
          color: Colors.deepPurple,
        ),
      ],
    );
  }

  Widget _insightTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: Colors.black54)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
