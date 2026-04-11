import 'package:demo/screens/teacher/pbl/models/pbl_project.dart';
import 'package:demo/screens/teacher/pbl/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'publish_success_screen.dart';

class PblEditorScreen extends StatefulWidget {
  final PblProject project;
  final String? classId;
  final String? pblId; // If provided, we are editing an existing project

  const PblEditorScreen({
    super.key,
    required this.project,
    this.classId,
    this.pblId,
  });

  @override
  State<PblEditorScreen> createState() => _PblEditorScreenState();
}

// ... (existing imports)

class _PblEditorScreenState extends State<PblEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _problemController;
  bool _isSaving = false;
  bool _isGenerating = false;

  // Local state for lists to allow UI updates after AI generation
  List<String> _learningObjectives = [];
  List<String> _milestones = [];
  List<Map<String, dynamic>> _rubric = [];
  List<Map<String, String>> _miniProjects = [];

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.project.title);
    _problemController = TextEditingController(
      text: widget.project.problemStatement,
    );

    // Initialize lists from project
    _learningObjectives = List.from(widget.project.learningObjectives);
    _milestones = List.from(widget.project.milestones);
    _rubric = List.from(widget.project.rubric);
    _miniProjects = List.from(widget.project.miniProjects);
  }

  Future<void> _generateDetails() async {
    setState(() {
      _isGenerating = true;
    });

    try {
      final filledProject = await GeminiService.generateProjectDetails(
        _titleController.text,
        _problemController.text,
        [], // Concepts are not easily available here, but title/problem should be enough context
      );

      setState(() {
        _learningObjectives = filledProject.learningObjectives;
        _milestones = filledProject.milestones;
        _rubric = filledProject.rubric;
        _miniProjects = filledProject.miniProjects;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Project details generated successfully!'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Generation failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isGenerating = false;
        });
      }
    }
  }

  // ... (rest of the class)

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.pblId != null;
    final isDetailsEmpty =
        _learningObjectives.isEmpty && _milestones.isEmpty && _rubric.isEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Edit Project Plan' : 'Review Project Plan'),
        actions: [
          if (isDetailsEmpty && !_isGenerating)
            IconButton(
              onPressed: _generateDetails,
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Generate Details with AI',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (_isGenerating)
              Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.indigo.shade100),
                ),
                child: const Row(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        "AI is generating project details... This may take a moment.",
                      ),
                    ),
                  ],
                ),
              ),

            // Title
            TextFormField(
              controller: _titleController,
              // ... (rest of title field)
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.indigo.shade900,
                fontWeight: FontWeight.bold,
              ),
              decoration: const InputDecoration(
                labelText: 'Project Title',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // Problem Statement
            _SectionHeader(title: 'Problem Statement'),
            TextFormField(
              controller: _problemController,
              maxLines: 4,
              decoration: const InputDecoration(border: OutlineInputBorder()),
            ),
            const SizedBox(height: 24),

            // Learning Objectives
            _SectionHeader(title: 'Learning Objectives'),
            if (_learningObjectives.isEmpty)
              const Text(
                'No objectives generated yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              ..._learningObjectives.map(
                    (obj) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 4,
                    ),
                    leading: const Icon(
                      Icons.check_circle_outline,
                      color: Colors.green,
                    ),
                    title: Text(obj),
                  ),
                ),
              ),
            const SizedBox(height: 24),

            // Milestones
            _SectionHeader(title: 'Project Milestones'),
            if (_milestones.isEmpty)
              const Text(
                'No milestones generated yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Stepper(
                physics: const NeverScrollableScrollPhysics(),
                controlsBuilder: (context, details) => const SizedBox.shrink(),
                steps: _milestones
                    .map(
                      (m) => Step(
                    title: Text(m),
                    content: const SizedBox.shrink(),
                    isActive: true,
                    state: StepState.indexed,
                  ),
                )
                    .toList(),
              ),
            const SizedBox(height: 24),

            // Rubric
            _SectionHeader(title: 'Assessment Rubric'),
            // ... (rest of rubric section using _rubric instead of widget.project.rubric)
            if (_rubric.isEmpty)
              const Text(
                'No rubric generated yet.',
                style: TextStyle(color: Colors.grey),
              )
            else
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      color: Colors.indigo.shade50,
                      child: const Row(
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              'Criteria',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text(
                              'Weight',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                    ..._rubric.map(
                          (r) => Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    r['criteria'] ?? 'Unknown',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 1,
                                  child: Text(
                                    '${r['weight']}%',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (r['descriptor'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.green.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.green.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      const Icon(
                                        Icons.star,
                                        size: 16,
                                        color: Colors.green,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Exemplary: ${r['descriptor']}',
                                          style: TextStyle(
                                            fontStyle: FontStyle.italic,
                                            fontSize: 13,
                                            color: Colors.grey.shade800,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            const Divider(),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ... (save button section using _learningObjectives, etc. in _saveProject)
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _isSaving ? null : () => _saveProject(context),
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.all(16),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                  isEditing ? 'Save Changes' : 'Publish Project to Class',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveProject(BuildContext context) async {
    // ... (use _learningObjectives, _milestones, _rubric instead of widget.project.*)
    try {
      if (widget.classId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Class ID not found')),
        );
        return;
      }

      setState(() {
        _isSaving = true;
      });

      final pblCollection = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('PBL');

      final data = {
        'title': _titleController.text.trim(),
        'problemStatement': _problemController.text.trim(),
        'learningObjectives': _learningObjectives,
        'milestones': _milestones,
        'rubric': _rubric,
        'miniProjects': _miniProjects,
      };

      if (widget.pblId != null) {
        // Update existing
        await pblCollection.doc(widget.pblId).update(data);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Project updated successfully!')),
          );
          Navigator.pop(context); // Go back to dashboard
        }
      } else {
        // Create new
        await pblCollection.add({
          ...data,
          'createdAt': FieldValue.serverTimestamp(),
        });
        if (mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => PublishSuccessScreen(classId: widget.classId!),
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error saving PBL: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.indigo.shade800,
        ),
      ),
    );
  }
}



