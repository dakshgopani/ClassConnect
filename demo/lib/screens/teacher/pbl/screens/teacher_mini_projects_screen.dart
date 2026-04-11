import 'package:flutter/material.dart';

class TeacherMiniProjectsScreen extends StatelessWidget {
  final List<Map<String, dynamic>> miniProjects;

  const TeacherMiniProjectsScreen({super.key, required this.miniProjects});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mini Projects')),
      body: miniProjects.isEmpty
          ? const Center(child: Text('No mini projects generated.'))
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: miniProjects.length,
        itemBuilder: (context, index) {
          final project = miniProjects[index];
          final title = project['title'] ?? 'No Title';
          final description = project['description'] ?? 'No Description';

          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: CircleAvatar(
                child: Text('${index + 1}'),
              ),
              title: Text(title,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text(description),
            ),
          );
        },
      ),
    );
  }
}



