import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'teacher_class_detail_screen.dart';
import 'pbl/pbl_main_screen.dart';
import 'quiz/quiz_tab_screen.dart';
import 'resources/teacher_resources_screen.dart';
import 'assignment/create_assignment_screen.dart';
import 'package:demo/utils/responsive_breakpoints.dart';

class TeacherClassesPage extends StatefulWidget {
  const TeacherClassesPage({super.key});

  @override
  State<TeacherClassesPage> createState() => _TeacherClassesPageState();
}

class _TeacherClassesPageState extends State<TeacherClassesPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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
          'students': data.containsKey('student_count') ? data['student_count'] : 0,
          'subject': data['subject'] ?? 'All Subjects',
          'createdAt': data['created_at'],
        };
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (isDesktop) {
      return _buildDesktopLayout();
    }

    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout() {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: _fetchClasses(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF3B82F6)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading classes',
                          style: TextStyle(
                            color: const Color(0xFF64748B),
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildEmptyState();
                }

                final classes = snapshot.data!;
                final filteredClasses = classes.where((c) {
                  final name = c['name'].toString().toLowerCase();
                  final code = c['code'].toString().toLowerCase();
                  final query = _searchQuery.toLowerCase();
                  return name.contains(query) || code.contains(query);
                }).toList();

                if (filteredClasses.isEmpty) {
                  return _buildNoSearchResultsState();
                }

                return _buildClassesGrid(filteredClasses);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 80,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              child: TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _searchQuery = value),
                decoration: InputDecoration(
                  hintText: 'Search by class name or code...',
                  hintStyle: TextStyle(color: const Color(0xFF94A3B8)),
                  prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2),
                  ),
                  filled: true,
                  fillColor: const Color(0xFFF8FAFC),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.class_rounded,
              size: 60,
              color: Color(0xFF3B82F6),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'No classes yet',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first class to get started',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoSearchResultsState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: const Color(0xFF64748B).withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 40,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No classes found',
            style: TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Try adjusting your search query',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassesGrid(List<Map<String, dynamic>> classes) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${classes.length} ${classes.length == 1 ? 'Class' : 'Classes'}',
                style: const TextStyle(
                  color: Color(0xFF64748B),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          LayoutBuilder(
            builder: (context, constraints) {
              final width = constraints.maxWidth;
              final crossAxisCount = width >= 1100 ? 3 : (width >= 600 ? 2 : 1);

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: width >= 1100 ? 1.35 : 1.45,
                ),
                itemCount: classes.length,
                itemBuilder: (context, index) {
                  return _buildClassCard(classes[index]);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildClassCard(Map<String, dynamic> classData) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => TeacherClassDetailScreen(classId: classData['id']),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -30,
              top: -30,
              child: Icon(
                Icons.school_rounded,
                size: 100,
                color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            classData['code'] ?? '---',
                            style: const TextStyle(
                              color: Color(0xFF3B82F6),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _buildOptionsMenu(classData),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    classData['name'] ?? 'Untitled',
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.3,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    classData['subject'] ?? 'All Subjects',
                    style: TextStyle(
                      color: const Color(0xFF64748B),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 16,
                        color: const Color(0xFF94A3B8),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${classData['students'] ?? 0} students',
                        style: const TextStyle(
                          color: Color(0xFF64748B),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionsMenu(Map<String, dynamic> classData) {
    return PopupMenuButton<String>(
      icon: const Icon(
        Icons.more_horiz,
        color: Color(0xFF94A3B8),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      onSelected: (value) => _handleAction(value, classData),
      itemBuilder: (_) => [
        const PopupMenuItem(
          value: 'pbl',
          child: Row(
            children: [
              Icon(Icons.rocket_launch_rounded, size: 20, color: Color(0xFF8B5CF6)),
              SizedBox(width: 10),
              Text('PBL Projects'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'quiz',
          child: Row(
            children: [
              Icon(Icons.quiz_rounded, size: 20, color: Color(0xFFEC4899)),
              SizedBox(width: 10),
              Text('Quizzes'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'resources',
          child: Row(
            children: [
              Icon(Icons.folder_rounded, size: 20, color: Color(0xFF3B82F6)),
              SizedBox(width: 10),
              Text('Resources'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: 'assignment',
          child: Row(
            children: [
              Icon(Icons.assignment_rounded, size: 20, color: Color(0xFF10B981)),
              SizedBox(width: 10),
              Text('Assignment'),
            ],
          ),
        ),
      ],
    );
  }

  void _handleAction(String action, Map<String, dynamic> classData) {
    switch (action) {
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
            builder: (context) => TeacherResourcesScreen(classId: classData['id']),
          ),
        );
        break;
      case 'assignment':
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CreateAssignmentScreen(classId: classData['id']),
          ),
        );
        break;
    }
  }

  Widget _buildMobileLayout() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: _fetchClasses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFF2E6BFF)),
          );
        }

        if (snapshot.hasError) {
          return Center(child: Text(snapshot.error.toString()));
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
    );
  }

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
              Positioned(
                right: -20,
                top: -20,
                child: Icon(
                  Icons.school_rounded,
                  size: 100,
                  color: const Color(0xFF2E6BFF).withOpacity(0.10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      width: 4,
                      height: 60,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2E6BFF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            classData['name']?.toUpperCase() ?? 'UNTITLED CLASS',
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
                        PopupMenuItem(value: 'resources', child: Text('Resources')),
                        PopupMenuItem(value: 'assignment', child: Text('Assignment')),
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
}