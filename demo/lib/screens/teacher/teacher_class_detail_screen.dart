import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'attendance/attendance_marking_screen.dart';
import 'quiz/quiz_tab_screen.dart';
import 'resources/teacher_resources_screen.dart';
import 'assignment/create_assignment_screen.dart';
import 'assignment/teacher_assignment_detail_screen.dart' show TeacherAssignmentDetailScreen;
import 'pbl/pbl_main_screen.dart';

class TeacherClassDetailScreen extends StatefulWidget {
  final String classId;
  const TeacherClassDetailScreen({super.key, required this.classId});

  @override
  State<TeacherClassDetailScreen> createState() => _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends State<TeacherClassDetailScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      drawer: isDesktop ? null : _buildDrawer(context),
      body: Row(
        children: [
          if (isDesktop) _buildSidebar(),
          Expanded(
            child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance.collection('classes').doc(widget.classId).snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
                }
                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return _buildNotFoundState();
                }
                final data = snapshot.data!.data()!;
                final className = data['class_name'] ?? 'Class';

                return Column(
                  children: [
                    if (isDesktop) _buildDesktopTopBar(className, data) else _buildMobileTopBar(className),
                    _buildTabBar(isDesktop),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _PostsTab(classId: widget.classId, isDesktop: isDesktop),
                          _AssignmentsTab(classId: widget.classId, isDesktop: isDesktop, className: data['class_name'] ?? 'Class'),
                          _DetailsTab(classData: data, classId: widget.classId, isDesktop: isDesktop),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 260,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xFF1E293B), Color(0xFF0F172A)]),
      ),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance.collection('classes').doc(widget.classId).snapshots(),
        builder: (context, snapshot) {
          final classData = snapshot.data?.data();
          return Column(
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.school_rounded, color: Colors.white, size: 30),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      classData?['class_name'] ?? 'Class',
                      style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Code: ${classData?['class_code'] ?? '---'}',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  children: [
                    // Note: Sidebar items now navigate to separate screens with their own context
                    // PBL, Resources, Quizzes, Attendance keep the same sidebar pattern in their own screens
                    _buildSidebarMenuItem(
                      icon: Icons.rocket_launch_rounded,
                      label: 'PBL Projects',
                      color: const Color(0xFF8B5CF6),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PblMainScreen(
                        classId: widget.classId,
                        className: classData?['class_name'] ?? 'Class',
                        classCode: classData?['class_code'] ?? '---',
                      ))),
                    ),
                    const SizedBox(height: 8),
                    _buildSidebarMenuItem(
                      icon: Icons.link,
                      label: 'Resources',
                      color: const Color(0xFF3B82F6),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => TeacherResourcesScreen(
                        classId: widget.classId,
                        className: classData?['class_name'] ?? 'Class',
                      ))),
                    ),
                    const SizedBox(height: 8),
                    _buildSidebarMenuItem(
                      icon: Icons.quiz_rounded,
                      label: 'Quizzes',
                      color: const Color(0xFFEC4899),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => QuizTabScreen(
                        classId: widget.classId,
                        className: classData?['class_name'] ?? 'Class',
                      ))),
                    ),
                    const SizedBox(height: 8),
                    _buildSidebarMenuItem(
                      icon: Icons.checklist_rounded,
                      label: 'Attendance',
                      color: const Color(0xFFF59E0B),
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => AttendanceMarkingScreen(
                        classId: widget.classId,
                        className: classData?['class_name'] ?? 'Class',
                      ))),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: const Color(0xFF334155), width: 1)),
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF94A3B8)),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Back',
                    ),
                    Expanded(
                      child: Text(
                        'Back to Classes',
                        style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSidebarMenuItem({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(7)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 11),
            Text(label, style: const TextStyle(color: Color(0xFFE2E8F0), fontSize: 13, fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTopBar(String className, Map<String, dynamic> data) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back to Classes',
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    InkWell(
                      onTap: () => Navigator.pop(context),
                      child: const Text('Classes / ', style: TextStyle(color: Color(0xFF64748B), fontSize: 13, fontWeight: FontWeight.w500)),
                    ),
                    Text(
                      className,
                      style: const TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w700, letterSpacing: -0.3),
                    ),
                  ],
                ),
                if (data['subject'] != null && data['subject'].toString().isNotEmpty)
                  Text(
                    data['subject'],
                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 12, fontWeight: FontWeight.w500),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.people_outline, color: Color(0xFF3B82F6), size: 18),
                const SizedBox(width: 6),
                Text(
                  '${data['student_count'] ?? 0} Students',
                  style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileTopBar(String className) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
      color: const Color(0xFFF4F8FF),
      child: Row(
        children: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu_rounded, color: Color(0xFF0D1B3D)),
              onPressed: () {
                Scaffold.of(context).openDrawer();
              },
              tooltip: 'Menu',
            ),
          ),
          Expanded(
            child: Text(
              className,
              style: const TextStyle(color: Color(0xFF0D1B3D), fontSize: 18, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D1B3D)),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back',
          ),
        ],
      ),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF4F8FF),
      child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .snapshots(),
        builder: (context, classSnapshot) {
          final classData = classSnapshot.data?.data();
          final className = classData?['class_name'] ?? 'Class';
          final classCode = classData?['class_code'] ?? '---';
          final pblEnabled = classData?['pblEnabled'] != false;

          return Column(
            children: [
              // Modern Header with Gradient
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 28),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF1E3A8A), Color(0xFF3B82F6)],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
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
                      'Code: $classCode',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.9),
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
                            builder: (context) => TeacherResourcesScreen(
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
                      title: "Quizzes",
                      subtitle: "Create & manage",
                      iconColor: const Color(0xFFEC4899),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => QuizTabScreen(
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
                      icon: Icons.checklist_rounded,
                      title: "Attendance",
                      subtitle: "Mark attendance",
                      iconColor: const Color(0xFFFBBF24),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AttendanceMarkingScreen(
                              classId: widget.classId,
                              className: className,
                            ),
                          ),
                        );
                      },
                    ),
                    if (pblEnabled) ...[
                      const SizedBox(height: 20),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          "PROJECT-BASED LEARNING",
                          style: TextStyle(
                            color: Color(0xFF5C6B8C),
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
                        title: "PBL Projects",
                        subtitle: "Manage projects",
                        iconColor: const Color(0xFF8B5CF6),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => PblMainScreen(
                                classId: widget.classId,
                                className: className,
                                classCode: classCode,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ],
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A2E6BFF)),
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: iconColor, size: 24),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF0D1B3D),
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(color: Color(0xFF5C6B8C), fontSize: 12),
        ),
        trailing: const Icon(Icons.chevron_right, color: Color(0xFFA5B2C8)),
      ),
    );
  }

  Widget _buildTabBar(bool isDesktop) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: const Color(0xFF2E6BFF),
        labelColor: const Color(0xFF2E6BFF),
        unselectedLabelColor: const Color(0xFF5C6B8C),
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
        tabs: const [
          Tab(text: 'Posts'),
          Tab(text: 'Assignments'),
          Tab(text: 'Details'),
        ],
      ),
    );
  }

  Widget _buildNotFoundState() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.school_rounded, color: Color(0xFF3B82F6), size: 50),
        ),
        const SizedBox(height: 24),
        const Text('Class not found', style: TextStyle(color: Color(0xFF1E293B), fontSize: 20, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('This class may have been deleted', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
      ],
    );
  }
}

