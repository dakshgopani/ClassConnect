import 'package:demo/screens/teacher/pbl/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'pbl_editor_screen.dart';

class GeneratePblScreen extends StatefulWidget {
  final List<String> concepts;
  final Map<String, String> selectedScenario;
  final String? classId;

  const GeneratePblScreen({
    super.key,
    required this.concepts,
    required this.selectedScenario,
    this.classId,
  });

  @override
  State<GeneratePblScreen> createState() => _GeneratePblScreenState();
}

class _GeneratePblScreenState extends State<GeneratePblScreen> {
  @override
  void initState() {
    super.initState();
    _generate();
  }

  Future<void> _generate() async {
    final project = await GeminiService.generateProjectDetails(
      widget.selectedScenario['title']!,
      widget.selectedScenario['problemStatement']!,
      widget.concepts,
    );
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              PblEditorScreen(project: project, classId: widget.classId),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}




