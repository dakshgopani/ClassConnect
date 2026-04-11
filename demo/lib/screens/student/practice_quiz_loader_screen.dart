import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/gemini_quiz_service.dart';
import 'student_practice_quiz_attempt_screen.dart';

class PracticeQuizLoaderScreen extends StatefulWidget {
  final String classId;
  final String studentId;
  final String studentName;
  final String conceptName;

  const PracticeQuizLoaderScreen({
    super.key,
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.conceptName,
  });

  @override
  State<PracticeQuizLoaderScreen> createState() =>
      _PracticeQuizLoaderScreenState();
}

class _PracticeQuizLoaderScreenState extends State<PracticeQuizLoaderScreen> {
  bool loading = true;
  late String practiceQuizId;

  @override
  void initState() {
    super.initState();
    _generatePracticeQuiz();
  }

  Future<void> _generatePracticeQuiz() async {
    final quizId = "practice_${widget.studentId}_${widget.conceptName}";

    final quizDoc = FirebaseFirestore.instance
        .collection('practice_quizzes')
        .doc(quizId);

    final exists = await quizDoc.get();

    if (!exists.exists) {
      final questions = await GeminiQuizService.generateQuizForConcept(
        conceptName: widget.conceptName,
      );

      await quizDoc.set({
        'quizId': quizId,
        'conceptName': widget.conceptName,
        'classId': widget.classId,
        'studentId': widget.studentId,
        'createdAt': FieldValue.serverTimestamp(),
      });

      for (int i = 0; i < questions.length; i++) {
        await quizDoc.collection('questions').add({
          ...questions[i],
          'order': i + 1,
        });
      }
    }

    setState(() {
      practiceQuizId = quizId;
      loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return StudentPracticeQuizAttemptScreen(
      classId: widget.classId,
      quizId: practiceQuizId,
      studentId: widget.studentId,
      studentName: widget.studentName,
      conceptName: widget.conceptName,
      practiceQuizId: practiceQuizId,
    );
  }
}
