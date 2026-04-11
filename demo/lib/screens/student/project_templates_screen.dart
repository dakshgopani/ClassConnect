import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle, ByteData;
import 'package:file_saver/file_saver.dart';
// Import your classes page here
// import 'student_classes_page.dart';

class ProjectTemplatesScreen extends StatelessWidget {
  const ProjectTemplatesScreen({super.key});

  final List<Map<String, String>> templates = const [
    {
      'name': 'Project Presentation Template',
      'file': 'Project_Presentation_Template.pptx',
      'icon': 'pptx',
    },
    {
      'name': 'Project Report Template',
      'file': 'Project_Report_Template.docx',
      'icon': 'docx',
    },
    {'name': 'README Template', 'file': 'README_Template.md', 'icon': 'md'},
    {
      'name': 'Testing Template',
      'file': 'Testing_Template.docx',
      'icon': 'docx',
    },
  ];

  Future<void> _downloadTemplate(BuildContext context, String fileName) async {
    try {
      final ByteData data = await rootBundle.load('assets/templates/$fileName');
      final Uint8List bytes = data.buffer.asUint8List();

      final String name = fileName.split('.').first;
      final String ext = fileName.split('.').last;

      await FileSaver.instance.saveAs(
        name: name,
        bytes: bytes,
        fileExtension: ext,
        mimeType: _getMimeType(fileName),
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('File saved successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Download error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to save file'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  MimeType _getMimeType(String fileName) {
    if (fileName.endsWith('.pptx')) return MimeType.microsoftPresentation;
    if (fileName.endsWith('.docx')) return MimeType.microsoftWord;
    if (fileName.endsWith('.md')) return MimeType.text;
    return MimeType.other;
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'pptx':
        return Icons.slideshow;
      case 'docx':
        return Icons.description;
      case 'md':
        return Icons.code;
      default:
        return Icons.insert_drive_file;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'pptx':
        return Colors.orange;
      case 'docx':
        return Colors.blue;
      case 'md':
        return Colors.grey;
      default:
        return Colors.white70;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          "Project Templates",
          style: TextStyle(color: Color(0xFF0D1B3D)),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        // 🔹 BACK ROUTING BUTTON
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0D1B3D),
          ),
          onPressed: () {
            // Option 1: Just pop if this was pushed from StudentClassesPage
            Navigator.pop(context);

            // Option 2: Explicit routing (if needed)
            // Navigator.pushReplacement(
            //   context,
            //   MaterialPageRoute(builder: (context) => const StudentClassesPage()),
            // );
          },
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: templates.length,
        itemBuilder: (context, index) {
          final template = templates[index];

          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            color: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(
                color: const Color(0xFF2E6BFF).withValues(alpha: 0.14),
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              leading: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getColorForType(
                    template['icon']!,
                  ).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  _getIconForType(template['icon']!),
                  color: _getColorForType(template['icon']!),
                  size: 28,
                ),
              ),
              title: Text(
                template['name']!,
                style: const TextStyle(
                  color: Color(0xFF0D1B3D),
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Text(
                template['file']!,
                style: const TextStyle(color: Color(0xFF5C6B8C), fontSize: 12),
              ),
              trailing: IconButton(
                icon: const Icon(
                  Icons.download_rounded,
                  color: Color(0xFF00D9FF),
                ),
                onPressed: () => _downloadTemplate(context, template['file']!),
              ),
            ),
          );
        },
      ),
    );
  }
}
