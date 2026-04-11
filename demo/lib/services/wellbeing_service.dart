import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:demo/models/wellbeing_data.dart';

/// Core engine for computing student wellbeing scores from Firestore data.
///
/// Wellbeing Score (0-100) weighted breakdown:
///   Quiz Performance  : 25%
///   Attendance Rate    : 20%
///   Assignment Completion: 15%
///   Community Engagement : 15%
///   XP Trend           : 15%
///   Score Consistency  : 10%
class WellbeingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton
  static final WellbeingService _instance = WellbeingService._();
  factory WellbeingService() => _instance;
  WellbeingService._();

  /// Compute wellbeing for all students belonging to a teacher's classes.
  Future<List<StudentWellbeing>> computeAllStudentWellbeing({
    required String teacherId,
  }) async {
    try {
      // 1. Get teacher's classes
      final classesSnap = await _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      final classIds = classesSnap.docs.map((d) => d.id).toList();
      if (classIds.isEmpty) return [];

      // 2. Collect unique student IDs
      Set<String> studentIds = {};
      for (final classId in classIds) {
        final csSnap = await _firestore
            .collection('class_students')
            .where('classId', isEqualTo: classId)
            .get();
        for (final doc in csSnap.docs) {
          studentIds.add(doc['studentId']);
        }
      }

      // 3. Get total PBLs for assignment completion calculation
      int totalPBLs = 0;
      for (final classDoc in classesSnap.docs) {
        final pblSnap = await classDoc.reference.collection('pbl').get();
        totalPBLs += pblSnap.docs.length;
      }

      // 4. Compute wellbeing for each student
      List<StudentWellbeing> results = [];
      for (final studentId in studentIds) {
        final wb = await _computeForStudent(
          studentId: studentId,
          teacherId: teacherId,
          totalPBLs: totalPBLs,
        );
        if (wb != null) results.add(wb);
      }

      // Sort by risk (high risk first)
      results.sort((a, b) => a.wellbeingScore.compareTo(b.wellbeingScore));

      return results;
    } catch (e) {
      debugPrint('WellbeingService error: $e');
      return [];
    }
  }

  Future<StudentWellbeing?> _computeForStudent({
    required String studentId,
    required String teacherId,
    required int totalPBLs,
  }) async {
    try {
      // --- Student profile ---
      final studentDoc =
          await _firestore.collection('students').doc(studentId).get();
      if (!studentDoc.exists) return null;
      final studentData = studentDoc.data()!;
      final studentName = studentData['name'] ?? 'Unknown';

      // --- Quiz Performance (0-100 scale) ---
      final quizSnap = await _firestore
          .collection('quiz_attempts')
          .where('studentId', isEqualTo: studentId)
          .get();

      double quizAvg = 0;
      List<double> quizScores = [];
      if (quizSnap.docs.isNotEmpty) {
        for (final q in quizSnap.docs) {
          final score = q['score'] as num?;
          final total = q['total'] as num?;
          if (score != null && total != null && total != 0) {
            quizScores.add((score / total) * 100);
          }
        }
        if (quizScores.isNotEmpty) {
          quizAvg = quizScores.reduce((a, b) => a + b) / quizScores.length;
        }
      }

      // --- Attendance Rate (0-100) ---
      final attendanceSnap = await _firestore
          .collection('attendance')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      int presentCount = 0;
      int totalSessions = 0;
      for (final att in attendanceSnap.docs) {
        final presentIds =
            att['presentStudentIds'] as List<dynamic>? ?? [];
        final absentIds =
            att['absentStudentIds'] as List<dynamic>? ?? [];
        if (presentIds.contains(studentId) ||
            absentIds.contains(studentId)) {
          totalSessions++;
          if (presentIds.contains(studentId)) presentCount++;
        }
      }
      double attendanceRate =
          totalSessions > 0 ? (presentCount / totalSessions) * 100 : 50;

      // --- Assignment Completion (0-100) ---
      final pblSubmissions = await _firestore
          .collection('students')
          .doc(studentId)
          .collection('submittedPBL')
          .get();
      double assignmentCompletion = totalPBLs > 0
          ? (pblSubmissions.docs.length / totalPBLs * 100).clamp(0, 100)
          : 50;

      // --- Community & XP from leaderboard ---
      double communityScore = 0;
      double xp = 0;

      final classesSnap = await _firestore
          .collection('classes')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      for (final classDoc in classesSnap.docs) {
        final lbSnap = await _firestore
            .collection('class_leaderboard')
            .doc(classDoc.id)
            .collection('students')
            .doc(studentId)
            .get();
        if (lbSnap.exists) {
          final lbData = lbSnap.data()!;
          communityScore += (lbData['community_score'] as num?)?.toDouble() ?? 0;
          xp += (lbData['xp'] as num?)?.toDouble() ?? 0;
        }
      }

      // Normalize community & XP to 0-100 (using reasonable caps)
      double communityNorm = (communityScore / 50 * 100).clamp(0, 100);
      double xpNorm = (xp / 200 * 100).clamp(0, 100);

      // --- Score Consistency (lower variance = better, 0-100) ---
      double consistency = 100;
      if (quizScores.length >= 2) {
        final mean = quizAvg;
        final variance = quizScores.fold<double>(
                0, (acc, s) => acc + (s - mean) * (s - mean)) /
            quizScores.length;
        final stdDev = variance > 0 ? _sqrt(variance) : 0;
        // Lower std dev = higher consistency. Cap at stdDev=40 → 0 consistency
        consistency = ((1 - (stdDev / 40)) * 100).clamp(0, 100);
      }

      // --- Weighted Wellbeing Score ---
      final breakdown = WellbeingBreakdown(
        quizComponent: quizAvg * 0.25,
        attendanceComponent: attendanceRate * 0.20,
        assignmentComponent: assignmentCompletion * 0.15,
        communityComponent: communityNorm * 0.15,
        xpComponent: xpNorm * 0.15,
        consistencyComponent: consistency * 0.10,
      );

      final wellbeingScore = breakdown.quizComponent +
          breakdown.attendanceComponent +
          breakdown.assignmentComponent +
          breakdown.communityComponent +
          breakdown.xpComponent +
          breakdown.consistencyComponent;

      // --- Risk Level ---
      final riskLevel = wellbeingScore >= 70
          ? RiskLevel.low
          : wellbeingScore >= 40
              ? RiskLevel.medium
              : RiskLevel.high;

      // --- Detect Alerts ---
      List<WellbeingAlert> alerts = _detectAlerts(
        quizAvg: quizAvg,
        attendanceRate: attendanceRate,
        assignmentCompletion: assignmentCompletion,
        communityNorm: communityNorm,
        xpNorm: xpNorm,
        wellbeingScore: wellbeingScore,
      );

      // --- Fetch historical trend ---
      List<double> trendScores = await _fetchTrend(studentId);

      // --- Store daily snapshot ---
      await _storeDailySnapshot(
        studentId: studentId,
        studentName: studentName,
        wellbeingScore: wellbeingScore,
        quizAvg: quizAvg,
        attendanceRate: attendanceRate,
        assignmentCompletion: assignmentCompletion,
        communityScore: communityScore,
        xp: xp,
      );

      return StudentWellbeing(
        studentId: studentId,
        studentName: studentName,
        wellbeingScore: wellbeingScore,
        riskLevel: riskLevel,
        alerts: alerts,
        breakdown: breakdown,
        trendScores: trendScores,
        computedAt: DateTime.now(),
        quizAvg: quizAvg,
        attendanceRate: attendanceRate,
        assignmentCompletion: assignmentCompletion,
        communityScore: communityScore,
        xp: xp,
      );
    } catch (e) {
      debugPrint('Error computing wellbeing for $studentId: $e');
      return null;
    }
  }

  List<WellbeingAlert> _detectAlerts({
    required double quizAvg,
    required double attendanceRate,
    required double assignmentCompletion,
    required double communityNorm,
    required double xpNorm,
    required double wellbeingScore,
  }) {
    List<WellbeingAlert> alerts = [];
    final now = DateTime.now();

    // Academic Stress: Low quiz but high attendance (trying but struggling)
    if (quizAvg < 40 && attendanceRate > 60) {
      alerts.add(WellbeingAlert(
        category: AlertCategory.academicStress,
        title: 'Academic Struggle Detected',
        message:
            'Quiz average is ${quizAvg.toStringAsFixed(0)}% despite ${attendanceRate.toStringAsFixed(0)}% attendance. Student is present but struggling with content.',
        severity: (1 - quizAvg / 100).clamp(0, 1),
        detectedAt: now,
      ));
    }

    // Emotional Distress: Sudden drop across all metrics
    if (quizAvg < 35 && attendanceRate < 50 && communityNorm < 20) {
      alerts.add(WellbeingAlert(
        category: AlertCategory.emotionalDistress,
        title: 'Possible Emotional Distress',
        message:
            'All engagement metrics are critically low. Quiz: ${quizAvg.toStringAsFixed(0)}%, Attendance: ${attendanceRate.toStringAsFixed(0)}%, Community: Low.',
        severity: 0.9,
        detectedAt: now,
      ));
    }

    // Disengagement: Low attendance + low community + declining XP
    if (attendanceRate < 50 && communityNorm < 15 && xpNorm < 25) {
      alerts.add(WellbeingAlert(
        category: AlertCategory.disengagement,
        title: 'Student Disengagement Warning',
        message:
            'Low attendance (${attendanceRate.toStringAsFixed(0)}%), minimal community activity, and low XP progression.',
        severity: 0.8,
        detectedAt: now,
      ));
    }

    // General low score alert
    if (wellbeingScore < 40 && alerts.isEmpty) {
      alerts.add(WellbeingAlert(
        category: AlertCategory.academicStress,
        title: 'Low Wellbeing Score',
        message:
            'Overall wellbeing score is ${wellbeingScore.toStringAsFixed(0)}/100. Multiple areas need attention.',
        severity: 0.7,
        detectedAt: now,
      ));
    }

    return alerts;
  }

  Future<List<double>> _fetchTrend(String studentId) async {
    try {
      final snapshots = await _firestore
          .collection('student_wellbeing')
          .doc(studentId)
          .collection('snapshots')
          .orderBy('date', descending: true)
          .limit(30)
          .get();

      return snapshots.docs
          .map((d) => (d['score'] as num?)?.toDouble() ?? 50)
          .toList()
          .reversed
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _storeDailySnapshot({
    required String studentId,
    required String studentName,
    required double wellbeingScore,
    required double quizAvg,
    required double attendanceRate,
    required double assignmentCompletion,
    required double communityScore,
    required double xp,
  }) async {
    try {
      final today = DateTime.now();
      final dateKey =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      await _firestore
          .collection('student_wellbeing')
          .doc(studentId)
          .collection('snapshots')
          .doc(dateKey)
          .set({
        'date': dateKey,
        'score': wellbeingScore,
        'quizAvg': quizAvg,
        'attendanceRate': attendanceRate,
        'assignmentCompletion': assignmentCompletion,
        'communityScore': communityScore,
        'xp': xp,
        'studentName': studentName,
        'timestamp': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error storing wellbeing snapshot: $e');
    }
  }

  /// Simple square root without dart:math import
  static double _sqrt(double x) {
    if (x <= 0) return 0;
    double guess = x / 2;
    for (int i = 0; i < 20; i++) {
      guess = (guess + x / guess) / 2;
    }
    return guess;
  }
}