import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'attendance/attendance_marking_screen.dart';
import 'package:demo/screens/teacher/pbl/pbl_main_screen.dart';
import 'package:demo/screens/teacher/quiz/quiz_tab_screen.dart';
import 'package:demo/screens/teacher/resources/teacher_resources_screen.dart';
import 'assignment/create_assignment_screen.dart';

class TeacherClassDetailScreen extends StatefulWidget {
  final String classId;

  const TeacherClassDetailScreen({super.key, required this.classId});

  @override
  State<TeacherClassDetailScreen> createState() =>
      _TeacherClassDetailScreenState();
}

class _TeacherClassDetailScreenState extends State<TeacherClassDetailScreen>
    with SingleTickerProviderStateMixin {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      drawer: _buildDrawer(context),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(
              color: const Color(0xFFF4F8FF),
              child: const Center(
                child: CircularProgressIndicator(color: Color(0xFF2E6BFF)),
              ),
            );
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return Container(
              color: const Color(0xFFF4F8FF),
              child: const Center(
                child: Text(
                  "Class not found",
                  style: TextStyle(color: Color(0xFF0D1B3D)),
                ),
              ),
            );
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final className = data['class_name'] ?? 'Class';

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
                        icon: const Icon(Icons.menu, color: Color(0xFF0D1B3D)),
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
                    // Tab(text: "Homework"),
                    Tab(text: "Details"),
                  ],
                ),
              ),

              // Tab Views
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _PostsTab(classId: widget.classId),
                    _AssignmentsTab(classId: widget.classId),
                    // _HomeworkTab(classId: widget.classId),
                    _DetailsTab(classData: data, classId: widget.classId),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 🔹 SIDE NAVIGATION DRAWER
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      backgroundColor: const Color(0xFFF4F8FF),
      child: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .snapshots(),
        builder: (context, classSnapshot) {
          final classData = classSnapshot.data?.data() as Map<String, dynamic>?;
          final className = classData?['class_name'] ?? 'Class';
          final classCode = classData?['class_code'] ?? '---';
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
                    colors: [const Color(0xFF1E3A8A), const Color(0xFF3B82F6)],
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
                      'Code: $classCode',
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
                            builder: (context) =>
                                TeacherResourcesScreen(classId: widget.classId),
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
                            builder: (context) =>
                                QuizTabScreen(classId: widget.classId),
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
                            color: const Color(0xFF5C6B8C),
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
            color: iconColor.withOpacity(0.2),
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
}

// 🔹 POSTS TAB
class _PostsTab extends StatefulWidget {
  final String classId;

  const _PostsTab({required this.classId});

  @override
  State<_PostsTab> createState() => _PostsTabState();
}

