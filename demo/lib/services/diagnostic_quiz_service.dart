import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'gemini_diagnostic_service.dart';

class DiagnosticQuizService {
  static final _firestore = FirebaseFirestore.instance;
  static final _auth = FirebaseAuth.instance;

  /// Generate diagnostic quiz ONCE per class
  static Future<void> generateDiagnosticQuiz({
    required String classId,
    required List<Map<String, dynamic>> concepts,
  }) async {
    final quizDoc = _firestore
        .collection('classes')
        .doc(classId)
        .collection('diagnostic_quiz')
        .doc('main');

    final exists = await quizDoc.get();
    if (exists.exists) {
      print("⚠️ Diagnostic quiz already exists. Skipping generation.");
      return;
    }

    // ✅ Convert Firestore concept maps → List<String>
    final conceptNames = concepts.map((c) => c['name'].toString()).toList();

    print("🧠 Concepts sent to Gemini: $conceptNames");

    final questions = await GeminiDiagnosticQuizService.generateDiagnosticQuiz(
      concepts: conceptNames,
    );

    await quizDoc.set({
      'quizId': 'main',
      'type': 'diagnostic',
      'status': 'published',
      'createdAt': FieldValue.serverTimestamp(),
    });

    for (int i = 0; i < questions.length; i++) {
      await quizDoc.collection('questions').add({
        ...questions[i],
        'order': i + 1,
      });
    }

    print("🎉 Diagnostic quiz generated successfully");
  }
}
