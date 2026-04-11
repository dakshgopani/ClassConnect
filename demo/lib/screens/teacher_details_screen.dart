import 'package:demo/theme/app_colors.dart';
import 'package:demo/widgets/ui/cc_button.dart';
import 'package:demo/widgets/ui/cc_card.dart';
import 'package:demo/widgets/ui/cc_section_header.dart';
import 'package:demo/widgets/ui/cc_text_field.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/screens/teacher_home.dart';

class TeacherDetailsScreen extends StatefulWidget {
  final String uid;

  const TeacherDetailsScreen({required this.uid, super.key});

  @override
  State<TeacherDetailsScreen> createState() => _TeacherDetailsScreenState();
}

class _TeacherDetailsScreenState extends State<TeacherDetailsScreen> {
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController collegeNameController = TextEditingController();
  bool _isLoading = false;

  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  void dispose() {
    departmentController.dispose();
    collegeNameController.dispose();
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
                    title: 'Teacher Information',
                    subtitle:
                        'Provide your department and institution details.',
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
              title: 'Professional Details',
              subtitle: 'These details are required for class context.',
            ),
            const SizedBox(height: 12),

            CcTextField(
              controller: departmentController,
              label: 'Department Name',
              icon: Icons.business_center_outlined,
            ),
            const SizedBox(height: 16),

            CcTextField(
              controller: collegeNameController,
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
    if (departmentController.text.trim().isEmpty ||
        collegeNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Please fill all fields"),
          backgroundColor: Colors.red.shade600,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await _db.collection('teachers').doc(widget.uid).update({
        'teacherDepartment': departmentController.text.trim(),
        'collegeName': collegeNameController.text.trim(),
      });

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const TeacherHome()),
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
