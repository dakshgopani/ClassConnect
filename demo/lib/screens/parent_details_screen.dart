import 'package:demo/services/class_automation_service.dart';
import 'package:demo/theme/app_colors.dart';
import 'package:demo/widgets/ui/cc_button.dart';
import 'package:demo/widgets/ui/cc_card.dart';
import 'package:demo/widgets/ui/cc_section_header.dart';
import 'package:demo/widgets/ui/cc_text_field.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'student_home.dart';

class ParentDetailsScreen extends StatefulWidget {
  final String uid;

  const ParentDetailsScreen({required this.uid, super.key});

  @override
  State<ParentDetailsScreen> createState() => _ParentDetailsScreenState();
}

class _ParentDetailsScreenState extends State<ParentDetailsScreen> {
  final TextEditingController parentEmailController = TextEditingController();
  final TextEditingController parentPhoneController = TextEditingController();
  final TextEditingController rollNoController = TextEditingController();
  final TextEditingController semController = TextEditingController();
  final TextEditingController classController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController collegeSchoolController = TextEditingController();
  bool _isLoading = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void dispose() {
    parentEmailController.dispose();
    parentPhoneController.dispose();
    rollNoController.dispose();
    semController.dispose();
    classController.dispose();
    departmentController.dispose();
    collegeSchoolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          "Complete Your Profile",
          style: TextStyle(
            color: Colors.white,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CcCard(
              glass: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const CcSectionHeader(
                    title: 'Parent & Student Information',
                    subtitle:
                        'Provide contact and academic details to continue.',
                  ),
                  const SizedBox(height: 8),
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.secondary,
                    size: 24,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            const CcSectionHeader(
              title: 'Parent Information',
              subtitle: 'These details are used for weekly updates.',
            ),
            const SizedBox(height: 12),

            CcTextField(
              controller: parentEmailController,
              keyboardType: TextInputType.emailAddress,
              label: 'Parent Email',
              icon: Icons.email_outlined,
            ),
            const SizedBox(height: 16),

            CcTextField(
              controller: parentPhoneController,
              keyboardType: TextInputType.phone,
              label: 'Parent Phone Number',
              icon: Icons.phone_outlined,
            ),

            const SizedBox(height: 32),

            const CcSectionHeader(
              title: 'Student Information',
              subtitle: 'Academic details drive class mapping and enrollment.',
            ),
            const SizedBox(height: 12),

            CcTextField(
              controller: rollNoController,
              label: 'Student Roll Number',
              icon: Icons.badge_outlined,
            ),
            const SizedBox(height: 16),

            CcTextField(
              controller: semController,
              keyboardType: TextInputType.number,
              label: 'Semester (-1 for School)',
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: 16),

            CcTextField(
              controller: classController,
              label: 'Class / Division',
              icon: Icons.class_outlined,
            ),
            const SizedBox(height: 16),

            CcTextField(
              controller: departmentController,
              label: 'Department Name',
              icon: Icons.business_center_outlined,
            ),
            const SizedBox(height: 16),

            CcTextField(
              controller: collegeSchoolController,
              label: 'College / School Name',
              icon: Icons.account_balance_outlined,
            ),

            const SizedBox(height: 40),

            CcButton(
              label: _isLoading ? 'Saving...' : 'Continue',
              isLoading: _isLoading,
              icon: _isLoading
                  ? null
                  : const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                    ),
              onPressed: _handleContinue,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleContinue() async {
    // ✅ Empty field validation
    if (parentEmailController.text.trim().isEmpty ||
        parentPhoneController.text.trim().isEmpty ||
        rollNoController.text.trim().isEmpty ||
        semController.text.trim().isEmpty ||
        classController.text.trim().isEmpty ||
        departmentController.text.trim().isEmpty ||
        collegeSchoolController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill all fields"),
          backgroundColor: Colors.red.shade600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    // ✅ Safe semester parsing
    final sem = int.tryParse(semController.text.trim());

    if (sem == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Enter a valid semester"),
          backgroundColor: Colors.red.shade600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 🔁 Original logic preserved
      final String studentType = sem == -1 ? 'school' : 'college';

      await _db.collection('students').doc(widget.uid).update({
        // student academic (one-time)
        'studentRollNo': rollNoController.text.trim(),
        'studentSem': sem,
        'studentType': studentType,
        'studentClass': classController.text.trim(),
        'studentDepartment': departmentController.text.trim(),
        'collegeSchoolName': collegeSchoolController.text.trim(),

        // parent
        'parentEmail': parentEmailController.text.trim(),
        'parentPhoneNumber': parentPhoneController.text.trim(),
      });

      if (!mounted) return;
      await ClassAutomationService().autoEnrollNewStudent(
        studentId: widget.uid,
        studentSem: sem,
        studentDiv: classController.text.trim(),
        collegeSchoolName: collegeSchoolController.text.trim(),
        studentType: studentType,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const StudentHome()),
      );
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red.shade600,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    }
  }
}
