import 'package:demo/screens/teacher/pbl/screens/problem_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:demo/screens/teacher/pbl/services/class_concept_service.dart';
import '../../../../widgets/cc_breadcrumb_bar.dart';

class ConceptReviewScreen extends StatefulWidget {
  final Map<String, List<String>> syllabus;
  final String? classId;
  final String? className;

  const ConceptReviewScreen({
    super.key,
    required this.syllabus,
    this.classId,
    this.className,
  });

  @override
  State<ConceptReviewScreen> createState() => _ConceptReviewScreenState();
}

class _ConceptReviewScreenState extends State<ConceptReviewScreen> {
  late Map<String, List<String>> syllabus;
  final ClassConceptService _conceptService = ClassConceptService();
  bool _savedOnce = false;

  @override
  void initState() {
    super.initState();
    // Create a mutable copy
    syllabus = widget.syllabus.map((k, v) => MapEntry(k, List.from(v)));
    _autoSaveSyllabus();
  }

  Future<void> _autoSaveSyllabus() async {
    if (_savedOnce || widget.classId == null) return;

    _savedOnce = true;

    try {
      await _conceptService.saveSyllabusChapters(
        classId: widget.classId!,
        syllabus: syllabus,
      );
    } catch (e) {
      debugPrint("Syllabus auto-save failed: $e");
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

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          'Review Syllabus',
          style: TextStyle(fontWeight: FontWeight.bold, color: const Color(0xFF0D1B3D)),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // Header / Instructions
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            color: Colors.white,
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: const Color(0xFF2E6BFF)),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    "Review and edit the extracted concepts before generating the project.",
                    style: TextStyle(
                      color: const Color(0xFF5C6B8C),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: syllabus.length,
              itemBuilder: (context, index) {
                final entry = syllabus.entries.elementAt(index);
                final chapterName = entry.key;
                final concepts = entry.value;

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F4FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1A2E6BFF)),
                  ),
                  child: Theme(
                    data: Theme.of(
                      context,
                    ).copyWith(dividerColor: Colors.transparent),
                    child: ExpansionTile(
                      iconColor: const Color(0xFF2E6BFF),
                      collapsedIconColor: const Color(0xFF5C6B8C),
                      title: Text(
                        chapterName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF0D1B3D),
                          fontSize: 16,
                        ),
                      ),
                      initiallyExpanded: true,
                      children: concepts.map((concept) {
                        return Container(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: ListTile(
                            dense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 0,
                            ),
                            leading: const Icon(
                              Icons.check_circle_outline,
                              size: 16,
                              color: const Color(0xFF2E6BFF),
                            ),
                            title: Text(
                              concept,
                              style: const TextStyle(
                                color: const Color(0xFF5C6B8C),
                                fontSize: 13,
                              ),
                            ),
                            trailing: IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: Colors.redAccent.withOpacity(0.7),
                              ),
                              onPressed: () {
                                setState(() {
                                  concepts.remove(concept);
                                  if (concepts.isEmpty) {
                                    syllabus.remove(chapterName);
                                  }
                                });
                              },
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                );
              },
            ),
          ),

          // Bottom Action Area
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFF0F1C3F),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 20,
                  offset: const Offset(0, -5),
                ),
              ],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () {
                  final allConcepts = syllabus.values.expand((x) => x).toList();

                  if (allConcepts.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("No concepts to generate PBL from"),
                        backgroundColor: Colors.red,
                      ),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProblemSelectionScreen(
                        concepts: allConcepts,
                        classId: widget.classId,
                        className: widget.className,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2E6BFF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFF2E6BFF).withOpacity(0.4),
                ),
                icon: const Icon(Icons.auto_awesome, size: 22),
                label: const Text(
                  'Confirm & Generate PBL',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopLayout() {
    final currentClassName = widget.className ?? 'Class';
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Column(
        children: [
          CCBreadcrumbBar(
            items: [
              BreadcrumbItem(
                label: 'Classes',
                onTap: () => Navigator.of(context).popUntil((route) => route.isFirst),
              ),
              BreadcrumbItem(
                label: currentClassName,
                onTap: () => Navigator.pop(context),
              ),
              BreadcrumbItem(
                label: 'PBL Projects',
                onTap: () => Navigator.pop(context),
              ),
              const BreadcrumbItem(
                label: 'Review Concepts',
              ),
            ],
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFF8B5CF6).withValues(alpha: 0.3)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.menu_book_rounded, size: 16, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 6),
                  Text(
                    'Step 2 of 4: Review Concepts',
                    style: TextStyle(
                      color: Color(0xFF8B5CF6),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1100),
                child: _buildDesktopContent(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopContent() {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20),
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
          ),
          child: const Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Review Syllabus & Concepts',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'Review and fine-tune extracted topics before generating PBL projects',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.all(40),
            itemCount: syllabus.length,
            itemBuilder: (context, index) {
              final entry = syllabus.entries.elementAt(index);
              final chapterName = entry.key;
              final concepts = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF8B5CF6).withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Theme(
                  data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                  child: ExpansionTile(
                    iconColor: const Color(0xFF8B5CF6),
                    collapsedIconColor: const Color(0xFF64748B),
                    backgroundColor: Colors.white,
                    collapsedBackgroundColor: const Color(0xFFF8FAFC),
                    initiallyExpanded: index < 2,
                    title: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFFA78BFA)]),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.folder_rounded, color: Colors.white, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            chapterName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E293B),
                              fontSize: 16,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${concepts.length} concepts',
                            style: const TextStyle(
                              color: Color(0xFF8B5CF6),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    children: [
                      const Divider(height: 1),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Concepts:',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ...concepts.asMap().entries.map((entry) {
                              final conceptIndex = entry.key;
                              final concept = entry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFF1F5F9),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Center(
                                        child: Text(
                                          '${conceptIndex + 1}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF64748B),
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        concept,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Color(0xFF1E293B),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, size: 16, color: Color(0xFF8B5CF6)),
                                      onPressed: () => _editConcept(index, conceptIndex),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, size: 16, color: Colors.redAccent),
                                      onPressed: () => _deleteConcept(index, conceptIndex),
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                TextButton.icon(
                                  onPressed: () => _addConcept(index),
                                  icon: const Icon(Icons.add, size: 16, color: Color(0xFF8B5CF6)),
                                  label: const Text('Add Concept', style: TextStyle(fontSize: 13, color: Color(0xFF8B5CF6))),
                                  style: TextButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Container(
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
              const Text(
                'Review complete? ',
                style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
              ),
              ElevatedButton.icon(
                onPressed: () async {
                  if (syllabus.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No chapters to generate PBL from')),
                    );
                    return;
                  }

                  final allConcepts = syllabus.values.expand((c) => c).toList();
                  if (allConcepts.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No concepts found')),
                    );
                    return;
                  }

                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ProblemSelectionScreen(
                        concepts: allConcepts,
                        classId: widget.classId,
                        className: widget.className,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                  shadowColor: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                ),
                icon: const Icon(Icons.auto_awesome, size: 20),
                label: const Text(
                  'Confirm & Generate PBL',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --- Concept editing helpers ---

  void _editConcept(int chapterIndex, int conceptIndex) {
    final chapterName = syllabus.keys.elementAt(chapterIndex);
    final concepts = syllabus[chapterName]!;
    final concept = concepts[conceptIndex];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Edit concept', style: TextStyle(color: Color(0xFF1E293B))),
        content: TextField(
          controller: TextEditingController(text: concept),
          decoration: const InputDecoration(
            labelText: 'Concept',
            labelStyle: TextStyle(color: Color(0xFF64748B)),
            filled: true,
            fillColor: Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          style: const TextStyle(color: Color(0xFF1E293B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Save', style: TextStyle(color: Color(0xFF8B5CF6))),
          ),
        ],
      ),
    ).then((newValue) {
      if (newValue != null && newValue is String && newValue.trim().isNotEmpty) {
        setState(() {
          syllabus[chapterName]![conceptIndex] = newValue.trim();
        });
      }
    });
  }

  void _deleteConcept(int chapterIndex, int conceptIndex) {
    final chapterName = syllabus.keys.elementAt(chapterIndex);
    setState(() {
      syllabus[chapterName]!.removeAt(conceptIndex);
      if (syllabus[chapterName]!.isEmpty) {
        syllabus.remove(chapterName);
      }
    });
  }

  void _addConcept(int chapterIndex) {
    final chapterName = syllabus.keys.elementAt(chapterIndex);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Add concept', style: TextStyle(color: Color(0xFF1E293B))),
        content: TextField(
          decoration: const InputDecoration(
            labelText: 'Concept',
            labelStyle: TextStyle(color: Color(0xFF64748B)),
            filled: true,
            fillColor: Color(0xFFF1F5F9),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.all(Radius.circular(10)),
            ),
          ),
          style: const TextStyle(color: Color(0xFF1E293B)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF64748B))),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Add', style: TextStyle(color: Color(0xFF8B5CF6))),
          ),
        ],
      ),
    ).then((newConcept) {
      if (newConcept != null && newConcept is String && newConcept.trim().isNotEmpty) {
        setState(() {
          syllabus[chapterName]!.add(newConcept.trim());
        });
      }
    });
  }
}




