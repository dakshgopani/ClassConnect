import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateAssignmentScreen extends StatefulWidget {
  final String classId;

  const CreateAssignmentScreen({super.key, required this.classId});

  @override
  State<CreateAssignmentScreen> createState() => _CreateAssignmentScreenState();
}

class _CreateAssignmentScreenState extends State<CreateAssignmentScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descController = TextEditingController();

  PlatformFile? _pickedFile;
  bool _isLoading = false;

  /// 🔹 Pick File (PDF/Doc)
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx'],
    );

    if (result != null) {
      setState(() {
        _pickedFile = result.files.first;
      });
    }
  }

  DateTime? _deadline;

  /// 🔹 Pick Deadline
  Future<void> _pickDeadline() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      setState(() => _deadline = picked);
    }
  }

  /// 🔹 Upload & Post Assignment
  Future<void> _postAssignment() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      String? attachmentUrl;
      String? attachmentName;

      // 1. Upload File (if any) to Firebase Storage
      if (_pickedFile != null) {
        attachmentName = _pickedFile!.name;
        final ref = FirebaseStorage.instance
            .ref()
            .child('assignments')
            .child(widget.classId)
            .child('${DateTime.now().millisecondsSinceEpoch}_$attachmentName');

        if (_pickedFile!.bytes != null) {
          // Web or Memory
          await ref.putData(_pickedFile!.bytes!);
        } else if (_pickedFile!.path != null) {
          // Mobile
          await ref.putFile(File(_pickedFile!.path!));
        }

        attachmentUrl = await ref.getDownloadURL();
      }

      // 2. Save to Firestore
      final teacherId = FirebaseAuth.instance.currentUser?.uid;

      await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('assignments')
          .add({
            'title': _titleController.text.trim(),
            'description': _descController.text.trim(),
            'attachmentUrl': attachmentUrl,
            'attachmentName': attachmentName,
            'createdAt': FieldValue.serverTimestamp(),
            'teacherId': teacherId,
            'deadline': _deadline != null
                ? Timestamp.fromDate(_deadline!)
                : null,
          });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Assignment posted successfully!")),
        );
        Navigator.pop(context);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          "Create Assignment",
          style: TextStyle(color: Color(0xFF0D1B3D)),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0D1B3D)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              const Text(
                "Title",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B3D),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _titleController,
                style: const TextStyle(color: Color(0xFF0D1B3D)),
                decoration: InputDecoration(
                  hintText: "Enter assignment title",
                  hintStyle: const TextStyle(color: Color(0xFF8DA6D8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0x1A2E6BFF)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) =>
                    val == null || val.isEmpty ? "Title is required" : null,
              ),

              const SizedBox(height: 20),

              // Description
              const Text(
                "Description",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B3D),
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _descController,
                maxLines: 5,
                style: const TextStyle(color: Color(0xFF0D1B3D)),
                decoration: InputDecoration(
                  hintText: "Enter instructions...",
                  hintStyle: const TextStyle(color: Color(0xFF8DA6D8)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: const BorderSide(color: Color(0x1A2E6BFF)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                ),
                validator: (val) => val == null || val.isEmpty
                    ? "Description is required"
                    : null,
              ),

              const SizedBox(height: 20),

              // Deadline
              const Text(
                "Deadline",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B3D),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickDeadline,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x1A2E6BFF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        color: Color(0xFF2E6BFF),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        _deadline != null
                            ? "${_deadline!.day}/${_deadline!.month}/${_deadline!.year}"
                            : "Select Deadline",
                        style: TextStyle(
                          color: _deadline != null
                              ? const Color(0xFF0D1B3D)
                              : const Color(0xFF8DA6D8),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Attachment
              const Text(
                "Attachment (Optional)",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B3D),
                ),
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0x1A2E6BFF)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.attach_file, color: Color(0xFF2E6BFF)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _pickedFile != null
                              ? _pickedFile!.name
                              : "Attach PDF or Doc",
                          style: TextStyle(
                            color: _pickedFile != null
                                ? const Color(0xFF0D1B3D)
                                : const Color(0xFF8DA6D8),
                          ),
                        ),
                      ),
                      if (_pickedFile != null)
                        IconButton(
                          icon: const Icon(
                            Icons.close,
                            color: Colors.redAccent,
                          ),
                          onPressed: () => setState(() => _pickedFile = null),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 40),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _postAssignment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Post Assignment",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
