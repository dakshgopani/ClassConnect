import 'package:demo/screens/student/attendance/student_attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/gemini_diagnostic_service.dart';
import 'student_quiz_list_screen.dart';
import 'student_quiz_attempt_screen.dart';
import 'practice_concept_list_screen.dart';
import 'class_leaderboard_screen.dart';
import 'pbl/student_pbl_selection_screen.dart';
import 'pbl/pbl_submission_sheet.dart';
import 'pbl/student_mini_project_detail_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'resources/student_resources_screen.dart';
import '../../services/gemini_homework_service.dart';
import 'assignment/student_assignment_detail_screen.dart';

class StudentClassDetailScreen extends StatefulWidget {
  final String classId;
  final int initialTabIndex;

  const StudentClassDetailScreen({
    super.key,
    required this.classId,
    this.initialTabIndex = 0,
  });

  @override
  State<StudentClassDetailScreen> createState() =>
      _StudentClassDetailScreenState();
}

class _StudentClassDetailScreenState extends State<StudentClassDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Set initial tab index after frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.initialTabIndex < _tabController.length) {
        _tabController.animateTo(widget.initialTabIndex);
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final student = FirebaseAuth.instance.currentUser;

    if (student == null) {
      return const Scaffold(body: Center(child: Text("User not logged in")));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      drawer: _buildDrawer(context, student),

      /// 🔹 FETCH STUDENT NAME AND CLASS DATA
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .snapshots(),
        builder: (context, classSnapshot) {
          if (!classSnapshot.hasData || !classSnapshot.data!.exists) {
            return Container(
              color: const Color(0xFFF4F8FF),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E6BFF)),
              ),
            );
          }

          final classData = classSnapshot.data!.data() as Map<String, dynamic>;
          final className = classData['class_name'] ?? 'Class';
          final canStudentPost = classData['studentCanPost'] == true;

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('students')
                .doc(student.uid)
                .snapshots(),
            builder: (context, studentSnap) {
              if (!studentSnap.hasData || !studentSnap.data!.exists) {
                return Container(
                  color: const Color(0xFFF4F8FF),
                  child: const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E6BFF)),
                  ),
                );
              }

              final studentData =
                  studentSnap.data!.data() as Map<String, dynamic>;
              final String studentName = studentData['name'] ?? 'Student';

              return Column(
                children: [
                  // Custom AppBar
                  Container(
                    color: const Color(0xFFF4F8FF),
                    padding: const EdgeInsets.only(top: 30),
                    child: Row(
                      children: [
                        Builder(
                          builder: (context) => IconButton(
                            icon: const Icon(
                              Icons.menu,
                              color: Color(0xFF0D1B3D),
                            ),
                            onPressed: () {
                              Scaffold.of(context).openDrawer();
                            },
                          ),
                        ),
                        Expanded(
                          child: Text(
                            className,
                            style: const TextStyle(
                              color: Color(0xFF0D1B3D),
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.arrow_back_ios_new_rounded,
                            color: Color(0xFF0D1B3D),
                          ),
                          onPressed: () {
                            Navigator.pop(context);
                          },
                        ),
                      ],
                    ),
                  ),

                  // Tab Bar
                  Container(
                    color: const Color(0xFFF4F8FF),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF2E6BFF),
                      labelColor: const Color(0xFF0D1B3D),
                      unselectedLabelColor: const Color(0xFF5C6B8C),
                      tabs: const [
                        Tab(text: "Posts"),
                        Tab(text: "Assignments"),
                        Tab(text: "Homework"),
                        Tab(text: "Details"),
                      ],
                    ),
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _PostsTab(
                          classId: widget.classId,
                          canStudentPost: canStudentPost,
                        ),
                        _AssignmentsTab(classId: widget.classId),
                        _HomeworkTab(
                          classId: widget.classId,
                          className: className,
                          studentName: studentName,
                          studentId: student.uid,
                        ),
                        _DetailsTab(
                          classData: classData,
                          studentName: studentName,
                          classId: widget.classId,
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// 🔹 SIDE NAVIGATION DRAWER
  Widget _buildDrawer(BuildContext context, User student) {
    return Drawer(
      backgroundColor: const Color(0xFFF4F8FF),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('students')
            .doc(student.uid)
            .snapshots(),
        builder: (context, studentSnap) {
          final studentData = studentSnap.data?.data() as Map<String, dynamic>?;
          final String studentName = studentData?['name'] ?? 'Student';

          return StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(widget.classId)
                .snapshots(),
            builder: (context, classSnapshot) {
              final classData =
                  classSnapshot.data?.data() as Map<String, dynamic>?;
              final className = classData?['class_name'] ?? 'Class';
              final pblEnabled = classData?['pblEnabled'] != false;

              return Column(
                children: [
                  // Modern Header with Gradient
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          const Color(0xFF1E3A8A),
                          const Color(0xFF3B82F6),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.school,
                            color: Colors.white,
                            size: 36,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          className,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          studentName,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Menu Items
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 16,
                      ),
                      children: [
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.link,
                          title: "Class Resources",
                          subtitle: "Notes & Materials",
                          iconColor: const Color(0xFF3B82F6),
                          onTap: () {
                            Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => StudentResourcesScreen(
                                  classId: widget.classId,
                                  className: className,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.quiz,
                          title: "Smart Quizzes",
                          subtitle: "Test your knowledge",
                          iconColor: const Color(0xFFEC4899),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => _QuizSection(
                                  classId: widget.classId,
                                  studentId: student.uid,
                                  studentName: studentName,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.bar_chart,
                          title: "Attendance",
                          subtitle: "Track your presence",
                          iconColor: const Color(0xFF10B981),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => StudentAttendanceScreen(
                                  classId: widget.classId,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        _buildModernMenuItem(
                          context: context,
                          icon: Icons.emoji_events,
                          title: "Leaderboard",
                          subtitle: "Your class ranking",
                          iconColor: const Color(0xFFFBBF24),
                          onTap: () {
                            // Navigator.pop(context);
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ClassLeaderboardScreen(
                                  classId: widget.classId,
                                ),
                              ),
                            );
                          },
                        ),
                        if (pblEnabled) ...[
                          const SizedBox(height: 20),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              "PROJECT-BASED LEARNING",
                              style: TextStyle(
                                color: const Color(0xFF0D1B3D).withOpacity(0.5),
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildModernMenuItem(
                            context: context,
                            icon: Icons.rocket_launch,
                            title: "My PBL Projects",
                            subtitle: "Active assignments",
                            iconColor: const Color(0xFF8B5CF6),
                            onTap: () {
                              Navigator.pop(context);
                              _showPblProjects(context, student.uid);
                            },
                          ),
                          const SizedBox(height: 8),
                          _buildModernMenuItem(
                            context: context,
                            icon: Icons.code,
                            title: "Mini Projects",
                            subtitle: "Your selections",
                            iconColor: const Color(0xFF06B6D4),
                            onTap: () {
                              Navigator.pop(context);
                              _showMiniProjects(context, student.uid);
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildModernMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1B3D).withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFF0D1B3D).withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: const Color(0xFF0D1B3D),
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: const Color(0xFF0D1B3D).withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  color: const Color(0xFF0D1B3D).withOpacity(0.3),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🔹 SHOW QUIZ OPTIONS
  void _showQuizOptions(
    BuildContext context,
    String studentId,
    String studentName,
  ) async {
    final attemptId = "${widget.classId}_${studentId}_diagnostic";
    final attemptSnap = await FirebaseFirestore.instance
        .collection('quiz_attempts')
        .doc(attemptId)
        .get();

    if (!attemptSnap.exists) {
      // Show diagnostic
      _handleDiagnosticFlow(context, studentName);
    } else {
      // Navigate to practice concepts
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PracticeConceptListScreen(
            classId: widget.classId,
            studentId: studentId,
            studentName: studentName,
          ),
        ),
      );
    }
  }

  /// 🔹 SHOW PBL PROJECTS
  void _showPblProjects(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            _PblProjectsScreen(classId: widget.classId, userId: userId),
      ),
    );
  }

  /// 🔹 SHOW MINI PROJECTS
  void _showMiniProjects(BuildContext context, String userId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _MiniProjectsScreen(
          classId: widget.classId,
          userId: userId,
          onSelectMiniProject: _selectMiniProject,
        ),
      ),
    );
  }

  /// 🔹 SELECT MINI PROJECT
  void _selectMiniProject(
    BuildContext context,
    String pblId,
    Map<String, dynamic> miniProject,
    String pblTitle,
  ) {
    final student = FirebaseAuth.instance.currentUser;
    if (student == null) return;

    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Confirm Selection',
          style: TextStyle(
            color: const Color(0xFF0D1B3D),
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to select this mini project?',
              style: TextStyle(color: Color(0xFF5C6B8C)),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF0D1B3D).withOpacity(0.05),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project: ${miniProject['title']}',
                    style: const TextStyle(
                      color: const Color(0xFF0D1B3D),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    miniProject['description'] ?? '',
                    style: const TextStyle(
                      color: Color(0xFF5C6B8C),
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Once selected, your steps and progress will be saved and personalized for this project.',
              style: TextStyle(color: Color(0xFF7A89A8), fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('Cancel', style: TextStyle(color: Color(0xFF7A89A8))),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _saveAndNavigateToDetail(
                context,
                pblId,
                miniProject,
                student.uid,
              );
            },
            child: Text(
              'Confirm',
              style: TextStyle(
                color: const Color(0xFF2E6BFF),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 SAVE AND NAVIGATE TO DETAIL SCREEN
  void _saveAndNavigateToDetail(
    BuildContext context,
    String pblId,
    Map<String, dynamic> miniProject,
    String studentId,
  ) {
    // Save selection to Firestore with timestamp for consistency
    FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('PBL')
        .doc(pblId)
        .collection('selections')
        .doc(studentId)
        .set({...miniProject, 'selectedAt': FieldValue.serverTimestamp()})
        .then((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("${miniProject['title']} selected successfully!"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );

          // Fetch PBL data to pass to detail screen
          FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId)
              .collection('PBL')
              .doc(pblId)
              .get()
              .then((pblDoc) {
                if (pblDoc.exists) {
                  final pblData = pblDoc.data() as Map<String, dynamic>;
                  // Navigate to personalized step screen
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StudentMiniProjectDetailScreen(
                        classId: widget.classId,
                        pblId: pblId,
                        studentId: studentId,
                        selectionData: miniProject,
                        pblData: pblData,
                      ),
                    ),
                  );
                }
              })
              .catchError((error) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Error loading project details: $error"),
                    backgroundColor: Colors.red,
                  ),
                );
              });
        })
        .catchError((error) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error saving selection: $error"),
              backgroundColor: Colors.red,
            ),
          );
        });
  }

  /// 🔹 HANDLE DIAGNOSTIC FLOW
  Future<void> _handleDiagnosticFlow(
    BuildContext context,
    String studentName,
  ) async {
    final student = FirebaseAuth.instance.currentUser;
    if (student == null) return;

    final String attemptId = "diagnostic_${widget.classId}_${student.uid}";

    final attemptRef = FirebaseFirestore.instance
        .collection('quiz_attempts')
        .doc(attemptId);

    final attemptSnap = await attemptRef.get();

    // ✅ 1. IF STUDENT HAS ALREADY GIVEN DIAGNOSTIC → DO NOTHING
    // UI (_QuizSection) WILL SHOW "IMPROVE WEAK CONCEPTS"
    if (attemptSnap.exists) {
      return;
    }

    // ✅ 2. CHECK IF DIAGNOSTIC QUIZ EXISTS FOR CLASS
    final diagRef = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('diagnostic_quiz');

    final metaSnap = await diagRef.doc('meta').get();

    // 🔥 3. GENERATE DIAGNOSTIC ONLY ONCE PER CLASS
    if (!metaSnap.exists) {
      final conceptSnap = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('concepts')
          .orderBy('order')
          .get();

      if (conceptSnap.docs.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Syllabus not uploaded yet")),
        );
        return;
      }

      final List<String> concepts = conceptSnap.docs
          .map((d) => d['name'] as String)
          .toList();

      final questions =
          await GeminiDiagnosticQuizService.generateDiagnosticQuiz(
            concepts: concepts,
          );

      await diagRef.doc('meta').set({
        'createdAt': FieldValue.serverTimestamp(),
        'totalQuestions': questions.length,
      });

      for (int i = 0; i < questions.length; i++) {
        await diagRef.doc('questions').collection('items').add({
          ...questions[i],
          'order': i + 1,
        });
      }
    }

    // ✅ 4. START DIAGNOSTIC QUIZ FOR THIS STUDENT
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => StudentQuizAttemptScreen(
          classId: widget.classId,
          quizId: 'diagnostic',
          studentId: student.uid,
          studentName: studentName,
          // isDiagnostic: true,
        ),
      ),
    );
  }
}

