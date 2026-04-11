import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'concept_validation_screen.dart';
import 'concept_video_validation_screen.dart';

class StudentPracticeQuizAttemptScreen extends StatefulWidget {
  final String classId;
  final String quizId; // 🔥 CHAPTER QUIZ ID (IMPORTANT)
  final String studentId;
  final String studentName;
  final String conceptName;
  final String practiceQuizId;

  const StudentPracticeQuizAttemptScreen({
    super.key,
    required this.classId,
    required this.quizId,
    required this.studentId,
    required this.studentName,
    required this.conceptName,
    required this.practiceQuizId,
  });

  @override
  State<StudentPracticeQuizAttemptScreen> createState() =>
      _StudentPracticeQuizAttemptScreenState();
}

class _StudentPracticeQuizAttemptScreenState
    extends State<StudentPracticeQuizAttemptScreen> {
  final Map<String, String> answers = {};
  int score = 0;
  bool submitted = false;

  /// 🔹 PRACTICE QUESTIONS
  CollectionReference get questionRef => FirebaseFirestore.instance
      .collection('practice_quizzes')
      .doc(widget.practiceQuizId)
      .collection('questions');

  /// 🔥 SINGLE SOURCE OF TRUTH (CHAPTER ATTEMPT)
  DocumentReference get chapterAttemptRef => FirebaseFirestore.instance
      .collection('quiz_attempts')
      .doc("${widget.classId}_${widget.quizId}_${widget.studentId}");

  /// ============================================================
  /// ✅ SUBMIT PRACTICE QUIZ (SAFE + PROGRESS-AWARE)
  /// ============================================================
  Future<void> submitPracticeQuiz(List<QueryDocumentSnapshot> questions) async {
    score = 0;

    for (final q in questions) {
      final data = q.data() as Map<String, dynamic>;
      if (answers[q.id] == data['correctAnswer']) {
        score++;
      }
    }

    /// 🔥 UPDATE CHAPTER ATTEMPT SAFELY
    final snap = await chapterAttemptRef.get();

    if (snap.exists) {
      final data = snap.data() as Map<String, dynamic>;

      final Map<String, dynamic> conceptMastery = Map<String, dynamic>.from(
        data['conceptMastery'] ?? {},
      );

      conceptMastery[widget.conceptName] = {
        ...(conceptMastery[widget.conceptName] ?? {}),
        'practiceScore': score,
        'lastPracticedAt': FieldValue.serverTimestamp(),
      };

      await chapterAttemptRef.update({'conceptMastery': conceptMastery});
    }

    setState(() => submitted = true);
  }

  /// ============================================================
  /// UI
  /// ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Practice: ${widget.conceptName}")),
      body: StreamBuilder<QuerySnapshot>(
        stream: questionRef.orderBy('order').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final questions = snapshot.data!.docs;

          if (submitted) {
            final passed = score >= (questions.length / 2);

            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Score: $score / ${questions.length}",
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (!passed) ...[
                    const Text(
                      "You need more practice.\nPlease try again.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          submitted = false;
                          answers.clear();
                        });
                      },
                      child: const Text("Retry Quiz"),
                    ),
                  ] else ...[
                    const Text(
                      "Good job! 🎉\nChoose how you want to validate this concept.",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 20),

                    /// ✍️ TEXT VALIDATION
                    ElevatedButton.icon(
                      icon: const Icon(Icons.edit),
                      label: const Text("Text Validation (100 words)"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConceptValidationScreen(
                              classId: widget.classId,
                              quizId: widget.quizId,
                              studentId: widget.studentId,
                              conceptName: widget.conceptName,
                              practiceScore: score,
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 12),

                    /// 🎥 VIDEO VALIDATION
                    ElevatedButton.icon(
                      icon: const Icon(Icons.videocam),
                      label: const Text("Video Validation (1 min)"),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ConceptVideoValidationScreen(
                              classId: widget.classId,
                              quizId: widget.quizId,
                              studentId: widget.studentId,
                              studentName: widget.studentName,
                              conceptName: widget.conceptName,
                              practiceScore: score,
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ],
              ),
            );
          }

          /// 🔹 QUESTIONS LIST
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              ...questions.map((q) {
                final data = q.data() as Map<String, dynamic>;
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['question'],
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ...List<String>.from(data['options']).map(
                          (opt) => RadioListTile<String>(
                            value: opt,
                            groupValue: answers[q.id],
                            title: Text(opt),
                            onChanged: (v) {
                              setState(() => answers[q.id] = v!);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              ElevatedButton(
                onPressed: () => submitPracticeQuiz(questions),
                child: const Text("Submit Practice Quiz"),
              ),
            ],
          );
        },
      ),
    );
  }
}
