import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import '../../../services/attendance_service.dart';
import '../../../widgets/cc_breadcrumb_bar.dart';

class AttendanceMarkingScreen extends StatefulWidget {
  final String classId;
  final String? className;

  const AttendanceMarkingScreen({super.key, required this.classId, this.className});

  @override
  State<AttendanceMarkingScreen> createState() =>
      _AttendanceMarkingScreenState();
}

class _AttendanceMarkingScreenState extends State<AttendanceMarkingScreen> {
  final AttendanceService _attendanceService = AttendanceService();
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  final Color _themeColor = const Color(0xFFF4F8FF);
  final Color _cardColor = Colors.white;

  /// Students marked PRESENT
  final Set<String> _presentStudentIds = {};

  bool _alreadySubmitted = false;
  bool _isSubmitting = false;
  bool _initialized = false;

  late final String _todayLabel;

  @override
  void initState() {
    super.initState();
    _checkAttendanceAlreadyTaken();

    _todayLabel = DateFormat('EEEE, dd MMM yyyy').format(DateTime.now());
  }

  /// Check if attendance already exists for today
  Future<void> _checkAttendanceAlreadyTaken() async {
    final exists = await _attendanceService.attendanceExistsToday(
      classId: widget.classId,
    );

    if (mounted) {
      setState(() => _alreadySubmitted = exists);
    }
  }

  /// Toggle present / absent
  void _togglePresent(String studentId, bool isPresent) {
    setState(() {
      if (isPresent) {
        _presentStudentIds.add(studentId);
      } else {
        _presentStudentIds.remove(studentId);
      }
    });
  }

  /// Save attendance (IMMUTABLE)
  Future<void> _saveAttendance(List<String> allStudentIds) async {
    if (_alreadySubmitted) return;

    setState(() => _isSubmitting = true);

    final teacherId = FirebaseAuth.instance.currentUser!.uid;

    final presentStudentIds = _presentStudentIds.toList();
    final absentStudentIds = allStudentIds
        .where((id) => !_presentStudentIds.contains(id))
        .toList();

    await _attendanceService.saveAttendance(
      classId: widget.classId,
      teacherId: teacherId,
      presentStudentIds: presentStudentIds,
      absentStudentIds: absentStudentIds,
    );

    if (!mounted) return;

    setState(() {
      _alreadySubmitted = true;
      _isSubmitting = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Attendance saved successfully'),
        backgroundColor: Colors.green[700],
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  /// Fetch students of this class
  Stream<QuerySnapshot> _studentsStream() {
    return _db
        .collection('class_students')
        .where('classId', isEqualTo: widget.classId)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return _buildDesktopLayout();
    }

    return Scaffold(
      backgroundColor: _themeColor,
      appBar: AppBar(
        title: const Text(
          'Mark Attendance',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF0D1B3D),
          ),
        ),
        backgroundColor: _themeColor,
        iconTheme: const IconThemeData(color: Color(0xFF0D1B3D)),
        elevation: 0,
        centerTitle: true,
        actions: [
          if (_alreadySubmitted)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E6BFF).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF2E6BFF).withOpacity(0.15),
                  ),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock, color: Color(0xFF2E6BFF), size: 16),
                    SizedBox(width: 4),
                    Text(
                      "Locked",
                      style: TextStyle(color: Color(0xFF0D1B3D), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Date Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: Colors.transparent,
            child: Text(
              _todayLabel,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF5C6B8C),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  _infoBanner(),
                  const SizedBox(height: 16),
                  StreamBuilder<QuerySnapshot>(
                    stream: _studentsStream(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF2E6BFF),
                          ),
                        );
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(
                          child: Text(
                            'No students found',
                            style: TextStyle(color: Color(0xFF5C6B8C)),
                          ),
                        );
                      }

                      final students = snapshot.data!.docs;

                      /// Initialize all students as PRESENT (once)
                      if (!_initialized) {
                        for (var doc in students) {
                          _presentStudentIds.add(doc['studentId']);
                        }
                        _initialized = true;
                      }

