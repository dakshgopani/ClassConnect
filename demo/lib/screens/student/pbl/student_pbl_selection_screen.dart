import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo/widgets/ui/cc_decorated_background.dart';

class StudentPblSelectionScreen extends StatefulWidget {
  final String classId;
  final String pblId;
  final String title;
  final String problemStatement;
  final List<dynamic> miniProjects;

  const StudentPblSelectionScreen({
    super.key,
    required this.classId,
    required this.pblId,
    required this.title,
    required this.problemStatement,
    required this.miniProjects,
  });

  @override
  State<StudentPblSelectionScreen> createState() =>
      _StudentPblSelectionScreenState();
}

class _StudentPblSelectionScreenState extends State<StudentPblSelectionScreen> {
  static const _bg = Color(0xFFF4F8FF);
  static const _surface = Colors.white;
  static const _surfaceLight = Color(0xFFF0F4FF);
  static const _accent = Color(0xFF2E6BFF);
  static const _textPrimary = Color(0xFF0D1B3D);
  static const _textSecondary = Color(0xFF5C6B8C);

  final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
  String? _selectedProjectTitle;
  DateTime? _selectedAt;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _checkSelection();
  }

  Future<void> _checkSelection() async {
    if (userId.isEmpty) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('PBL')
          .doc(widget.pblId)
          .collection('selections')
          .doc(userId)
          .get();

      if (doc.exists) {
        setState(() {
          _selectedProjectTitle = doc['title'];
          _selectedAt = (doc['selectedAt'] as Timestamp?)?.toDate();
        });
      }
    } catch (e) {
      debugPrint('Error checking selection: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _selectProject(String projectTitle, String description) async {
    if (userId.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Selection'),
        content: Text(
          'Are you sure you want to select "$projectTitle"? You cannot change this later.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // Fetch student data
      String studentName = 'Unknown Student';
      String studentEmail = '';
      try {
        final studentDoc = await FirebaseFirestore.instance
            .collection('students')
            .doc(userId)
            .get();
        if (studentDoc.exists) {
          final data = studentDoc.data()!;
          studentName = '${data['firstName']} ${data['lastName']}'.trim();
          studentEmail = data['email'] ?? '';
        }
      } catch (e) {
        debugPrint('Error fetching student info: $e');
      }

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('PBL')
          .doc(widget.pblId)
          .collection('selections')
          .doc(userId)
          .set({
            'title': projectTitle,
            'description': description,
            'selectedAt': FieldValue.serverTimestamp(),
            'studentId': userId,
            'studentName': studentName,
            'studentEmail': studentEmail,
          });

      setState(() {
        _selectedProjectTitle = projectTitle;
        _selectedAt = DateTime.now();
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project selected successfully!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error selecting project: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text('Select Mini Project'),
        backgroundColor: _bg,
        elevation: 0,
      ),
      body: CcDecoratedBackground(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('classes')
              .doc(widget.classId)
              .collection('PBL')
              .doc(widget.pblId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting &&
                _isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            final pblData = snapshot.data?.data() as Map<String, dynamic>?;
            final currentMiniProjects =
                (pblData?['miniProjects'] as List?)
                    ?.map((e) => Map<String, dynamic>.from(e as Map))
                    .toList() ??
                widget.miniProjects;

            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_selectedProjectTitle != null) ...[
                    // Show Selected Project
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.green.withValues(alpha: 0.08),
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'You selected:',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _selectedProjectTitle!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: _textPrimary,
                            ),
                          ),
                          if (_selectedAt != null) ...[
                            const SizedBox(height: 8),
                            Text(
                              'Selected on: ${_selectedAt!.toString().split(' ')[0]}',
                              style: const TextStyle(color: _textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ] else ...[
                    // List Options
                    const Text(
                      'Choose a Mini Project',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (currentMiniProjects.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange.shade700),
                        ),
                        child: const Row(
                          children: [
                            Icon(
                              Icons.warning_amber_rounded,
                              color: Colors.orange,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'No mini projects available. Ask your teacher to regenerate the project details.',
                                style: TextStyle(color: _textSecondary),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: currentMiniProjects.length,
                        itemBuilder: (context, index) {
                          var project = currentMiniProjects[index];
                          // Handle dynamic map if needed
                          if (project is! Map) {
                            project = {
                              'title': 'Error',
                              'description': 'Invalid data format',
                            };
                          }
                          final title = project['title'] ?? 'Untitled';
                          final desc = project['description'] ?? '';

                          return Card(
                            color: _surface,
                            margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: const Color(0x1A2E6BFF)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: _textPrimary,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    desc,
                                    style: const TextStyle(
                                      color: _textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: OutlinedButton(
                                      onPressed: () =>
                                          _selectProject(title, desc),
                                      style: OutlinedButton.styleFrom(
                                        side: const BorderSide(color: _accent),
                                        foregroundColor: _accent,
                                      ),
                                      child: const Text('Select this Project'),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
