import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';

class StudentResourcesScreen extends StatelessWidget {
  final String classId;
  final String className;

  const StudentResourcesScreen({
    super.key,
    required this.classId,
    required this.className,
  });

  Future<void> _launchUrl(BuildContext context, String urlString) async {
    final Uri url = Uri.parse(urlString);
    try {
      if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
        throw 'Could not launch $urlString';
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not launch URL: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$className Resources'),
        backgroundColor: const Color(0xFFF4F8FF),
        foregroundColor: const Color(0xFF0D1B3D),
      ),
      backgroundColor: const Color(0xFFF4F8FF),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('resources')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Color(0xFF5C6B8C)),
              ),
            );
          }

          final docs = snapshot.data?.docs ?? [];

          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.link_off, size: 64, color: Color(0xFF9CA9C2)),
                  const SizedBox(height: 16),
                  const Text(
                    'No resources shared yet.',
                    style: TextStyle(color: Color(0xFF5C6B8C), fontSize: 16),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index].data() as Map<String, dynamic>;
              final url = data['url'] ?? '';
              final description = data['description'] ?? '';

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                color: Colors.white,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(12),
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.cyan.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.link, color: Colors.cyan),
                  ),
                  title: Text(
                    description.isNotEmpty ? description : url,
                    style: const TextStyle(
                      color: Color(0xFF0D1B3D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    url,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Color(0xFF5C6B8C)),
                  ),
                  onTap: () => _launchUrl(context, url),
                  trailing: const Icon(
                    Icons.open_in_new,
                    color: Colors.white54,
                    size: 20,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
