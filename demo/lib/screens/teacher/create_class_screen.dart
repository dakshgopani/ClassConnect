import 'package:flutter/material.dart';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:demo/services/class_service.dart';
import 'package:share_plus/share_plus.dart';
import 'package:demo/widgets/ui/cc_button.dart';
import 'package:demo/widgets/ui/cc_card.dart';
import 'package:demo/widgets/ui/cc_dialog.dart';
import 'package:demo/widgets/ui/cc_section_header.dart';
import 'package:demo/widgets/ui/cc_text_field.dart';

enum EnrollmentMode { automatic, manual }

class CreateClassPage extends StatefulWidget {
  const CreateClassPage({super.key});

  @override
  State<CreateClassPage> createState() => _CreateClassPageState();
}

class _CreateClassPageState extends State<CreateClassPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _classNameController = TextEditingController();
  final TextEditingController _subjectController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _semesterController = TextEditingController();
  final TextEditingController _divisionController = TextEditingController();
  final ClassService _classService = ClassService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _collegeName;
  String? _teacherDepartment;
  EnrollmentMode _enrollmentMode = EnrollmentMode.manual;
  bool _pblEnabled = true;
  bool _studentCanPost = false;
  File? _syllabusFile;
  String? _syllabusFileName;

  @override
  void initState() {
    super.initState();
    _fetchTeacherDetails();
  }

  Future<void> _fetchTeacherDetails() async {
    try {
      final teacherId = _auth.currentUser?.uid;
      if (teacherId == null) return;

      final teacherDoc = await _firestore
          .collection('teachers')
          .doc(teacherId)
          .get();

      if (teacherDoc.exists) {
        setState(() {
          _collegeName = teacherDoc.data()?['collegeName'] ?? '';
          _teacherDepartment = teacherDoc.data()?['teacherDepartment'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error fetching teacher details: $e');
    }
  }

  Future<void> _createClass() async {
    if (!_formKey.currentState!.validate()) return;

    if (_collegeName == null || _collegeName!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('College name not found. Please update your profile.'),
        ),
      );
      return;
    }

    if (_teacherDepartment == null || _teacherDepartment!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Department not found. Please update your profile.'),
        ),
      );
      return;
    }

    try {
      final semester = int.tryParse(_semesterController.text.trim());
      if (semester == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter a valid semester number')),
        );
        return;
      }

      // Determine target student type for this class based on semester
      // -1 => school, otherwise => college
      final String targetStudentType = (semester == -1) ? 'school' : 'college';

      final result = await _classService.createClass(
        className: _classNameController.text.trim(),
        subject: _subjectController.text.trim(),
        description: _descriptionController.text.trim(),
        studentSem: semester,
        studentDiv: _divisionController.text.trim(),
        collegeSchoolName: _collegeName!,
        studentType: targetStudentType,
        autoAddStudents: _enrollmentMode == EnrollmentMode.automatic,
        pblEnabled: _pblEnabled,
        studentCanPost: _studentCanPost,
        syllabusFile: _syllabusFile,
      );

      if (!mounted) return;
      if (_enrollmentMode == EnrollmentMode.manual) {
        _showClassCodeDialog(result.classCode);
      } else {
        final enrolled = result.autoEnrolledCount;
        final syllabusMsg = _syllabusFile == null
            ? ''
            : (result.syllabusProcessed
                  ? ' Syllabus extracted successfully.'
                  : ' Syllabus was uploaded but extraction failed.');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Class created. Auto-added $enrolled student${enrolled == 1 ? '' : 's'}.$syllabusMsg',
            ),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _pickSyllabusFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'webp'],
    );

    if (result == null ||
        result.files.isEmpty ||
        result.files.first.path == null) {
      return;
    }

    setState(() {
      _syllabusFile = File(result.files.first.path!);
      _syllabusFileName = result.files.first.name;
    });
  }

  void _showClassCodeDialog(String classCode) {
    showCcDialog(
      context: context,
      barrierDismissible: false,
      title: 'Class Created!',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Share this class code with students:',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          CcCard(
            child: Center(
              child: Text(
                classCode,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Color(0xFF3B82F6),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: CcButton(
                  label: 'Copy',
                  icon: const Icon(Icons.copy_rounded, size: 18),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: classCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Class code copied!'),
                        duration: Duration(seconds: 2),
                        backgroundColor: Colors.green,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: CcButton(
                  label: 'Share',
                  variant: CcButtonVariant.secondary,
                  icon: const Icon(Icons.share_rounded, size: 18),
                  onPressed: () {
                    SharePlus.instance.share(
                      ShareParams(
                        text: 'Join my class using this code: $classCode',
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            Navigator.pop(context);
          },
          child: const Text('Done'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _classNameController.dispose();
    _subjectController.dispose();
    _descriptionController.dispose();
    _semesterController.dispose();
    _divisionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: Text(
          'Create New Class',
          style: TextStyle(color: colorScheme.onSurface),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: colorScheme.onSurface,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Class Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 20),

              // 📚 Teacher Info Display (Read-only)
              CcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CcSectionHeader(
                      title: 'Your Information',
                      subtitle: 'Auto-loaded from your teacher profile',
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(
                          Icons.account_balance,
                          color: Color(0xFF00D9FF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _collegeName ?? 'Loading...',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(
                          Icons.business_center,
                          color: Color(0xFF00D9FF),
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _teacherDepartment ?? 'Loading...',
                            style: TextStyle(
                              color: colorScheme.onSurface,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              CcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CcSectionHeader(
                      title: 'Class Options',
                      subtitle: 'Configure enrollment and access controls',
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Student Enrollment Mode',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    RadioListTile<EnrollmentMode>(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Automatically add matching students'),
                      value: EnrollmentMode.automatic,
                      groupValue: _enrollmentMode,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _enrollmentMode = value);
                      },
                    ),
                    RadioListTile<EnrollmentMode>(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Manually add using class code'),
                      value: EnrollmentMode.manual,
                      groupValue: _enrollmentMode,
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() => _enrollmentMode = value);
                      },
                    ),
                    const SizedBox(height: 6),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Enable PBL for this class'),
                      subtitle: const Text('Controls PBL section visibility'),
                      value: _pblEnabled,
                      onChanged: (value) {
                        setState(() => _pblEnabled = value);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text(
                        'Allow students to post in class posts',
                      ),
                      subtitle: const Text(
                        'Students can publish text posts in Posts tab',
                      ),
                      value: _studentCanPost,
                      onChanged: (value) {
                        setState(() => _studentCanPost = value);
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              CcCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const CcSectionHeader(
                      title: 'Optional Syllabus',
                      subtitle:
                          'Upload image/PDF to auto-extract chapters and concepts',
                    ),
                    const SizedBox(height: 12),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final compact = constraints.maxWidth < 380;

                        if (compact) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _syllabusFileName ?? 'No file selected',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _syllabusFileName == null
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 10),
                              CcButton(
                                label: 'Choose File',
                                variant: CcButtonVariant.secondary,
                                icon: const Icon(
                                  Icons.upload_file_rounded,
                                  size: 18,
                                ),
                                onPressed: _pickSyllabusFile,
                              ),
                            ],
                          );
                        }

                        return Row(
                          children: [
                            Expanded(
                              child: Text(
                                _syllabusFileName ?? 'No file selected',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: _syllabusFileName == null
                                      ? colorScheme.onSurfaceVariant
                                      : colorScheme.onSurface,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            SizedBox(
                              width: 140,
                              child: CcButton(
                                label: 'Choose File',
                                variant: CcButtonVariant.secondary,
                                icon: const Icon(
                                  Icons.upload_file_rounded,
                                  size: 18,
                                ),
                                onPressed: _pickSyllabusFile,
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              CcTextField(
                controller: _classNameController,
                label: 'Class Name',
                icon: Icons.class_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the class name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CcTextField(
                controller: _subjectController,
                label: 'Subject',
                icon: Icons.book_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the subject';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CcTextField(
                controller: _descriptionController,
                label: 'Description',
                icon: Icons.description_rounded,
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              CcTextField(
                controller: _semesterController,
                keyboardType: TextInputType.number,
                label: 'Semester (-1 for School)',
                icon: Icons.school_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the semester';
                  }
                  final sem = int.tryParse(value);
                  if (sem == null) {
                    return 'Please enter a valid number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              CcTextField(
                controller: _divisionController,
                label: 'Division / Section',
                icon: Icons.groups_rounded,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter the division';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: CcButton(
                  label: 'Create Class',
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  onPressed: _createClass,
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
