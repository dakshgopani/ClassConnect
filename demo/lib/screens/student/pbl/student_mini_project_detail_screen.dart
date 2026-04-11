import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/services/groq_service.dart';
import 'package:file_picker/file_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:path/path.dart' as path;
import 'package:demo/widgets/ui/cc_decorated_background.dart';

class StudentMiniProjectDetailScreen extends StatefulWidget {
  final String classId;
  final String pblId;
  final String studentId;
  final Map<String, dynamic> selectionData;
  final Map<String, dynamic> pblData;

  const StudentMiniProjectDetailScreen({
    super.key,
    required this.classId,
    required this.pblId,
    required this.studentId,
    required this.selectionData,
    required this.pblData,
  });

  @override
  State<StudentMiniProjectDetailScreen> createState() =>
      _StudentMiniProjectDetailScreenState();
}

class _StudentMiniProjectDetailScreenState
    extends State<StudentMiniProjectDetailScreen> {
  static const _surface = Colors.white;
  static const _surfaceLight = Color(0xFFF0F4FF);
  static const _accent = Color(0xFF2E6BFF);
  static const _textPrimary = Color(0xFF0D1B3D);
  static const _textSecondary = Color(0xFF5C6B8C);

  bool _isLoading = true;
  List<Map<String, dynamic>> _steps = [];
  String? _error;

  // Submission State
  PlatformFile? _selectedFile;
  bool _isUploading = false;
  bool _isSubmitted = false;
  String? _submissionUrl;

  @override
  void initState() {
    super.initState();
    _loadOrGenerateSteps();
  }

  Future<void> _loadOrGenerateSteps() async {
    try {
      final docRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('PBL')
          .doc(widget.pblId)
          .collection('selections')
          .doc(widget.studentId);

      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data()!;

        // 1. Check Submission Status
        if (data.containsKey('submitted') && data['submitted'] == true) {
          _isSubmitted = true;
          _submissionUrl = data['submissionUrl'];
        }

        // 2. Load Steps
        if (data.containsKey('steps')) {
          _steps = List<Map<String, dynamic>>.from(data['steps']);
          setState(() {
            _isLoading = false;
          });
        } else {
          // New: generate steps if document exists but steps don't (rare case or migration)
          await _generateAndSaveSteps(docRef);
        }
      } else {
        // Should usually exist if we are here, but just in case
        await _generateAndSaveSteps(docRef);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load steps: $e';
        });
      }
    }
  }

  Future<void> _generateAndSaveSteps(DocumentReference docRef) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final classDoc = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .get();
    final subject = classDoc.data()?['subject'] ?? 'General';

    final generatedSteps = await GroqService.generateProjectSteps(
      title: widget.selectionData['title'],
      description: widget.selectionData['description'] ?? '',
      subject: subject,
    );

    _steps = generatedSteps.map((s) => {...s, 'completed': false}).toList();

    await docRef.set({'steps': _steps}, SetOptions(merge: true));

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleStep(int index) async {
    // Don't allow editing if submitted
    if (_isSubmitted) return;

    setState(() {
      _steps[index]['completed'] = !(_steps[index]['completed'] ?? false);
    });

    try {
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('PBL')
          .doc(widget.pblId)
          .collection('selections')
          .doc(widget.studentId)
          .update({'steps': _steps});
    } catch (e) {
      debugPrint('Error updating step: $e');
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          _selectedFile = result.files.first;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error picking file: $e")));
    }
  }

  Future<void> _submitMiniProject() async {
    if (_selectedFile == null) return;

    setState(() {
      _isUploading = true;
    });

    try {
      final fileBytes = _selectedFile!.bytes;
      final fileName = _selectedFile!.name;
      // If bytes are null (e.g. on mobile sometimes if not read to stream), try path
      // Web always has bytes. Mac/Windows usually path.
      // Supabase uploadBinary needs bytes or file.

      final supabase = Supabase.instance.client;
      final uniqueName = '${DateTime.now().millisecondsSinceEpoch}_$fileName';
      final storagePath =
          'mini_projects/${widget.classId}/${widget.pblId}/${widget.studentId}/$uniqueName';

      // Upload
      if (fileBytes != null) {
        await supabase.storage
            .from('PBL - PROJECTS')
            .uploadBinary(storagePath, fileBytes);
      } else if (_selectedFile!.path != null) {
        await supabase.storage
            .from('PBL - PROJECTS')
            .upload(storagePath, File(_selectedFile!.path!));
      } else {
        throw Exception("Cannot read file data");
      }

      // Get Public URL
      final publicUrl = supabase.storage
          .from('PBL - PROJECTS')
          .getPublicUrl(storagePath);

      // Update Firestore
      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('PBL')
          .doc(widget.pblId)
          .collection('selections')
          .doc(widget.studentId)
          .update({
            'submitted': true,
            'submissionUrl': publicUrl,
            'fileName': fileName,
            'submittedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        setState(() {
          _isSubmitted = true;
          _isUploading = false;
          _submissionUrl = publicUrl;
          _selectedFile = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Project Submitted Successfully! 🚀"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Upload Failed: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = _steps.length;
    final completed = _steps.where((s) => s['completed'] == true).length;
    final progress = total == 0 ? 0.0 : completed / total;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        foregroundColor: const Color(0xFF0D1B3D),
        title: const Text(
          'Project Guidelines',
          style: TextStyle(color: Color(0xFF0D1B3D)),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0D1B3D),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: Colors.cyan),
                  SizedBox(height: 16),
                  Text(
                    "Generating personalized guidelines...",
                    style: TextStyle(color: Color(0xFF5C6B8C)),
                  ),
                ],
              ),
            )
          : _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.redAccent,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFF5C6B8C)),
                    ),
                    const SizedBox(height: 24),
                    OutlinedButton(
                      onPressed: _loadOrGenerateSteps,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : CcDecoratedBackground(
              child: Column(
                children: [
                  // Header Info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: _surface,
                      border: Border(bottom: BorderSide(color: _surfaceLight)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.selectionData['title'],
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: _textPrimary,
                                ),
                              ),
                            ),
                            if (_isSubmitted)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.green),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle,
                                      size: 16,
                                      color: Colors.greenAccent,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      "SUBMITTED",
                                      style: TextStyle(
                                        color: Colors.greenAccent,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.selectionData['description'] ?? '',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF5C6B8C),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Progress Bar
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "Progress: ${completed}/${total} Steps",
                              style: const TextStyle(
                                color: _accent,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              "${(progress * 100).toInt()}%",
                              style: const TextStyle(color: _textSecondary),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: progress,
                          backgroundColor: Color(0x142E6BFF),
                          color: _accent,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ],
                    ),
                  ),

                  // Steps List
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _steps.length,
                      itemBuilder: (context, index) {
                        final step = _steps[index];
                        final isDone = step['completed'] == true;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: isDone
                                ? Colors.green.withOpacity(0.1)
                                : const Color(0xFF0D1B3D).withOpacity(0.05),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDone
                                  ? Colors.green.withOpacity(0.5)
                                  : Color(0x142E6BFF),
                            ),
                          ),
                          child: Theme(
                            data: Theme.of(context).copyWith(
                              unselectedWidgetColor: Color(0xFF7A89A8),
                            ),
                            child: CheckboxListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              value: isDone,
                              onChanged: (val) => _toggleStep(index),
                              activeColor: Colors.green,
                              checkColor: const Color(0xFF0D1B3D),
                              title: Text(
                                "Step ${index + 1}: ${step['title']}",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDone
                                      ? Colors.green.shade200
                                      : const Color(0xFF0D1B3D),
                                  decoration: isDone
                                      ? TextDecoration.lineThrough
                                      : null,
                                ),
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  step['description'],
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isDone
                                        ? Color(0xFFA5B2C8)
                                        : Color(0xFF5C6B8C),
                                  ),
                                ),
                              ),
                              controlAffinity: ListTileControlAffinity.leading,
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Bottom Action (Submit)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      color: const Color(0xFFF4F8FF),
                      border: Border(top: BorderSide(color: Color(0x1A2E6BFF))),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isSubmitted) ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.check_circle_outline,
                                    color: Colors.green,
                                    size: 28,
                                  ),
                                  const SizedBox(width: 12),
                                  const Text(
                                    "Project Submitted",
                                    style: TextStyle(
                                      color: Colors.green,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            // File Selection
                            if (_selectedFile != null)
                              Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: _surfaceLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: const Color(0x1A2E6BFF),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      Icons.description,
                                      color: Color(0xFF5C6B8C),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        _selectedFile!.name,
                                        style: const TextStyle(
                                          color: const Color(0xFF0D1B3D),
                                          fontWeight: FontWeight.bold,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () =>
                                          setState(() => _selectedFile = null),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),

                            // Buttons
                            Row(
                              children: [
                                if (_selectedFile == null)
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: _pickFile,
                                      icon: const Icon(Icons.attach_file),
                                      label: const Text("Attach File"),
                                      style: OutlinedButton.styleFrom(
                                        foregroundColor: const Color(
                                          0xFF0D1B3D,
                                        ),
                                        side: const BorderSide(
                                          color: Color(0xFF7A89A8),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_selectedFile != null) ...[
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: _isUploading
                                          ? null
                                          : _submitMiniProject,
                                      icon: _isUploading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.black,
                                              ),
                                            )
                                          : const Icon(
                                              Icons.cloud_upload_rounded,
                                            ),
                                      label: Text(
                                        _isUploading
                                            ? "Uploading..."
                                            : "Submit Work",
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.cyan,
                                        foregroundColor: Colors.black,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 16,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
