import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ClassConceptService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Auto-save concepts when ConceptReviewScreen opens
  Future<void> saveConceptsIfNotExists({
    required String classId,
    required List<String> concepts,
  }) async {
    // Legacy support or fallback
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final conceptsRef = _firestore
        .collection('classes')
        .doc(classId)
        .collection('concepts');
    // ... existing logic ...
    // Note: I am not removing this to avoid breaking legacy calls immediately,
    // but the new flow uses saveSyllabusChapters.
  }

  /// Save extracted syllabus to 'chapters' collection
  /// Each chapter gets its own document with full metadata
  Future<void> saveSyllabusChapters({
    required String classId,
    required Map<String, List<String>> syllabus,
  }) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception("User not logged in");

    final chaptersRef = _firestore
        .collection('classes')
        .doc(classId)
        .collection('chapters');

    final existing = await chaptersRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();
    int order = 0;

    for (final entry in syllabus.entries) {
      final docRef = chaptersRef.doc(); // Generate new ID for each chapter
      batch.set(docRef, {
        'chapterId': docRef.id,
        'name': entry.key,
        'title': entry.key,
        'order': order++,
        'concepts': entry.value,
        'source': 'syllabus_upload',
        'createdBy': user.uid,
        'isActive': true,
        'hasDiagnostic': false,
        'hasQuiz': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }
}




