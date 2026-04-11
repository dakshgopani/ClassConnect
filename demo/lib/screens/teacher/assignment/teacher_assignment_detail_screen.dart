import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class TeacherAssignmentDetailScreen extends StatelessWidget {
  final String classId;
  final String assignmentId;
  final Map<String, dynamic> assignmentData;

  const TeacherAssignmentDetailScreen({
    super.key,
    required this.classId,
    required this.assignmentId,
    required this.assignmentData,
  });

  Future<void> _launchUrl(String url) async {
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          "Assignment Details",
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
            // Assignment Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0x1A2E6BFF)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
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
                          color: const Color(0xFF2E6BFF).withOpacity(0.1),
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
              "Student Submissions",
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
                          "No submissions yet",
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
                          backgroundColor: const Color(0xFF2E6BFF).withOpacity(0.1),
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
                                "Submitted on ${formatTimestamp(subData['submittedAt'])}",
                                style: const TextStyle(color: Color(0xFF5C6B8C), fontSize: 12),
                              )
                            : null,
                        trailing: subData['fileUrl'] != null
                            ? IconButton(
                                icon: const Icon(Icons.download, color: Color(0xFF2E6BFF)),
                                onPressed: () => _launchUrl(subData['fileUrl']),
                                tooltip: "View Submission",
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
      return "${date.day}/${date.month}/${date.year}";
    }
    return '';
  }
}