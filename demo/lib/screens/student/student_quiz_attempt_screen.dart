import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/theme/app_colors.dart';
import 'package:demo/theme/app_spacing.dart';
import 'package:demo/widgets/ui/cc_button.dart';
import 'package:demo/widgets/ui/cc_card.dart';
import 'package:demo/widgets/ui/cc_section_header.dart';
import 'package:demo/widgets/cc_breadcrumb_bar.dart';
import 'student_class_detail_screen.dart';
import '../../services/global_xp_service.dart';
import '../../services/class_xp_service.dart';

class StudentQuizAttemptScreen extends StatefulWidget {
  final String classId;
  final String? className;
  final String quizId; // chapterId
  final String studentId;
  final String studentName;

  const StudentQuizAttemptScreen({
    super.key,
    required this.classId,
    this.className,
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
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text(
          'Improve Your Learning',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'You need more practice in these concepts:',
              style: TextStyle(
                color: AppColors.textMuted.withValues(alpha: 0.95),
              ),
            ),
            const SizedBox(height: 12),
            ...weakConcepts.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.warning,
                      size: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        c,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
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
            child: const Text(
              'Later',
              style: TextStyle(color: AppColors.textMuted),
            ),
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
                    className: widget.className,
                    initialTabIndex: 2, // Homework tab index
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text(
              'Practice Now',
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
    final theme = Theme.of(context);
    final currentClassName = widget.className ?? 'Class';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            CCBreadcrumbBar(
              items: [
                BreadcrumbItem(
                  label: 'Classes',
                  onTap: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                ),
                BreadcrumbItem(
                  label: currentClassName,
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                BreadcrumbItem(
                  label: 'Quizzes',
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                ),
                const BreadcrumbItem(label: 'Chapter Quiz'),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: questionRef.orderBy('order').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }

                  final questions = snapshot.data!.docs;

                  if (submitted) {
                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 500),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CcCard(
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(AppSpacing.md),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: AppColors.primary.withValues(alpha: 0.25),
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Score: $score / ${questions.length}',
                                      style: theme.textTheme.headlineMedium?.copyWith(
                                        color: AppColors.textPrimary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '${((score / questions.length) * 100).toStringAsFixed(1)}%',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: AppColors.textMuted,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: AppSpacing.xl),
                            CcButton(
                              label: 'Continue',
                              icon: const Icon(
                                Icons.arrow_forward_rounded,
                                color: Colors.white,
                              ),
                              onPressed: () => showWeakConceptPopup(context),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 850),
                      child: ListView(
                        padding: const EdgeInsets.all(AppSpacing.lg),
                        children: [
                          const CcSectionHeader(
                            title: 'Answer All Questions',
                            subtitle:
                                'Pick one option for each question before submitting.',
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          ...questions.map((q) {
                            final data = q.data() as Map<String, dynamic>;
                            return CcCard(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: Padding(
                                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['question'],
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    ...List<String>.from(data['options']).map(
                                      (opt) => Container(
                                        margin: const EdgeInsets.only(bottom: 8),
                                        decoration: BoxDecoration(
                                          color: answers[q.id] == opt
                                              ? AppColors.primary.withValues(alpha: 0.12)
                                              : AppColors.surfaceAlt,
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: answers[q.id] == opt
                                                ? AppColors.primary
                                                : AppColors.primary.withValues(alpha: 0.18),
                                          ),
                                        ),
                                        child: RadioListTile<String>(
                                          value: opt,
                                          groupValue: answers[q.id],
                                          title: Text(
                                            opt,
                                            style: theme.textTheme.bodyLarge?.copyWith(
                                              color: AppColors.textPrimary,
                                            ),
                                          ),
                                          activeColor: AppColors.primary,
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
                          CcButton(
                            label: 'Submit Quiz',
                            icon: const Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                            ),
                            onPressed: () => submitQuiz(questions),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}