class _PostsTabState extends State<_PostsTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _attachmentUrl;
  String? _attachmentName;
  bool _isPosting = false;

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
      );

      if (result != null) {
        setState(() => _isPosting = true);

        final file = result.files.first;
        final fileName = file.name;
        final ref = FirebaseStorage.instance
            .ref()
            .child('posts')
            .child(widget.classId)
            .child('${DateTime.now().millisecondsSinceEpoch}_$fileName');

        if (file.bytes != null) {
          await ref.putData(file.bytes!);
        } else if (file.path != null) {
          await ref.putFile(File(file.path!));
        }

        final url = await ref.getDownloadURL();

        setState(() {
          _attachmentUrl = url;
          _attachmentName = fileName;
          _isPosting = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('File attached: $fileName'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isPosting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendPost() async {
    final message = _messageController.text.trim();

    if (message.isEmpty && _attachmentUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a message or attach a file'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final teacherId = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('posts')
          .add({
            'message': message,
            'attachmentUrl': _attachmentUrl,
            'attachmentName': _attachmentName,
            'publishedAt': FieldValue.serverTimestamp(),
            'teacherId': teacherId,
            'type': 'announcement',
          });

      _messageController.clear();
      setState(() {
        _attachmentUrl = null;
        _attachmentName = null;
        _isPosting = false;
      });

      // Scroll to bottom
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    } catch (e) {
      setState(() => _isPosting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error posting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F8FF),
      child: Column(
        children: [
          // Posts Feed
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('posts')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E6BFF)),
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
                          color: Colors.red.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading posts',
                          style: TextStyle(
                            color: const Color(0xFF0D1B3D),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            color: const Color(0xFF5C6B8C),
                            fontSize: 12,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 64,
                          color: const Color(0xFFA5B2C8),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No posts yet',
                          style: TextStyle(
                            color: const Color(0xFF0D1B3D),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Start by posting an announcement below',
                          style: TextStyle(
                            color: const Color(0xFF5C6B8C),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sort posts by publishedAt in memory (oldest first)
                final posts = snapshot.data!.docs.toList();
                posts.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['publishedAt'] as Timestamp?;
                  final bTime = bData['publishedAt'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return aTime.compareTo(
                    bTime,
                  ); // Ascending order (oldest first)
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: posts.length,
                  itemBuilder: (context, index) {
                    final post = posts[index];
                    final data = post.data() as Map<String, dynamic>;

                    return _buildPostCard(data, post.id);
                  },
                );
              },
            ),
          ),

          // Input Area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: const BorderSide(color: Color(0x1A2E6BFF))),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Attachment Preview
                if (_attachmentName != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF4F8FF),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0x1A2E6BFF)),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.attach_file,
                          color: Color(0xFF3B82F6),
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _attachmentName!,
                            style: const TextStyle(
                              color: Color(0xFF0D1B3D),
                              fontSize: 13,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _attachmentUrl = null;
                              _attachmentName = null;
                            });
                          },
                        ),
                      ],
                    ),
                  ),

                // Input Row
                Row(
                  children: [
                    // Attach File Button
                    IconButton(
                      onPressed: _isPosting ? null : _pickAndUploadFile,
                      icon: Icon(
                        Icons.attach_file,
                        color: _isPosting
                            ? const Color(0xFFA5B2C8)
                            : const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Text Input
                    Expanded(
                      child: TextField(
                        controller: _messageController,
                        enabled: !_isPosting,
                        style: const TextStyle(color: Color(0xFF0D1B3D)),
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: 'Write a post...',
                          hintStyle: const TextStyle(color: Color(0xFF8DA6D8)),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Send Button
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        onPressed: _isPosting ? null : _sendPost,
                        icon: _isPosting
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.send, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(Map<String, dynamic> data, String postId) {
    final message = data['message'] as String? ?? '';
    final attachmentUrl = data['attachmentUrl'] as String?;
    final attachmentName = data['attachmentName'] as String?;
    final publishedAt = data['publishedAt'] as Timestamp?;

    return Container(
      key: ValueKey('post_$postId'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A2E6BFF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E6BFF).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF3B82F6).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.person,
                  color: Color(0xFF3B82F6),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Teacher',
                      style: TextStyle(
                        color: Color(0xFF0D1B3D),
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                    if (publishedAt != null)
                      Text(
                        _formatTimestamp(publishedAt),
                        style: TextStyle(
                          color: const Color(0xFF5C6B8C),
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),

          // Message
          if (message.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              message,
              style: const TextStyle(
                color: Color(0xFF0D1B3D),
                fontSize: 15,
                height: 1.4,
              ),
            ),
          ],

          // Attachment
          if (attachmentUrl != null && attachmentName != null) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: () {
                // Open attachment URL
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Opening: $attachmentName')),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x1A2E6BFF)),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getFileIcon(attachmentName),
                      color: const Color(0xFF3B82F6),
                      size: 24,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        attachmentName,
                        style: const TextStyle(
                          color: Color(0xFF0D1B3D),
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(
                      Icons.download,
                      color: Color(0xFFA5B2C8),
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData _getFileIcon(String fileName) {
    final ext = fileName.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatTimestamp(Timestamp timestamp) {
    final dt = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inDays > 0) {
      return '${dt.day}/${dt.month}/${dt.year}';
    } else if (diff.inHours > 0) {
      return '${diff.inHours}h ago';
    } else if (diff.inMinutes > 0) {
      return '${diff.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}

// 🔹 ASSIGNMENTS TAB
class _AssignmentsTab extends StatelessWidget {
  final String classId;

  const _AssignmentsTab({required this.classId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F8FF),
      child: Column(
        children: [
          // Create Assignment Button
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          CreateAssignmentScreen(classId: classId),
                    ),
                  );
                },
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Create New Assignment',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
          // Assignment List
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(classId)
                  .collection('assignments')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: Color(0xFF2E6BFF)),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64,
                            color: Colors.red.withOpacity(0.5),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            "Error loading assignments",
                            style: TextStyle(
                              color: const Color(0xFF0D1B3D),
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "${snapshot.error}",
                            style: TextStyle(
                              color: const Color(0xFF5C6B8C),
                              fontSize: 12,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.assignment_outlined,
                          size: 64,
                          color: const Color(0xFF2E6BFF).withOpacity(0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "No assignments yet",
                          style: TextStyle(
                            color: const Color(0xFF0D1B3D),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Create your first assignment above",
                          style: TextStyle(
                            color: const Color(0xFF5C6B8C),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sort assignments by createdAt in memory
                final docs = snapshot.data!.docs.toList();
                docs.sort((a, b) {
                  final aData = a.data() as Map<String, dynamic>;
                  final bData = b.data() as Map<String, dynamic>;
                  final aTime = aData['createdAt'] as Timestamp?;
                  final bTime = bData['createdAt'] as Timestamp?;
                  if (aTime == null || bTime == null) return 0;
                  return bTime.compareTo(aTime);
                });

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return Container(
                      key: ValueKey('assignment_${doc.id}'),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x1A2E6BFF)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF2E6BFF).withOpacity(0.06),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E6BFF).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.assignment,
                            color: Color(0xFF3B82F6),
                          ),
                        ),
                        title: Text(
                          data['title'] ?? 'Assignment',
                          style: const TextStyle(
                            color: Color(0xFF0D1B3D),
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(
                              data['description'] ?? '',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: const Color(0xFF5C6B8C),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 8),
                            if (data['dueDate'] != null)
                              Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today,
                                    size: 12,
                                    color: const Color(0xFFA5B2C8),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'Due: ${_formatDate(data['dueDate'])}',
                                    style: TextStyle(
                                      color: const Color(0xFF5C6B8C),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        trailing: Icon(
                          Icons.chevron_right,
                          color: const Color(0xFFA5B2C8),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '';
    try {
      if (date is Timestamp) {
        final DateTime dt = date.toDate();
        return '${dt.day}/${dt.month}/${dt.year}';
      }
      return date.toString();
    } catch (e) {
      return '';
    }
  }
}

// 🔹 HOMEWORK TAB
// class _HomeworkTab extends StatelessWidget {
//   final String classId;

//   const _HomeworkTab({required this.classId});

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       color: const Color(0xFF0F1C3F),
//       child: Center(
//         child: Column(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.book_outlined,
//               size: 64,
//               color: Colors.white.withOpacity(0.3),
//             ),
//             const SizedBox(height: 16),
//             Text(
//               "Homework feature coming soon",
//               style: TextStyle(
//                 color: Colors.white.withOpacity(0.6),
//                 fontSize: 16,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// 🔹 DETAILS TAB (Original content)
class _DetailsTab extends StatelessWidget {
  final Map<String, dynamic> classData;
  final String classId;

  const _DetailsTab({required this.classData, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFF4F8FF),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            _buildHeaderCard(classData),

            const SizedBox(height: 24),

            // Description Section
            const Text(
              "About Class",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B3D),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x1A2E6BFF)),
              ),
              child: Text(
                classData['description'] ?? "No description provided",
                style: const TextStyle(
                  fontSize: 15,
                  color: Color(0xFF5C6B8C),
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Students Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Students",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF0D1B3D),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E6BFF).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${classData['student_count'] ?? 0} Joined",
                    style: const TextStyle(
                      color: Color(0xFF0D1B3D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Student List View (Embedded)
            _buildStudentList(classId),

            const SizedBox(height: 32),

            // Delete Class Button
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade300,
                    size: 32,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Danger Zone",
                    style: TextStyle(
                      color: Color(0xFF0D1B3D),
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: ElevatedButton.icon(
                      onPressed: () =>
                          _showDeleteConfirmation(context, classData),
                      icon: const Icon(
                        Icons.delete_forever,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Delete Class',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red.shade700,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Map<String, dynamic> classData,
  ) {
    final classCode = classData['class_code'] ?? '';
    final className = classData['class_name'] ?? 'Class';
    final TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red.shade400,
              size: 28,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Delete Class',
                style: TextStyle(
                  color: Color(0xFF0D1B3D),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Are you sure you want to permanently delete "$className"?',
                style: const TextStyle(color: Color(0xFF5C6B8C), fontSize: 15),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.withOpacity(0.3)),
                ),
                child: const Text(
                  '⚠️ This action cannot be undone. All class data, assignments, posts, and student records will be permanently deleted.',
                  style: TextStyle(
                    color: Colors.redAccent,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'To confirm, please enter the class code:',
                style: TextStyle(
                  color: Color(0xFF0D1B3D),
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F8FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0x1A2E6BFF)),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.qr_code,
                      color: Color(0xFF2E6BFF),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      classCode,
                      style: const TextStyle(
                        color: Color(0xFF0D1B3D),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                style: const TextStyle(
                  color: Color(0xFF0D1B3D),
                  fontSize: 16,
                  letterSpacing: 2,
                ),
                decoration: InputDecoration(
                  hintText: 'Enter class code',
                  hintStyle: TextStyle(color: const Color(0xFF8DA6D8)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0x1A2E6BFF)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0x1A2E6BFF)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Colors.red, width: 2),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              codeController.dispose();
              Navigator.pop(dialogContext);
            },
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF5C6B8C)),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.trim() == classCode) {
                codeController.dispose();
                Navigator.pop(dialogContext);
                Future<void>.microtask(() => _deleteClass(context));
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Incorrect class code. Please try again.'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
            ),
            child: const Text(
              'Delete Permanently',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteClass(BuildContext context) async {
    try {
      if (!context.mounted) return;

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: Color(0xFF2E6BFF)),
        ),
      );

      // Delete the class document
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .delete();

      // Delete subcollections (posts, assignments, etc.)
      final postsQuery = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('posts')
          .get();
      for (var doc in postsQuery.docs) {
        await doc.reference.delete();
      }

      final assignmentsQuery = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('assignments')
          .get();
      for (var doc in assignmentsQuery.docs) {
        await doc.reference.delete();
      }

      // Delete class_students entries
      final studentEnrollments = await FirebaseFirestore.instance
          .collection('class_students')
          .where('classId', isEqualTo: classId)
          .get();
      for (var doc in studentEnrollments.docs) {
        await doc.reference.delete();
      }

      if (context.mounted) {
        Navigator.of(
          context,
          rootNavigator: true,
        ).pop(); // Close loading dialog
        Navigator.pop(context); // Go back to previous screen
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Class deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        if (Navigator.of(context, rootNavigator: true).canPop()) {
          Navigator.of(
            context,
            rootNavigator: true,
          ).pop(); // Close loading dialog
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting class: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildHeaderCard(Map<String, dynamic> data) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E6BFF).withOpacity(0.06),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data['class_name'] ?? 'Class Name',
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B3D),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            data['subject'] ?? 'Subject',
            style: TextStyle(fontSize: 16, color: const Color(0xFF5C6B8C)),
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF2E6BFF).withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1A2E6BFF)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.qr_code, color: Color(0xFF2E6BFF), size: 20),
                const SizedBox(width: 10),
                Text(
                  "Code: ${data['class_code']}",
                  style: const TextStyle(
                    color: Color(0xFF0D1B3D),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStudentList(String classId) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('class_students')
          .where('classId', isEqualTo: classId)
          .snapshots(),
      builder: (context, studentSnap) {
        if (!studentSnap.hasData || studentSnap.data!.docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                children: [
                  Icon(
                    Icons.person_off_outlined,
                    size: 40,
                    color: const Color(0xFFA5B2C8),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "No students joined yet",
                    style: TextStyle(color: Color(0xFF5C6B8C)),
                  ),
                ],
              ),
            ),
          );
        }

        final students = studentSnap.data!.docs;

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: students.length,
          itemBuilder: (context, index) {
            final doc = students[index];
            final String studentId = doc['studentId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('students')
                  .doc(studentId)
                  .get(),
              builder: (context, snap) {
                if (!snap.hasData || !snap.data!.exists) {
                  return const SizedBox();
                }

                final studentData = snap.data!.data() as Map<String, dynamic>;
                final String name = studentData['name'] ?? 'Student';
                final String? photoURL = studentData['photoURL'];

                return Container(
                  key: ValueKey('student_$studentId'),
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0x1A2E6BFF)),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E6BFF).withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    leading: ClipOval(
                      child: photoURL != null
                          ? Image.network(
                              photoURL,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (
                                    BuildContext context,
                                    Object error,
                                    StackTrace? stackTrace,
                                  ) {
                                    return Container(
                                      width: 48,
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: const Color(
                                          0xFF2E6BFF,
                                        ).withOpacity(0.08),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Text(
                                        name.isNotEmpty
                                            ? name[0].toUpperCase()
                                            : '?',
                                        style: const TextStyle(
                                          color: Color(0xFF0D1B3D),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                        ),
                                      ),
                                    );
                                  },
                            )
                          : Container(
                              width: 48,
                              height: 48,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(
                                  0xFF2E6BFF,
                                ).withOpacity(0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  color: Color(0xFF0D1B3D),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                    ),
                    title: Text(
                      name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                        color: Color(0xFF0D1B3D),
                      ),
                    ),
                    subtitle: Text(
                      studentId,
                      style: const TextStyle(
                        color: Color(0xFF5C6B8C),
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
