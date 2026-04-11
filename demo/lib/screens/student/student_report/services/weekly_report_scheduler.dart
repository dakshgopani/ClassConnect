import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'student_report_service.dart';
import '../services/parent_report_export.dart';

class WeeklyReportScheduler {
  static final _db = FirebaseFirestore.instance;
  static Timer? _dailyTimer;

  /// Initialize daily report scheduler
  /// Sends reports every day at 10:25 PM
  static void initialize() {
    _scheduleDailyReports();
  }

  /// Stop the scheduler
  static void stop() {
    _dailyTimer?.cancel();
    _dailyTimer = null;
  }

  /// Schedule daily reports
  static void _scheduleDailyReports() {
    // Calculate time until next 6 PM
    final now = DateTime.now();
    final nextReport = _getNextReportTime(now);
    final duration = nextReport.difference(now);

    print('Next daily report scheduled for: $nextReport');
    print('Time until next report: ${duration.inHours} hours');

    // Schedule the first execution
    _dailyTimer = Timer(duration, () {
      _sendAllDailyReports();

      // Schedule recurring daily reports (every 24 hours)
      _dailyTimer = Timer.periodic(
        const Duration(days: 1),
        (_) => _sendAllDailyReports(),
      );
    });
  }

  /// Get next report time at 10:25 PM
  static DateTime _getNextReportTime(DateTime now) {
    var nextReport = DateTime(
      now.year,
      now.month,
      now.day,
      22, // 10 PM
      55, // 25 minutes
      0,
    );

    // If it's already past 10:25 PM today, schedule for tomorrow
    if (nextReport.isBefore(now)) {
      nextReport = nextReport.add(const Duration(days: 1));
    }

    return nextReport;
  }

  /// Send reports to all students
  static Future<void> _sendAllDailyReports() async {
    print('🕐 Starting daily report generation and email sending...');

    try {
      // Get all students
      final studentsSnapshot = await _db.collection('students').get();
      final reportService = StudentReportService();

      int successCount = 0;
      int failCount = 0;

      for (final studentDoc in studentsSnapshot.docs) {
        try {
          final studentId = studentDoc.id;
          final studentName = studentDoc['name'] ?? 'Unknown';
          final parentEmail = studentDoc['parentEmail'];

          if (parentEmail == null || parentEmail.isEmpty) {
            print('⚠️ Skipping $studentName - No parent email');
            continue;
          }

          print('📧 Generating report for: $studentName');

          // Generate report
          final report = await reportService.generateStudentReport(studentId);

          // Send email
          final success = await ParentReportExport.sendToParentEmail(
            report,
            customMessage:
                'Daily progress report for ${report.studentName}. This automated report is sent every day at 10:25 PM.',
          );

          if (success) {
            successCount++;
            print('✅ Sent to $parentEmail');

            // Log in Firestore
            await _logEmailSent(studentId, parentEmail, success: true);
          } else {
            failCount++;
            print('❌ Failed to send to $parentEmail');
            await _logEmailSent(studentId, parentEmail, success: false);
          }

          // Add delay to avoid rate limiting
          await Future.delayed(const Duration(seconds: 2));
        } catch (e) {
          failCount++;
          print('❌ Error processing student: $e');
        }
      }

      print(
        '✅ Daily report batch complete: $successCount sent, $failCount failed',
      );
    } catch (e) {
      print('❌ Error in daily report scheduler: $e');
    }
  }

  /// Manually trigger report sending (for testing)
  static Future<void> sendNow() async {
    print('🚀 Manual trigger - Sending daily reports now...');
    await _sendAllDailyReports();
  }

  /// Send report to a specific student (for testing)
  static Future<bool> sendToStudent(String studentId) async {
    try {
      final reportService = StudentReportService();
      final report = await reportService.generateStudentReport(studentId);

      final success = await ParentReportExport.sendToParentEmail(
        report,
        customMessage: 'Test report for ${report.studentName}.',
      );

      if (success) {
        await _logEmailSent(studentId, report.parentEmail, success: true);
      }

      return success;
    } catch (e) {
      print('Error sending test report: $e');
      return false;
    }
  }

  /// Log email sent in Firestore
  static Future<void> _logEmailSent(
    String studentId,
    String email, {
    required bool success,
  }) async {
    try {
      await _db.collection('email_logs').add({
        'studentId': studentId,
        'recipientEmail': email,
        'sentAt': FieldValue.serverTimestamp(),
        'success': success,
        'type': 'daily_report',
      });
    } catch (e) {
      print('Error logging email: $e');
    }
  }

  /// Get email sending history
  static Future<List<Map<String, dynamic>>> getEmailHistory({
    String? studentId,
    int limit = 50,
  }) async {
    Query query = _db
        .collection('email_logs')
        .orderBy('sentAt', descending: true)
        .limit(limit);

    if (studentId != null) {
      query = query.where('studentId', isEqualTo: studentId);
    }

    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => {'id': doc.id, ...doc.data() as Map<String, dynamic>})
        .toList();
  }
}
