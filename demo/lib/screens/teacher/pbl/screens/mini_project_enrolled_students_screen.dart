import 'package:flutter/material.dart';
import 'package:demo/widgets/ui/cc_loading_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../widgets/cc_breadcrumb_bar.dart';

class MiniProjectEnrolledStudentsScreen extends StatelessWidget {
  final String classId;
  final String pblId;
  final String miniProjectTitle;
  final String pblTitle;
  final String? className;

  const MiniProjectEnrolledStudentsScreen({
    super.key,
    required this.classId,
    required this.pblId,
    required this.miniProjectTitle,
    required this.pblTitle,
    this.className,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return _buildDesktopLayout(context);
    }

    return _buildMobileLayout(context);
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final currentClassName = className ?? 'Class';
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
              BreadcrumbItem(
                label: 'PBL Projects',
                onTap: () => Navigator.pop(context),
              ),
              BreadcrumbItem(
                label: 'All Mini Projects',
                onTap: () => Navigator.pop(context),
              ),
              BreadcrumbItem(
                label: miniProjectTitle,
              ),
            ],
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.groups, size: 16, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 6),
                  Text(
                    'Enrolled Students',
                    style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: _buildDesktopContent(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header Section
        Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1C3F),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFF2E6BFF).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.rocket_launch_rounded,
                  color: Color(0xFF2E6BFF),
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Mini Project Selection',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF94A3B8),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      miniProjectTitle,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // List Section
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(classId)
                .collection('PBL')
                .doc(pblId)
                .collection('selections')
                .where('title', isEqualTo: miniProjectTitle)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CcLoadingAnimation(color: Color(0xFF8B5CF6)),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.people_outline,
                          size: 64,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No students enrolled yet.',
                        style: TextStyle(
                          color: const Color(0xFF64748B),
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                );
              }

              final enrollments = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(40),
                itemCount: enrollments.length,
                itemBuilder: (context, index) {
                  final selectionData =
                      enrollments[index].data() as Map<String, dynamic>;

                  final studentId = enrollments[index].id;

                  return FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('students')
                        .doc(studentId)
                        .get(),
                    builder: (context, studentSnapshot) {
                      if (!studentSnapshot.hasData) {
                        return const SizedBox.shrink();
                      }

                      final studentData =
                          studentSnapshot.data!.data()
                              as Map<String, dynamic>? ??
                          {};

                      final name = studentData['name'] ?? 'Unknown Student';
                      final email = studentData['email'] ?? '';

                      final isSubmitted = selectionData['submitted'] == true;
                      final submissionUrl =
                          selectionData['submissionUrl'] as String?;
                      final submittedAt =
                          (selectionData['submittedAt'] as Timestamp?)
                              ?.toDate();

                      final steps = (selectionData['steps'] as List?) ?? [];
                      final completedSteps = steps
                          .where((s) => s['completed'] == true)
                          .length;
                      final totalSteps = steps.length;
                      final hasSteps = steps.isNotEmpty;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSubmitted
                                ? Colors.green.withValues(alpha: 0.3)
                                : const Color(0xFFE2E8F0),
                            width: isSubmitted ? 2 : 1,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: isSubmitted
                                  ? Colors.green.withValues(alpha: 0.1)
                                  : const Color(0xFF8B5CF6).withValues(alpha: 0.04),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: isSubmitted
                                    ? Colors.green.shade800
                                    : const Color(0xFF2E6BFF),
                                child: Text(
                                  name.isNotEmpty
                                      ? name[0].toUpperCase()
                                      : '?',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 24,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(
                                        color: Color(0xFF1E293B),
                                        fontWeight: FontWeight.w600,
                                        fontSize: 16,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      style: TextStyle(
                                        color: const Color(0xFF64748B),
                                        fontSize: 14,
                                      ),
                                    ),
                                    if (hasSteps) ...[
                                      const SizedBox(height: 12),
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: isSubmitted
                                                  ? Colors.green.withValues(alpha: 0.1)
                                                  : const Color(0xFFF1F5F9),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  isSubmitted ? Icons.check_circle : Icons.timelapse,
                                                  size: 14,
                                                  color: isSubmitted ? Colors.green : const Color(0xFF64748B),
                                                ),
                                                const SizedBox(width: 6),
                                                Text(
                                                  isSubmitted
                                                      ? "Project Completed"
                                                      : "$completedSteps/$totalSteps Steps",
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    color: isSubmitted ? Colors.green.shade700 : const Color(0xFF64748B),
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSubmitted)
                                ElevatedButton.icon(
                                  onPressed: () {
                                    if (submissionUrl != null) {
                                      _launchUrl(submissionUrl);
                                    }
                                  },
                                  icon: const Icon(Icons.visibility, size: 18),
                                  label: const Text('View Submission'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF2E6BFF),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                )
                              else
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.hourglass_empty, size: 18, color: Colors.amber.shade700),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Pending',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.amber.shade700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          'Enrolled Students',
          style: TextStyle(color: const Color(0xFF0D1B3D)),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0D1B3D),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1C3F),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2E6BFF).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.rocket_launch_rounded,
                    color: const Color(0xFF2E6BFF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mini Project Selection',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.indigo.shade200,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        miniProjectTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // List Section
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(classId)
                  .collection('PBL')
                  .doc(pblId)
                  .collection('selections')
                  .where('title', isEqualTo: miniProjectTitle)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CcLoadingAnimation(color: const Color(0xFF2E6BFF)),
                  );
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(
                    child: Text(
                      'No students enrolled yet.',
                      style: TextStyle(
                        color: const Color(0xFF5C6B8C),
                        fontSize: 16,
                      ),
                    ),
                  );
                }

                final enrollments = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: enrollments.length,
                  itemBuilder: (context, index) {
                    final selectionData =
                        enrollments[index].data() as Map<String, dynamic>;

                    // ✅ selection doc ID = student UID
                    final studentId = enrollments[index].id;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection(
                            'students',
                          ) // change if your collection name differs
                          .doc(studentId)
                          .get(),
                      builder: (context, studentSnapshot) {
                        if (!studentSnapshot.hasData) {
                          return const SizedBox.shrink();
                        }

                        final studentData =
                            studentSnapshot.data!.data()
                                as Map<String, dynamic>? ??
                            {};

                        final name = studentData['name'] ?? 'Unknown Student';
                        final email = studentData['email'] ?? '';

                        // Submission Data
                        final isSubmitted = selectionData['submitted'] == true;
                        final submissionUrl =
                            selectionData['submissionUrl'] as String?;
                        final submittedAt =
                            (selectionData['submittedAt'] as Timestamp?)
                                ?.toDate();

                        // Steps Data
                        final steps = (selectionData['steps'] as List?) ?? [];
                        final completedSteps = steps
                            .where((s) => s['completed'] == true)
                            .length;
                        final totalSteps = steps.length;
                        final hasSteps = steps.isNotEmpty;

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F4FF),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSubmitted
                                  ? Colors.green.withOpacity(0.3)
                                  : const Color(0x1A2E6BFF),
                              width: isSubmitted ? 1.5 : 1,
                            ),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                leading: CircleAvatar(
                                  radius: 26,
                                  backgroundColor: isSubmitted
                                      ? Colors.green.shade800
                                      : Colors.indigo.shade500,
                                  child: Text(
                                    name.isNotEmpty
                                        ? name[0].toUpperCase()
                                        : '?',
                                    style: const TextStyle(
                                      color: const Color(0xFF0D1B3D),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  name,
                                  style: const TextStyle(
                                    color: const Color(0xFF0D1B3D),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      email,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: const Color(0xFF5C6B8C),
                                        fontSize: 13,
                                      ),
                                    ),

                                    if (hasSteps) ...[
                                      const SizedBox(height: 8),
                                      Text(
                                        isSubmitted
                                            ? "Project Completed"
                                            : "$completedSteps/$totalSteps Steps Completed",
                                        style: TextStyle(
                                          color: isSubmitted
                                              ? Colors.greenAccent
                                              : const Color(0xFF5C6B8C),
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                trailing: isSubmitted
                                    ? IconButton(
                                        icon: const Icon(
                                          Icons.visibility,
                                          color: const Color(0xFF2E6BFF),
                                        ),
                                        onPressed: () {
                                          if (submissionUrl != null) {
                                            _launchUrl(submissionUrl);
                                          }
                                        },
                                      )
                                    : const Icon(
                                        Icons.hourglass_empty,
                                        color: Colors.amber,
                                      ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}




