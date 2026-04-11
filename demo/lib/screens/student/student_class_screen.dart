import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo/widgets/ui/cc_decorated_background.dart';
import 'student_class_detail_screen.dart';
import 'project_templates_screen.dart';

class StudentClassesPage extends StatelessWidget {
  const StudentClassesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const CcDecoratedBackground(
        child: Center(
          child: Text(
            "Not logged in",
            style: TextStyle(color: Color(0xFF0D1B3D)),
          ),
        ),
      );
    }

    return CcDecoratedBackground(
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('class_students')
            .where('studentId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "Your enrolled classes will appear here",
                style: TextStyle(color: Color(0xFF5C6B8C), fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          final classIds = snapshot.data!.docs
              .map((d) => d['classId'])
              .toList();

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .where(FieldPath.documentId, whereIn: classIds)
                .snapshots(),
            builder: (context, classSnapshot) {
              if (classSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
                );
              }

              if (!classSnapshot.hasData || classSnapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    "No classes found",
                    style: TextStyle(color: Color(0xFF0D1B3D)),
                  ),
                );
              }

              return ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 24,
                ),
                itemCount: classSnapshot.data!.docs.length + 1,
                itemBuilder: (context, index) {
                  if (index == classSnapshot.data!.docs.length) {
                    return _buildTemplateButton(context);
                  }

                  final doc = classSnapshot.data!.docs[index];
                  final data = doc.data() as Map<String, dynamic>;

                  return _buildModernClassCard(
                    context,
                    classId: doc.id,
                    data: data,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildModernClassCard(
    BuildContext context, {
    required String classId,
    required Map<String, dynamic> data,
  }) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => StudentClassDetailScreen(classId: classId),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF2E6BFF).withValues(alpha: 0.14),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E6BFF).withValues(alpha: 0.10),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Decorative background circle for flair
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.school_rounded,
                  size: 100,
                  color: const Color(0xFF00D9FF).withValues(alpha: 0.08),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    // Color Accent Bar
                    Container(
                      width: 4,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF00D9FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            data['class_name']?.toUpperCase() ??
                                'UNTITLED CLASS',
                            style: const TextStyle(
                              color: Color(0xFF0D1B3D),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            data['subject'] ?? 'General',
                            style: TextStyle(
                              color: const Color(0xFF2E6BFF),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _infoChip(
                                Icons.numbers,
                                data['class_code'] ?? '---',
                              ),
                              const SizedBox(width: 12),
                              _infoChip(
                                Icons.people_outline,
                                "${data['student_count'] ?? 0} Students",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Color(0xFF5C6B8C),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF3FF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: const Color(0xFF5C6B8C)),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF4A5A7A), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildTemplateButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 40),
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const ProjectTemplatesScreen(),
          ),
        ),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF00D9FF).withValues(alpha: 0.15),
                const Color(0xFF00D9FF).withValues(alpha: 0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF00D9FF).withValues(alpha: 0.4),
            ),
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.auto_awesome_motion_rounded, color: Color(0xFF00D9FF)),
              SizedBox(width: 12),
              Text(
                "Explore Project Templates",
                style: TextStyle(
                  color: Color(0xFF00D9FF),
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
