import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'quiz_detail_screen.dart';

class QuizTabScreen extends StatelessWidget {
  final String classId;

  const QuizTabScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF), // Deep Blue Background
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('chapters')
            .orderBy('order')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E6BFF)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(context);
          }

          final chapters = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: chapters.length,
            itemBuilder: (context, index) {
              final chapterDoc = chapters[index];
              return _ChapterCard(
                classId: classId,
                chapterDoc: chapterDoc,
                index: index,
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFEAF3FF),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.book_outlined,
              size: 64,
              color: Colors.indigo.shade200,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            "No chapters found",
            style: TextStyle(
              color: Colors.indigo.shade100,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "No syllabus chapters available for this class yet.",
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFF5C6B8C), fontSize: 14),
          ),
          const SizedBox(height: 6),
          Text(
            "Add optional syllabus during class creation to auto-generate chapters and concepts.",
            textAlign: TextAlign.center,
            style: TextStyle(color: const Color(0xFF8DA6D8), fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class _ChapterCard extends StatelessWidget {
  final String classId;
  final QueryDocumentSnapshot chapterDoc;
  final int index;

  const _ChapterCard({
    required this.classId,
    required this.chapterDoc,
    required this.index,
  });

  @override
  Widget build(BuildContext context) {
    final data = chapterDoc.data() as Map<String, dynamic>;
    final String chapterName = data['title'] ?? data['name'] ?? 'Chapter';
    final int order = data['order'] ?? index + 1;
    final List<String> concepts = List<String>.from(data['concepts'] ?? []);

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('quizzes')
          .doc(chapterDoc.id)
          .snapshots(),
      builder: (context, quizSnap) {
        bool isCompleted = false;

        if (quizSnap.hasData && quizSnap.data!.exists) {
          final quizData = quizSnap.data!.data() as Map<String, dynamic>;
          isCompleted = quizData['status'] == 'published';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCompleted
                  ? Colors.green.withOpacity(0.3)
                  : const Color(0x1A2E6BFF),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E6BFF).withOpacity(0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Theme(
            data: Theme.of(context).copyWith(
              dividerColor:
                  Colors.transparent, // Remove expansion tile dividers
            ),
            child: ExpansionTile(
              iconColor: const Color(0xFF2E6BFF),
              collapsedIconColor: const Color(0xFFA5B2C8),
              tilePadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? Colors.green.withOpacity(0.2)
                      : const Color(0xFFEAF3FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCompleted
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked,
                  color: isCompleted ? Colors.green : const Color(0xFFA5B2C8),
                  size: 20,
                ),
              ),
              title: Text(
                "Chapter $order",
                style: const TextStyle(
                  color: Color(0xFF2E6BFF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  chapterName,
                  style: const TextStyle(
                    color: Color(0xFF0D1B3D),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              trailing: isCompleted
                  ? Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.5),
                        ),
                      ),
                      child: const Text(
                        "Published",
                        style: TextStyle(
                          color: Colors.green,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    )
                  : null, // Let default icon show if not completed
              children: [
                const Divider(color: Color(0x1A2E6BFF)),
                const SizedBox(height: 12),

                // Concepts List
                if (concepts.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          size: 16,
                          color: const Color(0xFFA5B2C8),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          "No concepts added yet",
                          style: const TextStyle(
                            color: Color(0xFF8DA6D8),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  ...concepts.map(
                    (concept) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Colors.indigo.shade200,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              concept,
                              style: TextStyle(
                                color: const Color(0xFF5C6B8C),
                                fontSize: 14,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                // Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QuizDetailScreen(
                            classId: classId,
                            conceptId: chapterDoc.id,
                            conceptName: chapterName,
                            order: order,
                            chapterConcepts: concepts,
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      isCompleted
                          ? Icons.visibility_rounded
                          : Icons.edit_note_rounded,
                      size: 18,
                      color: isCompleted
                          ? Colors.black
                          : const Color(0xFF2E6BFF),
                    ),
                    label: Text(
                      isCompleted ? "View Published Quiz" : "Manage Quiz",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: isCompleted
                            ? Colors.black
                            : const Color(0xFF2E6BFF),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCompleted
                          ? Colors.greenAccent
                          : Colors.transparent,
                      foregroundColor: isCompleted
                          ? Colors.black
                          : const Color(0xFF2E6BFF),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: isCompleted
                          ? null
                          : const BorderSide(color: Color(0xFF2E6BFF)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: isCompleted ? 2 : 0,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
