// import 'dart:io'; // removed for web compatibility
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/theme/app_colors.dart';
import 'package:demo/theme/app_spacing.dart';
import 'package:demo/widgets/ui/cc_button.dart';
import 'package:demo/widgets/ui/cc_card.dart';
import 'package:demo/widgets/ui/cc_section_header.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:demo/services/pbl_supabase_client.dart';
import 'package:demo/widgets/cc_breadcrumb_bar.dart';

class StudentAssignmentDetailScreen extends StatefulWidget {
  final String classId;
  final String assignmentId;
  final Map<String, dynamic> assignmentData;
  final String? className;

  const StudentAssignmentDetailScreen({
    super.key,
    required this.classId,
    required this.assignmentId,
    required this.assignmentData,
    this.className,
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
      final supabase = PblSupabaseClient.client;

      // 1. Upload to Supabase Storage
      // Upload using binary data (available on both web and mobile when bytes are provided)
      if (_pickedFile!.bytes != null) {
        await supabase.storage
            .from('assignments')
            .uploadBinary(
              path,
              _pickedFile!.bytes!,
              fileOptions: const FileOptions(upsert: true),
            );
      } else {
        // If bytes are not available, show an error (fallback could be implemented later)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read file data for upload.')),
        );
        return;
      }

      final fullPath = await supabase.storage
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

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');
    return '$day/$month/$year, $hour:$minute';
  }

  String _submissionTimeLabel() {
    final submittedAt = _existingSubmission?['submittedAt'];
    if (submittedAt is Timestamp) {
      return _formatDateTime(submittedAt.toDate());
    }
    return 'Just now';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isSubmitted = _existingSubmission != null;
    final deadline = widget.assignmentData['deadline'] is Timestamp
        ? (widget.assignmentData['deadline'] as Timestamp).toDate()
        : null;
    final isOverdue = deadline != null && DateTime.now().isAfter(deadline);
    final title = widget.assignmentData['title'] ?? 'Untitled Assignment';
    final description =
        widget.assignmentData['description'] ?? 'No description provided.';

    final classTitle = widget.className ?? 'Class';
    return Scaffold(
      backgroundColor: AppColors.background,
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
              BreadcrumbItem(
                label: 'Assignments',
                onTap: () => Navigator.pop(context),
              ),
              BreadcrumbItem(label: title),
            ],
          ),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 900),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CcCard(
                        padding: const EdgeInsets.all(20),
              glass: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.assignment,
                          color: AppColors.primary,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Divider(color: Color(0x224A6FBF)),
                  const SizedBox(height: 12),

                  if (deadline != null) ...[
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: (isOverdue ? AppColors.error : AppColors.success)
                            .withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isOverdue
                              ? AppColors.error
                              : AppColors.success,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.schedule,
                            color: isOverdue
                                ? AppColors.error
                                : AppColors.success,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Due: ${_formatDateTime(deadline).split(',').first}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: isOverdue
                                  ? AppColors.error
                                  : AppColors.success,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  Text(
                    'Description',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: AppColors.textPrimary,
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
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_file,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                widget.assignmentData['attachmentName'] ??
                                    'Attachment',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.open_in_new,
                              color: AppColors.textMuted,
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

            const CcSectionHeader(
              title: 'Your Work',
              subtitle: 'Attach and submit your assignment file.',
            ),
            const SizedBox(height: 12),

            if (isSubmitted)
              CcCard(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.success.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.check_circle,
                        color: AppColors.success,
                        size: 48,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Submitted successfully!',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.success,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Submitted on ${_submissionTimeLabel()}',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              CcCard(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attach your work',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_pickedFile != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 20),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceAlt,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.25),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _pickedFile!.name,
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: AppColors.error,
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
                            color: AppColors.surfaceAlt,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.22),
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.upload_file,
                                color: AppColors.primary,
                                size: 40,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to attach file',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 20),

                      CcButton(
                        label: 'Hand In',
                        isLoading: _isSubmitting,
                        icon: const Icon(Icons.send_rounded, color: Colors.white),
                        onPressed: _submitAssignment,
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    ),
  ),
],
),
);
  }
}
