import 'dart:io' if (dart.library.html) 'package:demo/services/_file_stub.dart';
import 'package:demo/screens/teacher/pbl/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:demo/widgets/ui/cc_loading_animation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:demo/widgets/cc_breadcrumb_bar.dart';

import 'concept_review_screen.dart';

class UploadSyllabusScreen extends StatefulWidget {
  final String? classId;
  final String? className;

  const UploadSyllabusScreen({super.key, this.classId, this.className});

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
      withData: true,
    );

    if (result == null || result.files.isEmpty) return;

    final picked = result.files.single;
    fileName = picked.name;
    final bytes = picked.bytes;

    setState(() => loading = true);

    try {
      final lower = fileName!.toLowerCase();
      if (bytes != null && bytes.isNotEmpty) {
        if (lower.endsWith('.pdf')) {
          extractedText = await GeminiService.extractTextFromPdfBytes(bytes, fileName!);
        } else if (lower.endsWith('.docx') || lower.endsWith('.doc')) {
          extractedText = await GeminiService.extractTextFromDocBytes(bytes, fileName!);
        } else if (lower.endsWith('.jpg') || lower.endsWith('.png')) {
          extractedText = await GeminiService.extractTextFromImageBytes(bytes, fileName!);
        }
      } else if (picked.path != null) {
        final file = File(picked.path!);
        if (lower.endsWith('.pdf')) {
          extractedText = await GeminiService.extractTextFromPdf(file);
        } else if (lower.endsWith('.docx') || lower.endsWith('.doc')) {
          extractedText = await GeminiService.extractTextFromDoc(file);
        } else if (lower.endsWith('.jpg') || lower.endsWith('.png')) {
          extractedText = await GeminiService.extractTextFromImage(file);
        }
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
              className: widget.className,
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
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return _buildDesktopLayout();
    }

    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout() {
    final classTitle = widget.className ?? 'Class';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          CCBreadcrumbBar(
            items: [
              BreadcrumbItem(
                label: 'Classes',
                icon: Icons.school_rounded,
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              BreadcrumbItem(
                label: classTitle,
                onTap: () => Navigator.of(context).pop(),
              ),
              BreadcrumbItem(
                label: 'PBL Projects',
                onTap: () => Navigator.of(context).pop(),
              ),
              const BreadcrumbItem(label: 'Upload Syllabus'),
            ],
            badgeText: 'Step 1 of 4',
          ),
          Expanded(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 640),
                  child: _buildDesktopContent(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Upload syllabus document',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'AI will extract chapters and concepts from your document',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        const SizedBox(height: 32),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)],
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.upload_file_rounded, color: Colors.white, size: 26),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Upload Document',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'PDF, DOC, DOCX, JPG, PNG',
                              style: TextStyle(color: Color(0xFFE9D5FF), fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: InkWell(
                    onTap: loading ? null : _pickFile,
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 160,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF8B5CF6), width: 2, strokeAlign: BorderSide.strokeAlignInside),
                      ),
                      child: Center(
                        child: loading
                            ? const CcLoadingAnimation(color: Color(0xFF8B5CF6))
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.upload_file_rounded,
                                    size: 48,
                                    color: Color(0xFF8B5CF6),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    fileName ?? 'Click to upload syllabus',
                                    style: const TextStyle(
                                      fontSize: 15,
                                      color: Color(0xFF1E293B),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  const Text(
                                    'Supported: PDF, DOC, Images',
                                    style: TextStyle(color: Color(0xFF64748B), fontSize: 12),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
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
                      ? const CcLoadingAnimation()
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




