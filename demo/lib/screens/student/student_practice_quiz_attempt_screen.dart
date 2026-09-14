import 'package:flutter/material.dart';
import 'package:demo/widgets/ui/cc_loading_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/theme/app_colors.dart';
import 'package:demo/theme/app_spacing.dart';
import 'package:demo/widgets/ui/cc_button.dart';
import 'package:demo/widgets/ui/cc_card.dart';
import 'package:demo/widgets/cc_breadcrumb_bar.dart';
import 'concept_validation_screen.dart';
import 'concept_video_validation_screen.dart';

class StudentPracticeQuizAttemptScreen extends StatefulWidget {
  final String classId;
  final String? className;
  final String quizId; // 🔥 CHAPTER QUIZ ID (IMPORTANT)
  final String studentId;
  final String studentName;
  final String conceptName;
  final String practiceQuizId;

  const StudentPracticeQuizAttemptScreen({
    super.key,
    required this.classId,
    this.className,
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
                BreadcrumbItem(label: 'Practice: ${widget.conceptName}'),
              ],
            ),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: questionRef.orderBy('order').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CcLoadingAnimation());
                  }

                  final questions = snapshot.data!.docs;

                  if (submitted) {
                    final passed = score >= (questions.length / 2);

                    return Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 550),
                        child: Padding(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: CcCard(
                            padding: const EdgeInsets.all(AppSpacing.xl),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  "Score: $score / ${questions.length}",
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.md),
                                if (!passed) ...[
                                  Text(
                                    "You need more practice.\nPlease try again.",
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.lg),
                                  CcButton(
                                    label: "Retry Quiz",
                                    icon: const Icon(Icons.refresh_rounded, color: Colors.white),
                                    onPressed: () {
                                      setState(() {
                                        submitted = false;
                                        answers.clear();
                                      });
                                    },
                                  ),
                                ] else ...[
                                  Text(
                                    "Good job! 🎉\nChoose how you want to validate this concept.",
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xl),
                                  CcButton(
                                    label: "Text Validation (100 words)",
                                    icon: const Icon(Icons.edit_rounded, color: Colors.white),
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ConceptValidationScreen(
                                            classId: widget.classId,
                                            className: widget.className,
                                            quizId: widget.quizId,
                                            studentId: widget.studentId,
                                            conceptName: widget.conceptName,
                                            practiceScore: score,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: AppSpacing.md),
                                  CcButton(
                                    label: "Video Validation (1 min)",
                                    icon: const Icon(Icons.videocam_rounded, color: Colors.white),
                                    variant: CcButtonVariant.secondary,
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ConceptVideoValidationScreen(
                                            classId: widget.classId,
                                            className: widget.className,
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
                          ),
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
                          ...questions.map((q) {
                            final data = q.data() as Map<String, dynamic>;
                            return Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: CcCard(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      data['question'],
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppColors.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: AppSpacing.md),
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
                          const SizedBox(height: AppSpacing.md),
                          CcButton(
                            label: "Submit Practice Quiz",
                            icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                            onPressed: () => submitPracticeQuiz(questions),
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
