import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class MiniProjectEnrolledStudentsScreen extends StatelessWidget {
  final String classId;
  final String pblId;
  final String miniProjectTitle;
  final String pblTitle;

  const MiniProjectEnrolledStudentsScreen({
    super.key,
    required this.classId,
    required this.pblId,
    required this.miniProjectTitle,
    required this.pblTitle,
  });

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
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
            color: Colors.white,
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
                          color: const Color(0xFF0D1B3D),
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
                    child: CircularProgressIndicator(color: const Color(0xFF2E6BFF)),
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




