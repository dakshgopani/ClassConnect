import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:demo/widgets/cc_breadcrumb_bar.dart';

class TeacherAssignmentDetailScreen extends StatelessWidget {
  final String classId;
  final String assignmentId;
  final Map<String, dynamic> assignmentData;
  final String? className;

  const TeacherAssignmentDetailScreen({
    super.key,
    required this.classId,
    required this.assignmentId,
    required this.assignmentData,
    this.className,
  });

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return _buildDesktopLayout(context);
    }

    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout(BuildContext context) {
    final currentClassName = className ?? 'Class';
    final assignmentTitle = assignmentData['title'] ?? 'Assignment';

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
                label: 'Assignments',
                onTap: () => Navigator.pop(context),
              ),
              BreadcrumbItem(
                label: assignmentTitle,
              ),
            ],
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.assignment_outlined, size: 16, color: Color(0xFF3B82F6)),
                  SizedBox(width: 6),
                  Text(
                    'Assignment Overview',
                    style: TextStyle(
                      color: Color(0xFF3B82F6),
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
                constraints: const BoxConstraints(maxWidth: 1100),
                child: _buildDesktopContent(context),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Assignment Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  assignmentData['title'] ?? 'Untitled Assignment',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  assignmentData['description'] ?? 'No description provided.',
                  style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                    height: 1.6,
                  ),
                ),
                if (assignmentData['attachmentUrl'] != null) ...[
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _launchUrl(assignmentData['attachmentUrl']),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.attach_file, color: Color(0xFF3B82F6), size: 18),
                          const SizedBox(width: 10),
                          Flexible(
                            child: Text(
                              assignmentData['attachmentName'] ?? 'View Attachment',
                              style: const TextStyle(
                                color: Color(0xFF3B82F6),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 40),
          const Text(
            'Student Submissions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 20),
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('classes')
                .doc(classId)
                .collection('assignments')
                .doc(assignmentId)
                .collection('submissions')
                .orderBy('submittedAt', descending: true)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.inbox_outlined, size: 56, color: Color(0xFF94A3B8)),
                      SizedBox(height: 16),
                      Text(
                        'No submissions yet',
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 16),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Students will appear here when they submit',
                        style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                      ),
                    ],
                  ),
                );
              }

              final submissions = snapshot.data!.docs;

              return ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: submissions.length,
                itemBuilder: (context, index) {
                  final subDoc = submissions[index];
                  final subData = subDoc.data() as Map<String, dynamic>;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withValues(alpha: 0.04),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                            child: const Icon(Icons.person, color: Color(0xFF3B82F6)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  subData['studentName'] ?? 'Unknown Student',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1E293B),
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                if (subData['submittedAt'] != null)
                                  Text(
                                    'Submitted ${formatTimestamp(subData['submittedAt'])}',
                                    style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                                  ),
                              ],
                            ),
                          ),
                          if (subData['fileUrl'] != null)
                            ElevatedButton.icon(
                              onPressed: () => _launchUrl(subData['fileUrl']),
                              icon: const Icon(Icons.download, size: 18),
                              label: const Text('View'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF3B82F6),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: Colors.amber.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
                              ),
                              child: const Text(
                                'Pending',
                                style: TextStyle(
                                  color: Colors.amber,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          'Assignment Details',
          style: TextStyle(color: Color(0xFF0D1B3D), fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF0D1B3D)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x1A2E6BFF)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignmentData['title'] ?? 'Untitled Assignment',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0D1B3D),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    assignmentData['description'] ?? 'No description provided.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF5C6B8C),
                      height: 1.5,
                    ),
                  ),
                  if (assignmentData['attachmentUrl'] != null) ...[
                    const SizedBox(height: 16),
                    InkWell(
                      onTap: () => _launchUrl(assignmentData['attachmentUrl']),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E6BFF).withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_file, color: Color(0xFF2E6BFF), size: 18),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                assignmentData['attachmentName'] ?? 'View Attachment',
                                style: const TextStyle(
                                  color: Color(0xFF2E6BFF),
                                  fontWeight: FontWeight.bold,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Student Submissions',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF0D1B3D),
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('classes')
                  .doc(classId)
                  .collection('assignments')
                  .doc(assignmentId)
                  .collection('submissions')
                  .orderBy('submittedAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(30),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0x1A2E6BFF)),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.inbox, size: 48, color: Color(0xFFA5B2C8)),
                        SizedBox(height: 12),
                        Text(
                          'No submissions yet',
                          style: TextStyle(color: Color(0xFF5C6B8C), fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: snapshot.data!.docs.length,
                  itemBuilder: (context, index) {
                    final subDoc = snapshot.data!.docs[index];
                    final subData = subDoc.data() as Map<String, dynamic>;

                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0x1A2E6BFF)),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2E6BFF).withValues(alpha: 0.1),
                          child: const Icon(Icons.person, color: Color(0xFF2E6BFF)),
                        ),
                        title: Text(
                          subData['studentName'] ?? 'Unknown Student',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1B3D),
                          ),
                        ),
                        subtitle: subData['submittedAt'] != null
                            ? Text(
                                'Submitted ${formatTimestamp(subData['submittedAt'])}',
                                style: const TextStyle(color: Color(0xFF5C6B8C), fontSize: 12),
                              )
                            : null,
                        trailing: subData['fileUrl'] != null
                            ? IconButton(
                                icon: const Icon(Icons.download, color: Color(0xFF2E6BFF)),
                                onPressed: () => _launchUrl(subData['fileUrl']),
                                tooltip: 'View Submission',
                              )
                            : null,
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      final date = timestamp.toDate();
      return '${date.day}/${date.month}/${date.year}';
    }
    return '';
  }
}