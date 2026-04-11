import 'package:flutter/material.dart';
import '../models/student_report.dart';

class ParentReportView extends StatelessWidget {
  final StudentReport report;

  const ParentReportView({super.key, required this.report});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Student Progress Report',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Text('Student: ${report.studentName}'),
          Text('Attendance: ${report.attendancePercent.toStringAsFixed(1)}%'),
          Text('Avg Quiz Score: ${report.avgQuizScore.toStringAsFixed(1)}%'),

          const SizedBox(height: 16),

          Text('Weak Areas:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...report.weakConcepts.map((w) => Text('• $w')),

          const SizedBox(height: 16),

          Text('Engagement Summary:',
              style: TextStyle(fontWeight: FontWeight.bold)),
          Text('PBL Submissions: ${report.pblSubmitted}'),
          Text('Community Posts: ${report.communityPosts}'),
          Text('Community Answers: ${report.communityAnswers}'),

          const SizedBox(height: 24),

          Text(
            'Overall Insight:',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(_generateInsight(report)),
        ],
      ),
    );
  }

  String _generateInsight(StudentReport r) {
    if (r.attendancePercent < 75) {
      return 'Attendance needs improvement. Regular presence is advised.';
    }
    if (r.avgQuizScore < 60) {
      return 'Academic performance needs support. Focus on weak areas.';
    }
    return 'Student is progressing well. Keep up the good work!';
  }
}
