import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../services/gemini_text_validation_service.dart';

class ConceptValidationScreen extends StatefulWidget {
  final String classId;
  final String quizId;
  final String studentId;
  final String conceptName;
  final int practiceScore;

  const ConceptValidationScreen({
    super.key,
    required this.classId,
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
    return Scaffold(
      appBar: AppBar(title: Text("Validate: ${widget.conceptName}")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Explain this concept in your own words (minimum 100 words):",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 220,
              child: TextField(
                controller: _controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                onChanged: (value) {
                  wordCountNotifier.value = calculateWordCount(value);
                },
                decoration: InputDecoration(
                  hintText:
                      "Start explaining here...\n\nExample: Breadth First Search works by...",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),

            ValueListenableBuilder<int>(
              valueListenable: wordCountNotifier,
              builder: (_, count, __) {
                return Text(
                  "Word count: $count / 100",
                  style: TextStyle(
                    color: count < 100 ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                );
              },
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submitting ? null : submitValidation,
                child: submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Submit Validation"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}