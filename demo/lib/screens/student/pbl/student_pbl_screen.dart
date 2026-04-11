import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import 'pbl_submission_sheet.dart';
import 'package:demo/widgets/ui/cc_decorated_background.dart';

import 'package:demo/screens/student/resources/student_resources_screen.dart';

class StudentPblScreen extends StatefulWidget {
  const StudentPblScreen({super.key});

  @override
  State<StudentPblScreen> createState() => _StudentPblScreenState();
}

class _StudentPblScreenState extends State<StudentPblScreen> {
  static const _bg = Color(0xFFF4F8FF);
  static const _surface = Colors.white;
  static const _surfaceLight = Color(0xFFF0F4FF);
  static const _accent = Color(0xFF2E6BFF);
  static const _textPrimary = Color(0xFF0D1B3D);
  static const _textSecondary = Color(0xFF5C6B8C);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(
        child: Text('Please log in', style: TextStyle(color: _textSecondary)),
      );
    }

    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchStudentPblProjects(user.uid),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        final pblProjects = snapshot.data ?? [];

        if (pblProjects.isEmpty) {
          return CcDecoratedBackground(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 64,
                    color: Colors.blueGrey.shade300,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No PBL Projects Assigned',
                    style: TextStyle(
                      color: _textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Your teachers will assign PBL projects here',
                    style: TextStyle(color: _textSecondary, fontSize: 14),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          );
        }

        return CcDecoratedBackground(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                ...pblProjects.map((pbl) => _buildPblCard(context, pbl)),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchStudentPblProjects(
    String studentUid,
  ) async {
    try {
      final classesSnapshot = await FirebaseFirestore.instance
          .collection('classes')
          .get();

      final pblProjects = <Map<String, dynamic>>[];

      for (var classDoc in classesSnapshot.docs) {
        final classId = classDoc.id;
        final className = classDoc['class_name'] ?? 'Unknown Class';
        final classCode = classDoc['class_code'] ?? 'N/A';

        // Get PBL projects for this class
        final pblSnapshot = await FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('PBL')
            .get();

        for (var pblDoc in pblSnapshot.docs) {
          final pblData = pblDoc.data();
          final studentAssignments =
              pblData['studentAssignments'] as List<dynamic>? ?? [];

          // Check if current student is in any pair
          bool isAssigned = false;
          Map<String, dynamic>? studentPairInfo;

          for (var assignment in studentAssignments) {
            final students = assignment['students'] as List<dynamic>? ?? [];
            for (var student in students) {
              if (student is Map && student['uid'] == studentUid) {
                isAssigned = true;
                studentPairInfo = assignment;
                break;
              }
            }
            if (isAssigned) break;
          }

          if (isAssigned) {
            pblProjects.add({
              'classId': classId,
              'className': className,
              'classCode': classCode,
              'pblId': pblDoc.id,
              'title': pblData['title'] ?? 'Untitled',
              'problemStatement':
                  pblData['problemStatement'] ?? 'No problem statement',
              'learningObjectives':
                  pblData['learningObjectives'] as List<dynamic>? ?? [],
              'milestones': pblData['milestones'] as List<dynamic>? ?? [],
              'deadline': pblData['deadline'],
              'pairNumber': studentPairInfo?['pairNumber'] ?? 0,
              'pairStudents':
                  studentPairInfo?['students'] as List<dynamic>? ?? [],
            });
          }
        }
      }

      return pblProjects;
    } catch (e) {
      debugPrint('Error fetching PBL projects: $e');
      return [];
    }
  }

  Widget _buildPblCard(BuildContext context, Map<String, dynamic> pblData) {
    final title = pblData['title'] as String? ?? 'Untitled';
    final className = pblData['className'] as String? ?? 'Unknown Class';
    final problemStatement = pblData['problemStatement'] as String? ?? '';
    final pairNumber = pblData['pairNumber'] as int? ?? 0;
    final pairStudents = pblData['pairStudents'] as List<dynamic>? ?? [];

    final deadlineTimestamp = pblData['deadline'] as Timestamp?;
    final deadlineDate = deadlineTimestamp?.toDate();

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: _surface,
      child: InkWell(
        onTap: () {
          _showPblDetails(context, pblData);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Class info chip
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _surfaceLight,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  className,
                  style: const TextStyle(
                    color: _textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              if (deadlineDate != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.calendar_today,
                        size: 14,
                        color: Colors.orangeAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Due: ${DateFormat('MMM d, h:mm a').format(deadlineDate)}',
                        style: const TextStyle(
                          color: Colors.orangeAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 12),
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              // Problem statement
              Text(
                problemStatement,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14, color: _textSecondary),
              ),
              const SizedBox(height: 12),
              // Pair info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Pair: Pair #$pairNumber',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...pairStudents
                        .map(
                          (student) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.person,
                                  size: 14,
                                  color: _textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    student['name'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: _textPrimary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showPblDetails(BuildContext context, Map<String, dynamic> pblData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Allow full height if needed
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: _bg,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.8,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) =>
            PblSubmissionSheet(pblData: pblData),
      ),
    );
  }
}
