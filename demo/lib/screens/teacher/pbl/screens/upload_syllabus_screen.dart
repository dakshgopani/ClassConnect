import 'dart:io';
import 'package:demo/screens/teacher/pbl/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';

import 'concept_review_screen.dart';

class UploadSyllabusScreen extends StatefulWidget {
  final String? classId;

  const UploadSyllabusScreen({super.key, this.classId});

  @override
  State<UploadSyllabusScreen> createState() => _UploadSyllabusScreenState();
}

class _UploadSyllabusScreenState extends State<UploadSyllabusScreen> {
  bool loading = false;
  String? fileName;
  String? extractedText;

  /// Pick PDF / DOC / Image
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'png'],
    );

    if (result == null) return;

    final file = File(result.files.single.path!);
    fileName = result.files.single.name;

    setState(() => loading = true);

    try {
      if (fileName!.toLowerCase().endsWith('.pdf')) {
        extractedText = await GeminiService.extractTextFromPdf(file);
      } else if (fileName!.toLowerCase().endsWith('.docx')) {
        extractedText = await GeminiService.extractTextFromDoc(file);
      } else if (fileName!.toLowerCase().endsWith('.doc')) {
        extractedText = await GeminiService.extractTextFromDoc(file);
      } else if (fileName!.toLowerCase().endsWith('.jpg') ||
          fileName!.toLowerCase().endsWith('.png')) {
        extractedText = await GeminiService.extractTextFromImage(file);
      }

      // If extraction failed, show error
      if (extractedText == null || extractedText!.isEmpty) {
        throw Exception('Failed to extract text from file');
      }

      final syllabusMap = await GeminiService.extractChaptersAndConcepts(extractedText!);

      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ConceptReviewScreen(
              syllabus: syllabusMap,
              classId: widget.classId,
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint(e.toString());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to process syllabus')),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Upload syllabus document',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF0D1B3D),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Supported formats: PDF, DOC, Image',
              style: TextStyle(color: const Color(0xFF5C6B8C)),
            ),
            const SizedBox(height: 32),

            InkWell(
              onTap: loading ? null : _pickFile,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.indigo, width: 2),
                ),
                child: Center(
                  child: loading
                      ? const CircularProgressIndicator()
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.upload_file,
                              size: 60,
                              color: Colors.indigo,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              fileName ?? 'Tap to upload syllabus',
                              style: const TextStyle(
                                fontSize: 16,
                                color: const Color(0xFF0D1B3D),
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}




