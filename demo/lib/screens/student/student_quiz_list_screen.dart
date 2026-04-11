import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_quiz_attempt_screen.dart';

class StudentQuizListScreen extends StatelessWidget {
  final String classId;
  final String studentName;

  const StudentQuizListScreen({
    super.key,
    required this.classId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    final student = FirebaseAuth.instance.currentUser;

    if (student == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Quizzes")),

      /// ✅ FETCH STUDENT NAME FROM `students` COLLECTION
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .doc(student.uid)
            .snapshots(),
        builder: (context, studentSnap) {
          if (!studentSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!studentSnap.data!.exists) {
            return const Center(child: Text("Student profile not found"));
          }

          final studentData = studentSnap.data!.data() as Map<String, dynamic>;

          final String studentName = studentData['name'] ?? 'Student';

          return Column(
            children: [
              const Divider(),

              /* =====================================================
                 🔵 CHAPTER-WISE QUIZZES (POSTED BY TEACHER)
                 ===================================================== */
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('classes')
                      .doc(classId)
                      .collection('quizzes')
                      .where('status', isEqualTo: 'published')
                      .orderBy('conceptOrder')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final quizzes = snapshot.data!.docs;

                    if (quizzes.isEmpty) {
                      return const Center(
                        child: Text("No chapter quizzes available"),
                      );
                    }

                    return ListView.builder(
                      itemCount: quizzes.length,
                      itemBuilder: (_, i) {
                        final q = quizzes[i].data() as Map<String, dynamic>;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: ListTile(
                            title: Text(
                              "Quiz ${q['conceptOrder']} – ${q['conceptName']}",
                            ),
                            subtitle: const Text("Chapter assessment quiz"),
                            trailing: const Icon(Icons.arrow_forward),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => StudentQuizAttemptScreen(
                                    classId: classId,
                                    quizId: quizzes[i].id,
                                    studentId: student.uid,
                                    studentName: studentName,
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
              ),
            ],
          );
        },
      ),
    );
  }
}