class _PostsTab extends StatefulWidget {
  final String classId;
  final bool isDesktop;
  const _PostsTab({required this.classId, required this.isDesktop});

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  final TextEditingController _postController = TextEditingController();
  String _teacherName = 'Teacher';

  @override
  void initState() {
    super.initState();
    _loadTeacherName();
  }

  Future<void> _loadTeacherName() async {
    try {
      final user = await FirebaseFirestore.instance.collection('teachers').doc(widget.classId).get();
      // We need to get teacherId from the class document first
      final classDoc = await FirebaseFirestore.instance.collection('classes').doc(widget.classId).get();
      final teacherId = classDoc.data()?['teacherId'];
      if (teacherId != null) {
        final teacherDoc = await FirebaseFirestore.instance.collection('teachers').doc(teacherId).get();
        if (teacherDoc.exists && teacherDoc.data()?['teacherName'] != null) {
          setState(() {
            _teacherName = teacherDoc.data()!['teacherName'] as String;
          });
        }
      }
    } catch (_) {
      // Use default name
    }
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('posts')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF3B82F6), size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text('No posts yet', style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Be the first to post an announcement', style: TextStyle(color: const Color(0xFF64748B), fontSize: 14)),
                      ],
                    ),
                  );
                }
                final posts = snapshot.data!.docs;
                return ListView.builder(
                  padding: EdgeInsets.all(widget.isDesktop ? 32 : 16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index].data();
                    return Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.person, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(post['authorName'] ?? 'Teacher', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 2),
                                    Text(_formatDate(post['createdAt']), style: TextStyle(color: const Color(0xFF64748B), fontSize: 12)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(post['content'] ?? '', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, height: 1.5)),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: const Color(0xFFE2E8F0))),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, -2)),
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(widget.isDesktop ? 32 : 16, 16, widget.isDesktop ? 32 : 16, 16),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: TextField(
                            controller: _postController,
                            decoration: const InputDecoration(hintText: 'Write a post...', border: InputBorder.none),
                            maxLines: null,
                            textCapitalization: TextCapitalization.sentences,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(color: Color(0xFF3B82F6), borderRadius: BorderRadius.circular(10)),
                      child: IconButton(
                        onPressed: _postMessage,
                        icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _postMessage() async {
    if (_postController.text.trim().isEmpty) return;

    // Get teacher name
    final authorName = _teacherName.isNotEmpty ? _teacherName : 'Teacher';

    // Get teacherId from class document
    final classDoc = await FirebaseFirestore.instance.collection('classes').doc(widget.classId).get();
    final teacherId = classDoc.data()?['teacherId'] ?? 'unknown';

    final postData = {
      'classId': widget.classId,
      'content': _postController.text.trim(),
      'authorId': teacherId,
      'authorName': authorName,
      'createdAt': FieldValue.serverTimestamp(),
    };

    // Add to both top-level posts collection and class subcollection for redundancy
    await FirebaseFirestore.instance.collection('posts').add(postData);
    await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('posts')
        .add(postData);

    if (mounted) {
      _postController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Post published!'), backgroundColor: Color(0xFF10B981)),
      );
    }
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return '';
    final date = timestamp is Timestamp ? timestamp.toDate() : DateTime.tryParse(timestamp.toString());
    return date != null ? '${date.day}/${date.month}/${date.year}' : '';
  }
}

