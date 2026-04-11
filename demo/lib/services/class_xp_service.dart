import 'package:cloud_firestore/cloud_firestore.dart';

class ClassXpService {
  static Future<void> awardClassXp({
    required String classId,
    required String studentId,
    required String studentName,
    required int xpToAdd,
  }) async {
    final ref = FirebaseFirestore.instance
        .collection('class_leaderboard')
        .doc(classId)
        .collection('students')
        .doc(studentId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);

      final currentXp =
          snap.exists ? (snap.data()!['xp'] ?? 0) : 0;

      tx.set(
        ref,
        {
          'studentId': studentId,
          'studentName': studentName,
          'xp': currentXp + xpToAdd,
          'lastUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
