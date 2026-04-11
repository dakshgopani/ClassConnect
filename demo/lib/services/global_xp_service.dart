import 'package:cloud_firestore/cloud_firestore.dart';

class GlobalXpService {
  static final FirebaseFirestore _firestore =
      FirebaseFirestore.instance;

  static int calculateLevel(int xp) {
    if (xp < 50) return 1;
    if (xp < 150) return 2;
    if (xp < 300) return 3;
    if (xp < 500) return 4;
    return 5;
  }

  static Future<void> awardXp({
    required String studentId,
    required int xpToAdd,
  }) async {
    final ref = _firestore.collection('students').doc(studentId);

    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);

      int currentXp = 0;
      if (snap.exists) {
        currentXp = snap.data()!['xp'] ?? 0;
      }

      final newXp = currentXp + xpToAdd;
      final newLevel = calculateLevel(newXp);

      tx.set(
        ref,
        {
          'xp': newXp,
          'level': newLevel,
          'lastXpUpdated': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }
}
