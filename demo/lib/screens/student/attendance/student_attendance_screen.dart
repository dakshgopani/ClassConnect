import 'package:flutter/material.dart';
import 'package:demo/widgets/ui/cc_loading_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../utils/date_utils.dart';
import 'package:demo/widgets/cc_breadcrumb_bar.dart';

class StudentAttendanceScreen extends StatelessWidget {
  final String classId;
  final String? className;

  const StudentAttendanceScreen({
    super.key,
    required this.classId,
    this.className,
  });

  static const Color _bg = Color(0xFFF4F8FF);
  static const Color _primary = Color(0xFF2E6BFF);
  static const Color _textPrimary = Color(0xFF0D1B3D);
  static const Color _textSecondary = Color(0xFF5C6B8C);

  @override
  Widget build(BuildContext context) {
    final classTitle = className ?? 'Class';
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          CCBreadcrumbBar(
            items: [
              BreadcrumbItem(
                label: 'Classes',
                icon: Icons.school_rounded,
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              BreadcrumbItem(
                label: classTitle,
                onTap: () => Navigator.pop(context),
              ),
              const BreadcrumbItem(label: 'Attendance'),
            ],
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1000),
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _loadAttendanceDashboard(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CcLoadingAnimation(color: _primary));
                    }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Failed to load attendance. Please try again.',
                  style: const TextStyle(color: _textSecondary),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final data = snapshot.data ?? <String, dynamic>{};
          final records =
              (data['records'] as List<Map<String, dynamic>>?) ??
              const <Map<String, dynamic>>[];
          final weekly =
              data['weekly'] as Map<String, dynamic>? ??
              const <String, dynamic>{};
          final monthly =
              data['monthly'] as Map<String, dynamic>? ??
              const <String, dynamic>{};
          final overall =
              data['overall'] as Map<String, dynamic>? ??
              const <String, dynamic>{};
          final todayStatus = data['todayStatus'] as String? ?? 'Not Marked';
          final currentStreak = data['currentStreak'] as int? ?? 0;
          final bestStreak = data['bestStreak'] as int? ?? 0;

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _overviewCard(
                  percent: (overall['percentage'] as double?) ?? 0,
                  present: (overall['present'] as int?) ?? 0,
                  absent: (overall['absent'] as int?) ?? 0,
                  total: (overall['total'] as int?) ?? 0,
                  todayStatus: todayStatus,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        title: 'This Week',
                        value:
                            '${((weekly['percentage'] as double?) ?? 0).toStringAsFixed(0)}%',
                        subtitle:
                            '${(weekly['present'] as int?) ?? 0}/${(weekly['total'] as int?) ?? 0} days',
                        icon: Icons.date_range_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metricCard(
                        title: 'This Month',
                        value:
                            '${((monthly['percentage'] as double?) ?? 0).toStringAsFixed(0)}%',
                        subtitle:
                            '${(monthly['present'] as int?) ?? 0}/${(monthly['total'] as int?) ?? 0} days',
                        icon: Icons.calendar_month_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _metricCard(
                        title: 'Current Streak',
                        value: '$currentStreak',
                        subtitle: 'Consecutive present days',
                        icon: Icons.local_fire_department_rounded,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _metricCard(
                        title: 'Best Streak',
                        value: '$bestStreak',
                        subtitle: 'Highest present streak',
                        icon: Icons.emoji_events_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Attendance History',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 10),
                if (records.isEmpty)
                  _emptyHistory()
                else
                  ...records.map(_historyTile),
              ],
            ),
          );
        },
      ),
    ),
  ),
),
],
),
);
}

  Future<Map<String, dynamic>> _loadAttendanceDashboard() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {
        'todayStatus': 'Not Marked',
        'weekly': _emptyBreakdown(),
        'monthly': _emptyBreakdown(),
        'overall': _emptyBreakdown(),
        'currentStreak': 0,
        'bestStreak': 0,
        'records': <Map<String, dynamic>>[],
      };
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('attendance')
        .where('classId', isEqualTo: classId)
        .get();

    final now = DateTime.now();
    final weekStart = startOfWeek(now);
    final weekEnd = endOfWeek(now);
    final thisMonthKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}';

    final records = <Map<String, dynamic>>[];
    int overallPresent = 0;
    int overallAbsent = 0;
    int weeklyPresent = 0;
    int weeklyAbsent = 0;
    int monthlyPresent = 0;
    int monthlyAbsent = 0;
    String todayStatus = 'Not Marked';

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final date = (data['date'] as String?) ?? '';
      final presentIds = List<String>.from(
        data['presentStudentIds'] ?? const [],
      );
      final absentIds = List<String>.from(data['absentStudentIds'] ?? const []);

      String status = 'Not Recorded';
      if (presentIds.contains(user.uid)) {
        status = 'Present';
      } else if (absentIds.contains(user.uid)) {
        status = 'Absent';
      }

      if (date == todayDate()) {
        todayStatus = status == 'Not Recorded' ? 'Not Marked' : status;
      }

      final parsedDate = _parseDate(date);

      if (status == 'Present') {
        overallPresent++;
      } else if (status == 'Absent') {
        overallAbsent++;
      }

      if (parsedDate != null &&
          !parsedDate.isBefore(weekStart) &&
          !parsedDate.isAfter(weekEnd)) {
        if (status == 'Present') {
          weeklyPresent++;
        } else if (status == 'Absent') {
          weeklyAbsent++;
        }
      }

      if (date.startsWith(thisMonthKey)) {
        if (status == 'Present') {
          monthlyPresent++;
        } else if (status == 'Absent') {
          monthlyAbsent++;
        }
      }

      records.add({'date': date, 'parsedDate': parsedDate, 'status': status});
    }

    records.sort((a, b) {
      final aDate = a['date'] as String;
      final bDate = b['date'] as String;
      return bDate.compareTo(aDate);
    });

    final streakData = _calculateStreaks(records);

    return {
      'todayStatus': todayStatus,
      'weekly': _buildBreakdown(weeklyPresent, weeklyAbsent),
      'monthly': _buildBreakdown(monthlyPresent, monthlyAbsent),
      'overall': _buildBreakdown(overallPresent, overallAbsent),
      'currentStreak': streakData['current'] ?? 0,
      'bestStreak': streakData['best'] ?? 0,
      'records': records,
    };
  }

  Map<String, dynamic> _emptyBreakdown() {
    return {'present': 0, 'absent': 0, 'total': 0, 'percentage': 0.0};
  }

  Map<String, dynamic> _buildBreakdown(int present, int absent) {
    final total = present + absent;
    final percentage = total == 0 ? 0.0 : (present / total) * 100;
    return {
      'present': present,
      'absent': absent,
      'total': total,
      'percentage': percentage,
    };
  }

  Map<String, int> _calculateStreaks(List<Map<String, dynamic>> records) {
    final sorted = List<Map<String, dynamic>>.from(records)
      ..sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    int current = 0;
    int best = 0;
    int running = 0;

    for (final record in sorted) {
      final status = record['status'] as String;
      if (status == 'Present') {
        running++;
        if (running > best) {
          best = running;
        }
      } else if (status == 'Absent') {
        running = 0;
      }
    }

    for (int i = records.length - 1; i >= 0; i--) {
      final status = records[i]['status'] as String;
      if (status == 'Present') {
        current++;
      } else if (status == 'Absent') {
        break;
      }
    }

    return {'current': current, 'best': best};
  }

  DateTime? _parseDate(String rawDate) {
    if (rawDate.isEmpty) return null;
    try {
      return DateTime.parse(rawDate);
    } catch (_) {
      return null;
    }
  }

  Widget _overviewCard({
    required double percent,
    required int present,
    required int absent,
    required int total,
    required String todayStatus,
  }) {
    final statusColor = todayStatus == 'Present'
        ? Colors.green
        : todayStatus == 'Absent'
        ? Colors.redAccent
        : _textSecondary;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A2E6BFF)),
        boxShadow: [
          BoxShadow(
            color: _primary.withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Overall Attendance',
            style: TextStyle(
              color: _textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${percent.toStringAsFixed(0)}%',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '$present/$total present',
                style: const TextStyle(color: _textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (percent / 100).clamp(0.0, 1.0),
              minHeight: 9,
              backgroundColor: const Color(0xFFE7EEFF),
              valueColor: const AlwaysStoppedAnimation<Color>(_primary),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _statusChip(
                'Today: $todayStatus',
                statusColor.withValues(alpha: 0.12),
                statusColor,
              ),
              const SizedBox(width: 8),
              _statusChip(
                'Absent: $absent',
                const Color(0x14FF5C5C),
                Colors.redAccent,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusChip(String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _metricCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0x1A2E6BFF)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: _primary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: _textPrimary,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: const TextStyle(color: _textSecondary, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _emptyHistory() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A2E6BFF)),
      ),
      child: const Text(
        'No attendance records available yet for this class.',
        style: TextStyle(color: _textSecondary),
      ),
    );
  }

  Widget _historyTile(Map<String, dynamic> record) {
    final status = record['status'] as String? ?? 'Not Recorded';
    final date = record['date'] as String? ?? '';

    final isPresent = status == 'Present';
    final isAbsent = status == 'Absent';
    final icon = isPresent
        ? Icons.check_circle_rounded
        : isAbsent
        ? Icons.cancel_rounded
        : Icons.help_rounded;
    final color = isPresent
        ? Colors.green
        : isAbsent
        ? Colors.redAccent
        : _textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A2E6BFF)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _formatDisplayDate(date),
              style: const TextStyle(
                color: _textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              status,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDisplayDate(String iso) {
    final date = _parseDate(iso);
    if (date == null) return iso.isEmpty ? 'Unknown Date' : iso;

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];

    final weekday = weekdays[date.weekday - 1];
    final month = months[date.month - 1];
    return '$weekday, ${date.day} $month ${date.year}';
  }
}