class _AssignmentsTab extends StatelessWidget {
  final String classId;
  final bool isDesktop;
  final String? className;
  const _AssignmentsTab({required this.classId, required this.isDesktop, this.className});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF8FAFC),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(bottom: BorderSide(color: const Color(0xFFE2E8F0))),
            ),
            padding: EdgeInsets.all(isDesktop ? 20 : 16),
            child: Row(
              children: [
                const Text('Assignments', style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => CreateAssignmentScreen(classId: classId, className: className))),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Assignment'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection('assignments')
                  .where('classId', isEqualTo: classId)
                  .orderBy('dueDate', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.assignment_rounded, color: Color(0xFF3B82F6), size: 40),
                        ),
                        const SizedBox(height: 16),
                        const Text('No assignments yet', style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text('Create your first assignment', style: TextStyle(color: const Color(0xFF64748B), fontSize: 14)),
                      ],
                    ),
                  );
                }
                final assignments = snapshot.data!.docs;
                return ListView.builder(
                  padding: EdgeInsets.all(isDesktop ? 32 : 16),
                  itemCount: assignments.length,
                  itemBuilder: (context, index) {
                    final data = assignments[index].data();
                    final docId = assignments[index].id;
                    return InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => _AssignmentDetailWrapper(assignmentId: docId, classId: classId, assignmentData: data, className: className),
                          ),
                        );
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2)),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.assignment_rounded, color: Color(0xFF3B82F6), size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(data['title'] ?? 'Assignment', style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text(_formatDate(data['dueDate']), style: TextStyle(color: const Color(0xFF64748B), fontSize: 12)),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(data['status']).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                data['status'] ?? 'Active',
                                style: TextStyle(color: _getStatusColor(data['status']), fontSize: 11, fontWeight: FontWeight.w600),
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
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Color _getStatusColor(dynamic status) {
    final s = (status ?? '').toString().toLowerCase();
    if (s == 'active' || s == 'assigned') return const Color(0xFF10B981);
    if (s == 'graded') return const Color(0xFF3B82F6);
    if (s == 'overdue') return const Color(0xFFF59E0B);
    return const Color(0xFF64748B);
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'No due date';
    final date = timestamp is Timestamp ? timestamp.toDate() : DateTime.tryParse(timestamp.toString());
    return date != null ? 'Due: ${date.day}/${date.month}/${date.year}' : 'No due date';
  }
}

