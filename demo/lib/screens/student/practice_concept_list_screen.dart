import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/theme/app_colors.dart';
import 'package:demo/theme/app_spacing.dart';
import 'package:demo/widgets/ui/cc_card.dart';
import 'package:demo/widgets/ui/cc_section_header.dart';
import 'practice_quiz_loader_screen.dart';

class PracticeConceptListScreen extends StatelessWidget {
  final String classId;
  final String studentId;
  final String studentName;

  const PracticeConceptListScreen({
    super.key,
    required this.classId,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        title: const Text('Practice Weak Concepts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('quiz_attempts')
            .where('classId', isEqualTo: classId)
            .where('studentId', isEqualTo: studentId)
            .where('quizType', isEqualTo: 'chapter')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No quiz attempts found',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.textMuted,
                ),
              ),
            );
          }

          final Set<String> weakConcepts = {};
          final Map<String, Map<String, dynamic>> masteryByConcept = {};

          for (final doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;

            // 1️⃣ Collect weak concepts
            final List<String> wc = List<String>.from(
              data['weakConcepts'] ?? [],
            );
            weakConcepts.addAll(wc);

            // 2️⃣ Collect mastery SAFELY per concept
            final Map<String, dynamic> mastery = Map<String, dynamic>.from(
              data['conceptMastery'] ?? {},
            );

            mastery.forEach((concept, masteryData) {
              masteryByConcept[concept] = Map<String, dynamic>.from(
                masteryData,
              );
            });
          }

          if (weakConcepts.isEmpty) {
            return Center(
              child: Text(
                'No weak concepts',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: AppColors.success,
                ),
              ),
            );
          }

          final weakConceptList = weakConcepts.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: weakConceptList.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.lg),
                  child: CcSectionHeader(
                    title: 'Targeted Practice',
                    subtitle: 'Focus on weak concepts to improve mastery.',
                  ),
                );
              }

              final concept = weakConceptList[index - 1];
              final mastery = masteryByConcept[concept];
              final bool validated =
                  mastery != null && mastery['validated'] == true;
              final int score = mastery != null
                  ? mastery['individualMasteryScore'] ?? 0
                  : 0;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: CcCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.md,
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      concept,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.sm),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            validated
                                ? 'Mastered ($score%)'
                                : 'Needs Practice ($score%)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: score / 100,
                              minHeight: 7,
                              backgroundColor: AppColors.surfaceAlt,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                validated
                                    ? AppColors.success
                                    : AppColors.warning,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    trailing: Icon(
                      validated ? Icons.check_circle : Icons.play_circle_fill,
                      color: validated ? AppColors.success : AppColors.primary,
                    ),
                    onTap: () {
                      if (validated && score >= 80) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Concept already mastered'),
                          ),
                        );
                        return;
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PracticeQuizLoaderScreen(
                            classId: classId,
                            studentId: studentId,
                            studentName: studentName,
                            conceptName: concept,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}