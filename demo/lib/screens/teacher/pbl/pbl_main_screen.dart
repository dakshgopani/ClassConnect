import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'screens/concept_review_screen.dart';
import 'screens/pbl_detail_screen.dart';
import 'screens/pbl_editor_screen.dart';
import 'screens/class_mini_projects_screen.dart';
import 'models/pbl_project.dart';

class PblMainScreen extends StatefulWidget {
  final String classId;
  final String className;
  final String classCode;

  const PblMainScreen({
    super.key,
    required this.classId,
    required this.className,
    required this.classCode,
  });

  @override
  State<PblMainScreen> createState() => _PblMainScreenState();
}

class _PblMainScreenState extends State<PblMainScreen> {
  late Stream<QuerySnapshot> _pblStream;

  Future<void> _openConceptReviewFromStoredChapters() async {
    final chaptersSnapshot = await FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('chapters')
        .orderBy('order')
        .get();

    final syllabus = <String, List<String>>{};
    for (final doc in chaptersSnapshot.docs) {
      final data = doc.data();
      final chapterName = (data['title'] ?? data['name'] ?? '').toString();
      final concepts = List<String>.from(
        data['concepts'] ?? const <String>[],
      ).where((value) => value.trim().isNotEmpty).toList();

      if (chapterName.isNotEmpty) {
        syllabus[chapterName] = concepts;
      }
    }

    if (!mounted) return;

    if (syllabus.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'No syllabus chapters found for this class. Add syllabus during class creation.',
          ),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ConceptReviewScreen(syllabus: syllabus, classId: widget.classId),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _pblStream = FirebaseFirestore.instance
        .collection('classes')
        .doc(widget.classId)
        .collection('PBL')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: Text(
          '${widget.className} - PBL',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        foregroundColor: const Color(0xFF0D1B3D),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) =>
                      ClassMiniProjectsScreen(classId: widget.classId),
                ),
              );
            },
            icon: const Icon(Icons.list_alt, color: Color(0xFF2E6BFF)),
            tooltip: 'View All Mini Projects',
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _pblStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFF2E6BFF)),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error: ${snapshot.error}',
                style: const TextStyle(color: Color(0xFF0D1B3D)),
              ),
            );
          }

          final pblDocs = snapshot.data?.docs ?? [];

          // If no PBL exists, ask teacher to use stored chapters and concepts
          if (pblDocs.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.lightbulb_outline_rounded,
                      size: 54,
                      color: Color(0xFF2E6BFF),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'No PBL projects yet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF0D1B3D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Generate from the chapters and concepts extracted at class creation.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 14, color: Color(0xFF5C6B8C)),
                    ),
                    const SizedBox(height: 22),
                    ElevatedButton.icon(
                      onPressed: _openConceptReviewFromStoredChapters,
                      icon: const Icon(Icons.auto_awesome, color: Colors.white),
                      label: const Text('Generate PBL from Stored Chapters'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E6BFF),
                        foregroundColor: const Color(0xFF0D1B3D),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          // Show existing PBL problems
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Class Info Card
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF2E6BFF).withOpacity(0.06),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(color: const Color(0x1A2E6BFF)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.className,
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0D1B3D),
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFF2E6BFF).withOpacity(0.08),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Class Code: ${widget.classCode}',
                            style: const TextStyle(
                              color: Color(0xFF0D1B3D),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'ACTIVE PBL PROJECTS',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5C6B8C),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                // PBL Cards
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: pblDocs.length,
                  itemBuilder: (context, index) {
                    final pblDoc = pblDocs[index];
                    final pblData = pblDoc.data() as Map<String, dynamic>;
                    return _buildPblCard(context, pblData, pblDoc.id);
                  },
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openConceptReviewFromStoredChapters,
        backgroundColor: const Color(0xFF2E6BFF),
        foregroundColor: const Color(0xFF0D1B3D),
        tooltip: 'Create New PBL',
        child: const Icon(Icons.add_task, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPblCard(
    BuildContext context,
    Map<String, dynamic> pblData,
    String pblId,
  ) {
    final title = pblData['title'] ?? 'Untitled Project';
    final problemStatement =
        pblData['problemStatement'] ?? 'No problem statement';
    final objectives = pblData['learningObjectives'] as List<dynamic>?;
    final milestones = pblData['milestones'] as List<dynamic>?;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A2E6BFF)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E6BFF).withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => PblDetailScreen(
                  classId: widget.classId,
                  pblId: pblId,
                  title: title,
                  pblData: pblData,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF0D1B3D),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      color: Color(0xFFA5B2C8),
                      size: 16,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  problemStatement,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF5C6B8C),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    if (objectives != null && objectives.isNotEmpty)
                      _buildInfoChip(
                        Icons.track_changes,
                        '${objectives.length} Objectives',
                        Colors.blueAccent,
                      ),
                    if (objectives != null && objectives.isNotEmpty)
                      const SizedBox(width: 8),
                    if (milestones != null && milestones.isNotEmpty)
                      _buildInfoChip(
                        Icons.flag,
                        '${milestones.length} Milestones',
                        Colors.greenAccent,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                const Divider(color: Color(0x1A2E6BFF)),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PblEditorScreen(
                              classId: widget.classId,
                              project: PblProject.fromJson(pblData),
                              pblId: pblId,
                            ),
                          ),
                        );
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF2E6BFF),
                      ),
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                    ),
                    const SizedBox(width: 8),
                    TextButton.icon(
                      onPressed: () {
                        _deletePbl(context, pblId);
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                      ),
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  void _deletePbl(BuildContext context, String pblId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text(
          'Delete PBL?',
          style: TextStyle(color: Color(0xFF0D1B3D)),
        ),
        content: const Text(
          'This action cannot be undone.',
          style: TextStyle(color: Color(0xFF5C6B8C)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF5C6B8C)),
            ),
          ),
          TextButton(
            onPressed: () {
              FirebaseFirestore.instance
                  .collection('classes')
                  .doc(widget.classId)
                  .collection('PBL')
                  .doc(pblId)
                  .delete();
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}






