import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceCalculator {
  static Map<String, dynamic> calculateWeekly({
    required String studentId,
    required List<QueryDocumentSnapshot> docs,
  }) {
    int totalDays = docs.length;
    int presentDays = 0;

    for (final doc in docs) {
      final presentIds =
      List<String>.from(doc['presentStudentIds']);

      if (presentIds.contains(studentId)) {
        presentDays++;
      }
    }

    final percentage =
    totalDays == 0 ? 0 : (presentDays / totalDays) * 100;

    return {
      'totalDays': totalDays,
      'presentDays': presentDays,
      'percentage': percentage.toStringAsFixed(1),
    };
  }
}
