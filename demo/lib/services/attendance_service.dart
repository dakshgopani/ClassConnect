import 'package:cloud_firestore/cloud_firestore.dart';
import '../utils/date_utils.dart';

class AttendanceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Generate attendance doc ID
  String _attendanceId(String classId, String date) {
    return "${classId}_$date";
  }

  /// Check if attendance already exists for today
  Future<bool> attendanceExistsToday({
    required String classId,
  }) async {
    final date = todayDate();
    final docId = _attendanceId(classId, date);

    final doc = await _db.collection('attendance').doc(docId).get();
    return doc.exists;
  }

  /// Save attendance (IMMUTABLE)
  Future<void> saveAttendance({
    required String classId,
    required String teacherId,
    required List<String> presentStudentIds,
    required List<String> absentStudentIds,
  }) async {
    final date = todayDate();
    final docId = _attendanceId(classId, date);

    final totalStudents =
        presentStudentIds.length + absentStudentIds.length;

    await _db.collection('attendance').doc(docId).set({
      'classId': classId,
      'teacherId': teacherId,
      'date': date,

      'presentStudentIds': presentStudentIds,
      'absentStudentIds': absentStudentIds,

      'totalStudents': totalStudents,
      'presentCount': presentStudentIds.length,
      'absentCount': absentStudentIds.length,

      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Fetch attendance for specific date
  Future<DocumentSnapshot?> fetchAttendanceByDate({
    required String classId,
    required String date,
  }) async {
    final docId = _attendanceId(classId, date);
    final doc = await _db.collection('attendance').doc(docId).get();
    return doc.exists ? doc : null;
  }

  /// Fetch weekly attendance for a class
  Future<QuerySnapshot> fetchWeeklyAttendance({
    required String classId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    return _db
        .collection('attendance')
        .where('classId', isEqualTo: classId)
        .where('date',
        isGreaterThanOrEqualTo:
        startDate.toIso8601String().substring(0, 10))
        .where('date',
        isLessThanOrEqualTo:
        endDate.toIso8601String().substring(0, 10))
        .get();
  }
}