/* ============================================================
     ===================== QUIZ SECTION =========================
     ============================================================ */

class _QuizSection extends StatelessWidget {
  final String classId;
  final String studentId;
  final String studentName;

  const _QuizSection({
    required this.classId,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        elevation: 0,
        backgroundColor: const Color(0xFFF4F8FF),
        foregroundColor: const Color(0xFF0D1B3D),
        title: const Text("Concept Practice"),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0D1B3D),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('quiz_attempts')
              .where('classId', isEqualTo: classId)
              .where('studentId', isEqualTo: studentId)
              .snapshots(),
          builder: (context, snapshot) {
            // 🔄 Loading
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFF7A89A8)),
              );
            }

            // ❌ No data
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return _InfoCard(
                title: "No chapter quiz attempted yet",
                subtitle: "Attempt quizzes from Posts",
              );
            }

            /// ✅ FILTER ONLY CHAPTER QUIZZES
            final chapterAttempts = snapshot.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              return data['chapterId'] != null;
            }).toList();

            if (chapterAttempts.isEmpty) {
              return _InfoCard(
                title: "No chapter quiz attempted yet",
                subtitle: "Attempt quizzes from Posts",
              );
            }

            /// ✅ MERGE WEAK CONCEPTS
            final Set<String> weakConcepts = {};

            for (final doc in chapterAttempts) {
              final data = doc.data() as Map<String, dynamic>;
              final List<String> wc = List<String>.from(
                data['weakConcepts'] ?? [],
              );
              weakConcepts.addAll(wc);
            }

            /// 🔴 WEAK CONCEPT PRACTICE
            if (weakConcepts.isNotEmpty) {
              return _ImproveConceptsCard(
                weakConcepts: weakConcepts.toList(),
                masteryScore: (weakConcepts.length * 10).clamp(20, 100),
                classId: classId,
                studentName: studentName,
              );
            }

            /// 🟢 FREE PRACTICE
            return _ConceptQuizCard(
              classId: classId,
              studentId: studentId,
              studentName: studentName,
            );
          },
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final String subtitle;

  const _InfoCard({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: ListTile(
          leading: const Icon(
            Icons.info_outline,
            color: Color(0xFF1E3A8A),
            size: 28,
          ),
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          subtitle: Text(subtitle),
        ),
      ),
    );
  }
}

