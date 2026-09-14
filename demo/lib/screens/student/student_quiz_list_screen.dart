import 'package:flutter/material.dart';
import 'package:demo/widgets/ui/cc_loading_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'student_quiz_attempt_screen.dart';
import 'package:demo/widgets/cc_breadcrumb_bar.dart';

class StudentQuizListScreen extends StatelessWidget {
  final String classId;
  final String studentName;
  final String? className;

  const StudentQuizListScreen({
    super.key,
    required this.classId,
    required this.studentName,
    this.className,
  });

  @override
  Widget build(BuildContext context) {
    final student = FirebaseAuth.instance.currentUser;

    if (student == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    final classTitle = className ?? 'Class';
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      body: Column(
        children: [
          CCBreadcrumbBar(
            items: [
              BreadcrumbItem(
                label: 'Classes',
                icon: Icons.school_rounded,
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              BreadcrumbItem(
                label: classTitle,
                onTap: () => Navigator.pop(context),
              ),
              const BreadcrumbItem(label: 'Quizzes'),
            ],
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('students')
                      .doc(student.uid)
                      .snapshots(),
                  builder: (context, studentSnap) {
                    if (!studentSnap.hasData) {
                      return const Center(child: CcLoadingAnimation());
                    }

                    if (!studentSnap.data!.exists) {
                      return const Center(child: Text("Student profile not found"));
                    }

                    final studentData = studentSnap.data!.data() as Map<String, dynamic>;
                    final String sName = studentData['name'] ?? studentName;

                    return StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('classes')
                          .doc(classId)
                          .collection('quizzes')
                          .where('status', isEqualTo: 'published')
                          .orderBy('conceptOrder')
                          .snapshots(),
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const Center(child: CcLoadingAnimation());
                        }

                        final quizzes = snapshot.data!.docs;

                        if (quizzes.isEmpty) {
                          return const Center(
                            child: Text("No chapter quizzes available", style: TextStyle(color: Color(0xFF5C6B8C))),
                          );
                        }

                        return ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                          itemCount: quizzes.length,
                          itemBuilder: (_, i) {
                            final q = quizzes[i].data() as Map<String, dynamic>;

                            return Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              color: Colors.white,
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFEC4899).withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(Icons.quiz_rounded, color: Color(0xFFEC4899), size: 24),
                                ),
                                title: Text(
                                  "Quiz ${q['conceptOrder']} – ${q['conceptName']}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0D1B3D),
                                    fontSize: 16,
                                  ),
                                ),
                                subtitle: const Text("Chapter assessment quiz", style: TextStyle(color: Color(0xFF5C6B8C))),
                                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Color(0xFF94A3B8)),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => StudentQuizAttemptScreen(
                                        classId: classId,
                                        quizId: quizzes[i].id,
                                        studentId: student.uid,
                                        studentName: sName,
                                        className: className,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
