import 'package:demo/screens/teacher/pbl/screens/problem_selection_screen.dart';
import 'package:flutter/material.dart';
import 'package:demo/screens/teacher/pbl/services/class_concept_service.dart';

class ConceptReviewScreen extends StatefulWidget {
  final Map<String, List<String>> syllabus;
  final String? classId;

  const ConceptReviewScreen({super.key, required this.syllabus, this.classId});

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
}