class _ImproveConceptsCard extends StatelessWidget {
  final List<String> weakConcepts;
  final int masteryScore;
  final String classId;
  final String studentName;

  const _ImproveConceptsCard({
    required this.weakConcepts,
    required this.masteryScore,
    required this.classId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF), // app theme bg

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x1A2E6BFF)),
          ),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Improve Your Weak Concepts 🚀",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Color(0xFF0D1B3D),
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  "Weak concepts: ${weakConcepts.length}",
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5C6B8C),
                  ),
                ),

                const SizedBox(height: 12),

                LinearProgressIndicator(
                  value: masteryScore / 100,
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(8),
                  color: const Color(0xFF2E6BFF),
                  backgroundColor: const Color(0x1A2E6BFF),
                ),

                const SizedBox(height: 16),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E6BFF),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PracticeConceptListScreen(
                            classId: classId,
                            studentId: FirebaseAuth.instance.currentUser!.uid,
                            studentName: studentName,
                          ),
                        ),
                      );
                    },
                    child: const Text("Practice Weak Concepts"),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ConceptQuizCard extends StatelessWidget {
  final String classId;
  final String studentId;
  final String studentName;

  const _ConceptQuizCard({
    required this.classId,
    required this.studentId,
    required this.studentName,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.quiz),
        title: const Text("Concept Quizzes"),
        subtitle: const Text("Practice all concepts"),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PracticeConceptListScreen(
                classId: classId,
                studentId: studentId,
                studentName: studentName,
              ),
            ),
          );
        },
      ),
    );
  }
}

/* ============================================================
   ===================== TAB SCREENS ==========================
   ============================================================ */

class _PostsTab extends StatefulWidget {
  final String classId;
  final bool canStudentPost;

