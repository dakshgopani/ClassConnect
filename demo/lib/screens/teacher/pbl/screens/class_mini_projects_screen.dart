import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'mini_project_enrolled_students_screen.dart';

class ClassMiniProjectsScreen extends StatelessWidget {
  final String classId;

  const ClassMiniProjectsScreen({super.key, required this.classId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          'All Mini Projects',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: const Color(0xFF0D1B3D),
          ),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(classId)
            .collection('PBL')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: const Color(0xFF2E6BFF)),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.folder_open_rounded,
                    size: 64,
                    color: const Color(0xFF5C6B8C),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No projects found.',
                    style: TextStyle(
                      color: const Color(0xFF5C6B8C),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final allMiniProjects = <Map<String, dynamic>>[];

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final pblTitle = data['title'] ?? 'Untitled PBL';
            final pblId = doc.id;
            // Get mini projects list
            final miniList = (data['miniProjects'] as List?) ?? [];
            for (var item in miniList) {
              if (item is Map) {
                final miniProject = Map<String, dynamic>.from(item);
                // Add source PBL title for context
                miniProject['sourcePbl'] = pblTitle;
                miniProject['pblId'] = pblId;
                allMiniProjects.add(miniProject);
              }
            }
          }

          if (allMiniProjects.isEmpty) {
            return Center(
              child: Text(
                'No mini projects generated yet.',
                style: TextStyle(color: const Color(0xFF5C6B8C)),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: allMiniProjects.length,
            itemBuilder: (context, index) {
              final project = allMiniProjects[index];
              final title = project['title'] ?? 'No Title';
              final description = project['description'] ?? 'No Description';
              final source = project['sourcePbl'] ?? 'Unknown Project';
              final pblId = project['pblId'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.indigo.shade900.withOpacity(0.4),
                      Colors.indigo.shade900.withOpacity(0.2),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.indigo.shade200.withOpacity(0.1),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              MiniProjectEnrolledStudentsScreen(
                                classId: classId,
                                pblId: pblId,
                                miniProjectTitle: title,
                                pblTitle: source,
                              ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Spacer(),
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF0F4FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.people_alt_outlined,
                                  color: const Color(0xFF5C6B8C),
                                  size: 18,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF0D1B3D),
                              height: 1.3,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              color: const Color(0xFF5C6B8C),
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Text(
                                "View Enrolled Students",
                                style: TextStyle(
                                  color: const Color(0xFF2E6BFF),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Icon(
                                Icons.arrow_forward_rounded,
                                size: 14,
                                color: const Color(0xFF2E6BFF),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
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