                      return ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        itemCount: students.length,
                        itemBuilder: (context, index) {
                          final student = students[index];
                          final String studentId = student['studentId'];

                          return _buildStudentCard(studentId);
                        },
                      );
                    },
                  ),
                  // Extra padding for bottom button
                  const SizedBox(height: 80),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: _buildSaveButton(),
    );
  }

  /// Info banner
  Widget _infoBanner() {
    final bool isLocked = _alreadySubmitted;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isLocked
            ? Colors.white
            : const Color(0xFF3B82F6).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLocked
              ? const Color(0x1A2E6BFF)
              : const Color(0xFF3B82F6).withOpacity(0.22),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLocked ? Icons.lock_outline : Icons.info_outline,
            color: isLocked ? const Color(0xFF5C6B8C) : const Color(0xFF2E6BFF),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isLocked
                  ? 'Attendance submitted.\nRecord is locked.'
                  : 'Mark for today only.\nUntick to mark ABSENT.',
              style: TextStyle(
                fontSize: 14,
                color: isLocked
                    ? const Color(0xFF5C6B8C)
                    : const Color(0xFF2E6BFF),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Student Card Item
  Widget _buildStudentCard(String studentId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          // Minimal placeholder while loading
          return Container(
            height: 70,
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
            ),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          // Do not show any gap for non-existent students
          return const SizedBox.shrink();
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final String name = data['name'] ?? 'Student';
        final String? photoURL = data['photoURL'];

        final bool isPresent = _presentStudentIds.contains(studentId);

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E6BFF).withOpacity(0.06),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: isPresent
                  ? const Color(0x1A2E6BFF)
                  : Colors.red.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 4,
            ),
            leading: CircleAvatar(
              backgroundColor: const Color(0xFF2E6BFF).withOpacity(0.08),
              backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
              child: photoURL == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Color(0xFF0D1B3D),
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            title: Text(
              name,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0D1B3D),
                decoration: !isPresent && !_alreadySubmitted
                    ? TextDecoration.lineThrough
                    : null,
                decorationColor: const Color(0xFF5C6B8C),
              ),
            ),
            trailing: Transform.scale(
              scale: 1.2,
              child: Checkbox(
                activeColor: const Color(0xFF3B82F6),
                checkColor: Colors.white,
                side: BorderSide(
                  color: Colors.white.withOpacity(0.5),
                  width: 2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                value: isPresent,
                onChanged: _alreadySubmitted
                    ? null
                    : (val) => _togglePresent(studentId, val ?? false),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Save button
  Widget _buildSaveButton() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: SizedBox(
        width: double.infinity,
        height: 55,
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF3B82F6),
            disabledBackgroundColor: const Color(0xFFE3ECFF),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 4,
            shadowColor: const Color(0xFF3B82F6).withOpacity(0.4),
          ),
          onPressed: _alreadySubmitted || _isSubmitting
              ? null
              : () async {
                  final snapshot = await _studentsStream().first;

                  final allStudentIds = snapshot.docs
                      .map((doc) => doc['studentId'] as String)
                      .toList();

                  await _saveAttendance(allStudentIds);
                },
          child: _isSubmitting
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  _alreadySubmitted ? 'Submitted' : 'Save Attendance',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _alreadySubmitted
                        ? const Color(0xFF8DA6D8)
                        : Colors.white,
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final currentClassName = widget.className ?? 'Class';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          CCBreadcrumbBar(
            items: [
              BreadcrumbItem(
                label: 'Classes',
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              BreadcrumbItem(
                label: currentClassName,
                onTap: () => Navigator.pop(context),
              ),
              const BreadcrumbItem(
                label: 'Attendance',
              ),
            ],
            actions: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: _alreadySubmitted
                      ? Colors.amber.withValues(alpha: 0.1)
                      : const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _alreadySubmitted
                        ? Colors.amber.withValues(alpha: 0.3)
                        : const Color(0xFF10B981).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _alreadySubmitted ? Icons.lock : Icons.check_circle_outline,
                      color: _alreadySubmitted ? Colors.amber.shade800 : const Color(0xFF10B981),
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _alreadySubmitted ? 'Locked Today' : 'Ready to Mark',
                      style: TextStyle(
                        color: _alreadySubmitted ? Colors.amber.shade800 : const Color(0xFF10B981),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Expanded(
            child: _buildDesktopContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mark Attendance',
                      style: TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _todayLabel,
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: _alreadySubmitted
                      ? Colors.amber.withValues(alpha: 0.1)
                      : const Color(0xFF3B82F6).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _alreadySubmitted
                        ? Colors.amber.withValues(alpha: 0.3)
                        : const Color(0xFF3B82F6).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _alreadySubmitted ? Icons.lock : Icons.info,
                      color: _alreadySubmitted ? Colors.amber : const Color(0xFF3B82F6),
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _alreadySubmitted ? 'Submitted' : 'Pending',
                      style: TextStyle(
                        color: _alreadySubmitted ? Colors.amber : const Color(0xFF3B82F6),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: _studentsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Color(0xFF3B82F6),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No students found',
                    style: TextStyle(color: const Color(0xFF64748B)),
                  ),
                );
              }

              final students = snapshot.data!.docs;

              if (!_initialized) {
                for (var doc in students) {
                  _presentStudentIds.add(doc['studentId']);
                }
                _initialized = true;
              }

              return SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _alreadySubmitted
                            ? Colors.white
                            : const Color(0xFF3B82F6).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _alreadySubmitted
                              ? const Color(0xFFE2E8F0)
                              : const Color(0xFF3B82F6).withValues(alpha: 0.22),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _alreadySubmitted ? Icons.lock_outline : Icons.info_outline,
                            color: _alreadySubmitted
                                ? const Color(0xFF64748B)
                                : const Color(0xFF3B82F6),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _alreadySubmitted
                                  ? 'Attendance submitted. Record is locked.'
                                  : 'Tap checkbox to toggle. Unticked = Absent.',
                              style: TextStyle(
                                fontSize: 13,
                                color: _alreadySubmitted
                                    ? const Color(0xFF64748B)
                                    : const Color(0xFF3B82F6),
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        childAspectRatio: 2.2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                      ),
                      itemCount: students.length,
                      itemBuilder: (context, index) {
                        final student = students[index];
                        final String studentId = student['studentId'];
                        return _buildDesktopStudentCard(studentId);
                      },
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        _buildSaveButtonDesktop(students.map((doc) => doc['studentId'] as String).toList()),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopStudentCard(String studentId) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('students')
          .doc(studentId)
          .get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
          );
        }

        if (!snap.hasData || !snap.data!.exists) {
          return const SizedBox.shrink();
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final String name = data['name'] ?? 'Student';
        final String? photoURL = data['photoURL'];
        final bool isPresent = _presentStudentIds.contains(studentId);

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isPresent
                  ? const Color(0xFF3B82F6).withValues(alpha: 0.3)
                  : Colors.red.withValues(alpha: 0.3),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                backgroundImage: photoURL != null ? NetworkImage(photoURL) : null,
                child: photoURL == null
                    ? Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                          color: Color(0xFF3B82F6),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1E293B),
                    fontSize: 13,
                    decoration: !isPresent && !_alreadySubmitted
                        ? TextDecoration.lineThrough
                        : null,
                    decorationColor: const Color(0xFF64748B),
                  ),
                ),
              ),
              Transform.scale(
                scale: 1.1,
                child: Checkbox(
                  activeColor: const Color(0xFF3B82F6),
                  checkColor: Colors.white,
                  side: BorderSide(
                    color: Colors.white.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                  value: isPresent,
                  onChanged: _alreadySubmitted
                      ? null
                      : (val) => _togglePresent(studentId, val ?? false),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSaveButtonDesktop(List<String> allStudentIds) {
    return ElevatedButton.icon(
      onPressed: _alreadySubmitted || _isSubmitting
          ? null
          : () => _saveAttendance(allStudentIds),
      icon: _isSubmitting
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              ),
            )
          : const Icon(Icons.check, size: 18),
      label: Text(
        _alreadySubmitted ? 'Submitted' : 'Save Attendance',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: _alreadySubmitted ? const Color(0xFF64748B) : Colors.white,
        ),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF3B82F6),
        disabledBackgroundColor: const Color(0xFFE2E8F0),
        foregroundColor: _alreadySubmitted ? const Color(0xFF64748B) : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }
}