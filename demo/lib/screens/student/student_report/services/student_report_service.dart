import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/student_report.dart';

class StudentReportService {
  final _db = FirebaseFirestore.instance;

  Future<StudentReport> generateStudentReport(String studentId) async {
    // 1️⃣ Student info
    final studentDoc =
        await _db.collection('students').doc(studentId).get();

    final studentName = studentDoc['name'];
    final parentEmail = studentDoc['parentEmail'];

    // 2️⃣ Attendance
    final attendanceSnap = await _db
        .collection('attendance')
        .where('presentStudentIds', arrayContains: studentId)
        .get();

    final totalDays = attendanceSnap.docs.length;
    final attendancePercent =
        totalDays == 0 ? 0.0 : (attendanceSnap.docs.length / totalDays) * 100;

    // 3️⃣ Quiz performance
    final quizSnap = await _db
        .collection('quiz_attempts')
        .where('studentId', isEqualTo: studentId)
        .get();

    double avgQuizScore = 0;
    final Set<String> weakConcepts = {};

    if (quizSnap.docs.isNotEmpty) {
      double sum = 0;
      for (final q in quizSnap.docs) {
        sum += (q['score'] / q['total']) * 100;
        for (final wc in q['weakConcepts']) {
          weakConcepts.add(wc);
        }
      }
      avgQuizScore = sum / quizSnap.docs.length;
    }

    // 4️⃣ PBL
    final pblSnap = await _db
        .collection('students')
        .doc(studentId)
        .collection('submittedPBL')
        .get();

    // 5️⃣ Community engagement
    final postSnap = await _db
        .collection('community')
        .where('userId', isEqualTo: studentId)
        .get();

    final answerSnap = await _db
        .collectionGroup('answers')
        .where('userId', isEqualTo: studentId)
        .get();

    return StudentReport(
      studentId: studentId,
      studentName: studentName,
      parentEmail: parentEmail,
      attendancePercent: attendancePercent,
      avgQuizScore: avgQuizScore,
      weakConcepts: weakConcepts.toList(),
      pblSubmitted: pblSnap.docs.length,
      communityPosts: postSnap.docs.length,
      communityAnswers: answerSnap.docs.length,
    );
  }
}
