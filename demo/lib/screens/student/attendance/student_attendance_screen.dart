import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/attendance_service.dart';
import '../../../utils/date_utils.dart';
import '../../../utils/attendance_calculator.dart';

class StudentAttendanceScreen extends StatelessWidget {
  final String classId;

  const StudentAttendanceScreen({super.key, required this.classId});

  String get studentId => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final attendanceService = AttendanceService();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8FF),
        title: const Text(
          'My Attendance',
          style: TextStyle(color: Color(0xFF0D1B3D)),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0D1B3D),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        centerTitle: true,
      ),
      body: FutureBuilder(
        future: _loadWeeklyAttendance(attendanceService),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!;
          final todayStatus = data['todayStatus'];
          final summary = data['summary'];

          return Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _todayStatusCard(todayStatus),
                const SizedBox(height: 16),
                _weeklySummaryCard(summary),
              ],
            ),
          );
        },
      ),
    );
  }

  Map<String, dynamic> _calculateWeeklySummary(
    List<QueryDocumentSnapshot> docs,
    String studentId,
  ) {
    int presentDays = 0;
    int absentDays = 0;

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;

      final List presentIds = List.from(data['presentStudentIds'] ?? []);
      final List absentIds = List.from(data['absentStudentIds'] ?? []);

      if (presentIds.contains(studentId)) {
        presentDays++;
      } else if (absentIds.contains(studentId)) {
        absentDays++;
      }
    }

    final totalDays = presentDays + absentDays;

    final percentage = totalDays == 0
        ? 0
        : ((presentDays / totalDays) * 100).round();

    return {
      'present': presentDays,
      'absent': absentDays,
      'total': totalDays,
      'percentage': percentage,
    };
  }

  /// 🔍 Load weekly attendance + today status
  Future<Map<String, dynamic>> _loadWeeklyAttendance(
    AttendanceService service,
  ) async {
    final now = DateTime.now();
    final start = startOfWeek(now);
    final end = endOfWeek(now);

    final weeklySnapshot = await service.fetchWeeklyAttendance(
      classId: classId,
      startDate: start,
      endDate: end,
    );

    String todayStatus = 'Not Marked';

    final todayDoc = await service.fetchAttendanceByDate(
      classId: classId,
      date: todayDate(),
    );

    if (todayDoc != null) {
      final presentIds = List<String>.from(todayDoc['presentStudentIds']);
      todayStatus = presentIds.contains(studentId) ? 'Present' : 'Absent';
    }

    final summary = AttendanceCalculator.calculateWeekly(
      studentId: studentId,
      docs: weeklySnapshot.docs,
    );

    return {'todayStatus': todayStatus, 'summary': summary};
  }

  /// 📘 Today status UI
  Widget _todayStatusCard(String status) {
    return Card(
      child: ListTile(
        title: const Text('Today'),
        trailing: Text(
          status,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: status == 'Present'
                ? Colors.green
                : status == 'Absent'
                ? Colors.red
                : Colors.grey,
          ),
        ),
      ),
    );
  }

  /// 📊 Weekly summary UI
  Widget _weeklySummaryCard(Map<String, dynamic> summary) {
    if (summary['totalDays'] == 0) {
      return const Text(
        "No attendance marked for this week yet",
        style: TextStyle(color: Colors.grey),
      );
    }

    return Card(
      margin: const EdgeInsets.only(top: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "This Week",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text("Total Days: ${summary['totalDays']}"),
            Text("Present: ${summary['presentDays']}"),
            Text("Absent: ${summary['totalDays'] - summary['presentDays']}"),
            const SizedBox(height: 8),
            Text(
              "Attendance: ${summary['percentage']}%",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
