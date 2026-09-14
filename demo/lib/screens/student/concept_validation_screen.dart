import 'package:flutter/material.dart';
import 'package:demo/widgets/ui/cc_loading_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/theme/app_colors.dart';
import 'package:demo/theme/app_spacing.dart';
import 'package:demo/widgets/ui/cc_button.dart';
import 'package:demo/widgets/ui/cc_card.dart';
import 'package:demo/widgets/cc_breadcrumb_bar.dart';
import '../../../services/gemini_text_validation_service.dart';

class ConceptValidationScreen extends StatefulWidget {
  final String classId;
  final String? className;
  final String quizId;
  final String studentId;
  final String conceptName;
  final int practiceScore;

  const ConceptValidationScreen({
    super.key,
    required this.classId,
    this.className,
    required this.quizId,
    required this.studentId,
    required this.conceptName,
    required this.practiceScore,
  });

  @override
  State<ConceptValidationScreen> createState() =>
      _ConceptValidationScreenState();
}

class _ConceptValidationScreenState extends State<ConceptValidationScreen> {
  final TextEditingController _controller = TextEditingController();
  late final ValueNotifier<int> wordCountNotifier;
  bool submitting = false;

  @override
  void initState() {
    super.initState();
    wordCountNotifier = ValueNotifier<int>(0);
  }

  @override
  void dispose() {
    _controller.dispose();
    wordCountNotifier.dispose();
    super.dispose();
  }

  /// ✅ ROBUST WORD COUNT
  int calculateWordCount(String text) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return 0;

    return trimmed
        .replaceAll(RegExp(r'\n'), ' ')
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
  }

  String get attemptId =>
      "${widget.classId}_${widget.quizId}_${widget.studentId}";

  Future<void> submitValidation() async {
    if (wordCountNotifier.value < 100) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please write at least 100 words")),
      );
      return;
    }

    setState(() => submitting = true);

    final result = await GeminiTextValidationService.validateTextExplanation(
      conceptName: widget.conceptName,
      explanation: _controller.text,
    );

    /// ❌ REJECT IF GEMINI FAILS
    if (result['isRelevant'] != true || (result['confidence'] ?? 0.0) < 0.6) {
      setState(() => submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Your explanation does not clearly demonstrate understanding of "
            "${widget.conceptName}.\n\nReason: ${result['reason']}",
          ),
        ),
      );
      return;
    }

    final attemptRef = FirebaseFirestore.instance
        .collection('quiz_attempts')
        .doc(attemptId);

    final snap = await attemptRef.get();

    /// ✅ SAFE DATA INITIALIZATION
    final Map<String, dynamic> data = snap.exists && snap.data() != null
        ? snap.data()!
        : {};

    final Map<String, dynamic> conceptMastery = Map<String, dynamic>.from(
      data['conceptMastery'] ?? {},
    );

    final List<String> weakConcepts = List<String>.from(
      data['weakConcepts'] ?? [],
    );

    /// 🔢 CALCULATE INDIVIDUAL MASTERY SCORE
    int individualMasteryScore;
    if (widget.practiceScore >= 8) {
      individualMasteryScore = 90;
    } else if (widget.practiceScore >= 6) {
      individualMasteryScore = 75;
    } else {
      individualMasteryScore = 60;
    }

    /// ✅ UPDATE THIS CONCEPT
    conceptMastery[widget.conceptName] = {
      'quizScore': widget.practiceScore,
      'validated': true,
      'validationType': 'text',
      'individualMasteryScore': individualMasteryScore,
      'geminiConfidence': result['confidence'],
      'geminiReason': result['reason'],
      'explanation': _controller.text.trim(),
      'validatedAt': FieldValue.serverTimestamp(),
    };

    final validatedConcepts = conceptMastery.values
        .where((c) => c['validated'] == true)
        .toList();

    int masteryScore = 0;

    if (validatedConcepts.isNotEmpty) {
      masteryScore =
          (validatedConcepts
                      .map((c) => c['individualMasteryScore'] as int)
                      .reduce((a, b) => a + b) /
                  validatedConcepts.length)
              .round();
    }

    /// ✅ CREATE OR UPDATE DOC
    if (!snap.exists) {
      await attemptRef.set({
        'classId': widget.classId,
        'studentId': widget.studentId,
        'quizType': 'chapter',
        'weakConcepts': weakConcepts,
        'conceptMastery': conceptMastery,
        'masteryScore': masteryScore,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } else {
      await attemptRef.update({
        'conceptMastery': conceptMastery,
        'masteryScore': masteryScore,
      });
    }

    setState(() => submitting = false);

    /// ✅ SUCCESS UI
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: const Text("Concept Mastered 🎉"),
        content: Text(
          "You are now a master of ${widget.conceptName}.\n\n"
          "Overall Mastery Score: $masteryScore%",
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("Continue"),
          ),
        ],
      ),
    );
  }

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
                BreadcrumbItem(label: 'Validate: ${widget.conceptName}'),
              ],
            ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 850),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: CcCard(
                      padding: const EdgeInsets.all(AppSpacing.xl),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Explain this concept in your own words (minimum 100 words):",
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
                          SizedBox(
                            height: 220,
                            child: TextField(
                              controller: _controller,
                              maxLines: null,
                              keyboardType: TextInputType.multiline,
                              onChanged: (value) {
                                wordCountNotifier.value = calculateWordCount(value);
                              },
                              style: const TextStyle(color: AppColors.textPrimary),
                              decoration: InputDecoration(
                                filled: true,
                                fillColor: AppColors.surfaceAlt,
                                hintText:
                                    "Start explaining here...\n\nExample: Breadth First Search works by...",
                                hintStyle: const TextStyle(color: AppColors.textMuted),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.18),
                                  ),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: BorderSide(
                                    color: AppColors.primary.withValues(alpha: 0.18),
                                  ),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  borderSide: const BorderSide(
                                    color: AppColors.primary,
                                    width: 2,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          ValueListenableBuilder<int>(
                            valueListenable: wordCountNotifier,
                            builder: (_, count, __) {
                              return Text(
                                "Word count: $count / 100",
                                style: TextStyle(
                                  color: count < 100 ? AppColors.error : AppColors.success,
                                  fontWeight: FontWeight.bold,
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          SizedBox(
                            width: double.infinity,
                            child: CcButton(
                              label: submitting ? "Validating..." : "Submit Validation",
                              icon: submitting
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CcLoadingAnimation(strokeWidth: 2),
                                    )
                                  : const Icon(Icons.check_circle_rounded, color: Colors.white),
                              onPressed: submitting ? null : submitValidation,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}