import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        title: const Text(
          "Practice Weak Concepts",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
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
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No quiz attempts found"));
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
            return const Center(child: Text("No weak concepts 🎉"));
          }

          final weakConceptList = weakConcepts.toList();

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: weakConceptList.length,
            itemBuilder: (context, index) {
              final concept = weakConceptList[index];
              final mastery = masteryByConcept[concept];

              final bool validated =
                  mastery != null && mastery['validated'] == true;

              final int score = mastery != null
                  ? mastery['individualMasteryScore'] ?? 0
                  : 0;

              return Card(
                color: const Color(0xFF1E1E1E),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  title: Text(
                    concept,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        validated
                            ? "Mastered ($score%)"
                            : "Needs Practice ($score%)",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                        value: score / 100,
                        minHeight: 6,
                        backgroundColor: Colors.white.withOpacity(0.08),
                        valueColor: AlwaysStoppedAnimation(
                          validated ? Colors.greenAccent : Colors.orangeAccent,
                        ),
                      ),
                    ],
                  ),
                  trailing: Icon(
                    validated ? Icons.check_circle : Icons.play_circle_fill,
                    color: validated ? Colors.greenAccent : Colors.cyanAccent,
                  ),
                  onTap: () {
                    if (validated && score >= 80) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Concept already mastered 🎉"),
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
              );
            },
          );
        },
      ),
    );
  }
}
