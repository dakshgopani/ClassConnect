import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentAssignmentDetailScreen extends StatefulWidget {
  final String classId;
  final String assignmentId;
  final Map<String, dynamic> assignmentData;

  const StudentAssignmentDetailScreen({
    super.key,
    required this.classId,
    required this.assignmentId,
    required this.assignmentData,
  });

  @override
  State<StudentAssignmentDetailScreen> createState() =>
      _StudentAssignmentDetailScreenState();
}

class _StudentAssignmentDetailScreenState
    extends State<StudentAssignmentDetailScreen> {
  PlatformFile? _pickedFile;
  bool _isSubmitting = false;
  Map<String, dynamic>? _existingSubmission;

  @override
  void initState() {
    super.initState();
    _checkSubmission();
  }

  /// 🔹 Check for existing submission
  Future<void> _checkSubmission() async {
    final studentId = FirebaseAuth.instance.currentUser?.uid;
    if (studentId == null) return;

    final doc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('assignments')
        .doc(widget.assignmentId)
        .collection('submissions')
        .doc(studentId)
        .get();

    if (doc.exists) {
      if (mounted) {
        setState(() {
          _existingSubmission = doc.data();
        });
      }
    }
  }

  /// 🔹 Pick File (Any Type)
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.any);

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  /// 🔹 Submit Assignment
  Future<void> _submitAssignment() async {
    if (_pickedFile == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please attach a file.")));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final student = FirebaseAuth.instance.currentUser;
      if (student == null) return;

      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_pickedFile!.name}';
      final path =
          'student_assignments/${widget.classId}/${widget.assignmentId}/${student.uid}/$fileName';

      // 1. Upload to Supabase Storage
      if (_pickedFile!.bytes != null) {
        // Web or Memory
        await Supabase.instance.client.storage
            .from('assignments')
            .uploadBinary(
              path,
              _pickedFile!.bytes!,
              fileOptions: const FileOptions(upsert: true),
            );
      } else if (_pickedFile!.path != null) {
        // Mobile IO
        await Supabase.instance.client.storage
            .from('assignments')
            .upload(
              path,
              File(_pickedFile!.path!),
              fileOptions: const FileOptions(upsert: true),
            );
      }

      final fullPath = await Supabase.instance.client.storage
          .from('assignments')
          .createSignedUrl(path, 60 * 60 * 24 * 365); // 1 year validity

      // 2. Save metadata to Firestore
      final submissionData = {
        'studentId': student.uid,
        'studentName': student.displayName ?? 'Student',
        'submittedAt': FieldValue.serverTimestamp(),
        'fileUrl': fullPath,
        'fileName': _pickedFile!.name,
        'storagePath': path,
        'status': 'submitted',
      };

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('assignments')
          .doc(widget.assignmentId)
          .collection('submissions')
          .doc(student.uid)
          .set(submissionData);

      setState(() {
        _existingSubmission = submissionData;
        _existingSubmission!['submittedAt'] =
            Timestamp.now(); // Optimistic update
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Work submitted successfully!")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error submitting work: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  /// 🔹 Open URL
  Future<void> _openUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Could not open attachment.")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Determine status color
    final isSubmitted = _existingSubmission != null;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          "Assignment Details",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E2E52),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assignment,
                          color: Color(0xFF3B82F6),
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          widget.assignmentData['title'] ??
                              'Untitled Assignment',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Colors.white10),
                  const SizedBox(height: 12),

                  // Deadline Display
                  if (widget.assignmentData['deadline'] != null) ...[
                    Builder(
                      builder: (context) {
                        final Timestamp deadlineTimestamp =
                            widget.assignmentData['deadline'];
                        final DateTime deadline = deadlineTimestamp.toDate();
                        final bool isOverdue = DateTime.now().isAfter(deadline);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isOverdue
                                ? Colors.red.withOpacity(0.2)
                                : Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isOverdue ? Colors.red : Colors.green,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.access_time,
                                color: isOverdue ? Colors.red : Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                "Due: ${deadline.day}/${deadline.month}/${deadline.year}",
                                style: TextStyle(
                                  color: isOverdue ? Colors.red : Colors.green,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],

                  const Text(
                    "Description",
                    style: TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.assignmentData['description'] ??
                        'No description provided.',
                    style: const TextStyle(
                      color: Colors.white60,
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),

                  if (widget.assignmentData['attachmentUrl'] != null) ...[
                    const SizedBox(height: 20),
                    InkWell(
                      onTap: () =>
                          _openUrl(widget.assignmentData['attachmentUrl']),
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_file,
                              color: Colors.cyanAccent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.assignmentData['attachmentName'] ??
                                    "Attachment",
                                style: const TextStyle(
                                  color: Colors.cyanAccent,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.open_in_new,
                              color: Colors.white30,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Submission Section
            const Text(
              "Your Work",
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            if (isSubmitted)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    const Icon(
                      Icons.check_circle,
                      color: Color(0xFF10B981),
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    const Text(
                      "Submitted successfully!",
                      style: TextStyle(
                        color: Color(0xFF10B981),
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Submitted on ${_existingSubmission!['submittedAt'] is Timestamp ? (_existingSubmission!['submittedAt'] as Timestamp).toDate().toString().split('.')[0] : 'Just now'}",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2E52),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Attach your work",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 12),

                    if (_pickedFile != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.white10),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file,
                              color: Colors.blueAccent,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _pickedFile!.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.redAccent,
                              ),
                              onPressed: () =>
                                  setState(() => _pickedFile = null),
                            ),
                          ],
                        ),
                      )
                    else
                      InkWell(
                        onTap: _pickFile,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 120,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white10,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.upload_file,
                                color: Colors.white30,
                                size: 40,
                              ),
                              SizedBox(height: 8),
                              Text(
                                "Tap to attach file",
                                style: TextStyle(color: Colors.white30),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitAssignment,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cOnSumbitColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isSubmitting
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Hand In",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
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

  Color get cOnSumbitColor => const Color(0xFF3B82F6);
}
