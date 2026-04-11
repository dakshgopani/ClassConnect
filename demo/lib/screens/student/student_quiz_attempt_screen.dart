import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'practice_concept_list_screen.dart';
import 'student_class_detail_screen.dart';
import '../../services/global_xp_service.dart';
import '../../services/class_xp_service.dart';

class StudentQuizAttemptScreen extends StatefulWidget {
  final String classId;
  final String quizId; // chapterId
  final String studentId;
  final String studentName;

  const StudentQuizAttemptScreen({
    super.key,
    required this.classId,
    required this.quizId,
    required this.studentId,
    required this.studentName,
  });

  @override
  State<StudentQuizAttemptScreen> createState() =>
      _StudentQuizAttemptScreenState();
}

class _StudentQuizAttemptScreenState extends State<StudentQuizAttemptScreen> {
  final Map<String, String> answers = {};
  bool submitted = false;
  int score = 0;

  /// 🔹 QUESTIONS (CHAPTER QUIZ ONLY)
  CollectionReference get questionRef {
    return FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('quizzes')
        .doc(widget.quizId)
        .collection('questions');
  }

  /// 🔹 ATTEMPT DOC
  DocumentReference get attemptRef {
    final attemptId = "${widget.classId}_${widget.quizId}_${widget.studentId}";
    return FirebaseFirestore.instance
        .collection('quiz_attempts')
        .doc(attemptId);
  }

  /// ============================================================
  /// ✅ SUBMIT QUIZ (FIXED SCORING + WEAK CONCEPT LOGIC)
  /// ============================================================
  Future<void> submitQuiz(List<QueryDocumentSnapshot> questions) async {
    score = 0;

    final Map<String, int> conceptMistakes = {};
    final Map<String, int> conceptTotal = {};

    for (final q in questions) {
      final data = q.data() as Map<String, dynamic>;

      final String concept = data['concept'] ?? 'unknown';
      final String? selected = answers[q.id];
      final String correct = data['correctAnswer'];

      // Total questions per concept
      conceptTotal[concept] = (conceptTotal[concept] ?? 0) + 1;

      // ❗ Skip unanswered questions
      if (selected == null) {
        conceptMistakes[concept] = (conceptMistakes[concept] ?? 0) + 1;
        continue;
      }

      // ✅ SAFE COMPARISON
      if (selected.trim().toLowerCase() == correct.trim().toLowerCase()) {
        score++;
      } else {
        conceptMistakes[concept] = (conceptMistakes[concept] ?? 0) + 1;
      }
    }

    /// 🔥 APPLY THRESHOLD (>= 40% wrong → weak)
    final List<String> weakConcepts = [];

    conceptMistakes.forEach((concept, mistakes) {
      final total = conceptTotal[concept] ?? 1;
      final errorRate = mistakes / total;

      if (errorRate >= 0.4) {
        weakConcepts.add(concept);
      }
    });

    /// 🔐 SAVE ATTEMPT
    await attemptRef.set({
      'classId': widget.classId,
      'chapterId': widget.quizId,
      'studentId': widget.studentId,
      'quizType': 'chapter',
      'score': score,
      'total': questions.length,
      'weakConcepts': weakConcepts,
      'submittedAt': FieldValue.serverTimestamp(),
    });

    /// 🎯 XP
    await GlobalXpService.awardXp(studentId: widget.studentId, xpToAdd: 15);

    await ClassXpService.awardClassXp(
      classId: widget.classId,
      studentId: widget.studentId,
      studentName: widget.studentName,
      xpToAdd: 15,
    );

    setState(() => submitted = true);
  }

  /// ============================================================
  /// 🔹 WEAK CONCEPT POPUP
  /// ============================================================
  Future<void> showWeakConceptPopup(BuildContext context) async {
    final snap = await attemptRef.get();
    if (!snap.exists) return;

    final data = snap.data() as Map<String, dynamic>;
    final List<String> weakConcepts = List<String>.from(
      data['weakConcepts'] ?? [],
    );

    // ✅ If no weak concepts, just do nothing or show a message
    if (weakConcepts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Great job! No weak concepts 🎉")),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1E2E52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          "Improve Your Learning 💡",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "You need more practice in these concepts:",
              style: TextStyle(color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 12),
            ...weakConcepts.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.orange,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // ✅ closes dialog ONLY
            },
            child: const Text("Later", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context); // close dialog

              // Navigate to StudentClassDetailScreen with Homework tab selected
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => StudentClassDetailScreen(
                    classId: widget.classId,
                    initialTabIndex: 2, // Homework tab index
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF3B82F6),
            ),
            child: const Text(
              "Practice Now",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  /// ============================================================
  /// UI
  /// ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        title: const Text(
          "Chapter Quiz",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: questionRef.orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white30),
            );
          }

          final questions = snapshot.data!.docs;

          if (submitted) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E2E52),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white),
                    ),
                    child: Column(
                      children: [
                        Text(
                          "Score: $score / ${questions.length}",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "${((score / questions.length) * 100).toStringAsFixed(1)}%",
                          style: TextStyle(
                            fontSize: 20,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: () => showWeakConceptPopup(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF3B82F6),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "Continue",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...questions.map((q) {
                final data = q.data() as Map<String, dynamic>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E1E1E),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.white, width: 1),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['question'],
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 16),
                        ...List<String>.from(data['options']).map(
                          (opt) => Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: answers[q.id] == opt
                                  ? const Color(0xFF3B82F6).withOpacity(0.2)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: answers[q.id] == opt
                                    ? const Color(0xFF3B82F6)
                                    : Colors.white.withOpacity(0.2),
                              ),
                            ),
                            child: RadioListTile<String>(
                              value: opt,
                              groupValue: answers[q.id],
                              title: Text(
                                opt,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                ),
                              ),
                              activeColor: const Color(0xFF3B82F6),
                              onChanged: (v) {
                                setState(() => answers[q.id] = v!);
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => submitQuiz(questions),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 8,
                    shadowColor: const Color(0xFF3B82F6).withOpacity(0.5),
                  ),
                  child: const Text(
                    "Submit Quiz",
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