  const _PostsTab({required this.classId, required this.canStudentPost});

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  final TextEditingController _messageController = TextEditingController();
  bool _isPosting = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _sendStudentPost() async {
    final student = FirebaseAuth.instance.currentUser;
    final message = _messageController.text.trim();

    if (student == null || message.isEmpty) return;

    setState(() => _isPosting = true);
    try {
      final studentDoc = await FirebaseFirestore.instance
          .collection('students')
          .doc(student.uid)
          .get();
      final studentName =
          (studentDoc.data()?['name'] as String?) ??
          student.displayName ??
          'Student';

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('posts')
          .add({
            'type': 'student_post',
            'message': message,
            'studentId': student.uid,
            'studentName': studentName,
            'publishedAt': FieldValue.serverTimestamp(),
          });

      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to post: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isPosting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final student = FirebaseAuth.instance.currentUser;

    if (student == null) {
      return const Center(child: Text("User not logged in"));
    }

    return Container(
      color: const Color(0xFFF4F8FF),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('posts')
                  .orderBy('publishedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final quizzes = snapshot.data!.docs;

                if (quizzes.isEmpty) {
                  return const Center(
                    child: Text(
                      "No posts yet",
                      style: TextStyle(fontSize: 16, color: Color(0xFF5C6B8C)),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: quizzes.length,
                  itemBuilder: (context, index) {
                    final quizDoc = quizzes[index];
                    final data = quizDoc.data() as Map<String, dynamic>;

                    final String postType = data['type'] ?? 'chapter_quiz';

                    if (postType == 'student_post') {
                      final String content = data['message'] ?? '';
                      final String studentName =
                          data['studentName'] ?? 'Student';
                      final Timestamp publishedAt =
                          data['publishedAt'] ?? Timestamp.now();

                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: const Color(0xFF2E6BFF).withOpacity(0.2),
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(
                                    Icons.person,
                                    color: Color(0xFF2E6BFF),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      studentName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF0D1B3D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(
                                content,
                                style: const TextStyle(
                                  color: Color(0xFF0D1B3D),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "Posted: ${publishedAt.toDate().toLocal().toString().split(' ')[0]}",
                                style: const TextStyle(
                                  color: Color(0xFF7A89A8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // 🔹 ANNOUNCEMENT POST
                    if (postType == 'announcement') {
                      final String title = data['title'] ?? 'Announcement';
                      final String content = data['message'] ?? '';
                      final Timestamp publishedAt =
                          data['publishedAt'] ?? Timestamp.now();

                      return Card(
                        color: Colors.white,
                        elevation: 2,
                        margin: const EdgeInsets.only(bottom: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Colors.orange.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              /// 🔹 HEADER WITH ANNOUNCEMENT ICON
                              Row(
                                children: [
                                  const Icon(
                                    Icons.notifications_active,
                                    color: Colors.orangeAccent,
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF0D1B3D),
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              /// 🔹 ANNOUNCEMENT CONTENT
                              Text(
                                content,
                                style: const TextStyle(
                                  color: const Color(0xFF0D1B3D),
                                  fontSize: 18,
                                  // height: 1.5,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),

                              const SizedBox(height: 12),

                              /// 🔹 PUBLISHED DATE
                              Text(
                                "Posted: ${publishedAt.toDate().toLocal().toString().split(' ')[0]}",
                                style: TextStyle(
                                  color: Color(0xFF7A89A8),
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    // 🔹 CHAPTER QUIZ POST
                    final String chapterName =
                        data['chapterName'] ?? 'Chapter Quiz';

                    final Timestamp publishedAt =
                        data['publishedAt'] ?? Timestamp.now();

                    // ⏰ Deadline = 7 days after publish
                    final DateTime deadline = publishedAt.toDate().add(
                      const Duration(days: 7),
                    );

                    final bool isExpired = DateTime.now().isAfter(deadline);

                    return Card(
                      color: Colors.white,
                      elevation: 3,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: const BorderSide(color: Color(0x1A2E6BFF)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// 🔹 HEADER
                            Row(
                              children: [
                                const Icon(
                                  Icons.assignment,
                                  color: Color(0xFF2E6BFF),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    chapterName,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF0D1B3D),
                                    ),
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 8),

                            /// 🔹 DEADLINE
                            Text(
                              isExpired
                                  ? "Deadline passed"
                                  : "Deadline: ${deadline.toLocal().toString().split(' ')[0]}",
                              style: TextStyle(
                                color: isExpired
                                    ? Colors.redAccent
                                    : Colors.greenAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),

                            const SizedBox(height: 12),

                            /// 🔹 ACTION
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                icon: Icon(
                                  isExpired ? Icons.lock : Icons.play_arrow,
                                  color: Colors.black,
                                ),
                                label: Text(
                                  isExpired ? "Quiz Closed" : "Attempt Quiz",
                                  style: const TextStyle(color: Colors.black),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isExpired
                                      ? Colors.grey.shade300
                                      : const Color(0xFF2E6BFF),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                                onPressed: isExpired
                                    ? null
                                    : () {
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                StudentQuizAttemptScreen(
                                                  classId: widget.classId,
                                                  quizId:
                                                      quizDoc.id, // chapterId
                                                  studentId: student.uid,
                                                  studentName:
                                                      student.displayName ??
                                                      "Student",
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
                  },
                );
              },
            ),
          ),
          if (widget.canStudentPost)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      enabled: !_isPosting,
                      decoration: InputDecoration(
                        hintText: 'Write a post...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: _isPosting ? null : _sendStudentPost,
                    icon: _isPosting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _AssignmentsTab extends StatelessWidget {
  final String classId;

  const _AssignmentsTab({super.key, this.classId = ''});

  @override
  Widget build(BuildContext context) {
    if (classId.isEmpty) return const SizedBox();

    return Container(
      color: const Color(0xFFF4F8FF),
      child: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('assignments')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E6BFF)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.assignment_outlined,
                    size: 60,
                    color: Color(0xFFB5C3DE),
                  ),
                  SizedBox(height: 16),
                  Text(
                    "No assignments yet",
                    style: TextStyle(color: Color(0xFF5C6B8C), fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;

              return Card(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: Color(0x1A2E6BFF)),
                ),
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0x142E6BFF),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.assignment,
                      color: Color(0xFF2E6BFF),
                    ),
                  ),
                  title: Text(
                    data['title'] ?? 'Untitled Assignment',
                    style: const TextStyle(
                      color: const Color(0xFF0D1B3D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    data['description'] ?? '',
                    style: const TextStyle(color: Color(0xFF5C6B8C)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios,
                    color: Color(0xFFA5B2C8),
                    size: 16,
                  ),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentAssignmentDetailScreen(
                          classId: classId,
                          assignmentId: doc.id,
                          assignmentData: data,
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

class _HomeworkTab extends StatefulWidget {
  final String classId;
  final String className;
  final String studentName;
  final String studentId;

  const _HomeworkTab({
    required this.classId,
    required this.className,
    required this.studentName,
    required this.studentId,
  });

  @override
  State<_HomeworkTab> createState() => _HomeworkTabState();
}

class _HomeworkTabState extends State<_HomeworkTab> {
  bool _isLoading = false;

  /// 🔹 GENERATE HOMEWORK
  Future<void> _generateHomework(List<String> weakConcepts) async {
    setState(() => _isLoading = true);

    try {
      final homeworkData = await GeminiHomeworkService.generateHomework(
        weakConcepts: weakConcepts,
        className: widget.className,
      );

      // Save to Firestore
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .collection('homework')
          .add({
            'classId': widget.classId,
            'className': widget.className,
            'createdAt': FieldValue.serverTimestamp(),
            'status': 'pending',
            'weakConcepts': weakConcepts,
            'data': homeworkData,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Homework generated successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🔹 SUBMIT HOMEWORK
  Future<void> _submitHomework(
    String homeworkDocId,
    Map<String, String> answers,
    PlatformFile? attachedFile,
  ) async {
    setState(() => _isLoading = true);

    try {
      String? fileUrl;
      String? fileName;

      // 1. Upload File if present
      if (attachedFile != null) {
        fileName = attachedFile.name;
        // Simple unique path
        final ref = FirebaseStorage.instance
            .ref()
            .child('homework_uploads')
            .child(widget.classId)
            .child(widget.studentId)
            .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

        if (attachedFile.bytes != null) {
          await ref.putData(attachedFile.bytes!);
          fileUrl = await ref.getDownloadURL();
        }
      }

      // 2. Prepare for AI Evaluation
      final List<Map<String, dynamic>> qna = [];
      answers.forEach((q, a) {
        qna.add({'question': q, 'answer': a});
      });

      // 3. Evaluate
      final result = await GeminiHomeworkService.evaluateHomework(
        qna: qna,
        attachmentName: fileName,
      );

      // 4. Save to Firestore
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .collection('homework')
          .doc(homeworkDocId)
          .update({
            'status': 'submitted',
            'submittedAt': FieldValue.serverTimestamp(),
            'answers': answers,
            'attachmentUrl': fileUrl,
            'attachmentName': fileName,
            'score': result['score'],
            'feedback': result['feedback'],
            'corrections': result['corrections'], // list of details
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Submitted! You scored ${result['score']}/100 🎉"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error submitting: $e"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// 🔹 DELETE/RETRY HOMEWORK
  Future<void> _deleteHomework(String homeworkDocId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          "Regenerate Homework?",
          style: TextStyle(color: Color(0xFF0D1B3D)),
        ),
        content: const Text(
          "This will discard the current questions and generate new ones based on your weak concepts.",
          style: TextStyle(color: Color(0xFF5C6B8C)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              "Regenerate",
              style: TextStyle(color: Color(0xFF2E6BFF)),
            ),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('students')
          .doc(widget.studentId)
          .collection('homework')
          .doc(homeworkDocId)
          .delete();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFFF4F8FF),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(color: Color(0xFF2E6BFF)),
              SizedBox(height: 16),
              Text(
                "AI is crafting your personal homework...",
                style: TextStyle(color: Color(0xFF5C6B8C)),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFFF4F8FF),
      child: StreamBuilder<QuerySnapshot>(
        // 1. Get ALL homeworks for student, then filter client-side to avoid Index errors
        stream: FirebaseFirestore.instance
            .collection('students')
            .doc(widget.studentId)
            .collection('homework')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, homeworkSnap) {
          if (homeworkSnap.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  "Error loading homework: ${homeworkSnap.error}",
                  style: const TextStyle(color: Colors.redAccent),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final allHomeworks = homeworkSnap.data?.docs ?? [];

          // Filter for current class client-side
          // This avoids the "stateless query requires an index" error
          final classHomeworks = allHomeworks.where((doc) {
            final data = doc.data() as Map<String, dynamic>;
            return data['classId'] == widget.classId;
          }).toList();

          final latestHomeworkDoc = classHomeworks.isNotEmpty
              ? classHomeworks.first
              : null;

          final latestHomeworkTime = latestHomeworkDoc != null
              ? (latestHomeworkDoc['createdAt'] as Timestamp?)?.toDate()
              : null;

          // 2. Get Quiz Attempts to find new weak concepts
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('quiz_attempts')
                .where('classId', isEqualTo: widget.classId)
                .where('studentId', isEqualTo: widget.studentId)
                .snapshots(),
            builder: (context, quizSnap) {
              if (!quizSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              // Extract weak concepts & latest quiz time
              final weakConcepts = <String>{};
              DateTime? latestQuizTime;

              for (var doc in quizSnap.data!.docs) {
                final data = doc.data() as Map<String, dynamic>;

                // Track latest quiz submission
                if (data['submittedAt'] != null) {
                  final t = (data['submittedAt'] as Timestamp).toDate();
                  if (latestQuizTime == null || t.isAfter(latestQuizTime)) {
                    latestQuizTime = t;
                  }
                }

                if (data['weakConcepts'] != null) {
                  weakConcepts.addAll(List<String>.from(data['weakConcepts']));
                }
              }

              // 🟢 LOGIC: CHECK IF WE NEED NEW HOMEWORK
              bool needNewHomework = false;
              if (weakConcepts.isNotEmpty) {
                if (latestHomeworkTime == null) {
                  // No homework ever -> Need one
                  needNewHomework = true;
                } else if (latestQuizTime != null &&
                    latestQuizTime.isAfter(latestHomeworkTime)) {
                  // New quiz taken AFTER last homework -> Need updated one
                  needNewHomework = true;
                }
              }

              // 🚀 ACTION: TRIGGER GENERATION
              if (needNewHomework && !_isLoading) {
                // Trigger in next frame to avoid build conflicts
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _generateHomework(weakConcepts.toList());
                });

                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(color: Color(0xFF2E6BFF)),
                      const SizedBox(height: 16),
                      Text(
                        "New weak concepts detected!\nGenerating personalized homework...",
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Color(0xFF5C6B8C)),
                      ),
                    ],
                  ),
                );
              }

              // 🟢 SHOW EXISTING HOMEWORK (Pending or Submitted)
              if (latestHomeworkDoc != null) {
                final status = latestHomeworkDoc['status'];
                final isSubmitted = status == 'submitted';

                return _ActiveHomeworkView(
                  classId: widget.classId,
                  studentId: widget.studentId,
                  studentName: widget.studentName,
                  homeworkId: latestHomeworkDoc.id,
                  data: latestHomeworkDoc['data'] as Map<String, dynamic>,
                  submissionData: isSubmitted
                      ? latestHomeworkDoc.data() as Map<String, dynamic>
                      : null,
                  isReadOnly: isSubmitted,
                  onRetry: () => _deleteHomework(latestHomeworkDoc.id),
                  onSubmit: (answers, file) =>
                      _submitHomework(latestHomeworkDoc.id, answers, file),
                );
              }

              // 🟢 FALLBACK: NO WEAK CONCEPTS
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.check_circle_outline,
                      size: 80,
                      color: Colors.greenAccent,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      "No homework needed! 🎉",
                      style: TextStyle(
                        color: const Color(0xFF0D1B3D),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "You have no weak concepts pending.\nKeep taking quizzes to check your progress.",
                      style: TextStyle(color: Color(0xFF5C6B8C)),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _ActiveHomeworkView extends StatefulWidget {
  final String classId;
  final String studentId;
  final String studentName;
  final String homeworkId;
  final Map<String, dynamic> data;
  final Map<String, dynamic>? submissionData; // Feedback, score, etc.
  final bool isReadOnly;
  final VoidCallback? onRetry;
  final Function(Map<String, String>, PlatformFile?) onSubmit;

  const _ActiveHomeworkView({
    required this.classId,
    required this.studentId,
    required this.studentName,
    required this.homeworkId,
    required this.data,
    this.submissionData,
    this.isReadOnly = false,
    this.onRetry,
    required this.onSubmit,
  });

  @override
  State<_ActiveHomeworkView> createState() => _ActiveHomeworkViewState();
}

class _ActiveHomeworkViewState extends State<_ActiveHomeworkView> {
  final Map<int, TextEditingController> _theoryControllers = {};
  PlatformFile? _attachedFile;

  @override
  void initState() {
    super.initState();
    // Initialize controllers
    final theoryQuestions = widget.data['theory'] as List? ?? [];
    for (int i = 0; i < theoryQuestions.length; i++) {
      _theoryControllers[i] = TextEditingController();

      // Pre-fill if read-only
      if (widget.isReadOnly && widget.submissionData != null) {
        final answers =
            widget.submissionData!['answers'] as Map<String, dynamic>?;
        if (answers != null) {
          final q = theoryQuestions[i]['question'];
          if (answers.containsKey(q)) {
            _theoryControllers[i]?.text = answers[q] as String;
          }
        }
      }
    }
  }

  @override
  void dispose() {
    for (var controller in _theoryControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles();
    if (result != null) {
      setState(() {
        _attachedFile = result.files.first;
      });
    }
  }

  void _handleSubmit() {
    final theoryQuestions = widget.data['theory'] as List? ?? [];
    final answers = <String, String>{};

    for (int i = 0; i < theoryQuestions.length; i++) {
      final q = theoryQuestions[i]['question'];
      answers[q] = _theoryControllers[i]?.text ?? "";
    }

    widget.onSubmit(answers, _attachedFile);
  }

  @override
  Widget build(BuildContext context) {
    final theory = widget.data['theory'] as List? ?? [];
    final dynamic rawScore = widget.submissionData?['score'];
    final double? score = rawScore is num ? rawScore.toDouble() : null;
    final feedback = widget.submissionData?['feedback'];
    final previousFileName = widget.submissionData?['attachmentName'];

    return Column(
      children: [
        /// 🔹 TOP ACTIONS (REGENERATE IF NOT SUBMITTED)
        if (widget.onRetry != null && !widget.isReadOnly)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: widget.onRetry,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.orangeAccent,
                    backgroundColor: Colors.orangeAccent.withOpacity(0.1),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text("Regenerate Questions"),
                ),
              ],
            ),
          ),

        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              /// 🔹 SCORE CARD
              if (widget.isReadOnly && score != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF059669),
                        const Color(0xFF10B981),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 15,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 28,
                          ),
                          const SizedBox(width: 10),
                          const Text(
                            "Homework Evaluated",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        "$score",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 48,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const Text(
                        "OUT OF 100",
                        style: TextStyle(
                          color: Color(0xFFE5F9EE),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.5,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          feedback ?? "Good effort!",
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                if (score > 60)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PracticeConceptListScreen(
                            classId: widget.classId,
                            studentId: widget.studentId,
                            studentName: widget.studentName,
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.play_arrow, color: Colors.white),
                    label: const Text(
                      "Practice Now",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                const SizedBox(height: 32),
              ],

              _buildSectionHeader("📝 Theory Questions", Icons.edit_note),

              /// 🔹 QUESTIONS LIST
              ...List.generate(theory.length, (index) {
                final q = theory[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1A2E6BFF)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E6BFF).withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question Header
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFF),
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          border: Border(
                            bottom: BorderSide(color: const Color(0x1A2E6BFF)),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Q${index + 1}",
                              style: const TextStyle(
                                color: Color(0xFF2E6BFF),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                q['question'],
                                style: const TextStyle(
                                  color: const Color(0xFF0D1B3D),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 16,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Answer Input
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: TextField(
                          controller: _theoryControllers[index],
                          maxLines: 5,
                          readOnly: widget.isReadOnly,
                          style: const TextStyle(
                            color: const Color(0xFF0D1B3D),
                            fontSize: 14,
                          ),
                          cursorColor: const Color(0xFF2E6BFF),
                          decoration: InputDecoration(
                            hintText: "Type your detailed answer here...",
                            hintStyle: TextStyle(
                              color: const Color(0xFF0D1B3D).withOpacity(0.3),
                              fontSize: 14,
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF4F8FF),
                            contentPadding: const EdgeInsets.all(16),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(
                                color: const Color(0xFF0D1B3D).withOpacity(0.1),
                              ),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(
                                color: Color(0xFF2E6BFF),
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
              _buildSectionHeader(
                "📎 Attachments (Optional)",
                Icons.attach_file,
              ),

              /// 🔹 ATTACHMENT SECTION
              if (widget.isReadOnly)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0D1B3D).withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color(0x1A2E6BFF)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.blueAccent.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(
                          Icons.file_present,
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              previousFileName ?? "No file attached",
                              style: const TextStyle(
                                color: const Color(0xFF0D1B3D),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            if (widget.submissionData?['attachmentUrl'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  "Tap to view",
                                  style: TextStyle(
                                    color: const Color(
                                      0xFF0D1B3D,
                                    ).withOpacity(0.5),
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                )
              else
                InkWell(
                  onTap: _pickFile,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: _attachedFile == null
                            ? const Color(0x553C5A99)
                            : const Color(0xFF10B981),
                        style: BorderStyle.solid,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      color: _attachedFile == null
                          ? Colors.white
                          : const Color(0x1910B981),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _attachedFile == null
                              ? Icons.cloud_upload_outlined
                              : Icons.check_circle_rounded,
                          color: _attachedFile == null
                              ? const Color(0xFF2E6BFF)
                              : const Color(0xFF10B981),
                          size: 28,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _attachedFile == null
                                ? "Upload Document / Scan"
                                : _attachedFile!.name,
                            style: TextStyle(
                              color: _attachedFile == null
                                  ? const Color(0xFF0D1B3D)
                                  : const Color(0xFF10B981),
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 40),

              /// 🔹 ACTION BUTTONS
              if (!widget.isReadOnly)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E6BFF),
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 24),
                        SizedBox(width: 8),
                        Text(
                          "Submit Homework",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (widget.onRetry != null)
                Column(
                  children: [
                    const Text(
                      "Want to improve your score?",
                      style: TextStyle(color: Color(0xFF7A89A8)),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: OutlinedButton.icon(
                        onPressed: widget.onRetry,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF0D1B3D),
                          side: const BorderSide(
                            color: Color(0xFF2E6BFF),
                            width: 1.5,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(
                          Icons.refresh_rounded,
                          color: Color(0xFF2E6BFF),
                        ),
                        label: const Text(
                          "Retry / Get New Homework",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Color(0xFF2E6BFF),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 8),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF2E6BFF), size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              color: const Color(0xFF0D1B3D),
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final Map<String, dynamic> classData;
  final String studentName;
  final String classId;

  const _DetailsTab({
    required this.classData,
    required this.studentName,
    required this.classId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _infoCard("Class Name", classData['class_name']),
            _infoCard("Subject", classData['subject']),
            _infoCard("Class Code", classData['class_code']),
            _infoCard(
              "Students Joined",
              (classData['student_count'] ?? 0).toString(),
            ),

            const SizedBox(height: 24),

            const Text(
              "Description",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D1B3D),
              ),
            ),
            const SizedBox(height: 8),

            Card(
              color: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: const BorderSide(color: Color(0x1A2E6BFF)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  classData['description'] ?? "No description provided",
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF5C6B8C),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard(String label, String? value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Color(0x1A2E6BFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF0D1B3D),
                ),
              ),
            ),
            Expanded(
              flex: 5,
              child: Text(
                value ?? "-",
                textAlign: TextAlign.right,
                style: const TextStyle(color: Color(0xFF5C6B8C)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/* ============================================================
   ===================== PBL LIST SHEET =======================
   ============================================================ */
class _PblListSheet extends StatelessWidget {
  final String classId;
  final String userId;
  final ScrollController scrollController;

  const _PblListSheet({
    required this.classId,
    required this.userId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('PBL')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Container(
            color: const Color(0xFFF4F8FF),
            child: const Center(
              child: Text(
                "No PBL projects assigned yet",
                style: TextStyle(color: Color(0xFF5C6B8C)),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final assignedPbls = <Map<String, dynamic>>[];

        // Filter for assigned PBLs
        for (var doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final studentAssignments =
              data['studentAssignments'] as List<dynamic>? ?? [];

          bool isAssigned = false;
          Map<String, dynamic>? pairInfo;

          for (var assignment in studentAssignments) {
            final students = assignment['students'] as List<dynamic>? ?? [];
            for (var student in students) {
              if (student is Map && student['uid'] == userId) {
                isAssigned = true;
                pairInfo = assignment;
                break;
              }
            }
            if (isAssigned) break;
          }

          if (isAssigned) {
            assignedPbls.add({
              'id': doc.id,
              'data': data,
              'pairInfo': pairInfo,
            });
          }
        }

        if (assignedPbls.isEmpty) {
          return Container(
            color: const Color(0xFFF4F8FF),
            child: const Center(
              child: Text(
                "No PBL projects assigned to you yet",
                style: TextStyle(color: Color(0xFF5C6B8C)),
              ),
            ),
          );
        }

        return Container(
          color: const Color(0xFFF4F8FF),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                child: const Text(
                  "My PBL Projects",
                  style: TextStyle(
                    color: const Color(0xFF0D1B3D),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: assignedPbls.length,
                  itemBuilder: (context, index) {
                    final pblInfo = assignedPbls[index];
                    return Column(
                      children: [
                        _PblSubmissionCard(
                          classId: classId,
                          pblId: pblInfo['id'],
                          pblData: pblInfo['data'],
                          pairInfo: pblInfo['pairInfo'],
                        ),
                        const SizedBox(height: 12),
                        // _PblMiniProjectStatus(
                        //   classId: classId,
                        //   pblId: pblInfo['id'],
                        //   pblData: pblInfo['data'],
                        //   studentId: userId,
                        // ),
                        // const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/* ============================================================
   =================== MINI PROJECTS SCREEN ==================
   ============================================================ */

class _MiniProjectsScreen extends StatefulWidget {
  final String classId;
  final String userId;
  final Function(BuildContext, String, Map<String, dynamic>, String)
  onSelectMiniProject;

  const _MiniProjectsScreen({
    required this.classId,
    required this.userId,
    required this.onSelectMiniProject,
  });

  @override
  State<_MiniProjectsScreen> createState() => _MiniProjectsScreenState();
}

class _MiniProjectsScreenState extends State<_MiniProjectsScreen> {
  /// Helper to find if the user has already selected a project in any of the PBLs
  Future<Map<String, dynamic>?> _findActiveSelection(
    List<QueryDocumentSnapshot> pblDocs,
  ) async {
    for (var doc in pblDocs) {
      final selectionSnap = await doc.reference
          .collection('selections')
          .doc(widget.userId)
          .get();

      if (selectionSnap.exists) {
        return {
          'pblId': doc.id,
          'pblData': doc.data() as Map<String, dynamic>,
          'selectionData': selectionSnap.data() as Map<String, dynamic>,
        };
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFF0D1B3D),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Mini Projects",
          style: TextStyle(
            color: const Color(0xFF0D1B3D),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      // 1. Fetch all PBLs for this class
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('PBL')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, pblSnapshot) {
          if (pblSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFA5B2C8)),
            );
          }

          if (!pblSnapshot.hasData || pblSnapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No mini projects available yet",
                style: TextStyle(color: Color(0xFF7A89A8), fontSize: 16),
              ),
            );
          }

          final pblDocs = pblSnapshot.data!.docs;

          // 2. Check for active selection across these PBLs
          return FutureBuilder<Map<String, dynamic>?>(
            future: _findActiveSelection(pblDocs),
            builder: (context, selectionSnapshot) {
              if (selectionSnapshot.connectionState ==
                  ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFFA5B2C8)),
                );
              }

              final activeSelection = selectionSnapshot.data;

              // 🔹 SCENARIO A: PROJECT ALREADY SELECTED
              if (activeSelection != null) {
                return _buildSelectedView(
                  context,
                  activeSelection['selectionData'],
                  activeSelection['pblId'],
                  activeSelection['pblData'],
                );
              }

              // 🔹 SCENARIO B: NO SELECTION -> SHOW ALL AVAILABLE OPTIONS
              return _buildAvailableProjectsList(pblDocs);
            },
          );
        },
      ),
    );
  }

  Widget _buildSelectedView(
    BuildContext context,
    Map<String, dynamic> selectedData,
    String pblId,
    Map<String, dynamic> pblData,
  ) {
    return Padding(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0x1A2E6BFF)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF2E6BFF).withOpacity(0.08),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ],
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.check_circle_outline_rounded,
                  size: 64,
                  color: Color(0xFF2E6BFF),
                ),
                const SizedBox(height: 16),
                const Text(
                  "Active Project",
                  style: TextStyle(
                    color: Color(0xFF2E6BFF),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  selectedData['title'] ?? 'Untitled Project',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: const Color(0xFF0D1B3D),
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selectedData['description'] ?? '',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF0D1B3D).withOpacity(0.7),
                    fontSize: 14,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => StudentMiniProjectDetailScreen(
                            classId: widget.classId,
                            pblId: pblId,
                            studentId: widget.userId,
                            selectionData: selectedData,
                            pblData: pblData,
                          ),
                        ),
                      ).then((_) {
                        // Refresh state when coming back
                        setState(() {});
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E6BFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Icons.rocket_launch_rounded),
                    label: const Text(
                      "Continue Working",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "You have limited your focus to one project.\nComplete it to unlock more opportunities.",
            textAlign: TextAlign.center,
            style: TextStyle(color: Color(0xFF94A3BC), fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildAvailableProjectsList(List<QueryDocumentSnapshot> pblDocs) {
    List<Map<String, dynamic>> allMiniProjects = [];

    // Aggregate all mini projects
    for (var doc in pblDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final List<dynamic> projects = data['miniProjects'] ?? [];

      for (var p in projects) {
        allMiniProjects.add({
          ...p as Map<String, dynamic>,
          'pblId': doc.id,
          'pblTitle': data['title'] ?? 'Unknown Collection',
        });
      }
    }

    if (allMiniProjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.folder_open_rounded,
              size: 64,
              color: Color(0xFFB5C3DE),
            ),
            const SizedBox(height: 16),
            const Text(
              "No mini projects available yet",
              style: TextStyle(color: Color(0xFF7A89A8), fontSize: 16),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allMiniProjects.length,
      itemBuilder: (context, index) {
        final project = allMiniProjects[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B3D).withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF0D1B3D).withOpacity(0.08),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          // decoration: BoxDecoration(
                          //   color: Colors.blueAccent.withOpacity(0.2),
                          //   borderRadius: BorderRadius.circular(6),
                          // ),
                          // child: Text(
                          //   project['pblTitle']?.toUpperCase() ?? 'PBL',
                          //   style: const TextStyle(
                          //     color: Colors.blueAccent,
                          //     fontSize: 10,
                          //     fontWeight: FontWeight.bold,
                          //     letterSpacing: 0.5,
                          //   ),
                          // ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      project['title'] ?? 'Untitled',
                      style: const TextStyle(
                        color: const Color(0xFF0D1B3D),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      project['description'] ?? 'No description',
                      style: TextStyle(
                        color: const Color(0xFF0D1B3D).withOpacity(0.7),
                        fontSize: 14,
                        height: 1.5,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7FAFF),
                  border: Border(
                    top: BorderSide(
                      color: const Color(0xFF0D1B3D).withOpacity(0.05),
                    ),
                  ),
                ),
                child: TextButton.icon(
                  onPressed: () {
                    widget
                        .onSelectMiniProject(
                          context,
                          project['pblId'],
                          project,
                          project['pblTitle'],
                        )
                        .then((_) {
                          // Refresh after selection
                          if (mounted) setState(() {});
                        });
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    foregroundColor: const Color(0xFF2E6BFF),
                  ),
                  icon: const Icon(Icons.touch_app_rounded, size: 20),
                  label: const Text(
                    "Select & Start",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// REMOVED OLD CLASS AND METHODS TO ENSURE CLEANUP
// (This is redundant if the above replaces it all, but ensures clarity)

/* ============================================================
   =================== PBL PROJECTS SCREEN ====================
   ============================================================ */
class _PblProjectsScreen extends StatelessWidget {
  final String classId;
  final String userId;

  const _PblProjectsScreen({required this.classId, required this.userId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: const Color(0xFF0D1B3D),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "My PBL Projects",
          style: TextStyle(
            color: const Color(0xFF0D1B3D),
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('PBL')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFA5B2C8)),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                "No PBL projects assigned yet",
                style: TextStyle(color: Color(0xFF5C6B8C), fontSize: 16),
              ),
            );
          }

          final docs = snapshot.data!.docs;
          final assignedPbls = <Map<String, dynamic>>[];

          // Filter for assigned PBLs
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final studentAssignments =
                data['studentAssignments'] as List<dynamic>? ?? [];

            bool isAssigned = false;
            Map<String, dynamic>? pairInfo;

            for (var assignment in studentAssignments) {
              final students = assignment['students'] as List<dynamic>? ?? [];
              for (var student in students) {
                if (student is Map && student['uid'] == userId) {
                  isAssigned = true;
                  pairInfo = assignment;
                  break;
                }
              }
              if (isAssigned) break;
            }

            if (isAssigned) {
              assignedPbls.add({
                'id': doc.id,
                'data': data,
                'pairInfo': pairInfo,
              });
            }
          }

          if (assignedPbls.isEmpty) {
            return const Center(
              child: Text(
                "No PBL projects assigned to you yet",
                style: TextStyle(color: Color(0xFF5C6B8C), fontSize: 16),
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: assignedPbls.length,
                  itemBuilder: (context, index) {
                    final pblInfo = assignedPbls[index];
                    return Column(
                      children: [
                        _PblSubmissionCard(
                          classId: classId,
                          pblId: pblInfo['id'],
                          pblData: pblInfo['data'],
                          pairInfo: pblInfo['pairInfo'],
                        ),
                        const SizedBox(height: 12),
                        // _PblMiniProjectStatus(
                        //   classId: classId,
                        //   pblId: pblInfo['id'],
                        //   pblData: pblInfo['data'],
                        //   studentId: userId,
                        // ),
                        // const SizedBox(height: 24),
                      ],
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
/* ============================================================
   ===================== REMAINING WIDGETS ====================
   ============================================================ */

Widget _infoTile(String label, String? value) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        SizedBox(
          width: 130,
          child: Text(
            "$label:",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0D1B3D),
            ),
          ),
        ),
        Expanded(
          child: Text(
            value ?? "-",
            style: const TextStyle(color: Color(0xFF5C6B8C)),
          ),
        ),
      ],
    ),
  );
}

/* ============================================================
   ===================== PBL SECTION ==========================
   ============================================================ */

// PBL Section widget removed - now accessible via drawer

class _PblSubmissionCard extends StatelessWidget {
  final String classId;
  final String pblId;
  final Map<String, dynamic> pblData;
  final Map<String, dynamic>? pairInfo;

  const _PblSubmissionCard({
    required this.classId,
    required this.pblId,
    required this.pblData,
    required this.pairInfo,
  });

  @override
  Widget build(BuildContext context) {
    final title = pblData['title'] ?? 'Untitled Project';
    final problemStatement = pblData['problemStatement'] ?? '';
    final pairNumber = pairInfo?['pairNumber'] ?? 0;

    final submissionData = {
      'classId': classId,
      'pblId': pblId,
      ...pblData,
      'pairNumber': pairNumber,
      'pairStudents': pairInfo?['students'] ?? [],
    };

    return Card(
      color: Colors.white,
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: Color(0x1A2E6BFF)),
      ),
      child: InkWell(
        onTap: () {
          _showSubmissionSheet(context, submissionData);
        },
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.rocket_launch, color: Color(0xFF2E6BFF)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0D1B3D),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Color(0x142E6BFF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Pair #$pairNumber',
                      style: const TextStyle(
                        color: Color(0xFF2E6BFF),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                problemStatement,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFF5C6B8C), fontSize: 13),
              ),
              const SizedBox(height: 12),
              const Row(
                children: [
                  Icon(Icons.touch_app, size: 14, color: Color(0xFF7A89A8)),
                  SizedBox(width: 4),
                  Text(
                    'Tap to view details & submit work',
                    style: TextStyle(color: Color(0xFF7A89A8), fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSubmissionSheet(
    BuildContext context,
    Map<String, dynamic> pblData,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF4F8FF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.85,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            PblSubmissionSheet(pblData: pblData),
      ),
    );
  }
}

class _PblMiniProjectStatus extends StatelessWidget {
  final String classId;
  final String pblId;
  final Map<String, dynamic> pblData;
  final String studentId;

  const _PblMiniProjectStatus({
    required this.classId,
    required this.pblId,
    required this.pblData,
    required this.studentId,
  });

  @override
  Widget build(BuildContext context) {
    final title = pblData['title'] ?? 'Untitled';
    final problemStatement = pblData['problemStatement'] ?? '';
    final miniProjects =
        (pblData['miniProjects'] as List?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        [];

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('PBL')
          .doc(pblId)
          .collection('selections')
          .doc(studentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 60,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final selectionData = snapshot.data?.data() as Map<String, dynamic>?;
        final isSelected = selectionData != null;

        // Only show if selected
        if (!isSelected) {
          return const SizedBox.shrink();
        }

        // Container card for Mini Project Status
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0D1B3D).withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0x142E6BFF)),
          ),
          child: Column(
            children: [
              // Show selected mini project
              Padding(
                padding: const EdgeInsets.all(16),
                child: InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => StudentMiniProjectDetailScreen(
                          classId: classId,
                          pblId: pblId,
                          studentId: studentId,
                          selectionData: selectionData,
                          pblData: pblData,
                        ),
                      ),
                    );
                  },
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.check_circle,
                            color: Colors.green,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Selected: ${selectionData['title']}",
                              style: const TextStyle(
                                color: const Color(0xFF0D1B3D),
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF7A89A8),
                            size: 16,
                          ),
                        ],
                      ),
                      if (selectionData['description'] != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 4, left: 28),
                          child: Text(
                            selectionData['description'],
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8, left: 28),
                        child: Text(
                          "Tap to view step-by-step guidelines",
                          style: TextStyle(
                            color: Colors.cyanAccent,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
