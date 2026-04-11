import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/screens/teacher/pbl/services/gemini_service.dart';
import 'package:flutter/material.dart';

class ProblemSelectionScreen extends StatefulWidget {
  final List<String> concepts;
  final String? classId;

  const ProblemSelectionScreen({
    super.key,
    required this.concepts,
    this.classId,
  });

  @override
  State<ProblemSelectionScreen> createState() => _ProblemSelectionScreenState();
}

class _ProblemSelectionScreenState extends State<ProblemSelectionScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _scenarios = [];

  @override
  void initState() {
    super.initState();
    _fetchAndSaveScenarios();
  }

  Future<void> _fetchAndSaveScenarios() async {
    try {
      final scenarios = await GeminiService.generateProjectScenarios(
        widget.concepts,
      );

      // Save to Firestore immediately
      if (widget.classId != null && scenarios.isNotEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        final pblCollection = FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('PBL');

        for (var scenario in scenarios) {
          final docRef = pblCollection.doc();

          final miniProjects =
              (scenario['miniProjects'] as List?)
                  ?.map((e) => Map<String, dynamic>.from(e as Map))
                  .toList() ??
              [];

          batch.set(docRef, {
            'title': scenario['title'] ?? 'Untitled',
            'problemStatement': scenario['problemStatement'] ?? '',
            'learningObjectives': [],
            'milestones': [],
            'rubric': [],
            'studentAssignments': [],
            'miniProjects': miniProjects,
            'createdAt': FieldValue.serverTimestamp(),
          });
        }
        await batch.commit();
      }

      if (mounted) {
        setState(() {
          _scenarios = scenarios;
          _isLoading = false;
        });

        // Redirect back to dashboard after successful save
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PBL Projects generated and added to dashboard!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error fetching/saving scenarios: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          'Generated Problems',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        elevation: 0,
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      shape: BoxShape.circle,
                    ),
                    child: const CircularProgressIndicator(
                      color: const Color(0xFF2E6BFF),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Generating and saving problem scenarios...',
                    style: TextStyle(
                      color: const Color(0xFF0D1B3D),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "This may take a few seconds",
                    style: TextStyle(
                      color: const Color(0xFF5C6B8C),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            )
          : _scenarios.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: const Color(0xFF5C6B8C),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Failed to generate scenarios',
                    style: TextStyle(color: const Color(0xFF5C6B8C), fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () {
                      setState(() => _isLoading = true);
                      _fetchAndSaveScenarios();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF2E6BFF),
                      foregroundColor: Colors.black,
                    ),
                    child: const Text("Try Again"),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _scenarios.length,
              itemBuilder: (context, index) {
                final scenario = _scenarios[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0x1A2E6BFF)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                scenario['title'] ?? 'Untitled',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF0D1B3D),
                                ),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 5,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.5),
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.check_circle,
                                    size: 14,
                                    color: Colors.greenAccent,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "SAVED",
                                    style: TextStyle(
                                      color: Colors.greenAccent,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          scenario['problemStatement'] ?? '',
                          style: TextStyle(
                            fontSize: 15,
                            color: const Color(0xFF5C6B8C),
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: const Color(0x1A2E6BFF)),
                        const SizedBox(height: 8),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'Added to Dashboard',
                            style: TextStyle(
                              color: const Color(0xFF2E6BFF),
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}




