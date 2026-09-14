import 'package:demo/screens/teacher/pbl/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:demo/widgets/ui/cc_loading_animation.dart';
import 'pbl_editor_screen.dart';

class GeneratePblScreen extends StatefulWidget {
  final List<String> concepts;
  final Map<String, String> selectedScenario;
  final String? classId;
  final String? className;

  const GeneratePblScreen({
    super.key,
    required this.concepts,
    required this.selectedScenario,
    this.classId,
    this.className,
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
              PblEditorScreen(
                project: project,
                classId: widget.classId,
                className: widget.className,
              ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CcLoadingAnimation()));
  }
}




