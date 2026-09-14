import 'package:demo/screens/teacher/pbl/models/pbl_project.dart';
import 'package:demo/screens/teacher/pbl/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:demo/widgets/ui/cc_loading_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/widgets/cc_breadcrumb_bar.dart';
import 'publish_success_screen.dart';

class PblEditorScreen extends StatefulWidget {
  final PblProject project;
  final String? classId;
  final String? className;
  final String? pblId; // If provided, we are editing an existing project

  const PblEditorScreen({
    super.key,
    required this.project,
    this.classId,
    this.className,
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

    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return _buildDesktopLayout(isEditing, isDetailsEmpty);
    }

    return _buildMobileLayout(isEditing, isDetailsEmpty);
  }

  Widget _buildDesktopLayout(bool isEditing, bool isDetailsEmpty) {
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
              BreadcrumbItem(
                label: isEditing ? 'Edit Project Plan' : 'Review & Publish',
              ),
            ],
            badgeText: isEditing ? null : 'Step 4 of 4',
          ),
          Expanded(
            child: _buildDesktopContent(isEditing, isDetailsEmpty),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent(bool isEditing, bool isDetailsEmpty) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(40),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Edit Project Plan' : 'Review & Publish Project',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 24),
                  if (_isGenerating)
                    Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const CcLoadingAnimation(color: Color(0xFF8B5CF6)),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  "AI is generating project details...",
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                Text(
                                  "This may take a moment. Please wait.",
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: const Color(0xFF64748B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Title
                  const Text(
                    'Project Title',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _titleController,
                    style: const TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Problem Statement
                  const Text(
                    'Problem Statement',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _problemController,
                    maxLines: 4,
                    style: const TextStyle(color: Color(0xFF1E293B), fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: const Color(0xFFE2E8F0)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Learning Objectives
                  _buildDesktopSection('Learning Objectives', _learningObjectives.isEmpty),
                  if (_learningObjectives.isEmpty)
                    _buildDesktopEmptyState('No objectives generated yet.')
                  else
                    ..._learningObjectives.map((obj) => _buildDesktopObjectiveCard(obj)),
                  const SizedBox(height: 32),

                  // Milestones
                  _buildDesktopSection('Project Milestones', _milestones.isEmpty),
                  if (_milestones.isEmpty)
                    _buildDesktopEmptyState('No milestones generated yet.')
                  else
                    _buildDesktopMilestoneStepper(),
                  const SizedBox(height: 32),

                  // Rubric
                  _buildDesktopSection('Assessment Rubric', _rubric.isEmpty),
                  if (_rubric.isEmpty)
                    _buildDesktopEmptyState('No rubric generated yet.')
                  else
                    _buildDesktopRubricTable(),
                  const SizedBox(height: 48),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _isSaving ? null : () => _saveProject(context),
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF8B5CF6),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.all(20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSaving
                          ? const CcLoadingAnimation(color: Colors.white)
                          : Text(
                              isEditing ? 'Save Changes' : 'Publish Project to Class',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _buildDesktopActionBar(isEditing, isDetailsEmpty),
      ],
    );
  }

  Widget _buildDesktopSection(String title, bool isEmpty) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            color: const Color(0xFF8B5CF6),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(width: 12),
        if (isEmpty)
          IconButton(
            onPressed: _generateDetails,
            icon: const Icon(Icons.auto_awesome, size: 18, color: Color(0xFF8B5CF6)),
            tooltip: 'Generate with AI',
          ),
      ],
    );
  }

  Widget _buildDesktopEmptyState(String message) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(color: const Color(0xFF64748B), fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildDesktopObjectiveCard(String objective) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 14, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              objective,
              style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopMilestoneStepper() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: _milestones.asMap().entries.map((entry) {
          final index = entry.key;
          final milestone = entry.value;
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    milestone,
                    style: const TextStyle(fontSize: 14, color: Color(0xFF1E293B)),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDesktopRubricTable() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                Expanded(flex: 3, child: const Text('Criteria', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
                Expanded(flex: 1, child: const Text('Weight', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)))),
              ],
            ),
          ),
          ..._rubric.map((r) => Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 3, child: Text(r['criteria'] ?? 'Unknown', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15, color: Color(0xFF1E293B)))),
                    Expanded(flex: 1, child: Text('${r['weight']}%', style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF8B5CF6)))),
                  ],
                ),
                if (r['descriptor'] != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.green.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star, size: 16, color: Colors.green),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Exemplary: ${r['descriptor']}',
                            style: TextStyle(fontSize: 13, color: const Color(0xFF475569), fontStyle: FontStyle.italic),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Divider(height: 24),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _buildDesktopActionBar(bool isEditing, bool isDetailsEmpty) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isDetailsEmpty && !_isGenerating)
            ElevatedButton.icon(
              onPressed: _generateDetails,
              icon: const Icon(Icons.auto_awesome, color: Color(0xFF8B5CF6)),
              label: const Text('Generate Details with AI', style: TextStyle(color: Color(0xFF8B5CF6))),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFF8B5CF6)),
              ),
            ),
          if (isDetailsEmpty && !_isGenerating) const SizedBox(width: 16),
          ElevatedButton(
            onPressed: _isSaving ? null : () => _saveProject(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF8B5CF6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                  )
                : Text(
                    isEditing ? 'Save Changes' : 'Publish Project to Class',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(bool isEditing, bool isDetailsEmpty) {
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
                    CcLoadingAnimation(),
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
                    ? const CcLoadingAnimation(color: Colors.white)
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



