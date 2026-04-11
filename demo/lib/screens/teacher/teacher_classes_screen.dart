import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'teacher_class_detail_screen.dart';
import 'package:demo/screens/teacher/pbl/pbl_main_screen.dart';
import 'package:demo/screens/teacher/quiz/quiz_tab_screen.dart';
import 'package:demo/screens/teacher/resources/teacher_resources_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'assignment/create_assignment_screen.dart';
import 'package:demo/widgets/ui/cc_decorated_background.dart';

class TeacherClassesPage extends StatefulWidget {
  const TeacherClassesPage({super.key});

  @override
  State<TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends State<TeacherClassesPage> {
  // 🔹 Fetch classes safely
  Stream<List<Map<String, dynamic>>> _fetchClasses() {
    final String teacherId = FirebaseAuth.instance.currentUser!.uid;

    return FirebaseFirestore.instance
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('created_at', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            final data = doc.data();

            return {
              'id': doc.id,
              'name': data['class_name'] ?? 'Untitled Class',
              'code': data['class_code'] ?? '------',
              'students': data.containsKey('student_count')
                  ? data['student_count']
                  : 0,
              'createdAt': data['created_at'],
            };
          }).toList();
        });
  }

  @override
  Widget build(BuildContext context) {
    return CcDecoratedBackground(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fetchClasses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF00D9FF)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                snapshot.error.toString(),
                style: const TextStyle(color: Color(0xFF0D1B3D)),
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                "📘 Your created classes will appear here",
                style: TextStyle(color: Color(0xFF5C6B8C), fontSize: 16),
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildModernClassCard(snapshot.data![index]);
            },
          );
        },
      ),
    );
  }

  // 🔹 Modern Class card with same UI as student
  Widget _buildModernClassCard(Map<String, dynamic> classData) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherClassDetailScreen(classId: classData['id']),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0x1A2E6BFF)),
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
                  color: const Color(0xFF00D9FF).withOpacity(0.03),
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
                            classData['name']?.toUpperCase() ??
                                'UNTITLED CLASS',
                            style: const TextStyle(
                              color: Color(0xFF0D1B3D),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _infoChip(
                                Icons.numbers,
                                classData['code'] ?? '---',
                              ),
                              const SizedBox(width: 12),
                              _infoChip(
                                Icons.people_outline,
                                "${classData['students']} Students",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Popup menu with modern icon
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: Color(0xFF7A89A8),
                      ),
                      onSelected: (value) => _handleAction(value, classData),
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'edit', child: Text('Edit')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                        PopupMenuItem(value: 'pbl', child: Text('PBL')),
                        PopupMenuItem(value: 'quiz', child: Text('Quiz')),
                        PopupMenuItem(
                          value: 'resources',
                          child: Text('Resources'),
                        ),
                        PopupMenuItem(
                          value: 'assignment',
                          child: Text('Assignment'),
                        ),
                      ],
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

  // 🔹 Search bar
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const TextField(
        decoration: InputDecoration(
          icon: Icon(Icons.search),
          hintText: 'Search classes...',
          border: InputBorder.none,
        ),
      ),
    );
  }

  // 🔹 Class list
  Widget _buildClassesList() {
    return Expanded(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fetchClasses(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No classes yet.\nUse “Create Class” to get started.',
                textAlign: TextAlign.center,
              ),
            );
          }

          return ListView.builder(
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              return _buildClassCard(snapshot.data![index]);
            },
          );
        },
      ),
    );
  }

  // 🔹 Class card
  Widget _buildClassCard(Map<String, dynamic> classData) {
    final Timestamp? ts = classData['createdAt'];

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  TeacherClassDetailScreen(classId: classData['id']),
            ),
          );
        },
        title: Text(
          classData['name'],
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),

        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Code: ${classData['code']}'),
            Text('Students: ${classData['students']}'),
            if (ts != null)
              Text(
                'Created: ${ts.toDate().toLocal().toString().split(".").first}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleAction(value, classData),
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'edit', child: Text('Edit')),
            PopupMenuItem(value: 'delete', child: Text('Delete')),
            PopupMenuItem(value: 'pbl', child: Text('PBL')),
            PopupMenuItem(value: 'quiz', child: Text('Quiz')),
            PopupMenuItem(value: 'resources', child: Text('Resources')),
            PopupMenuItem(value: 'assignment', child: Text('Assignment')),
          ],
        ),
      ),
    );
  }

  // 🔹 Actions
  void _handleAction(String action, Map<String, dynamic> classData) {
    switch (action) {
      case 'edit':
        debugPrint('Edit ${classData['name']}');
        break;
      case 'delete':
        debugPrint('Delete ${classData['name']}');
        break;
      case 'pbl':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PblMainScreen(
              classId: classData['id'],
              className: classData['name'],
              classCode: classData['code'],
            ),
          ),
        );
        break;
      case 'quiz':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => QuizTabScreen(classId: classData['id']),
          ),
        );
        break;
      case 'resources':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                TeacherResourcesScreen(classId: classData['id']),
          ),
        );
        break;
      case 'assignment':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                CreateAssignmentScreen(classId: classData['id']),
          ),
        );
        break;
    }
  }
}