class _AssignmentDetailWrapper extends StatelessWidget {
  final String assignmentId;
  final String classId;
  final Map<String, dynamic> assignmentData;
  final String? className;

  const _AssignmentDetailWrapper({
    required this.assignmentId,
    required this.classId,
    required this.assignmentData,
    this.className,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('assignments').doc(assignmentId).snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
          );
        }
        final data = snapshot.data!.data() as Map<String, dynamic>;
        return TeacherAssignmentDetailScreen(
          classId: classId,
          assignmentId: assignmentId,
          assignmentData: data,
          className: className,
        );
      },
    );
  }
}

class _DetailsTab extends StatelessWidget {
  final Map<String, dynamic> classData;
  final String classId;
  final bool isDesktop;
  const _DetailsTab({required this.classData, required this.classId, required this.isDesktop});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(isDesktop ? 32 : 16),
      child: Column(
        children: [
          _buildInfoCard(),
          const SizedBox(height: 16),
          _buildStudentsList(),
        ],
      ),
    );
  }

  Widget _buildInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.school_rounded, color: Colors.white, size: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        classData['class_name'] ?? 'Class',
                        style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'Code: ${classData['class_code'] ?? '---'}',
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Class Information', style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 16),
                _buildInfoRow(Icons.people_outline, 'Students', '${classData['student_count'] ?? 0}'),
                const SizedBox(height: 12),
                if (classData['subject'] != null && classData['subject'].toString().isNotEmpty) ...[
                  _buildInfoRow(Icons.book_rounded, 'Subject', classData['subject']),
                  const SizedBox(height: 12),
                ],
                _buildInfoRow(Icons.calendar_today, 'Created', _formatDate(classData['created_at'])),
              ],
            ),
          ),
          Container(height: 1, color: const Color(0xFFE2E8F0)),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.description_rounded, color: const Color(0xFF3B82F6), size: 18),
                    const SizedBox(width: 8),
                    const Text('Description', style: TextStyle(color: Color(0xFF1E293B), fontSize: 16, fontWeight: FontWeight.w700)),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  classData['description'] ?? 'No description provided',
                  style: TextStyle(color: const Color(0xFF64748B), fontSize: 14, height: 1.6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentsList() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                const Text('Students', style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.w700)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.people_outline, color: const Color(0xFF3B82F6), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        '${classData['student_count'] ?? 0} enrolled',
                        style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('class_students')
                .where('classId', isEqualTo: classId)
                .snapshots(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(child: CircularProgressIndicator(color: Color(0xFF3B82F6))),
                );
              }
              final students = snapshot.data!.docs;
              if (students.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(40),
                  child: Center(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.people_outline, color: const Color(0xFF3B82F6), size: 32),
                        ),
                        const SizedBox(height: 12),
                        Text('No students enrolled yet', style: TextStyle(color: Color(0xFF64748B), fontSize: 14)),
                      ],
                    ),
                  ),
                );
              }
              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                itemCount: students.length,
                separatorBuilder: (context, index) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final student = students[index].data() as Map<String, dynamic>;
                  final studentName = student['studentName'] ?? student['name'] ?? student['student_name'] ?? 'Student';
                  final email = student['email'] ?? student['studentEmail'] ?? student['student_email'] ?? '';
                  final initials = studentName.trim().isNotEmpty ? studentName[0].toString().toUpperCase() : 'S';

                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              initials,
                              style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                studentName,
                                style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.w600),
                              ),
                              if (email.isNotEmpty)
                                Text(
                                  email,
                                  style: TextStyle(color: const Color(0xFF64748B), fontSize: 13),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.mail_outline, color: Color(0xFF3B82F6), size: 20),
                          onPressed: email.isNotEmpty ? () async {
                            // Could launch mail app
                          } : null,
                          tooltip: email.isNotEmpty ? 'Email student' : 'No email',
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF3B82F6), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(color: const Color(0xFF64748B), fontSize: 12)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 15, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp == null) return 'N/A';
    final date = timestamp is Timestamp ? timestamp.toDate() : DateTime.tryParse(timestamp.toString());
    return date != null ? '${date.day}/${date.month}/${date.year}' : 'N/A';
  }
}