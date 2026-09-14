import 'package:flutter/material.dart';
import 'dart:io' if (dart.library.html) 'package:demo/services/_file_stub.dart';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:demo/services/class_service.dart';
import 'package:share_plus/share_plus.dart';

enum EnrollmentMode { automatic, manual }

typedef CreateClassScreen = CreateClassPage;

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
  Uint8List? _syllabusBytes;
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
        const SnackBar(content: Text('College name not found. Please update your profile.')),
      );
      return;
    }

    if (_teacherDepartment == null || _teacherDepartment!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Department not found. Please update your profile.')),
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
        syllabusBytes: _syllabusBytes,
        syllabusFileName: _syllabusFileName,
      );

      if (!mounted) return;
      if (_enrollmentMode == EnrollmentMode.manual) {
        _showClassCodeDialog(result.classCode);
      } else {
        final enrolled = result.autoEnrolledCount;
        final hasSyllabus = _syllabusFile != null || _syllabusBytes != null;
        final syllabusMsg = !hasSyllabus
            ? ''
            : (result.syllabusProcessed ? ' Syllabus extracted successfully.' : ' Syllabus was uploaded but extraction failed.');

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Class created. Auto-added $enrolled student${enrolled == 1 ? '' : 's'}.$syllabusMsg')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  Future<void> _pickSyllabusFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png', 'webp'],
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.first;
    setState(() {
      _syllabusBytes = picked.bytes;
      _syllabusFileName = picked.name;
      if (picked.path != null) {
        _syllabusFile = File(picked.path!);
      }
    });
  }

  void _showClassCodeDialog(String classCode) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Class Created!'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Share this class code with students:', textAlign: TextAlign.center, style: TextStyle(color: const Color(0xFF64748B))),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: const Color(0xFF3B82F6))),
              child: Text(classCode, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, letterSpacing: 2, color: Color(0xFF3B82F6))),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: classCode));
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Class code copied!'), duration: Duration(seconds: 2)));
                    },
                    icon: const Icon(Icons.copy_rounded, size: 18),
                    label: const Text('Copy'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF3B82F6), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => SharePlus.instance.share(ShareParams(text: 'Join my class using this code: $classCode')),
                    icon: const Icon(Icons.share_rounded, size: 18),
                    label: const Text('Share'),
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () { Navigator.pop(context); Navigator.pop(context); },
            child: const Text('Done'),
          ),
        ],
      ),
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
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return _buildDesktopLayout();
    }

    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(child: _buildForm()),
                ],
              ),
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
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Container(width: 56, height: 56, decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]), borderRadius: BorderRadius.circular(14)), child: const Icon(Icons.school_rounded, color: Colors.white, size: 30)),
                const SizedBox(height: 14),
                const Text('Create Class', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text('Set up a new class', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 12)),
              ],
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(border: Border(top: BorderSide(color: const Color(0xFF334155), width: 1))),
            child: Row(
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF94A3B8)), onPressed: () => Navigator.pop(context), tooltip: 'Back'),
                Expanded(child: Text('Back to Classes', style: TextStyle(color: const Color(0xFF94A3B8), fontSize: 13))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: const Color(0xFFE2E8F0))),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Color(0xFF1E293B)),
            onPressed: () => Navigator.pop(context),
            tooltip: 'Back to Classes',
          ),
          const SizedBox(width: 8),
          const Text('Create New Class', style: TextStyle(color: Color(0xFF1E293B), fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, color: Color(0xFF3B82F6), size: 18),
                const SizedBox(width: 6),
                Text(_enrollmentMode == EnrollmentMode.automatic ? 'Auto Enrollment' : 'Manual Enrollment', style: const TextStyle(color: Color(0xFF3B82F6), fontSize: 13, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTeacherInfoCard(),
              const SizedBox(height: 20),
              _buildClassOptionsCard(),
              const SizedBox(height: 20),
              _buildSyllabusCard(),
              const SizedBox(height: 20),
              _buildTextFieldCard(),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createClass,
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                  label: const Text('Create Class'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeacherInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)]),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.account_balance, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Your Information', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text('Auto-loaded from your teacher profile', style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildInfoRow(Icons.account_balance, 'College', _collegeName ?? 'Loading...'),
                const SizedBox(height: 12),
                _buildInfoRow(Icons.business_center, 'Department', _teacherDepartment ?? 'Loading...'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassOptionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF10B981), Color(0xFF34D399)]),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.settings_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Class Options', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Configure enrollment and access controls', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const Text('Student Enrollment Mode', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B), fontSize: 14)),
                const SizedBox(height: 8),
                RadioListTile<EnrollmentMode>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Automatically add matching students', style: TextStyle(fontSize: 13)),
                  value: EnrollmentMode.automatic,
                  groupValue: _enrollmentMode,
                  onChanged: (value) { if (value == null) return; setState(() => _enrollmentMode = value); },
                ),
                RadioListTile<EnrollmentMode>(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Manually add using class code', style: TextStyle(fontSize: 13)),
                  value: EnrollmentMode.manual,
                  groupValue: _enrollmentMode,
                  onChanged: (value) { if (value == null) return; setState(() => _enrollmentMode = value); },
                ),
                const SizedBox(height: 6),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Enable PBL for this class', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('Controls PBL section visibility', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  value: _pblEnabled,
                  onChanged: (value) => setState(() => _pblEnabled = value),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Allow students to post in class posts', style: TextStyle(fontSize: 13)),
                  subtitle: const Text('Students can publish text posts in Posts tab', style: TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  value: _studentCanPost,
                  onChanged: (value) => setState(() => _studentCanPost = value),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyllabusCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
              borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), topRight: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                  child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Optional Syllabus', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Upload image/PDF to auto-extract chapters and concepts', style: TextStyle(color: Color(0xFF9CA3AF), fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 1))],
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.file_present_rounded, color: Color(0xFF64748B), size: 20),
                        const SizedBox(width: 12),
                        Flexible(
                          child: Text(
                            _syllabusFileName ?? 'No file selected',
                            style: TextStyle(color: _syllabusFileName == null ? const Color(0xFF94A3B8) : const Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _pickSyllabusFile,
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Choose File'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextFieldCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildDesktopTextField(_classNameController, 'Class Name', Icons.class_rounded, validator: (value) => (value == null || value.isEmpty) ? 'Please enter the class name' : null),
            const SizedBox(height: 16),
            _buildDesktopTextField(_subjectController, 'Subject', Icons.book_rounded, validator: (value) => (value == null || value.isEmpty) ? 'Please enter the subject' : null),
            const SizedBox(height: 16),
            _buildDesktopTextField(_descriptionController, 'Description', Icons.description_rounded, maxLines: 3),
            const SizedBox(height: 16),
            _buildDesktopTextField(_semesterController, 'Semester (-1 for School)', Icons.school_rounded, keyboardType: TextInputType.number, validator: (value) {
              if (value == null || value.isEmpty) return 'Please enter the semester';
              if (int.tryParse(value) == null) return 'Please enter a valid number';
              return null;
            }),
            const SizedBox(height: 16),
            _buildDesktopTextField(_divisionController, 'Division / Section', Icons.groups_rounded, validator: (value) => (value == null || value.isEmpty) ? 'Please enter the division' : null),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(6)),
              child: Icon(icon, color: const Color(0xFF3B82F6), size: 16),
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: const Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: const Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: Colors.red)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(color: const Color(0xFF3B82F6).withValues(alpha: 0.08), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: const Color(0xFF3B82F6), size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: const Color(0xFF64748B), fontSize: 12)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text('Create New Class', style: TextStyle(color: Color(0xFF0D1B3D), fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0D1B3D)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Class Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF0D1B3D))),
              const SizedBox(height: 20),
              _buildMobileTeacherInfoCard(),
              const SizedBox(height: 24),
              _buildMobileClassOptionsCard(),
              const SizedBox(height: 20),
              _buildMobileSyllabusCard(),
              const SizedBox(height: 20),
              _buildMobileTextFields(),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _createClass,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: const Text('Create Class'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileTeacherInfoCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A2E6BFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Your Information', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3D))),
            const SizedBox(height: 4),
            Text('Auto-loaded from your teacher profile', style: TextStyle(color: const Color(0xFF5C6B8C), fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [
                const Icon(Icons.account_balance, color: Color(0xFF2E6BFF), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_collegeName ?? 'Loading...', style: TextStyle(color: const Color(0xFF0D1B3D), fontSize: 14, fontWeight: FontWeight.w500))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.business_center, color: Color(0xFF2E6BFF), size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(_teacherDepartment ?? 'Loading...', style: TextStyle(color: const Color(0xFF0D1B3D), fontSize: 14, fontWeight: FontWeight.w500))),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileClassOptionsCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A2E6BFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Class Options', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3D))),
            const SizedBox(height: 4),
            Text('Configure enrollment and access controls', style: TextStyle(color: const Color(0xFF5C6B8C), fontSize: 13)),
            const SizedBox(height: 16),
            const Text('Student Enrollment Mode', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF0D1B3D), fontSize: 14)),
            RadioListTile<EnrollmentMode>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Automatically add matching students'),
              value: EnrollmentMode.automatic,
              groupValue: _enrollmentMode,
              onChanged: (value) { if (value == null) return; setState(() => _enrollmentMode = value); },
            ),
            RadioListTile<EnrollmentMode>(
              contentPadding: EdgeInsets.zero,
              title: const Text('Manually add using class code'),
              value: EnrollmentMode.manual,
              groupValue: _enrollmentMode,
              onChanged: (value) { if (value == null) return; setState(() => _enrollmentMode = value); },
            ),
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Enable PBL for this class'),
              subtitle: const Text('Controls PBL section visibility', style: TextStyle(fontSize: 11)),
              value: _pblEnabled,
              onChanged: (value) => setState(() => _pblEnabled = value),
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Allow students to post'),
              subtitle: const Text('Students can publish text posts', style: TextStyle(fontSize: 11)),
              value: _studentCanPost,
              onChanged: (value) => setState(() => _studentCanPost = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileSyllabusCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A2E6BFF)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Optional Syllabus', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF0D1B3D))),
            const SizedBox(height: 4),
            Text('Upload image/PDF to auto-extract chapters', style: TextStyle(color: const Color(0xFF5C6B8C), fontSize: 13)),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _syllabusFileName ?? 'No file selected',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: _syllabusFileName == null ? const Color(0xFF5C6B8C) : const Color(0xFF0D1B3D), fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _pickSyllabusFile,
                  icon: const Icon(Icons.upload_file_rounded, size: 18),
                  label: const Text('Choose'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    elevation: 0,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileTextFields() {
    return Column(
      children: [
        _buildMobileTextField(_classNameController, 'Class Name', Icons.class_rounded, validator: (value) => (value == null || value.isEmpty) ? 'Please enter the class name' : null),
        const SizedBox(height: 16),
        _buildMobileTextField(_subjectController, 'Subject', Icons.book_rounded, validator: (value) => (value == null || value.isEmpty) ? 'Please enter the subject' : null),
        const SizedBox(height: 16),
        _buildMobileTextField(_descriptionController, 'Description', Icons.description_rounded, maxLines: 3),
        const SizedBox(height: 16),
        _buildMobileTextField(_semesterController, 'Semester (-1 for School)', Icons.school_rounded, keyboardType: TextInputType.number, validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter the semester';
          if (int.tryParse(value) == null) return 'Please enter a valid number';
          return null;
        }),
        const SizedBox(height: 16),
        _buildMobileTextField(_divisionController, 'Division / Section', Icons.groups_rounded, validator: (value) => (value == null || value.isEmpty) ? 'Please enter the division' : null),
      ],
    );
  }

  Widget _buildMobileTextField(TextEditingController controller, String label, IconData icon, {int maxLines = 1, TextInputType? keyboardType, String? Function(String?)? validator}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF0D1B3D))),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0x1A2E6BFF))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: const Color(0x1A2E6BFF))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2E6BFF), width: 2)),
            prefixIcon: Icon(icon, color: const Color(0xFF2E6BFF)),
          ),
        ),
      ],
    );
  }
}