import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/screens/teacher/pbl/services/gemini_service.dart';
import 'package:flutter/material.dart';
import 'package:demo/widgets/ui/cc_loading_animation.dart';
import '../../../../widgets/cc_breadcrumb_bar.dart';

class ProblemSelectionScreen extends StatefulWidget {
  final List<String> concepts;
  final String? classId;
  final String? className;

  const ProblemSelectionScreen({
    super.key,
    required this.concepts,
    this.classId,
    this.className,
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
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return _buildDesktopLayout();
    }

    return _buildMobileLayout();
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
                label: 'Problem Selection',
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
                  Icon(Icons.auto_awesome, size: 16, color: Color(0xFF8B5CF6)),
                  SizedBox(width: 6),
                  Text(
                    'Step 3 of 4: Select Problem',
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
                    'Generated Problems',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Text(
                    'AI-crafted problem scenarios based on selected syllabus concepts',
                    style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: const CcLoadingAnimation(
                          color: const Color(0xFF8B5CF6),
                        ),
                      ),
                      const SizedBox(height: 32),
                      const Text(
                        'Generating and saving problem scenarios...',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "This may take a few seconds",
                        style: TextStyle(
                          color: const Color(0xFF64748B),
                          fontSize: 14,
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
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline,
                          size: 64,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Failed to generate scenarios',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Please try again",
                        style: TextStyle(
                          color: const Color(0xFF64748B),
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: () {
                          setState(() => _isLoading = true);
                          _fetchAndSaveScenarios();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                        ),
                        child: const Text("Try Again"),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(40),
                  itemCount: _scenarios.length,
                  itemBuilder: (context, index) {
                    final scenario = _scenarios[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF8B5CF6).withValues(alpha: 0.08),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28),
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
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1E293B),
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(Icons.check_circle, size: 16, color: Colors.green),
                                      const SizedBox(width: 8),
                                      Text(
                                        "SAVED",
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              scenario['problemStatement'] ?? '',
                              style: TextStyle(
                                fontSize: 15,
                                color: const Color(0xFF475569),
                                height: 1.6,
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Divider(height: 1),
                            const SizedBox(height: 12),
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Icon(Icons.check_circle, size: 16, color: Color(0xFF8B5CF6)),
                                SizedBox(width: 8),
                                Text(
                                  'Added to Dashboard',
                                  style: TextStyle(
                                    color: Color(0xFF8B5CF6),
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
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
                    child: const CcLoadingAnimation(
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




