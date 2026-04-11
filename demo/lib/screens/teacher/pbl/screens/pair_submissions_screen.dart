import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/services/groq_service.dart';
import 'package:demo/services/firestore_service.dart';

class PairSubmissionsScreen extends StatefulWidget {
  final String classId;
  final String pblId;
  final int pairNumber;
  final List<dynamic> students;
  final String problemStatement;

  const PairSubmissionsScreen({
    super.key,
    required this.classId,
    required this.pblId,
    required this.pairNumber,
    required this.students,
    required this.problemStatement,
  });

  @override
  State<PairSubmissionsScreen> createState() => _PairSubmissionsScreenState();
}

class _PairSubmissionsScreenState extends State<PairSubmissionsScreen> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? _currentlyPlayingUrl;
  bool _isPlaying = false;

  bool _isEvaluating = false;
  Map<String, dynamic>? _evaluationResult;
  bool _isLoadingMilestones = true;
  Map<String, bool> _milestoneStatus = {};

  List<String> _milestoneNames = [
    'Research Phase',
    'Problem Definition',
    'Goal & Objective Setting',
    'Planning & Project Design',
    'Requirement Analysis',
    'Solution Design / Architecture',
    'Development / Implementation',
    'Testing & Debugging',
    'Evaluation & Improvement',
    'Presentation & Reflection',
  ];

  @override
  void initState() {
    super.initState();
    _loadEvaluation();
    _loadMilestones();
    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    _audioPlayer.onPlayerComplete.listen((_) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
          _currentlyPlayingUrl = null;
        });
      }
    });
  }

  Future<void> _loadEvaluation() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('PBL')
          .doc(widget.pblId)
          .collection('evaluations')
          .doc('pair_${widget.pairNumber}')
          .get();

      if (doc.exists && mounted) {
        setState(() {
          _evaluationResult = doc.data();
        });
      }
    } catch (e) {
      print('Error loading evaluation: $e');
    }
  }

  Future<void> _loadMilestones() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('PBL')
          .doc(widget.pblId)
          .collection('milestones')
          .doc('pair_${widget.pairNumber}')
          .get();

      if (doc.exists && mounted) {
        final data = doc.data() ?? {};
        final statusMap = <String, bool>{};
        
        data.forEach((key, value) {
          if (value is bool) {
            statusMap[key] = value;
          }
        });

        setState(() {
          _milestoneStatus = statusMap;

          if (data['milestoneNames'] != null) {
            _milestoneNames = List<String>.from(data['milestoneNames']);
          }
        });
      }
    } catch (e) {
      print('Error loading milestones: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingMilestones = false;
        });
      }
    }
  }

  Future<void> _toggleMilestone(String milestone) async {
    final currentStatus = _milestoneStatus[milestone] ?? false;
    final newValue = !currentStatus;

    if (newValue) {
      // Mark as Complete - Show Feedback Dialog
      final feedbackController = TextEditingController();
      final shouldSave = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          title: Text(
            'Mark "$milestone" as Complete?',
            style: const TextStyle(color: const Color(0xFF0D1B3D), fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Enter feedback for the students (optional):',
                style: TextStyle(color: const Color(0xFF5C6B8C)),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: feedbackController,
                maxLines: 3,
                style: const TextStyle(color: const Color(0xFF0D1B3D)),
                decoration: InputDecoration(
                  hintText: 'e.g., Great work on the research...',
                  hintStyle: const TextStyle(color: Color(0xFF5C6B8C)),
                  filled: true,
                  fillColor: Colors.black12,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false), // Cancel
              child: const Text(
                'Cancel',
                style: TextStyle(color: const Color(0xFF5C6B8C)),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true), // Confirm
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2E6BFF),
              ),
              child: const Text(
                'Confirm',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      );

      if (shouldSave != true) return;

      // Update State
      setState(() {
        _milestoneStatus[milestone] = true;
      });

      // Update Firestore
      try {
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('PBL')
            .doc(widget.pblId)
            .collection('milestones')
            .doc('pair_${widget.pairNumber}')
            .set({
              milestone: true,
              'feedback_$milestone': feedbackController.text.trim(),
            }, SetOptions(merge: true));
      } catch (e) {
        if (mounted) {
          setState(() {
            _milestoneStatus[milestone] = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    } else {
      // Uncheck - Just toggle off
      setState(() {
        _milestoneStatus[milestone] = false;
      });

      try {
        await FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('PBL')
            .doc(widget.pblId)
            .collection('milestones')
            .doc('pair_${widget.pairNumber}')
            .set({milestone: false}, SetOptions(merge: true));
        // Optional: We could delete feedback here, but keeping it might be safer unless explicitly requested.
      } catch (e) {
        if (mounted) {
          setState(() {
            _milestoneStatus[milestone] = true;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio(String url) async {
    if (_currentlyPlayingUrl == url && _isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(UrlSource(url));
      setState(() {
        _currentlyPlayingUrl = url;
      });
    }
  }

  Future<void> _launchFile(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Could not open file')));
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _evaluateMarks() async {
    setState(() {
      _isEvaluating = true;
    });

    try {
      final studentData = widget.students
          .map((e) => e as Map<String, dynamic>)
          .toList();
      final result = await GroqService.evaluatePblSubmission(
        problemStatement: widget.problemStatement,
        studentSubmissions: studentData,
      );

      // Save evaluation to Firestore
      final evalRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(widget.classId)
          .collection('PBL')
          .doc(widget.pblId)
          .collection('evaluations')
          .doc('pair_${widget.pairNumber}');

      // Check if points already awarded to avoid double counting if re-evaluating
      final docSnapshot = await evalRef.get();
      final bool alreadyAwarded =
          docSnapshot.exists && (docSnapshot.data()?['pointsAwarded'] == true);

      // Save result
      final dataToSave = Map<String, dynamic>.from(result);
      if (!alreadyAwarded) {
        dataToSave['pointsAwarded'] = true;
      }
      await evalRef.set(dataToSave, SetOptions(merge: true));

      // Update XP for each student if not already awarded
      if (!alreadyAwarded) {
        final individualEvals = result['studentEvaluations'] as List;
        for (var eval in individualEvals) {
          final studentName = eval['name'];
          final score = (eval['score'] ?? 0) as int;

          final student = widget.students.firstWhere(
            (s) => s['name'] == studentName,
            orElse: () => null,
          );

          if (student != null && student['uid'] != null) {
            await FirestoreService().updateStudentPblScore(
              student['uid'],
              score,
              widget.classId,
            );
          }
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks evaluated and PBL Score updated!'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marks re-evaluated (PBL Score not updated again)'),
          ),
        );
      }

      setState(() {
        _evaluationResult = result;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Evaluation failed: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEvaluating = false;
        });
      }
    }
  }

  void _editMilestones() {
    List<String> tempNames = List.from(_milestoneNames);
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            backgroundColor: Colors.white,
            title: const Text(
              "Edit Milestones",
              style: TextStyle(color: const Color(0xFF0D1B3D)),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: tempNames.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8.0),
                          child: Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  initialValue: tempNames[index],
                                  style: const TextStyle(color: const Color(0xFF0D1B3D)),
                                  decoration: const InputDecoration(
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: const Color(0x1A2E6BFF),
                                      ),
                                    ),
                                    focusedBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: const Color(0xFF2E6BFF),
                                      ),
                                    ),
                                  ),
                                  onChanged: (val) {
                                    tempNames[index] = val;
                                  },
                                ),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  setDialogState(() {
                                    tempNames.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text("Add Milestone"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF0F4FF),
                    ),
                    onPressed: () {
                      setDialogState(() {
                        tempNames.add("New Milestone");
                      });
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Cancel",
                  style: TextStyle(color: const Color(0xFF5C6B8C)),
                ),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2E6BFF)),
                onPressed: () async {
                  setState(() {
                    _milestoneNames = tempNames;
                  });

                  // Save to firestore
                  try {
                    await FirebaseFirestore.instance
                        .collection('classes')
                        .doc(widget.classId)
                        .collection('PBL')
                        .doc(widget.pblId)
                        .collection('milestones')
                        .doc('pair_${widget.pairNumber}')
                        .set({
                          'milestoneNames': tempNames,
                        }, SetOptions(merge: true));
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Error saving: $e")),
                      );
                    }
                  }

                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text(
                  "Save",
                  style: TextStyle(color: Colors.black),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF), // Dark Navy background
      appBar: AppBar(
        title: Text(
          'Pair ${widget.pairNumber} Dashboard',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        foregroundColor: const Color(0xFF0D1B3D),
        elevation: 0,
        actions: [],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('classes')
            .doc(widget.classId)
            .collection('PBL')
            .doc(widget.pblId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final pblData = snapshot.data!.data() as Map<String, dynamic>?;
          final List<dynamic> allAssignments =
              pblData?['studentAssignments'] ?? [];

          List<dynamic> liveStudents = widget.students;

          try {
            final assignment = allAssignments.firstWhere(
              (a) => a['pairNumber'] == widget.pairNumber,
              orElse: () => null,
            );
            if (assignment != null) {
              liveStudents = assignment['students'] ?? [];
            }
          } catch (e) {
            // retain fallback
          }

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Header Section: Students ---
                    _buildStudentsHeader(liveStudents),
                    const SizedBox(height: 24),

                    // --- Evaluation Section (if exists) ---
                    if (_evaluationResult != null) ...[
                      _buildEvaluationCard(),
                      const SizedBox(height: 24),
                    ],

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "PROJECT ROADMAP",
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                            color: const Color(0xFF5C6B8C),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit,
                            color: const Color(0xFF5C6B8C),
                            size: 16,
                          ),
                          onPressed: _editMilestones,
                          tooltip: "Edit Milestones",
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    if (_isLoadingMilestones)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.all(20.0),
                          child: CircularProgressIndicator(),
                        ),
                      )
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _milestoneNames.length,
                        itemBuilder: (context, index) {
                          // Timeline logic
                          final name = _milestoneNames[index];
                          final isCompleted = _milestoneStatus[name] ?? false;

                          // Determine unlock status
                          bool isNext = false;
                          if (!isCompleted) {
                            if (index == 0) {
                              isNext = true;
                            } else {
                              bool allPrevCompleted = true;
                              for (int i = 0; i < index; i++) {
                                if (!(_milestoneStatus[_milestoneNames[i]] ??
                                    false)) {
                                  allPrevCompleted = false;
                                  break;
                                }
                              }
                              isNext = allPrevCompleted;
                            }
                          }

                          // Get submissions
                          List<Map<String, dynamic>> submissionsList = [];
                          for (var student in liveStudents) {
                            if (student is Map &&
                                student['milestone_submissions'] != null) {
                              final submissions =
                                  student['milestone_submissions']
                                      as Map<String, dynamic>;
                              if (submissions.containsKey(name)) {
                                final sub = submissions[name];
                                submissionsList.add({
                                  'studentName': student['name'] ?? 'Student',
                                  ...sub,
                                });
                              }
                            }
                          }

                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Timeline Line
                                Column(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isCompleted
                                            ? Colors.green
                                            : (isNext
                                                  ? Colors.orange
                                                  : Colors.grey.shade300),
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white,
                                          width: 2,
                                        ),
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (isCompleted
                                                        ? Colors.green
                                                        : (isNext
                                                              ? Colors.orange
                                                              : Colors.grey))
                                                    .withOpacity(0.3),
                                            blurRadius: 4,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: Icon(
                                        isCompleted
                                            ? Icons.check
                                            : (isNext
                                                  ? Icons.access_time
                                                  : Icons.lock),
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                    ),
                                    Expanded(
                                      child: index < _milestoneNames.length - 1
                                          ? Container(
                                              width: 2,
                                              color: isCompleted
                                                  ? Colors.green.withOpacity(
                                                      0.5,
                                                    )
                                                  : const Color(0xFFF0F4FF),
                                              margin:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 4,
                                                  ),
                                            )
                                          : const SizedBox(),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                // Content
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(bottom: 24),
                                    child: _buildMilestoneCard(
                                      name,
                                      isCompleted,
                                      isNext,
                                      submissionsList,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),

                    const SizedBox(height: 40),
                  ],
                ),
              ),

              if (_isEvaluating)
                Container(
                  color: Colors.black54,
                  child: const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: Colors.white),
                        SizedBox(height: 16),
                        Text(
                          "AI Evaluating Submissions...",
                          style: TextStyle(
                            color: const Color(0xFF0D1B3D),
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildStudentsHeader(List<dynamic> students) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white, // Lighter navy
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F4FF)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.people_alt,
                color: const Color(0xFF2E6BFF),
                size: 20,
              ),
              const SizedBox(width: 10),
              Text(
                "TEAM MEMBERS • PAIR #${widget.pairNumber}",
                style: TextStyle(
                  color: const Color(0xFF2E6BFF),
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: students.map((s) {
              final name = s['name'] ?? 'Unknown';
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFECF3FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEAF1FF)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: const Color(0xFF2E6BFF),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.black, // Dark text on bright cyan
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      name,
                      style: const TextStyle(
                        color: const Color(0xFF0D1B3D),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildMilestoneCard(
    String title,
    bool isCompleted,
    bool isNext,
    List<Map<String, dynamic>> submissions,
  ) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNext
              ? Colors.orange.withOpacity(0.5)
              : (isCompleted ? Colors.green.withOpacity(0.3) : const Color(0xFFF0F4FF)),
          width: isNext ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: isCompleted || isNext
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isCompleted
                          ? Colors.white
                          : (isNext ? Colors.white : Colors.black38),
                    ),
                  ),
                ),
                if (!isCompleted && isNext)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.withOpacity(0.5)),
                    ),
                    child: const Text(
                      "Current Phase",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (isCompleted)
                  const Icon(Icons.verified, size: 18, color: Colors.green),

                if (isNext || isCompleted) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: isCompleted,
                      onChanged: (val) => _toggleMilestone(title),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      activeColor: Colors.green,
                    ),
                  ),
                ],
              ],
            ),
          ),

          if (submissions.isNotEmpty) const Divider(height: 1),

          // Submissions List
          if (submissions.isNotEmpty)
            Container(
              decoration: BoxDecoration(
                color: Colors.black12,
                borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: submissions
                    .map(
                      (sub) => Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF0F4FF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  sub['studentName'] ?? 'Student',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: const Color(0xFF0D1B3D),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatDate(sub['submittedAt']),
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            // File
                            InkWell(
                              onTap: sub['fileUrl'] != null
                                  ? () => _launchFile(context, sub['fileUrl'])
                                  : null,
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.insert_drive_file,
                                    size: 16,
                                    color: Colors.indigo,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      sub['fileName'] ?? 'Attachment',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: const Color(0xFF2E6BFF),
                                        decoration: TextDecoration.underline,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Voice
                            if (sub['voiceUrl'] != null) ...[
                              const SizedBox(height: 8),
                              InkWell(
                                onTap: () => _toggleAudio(sub['voiceUrl']),
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2E6BFF).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        _currentlyPlayingUrl ==
                                                    sub['voiceUrl'] &&
                                                _isPlaying
                                            ? Icons.pause_circle
                                            : Icons.play_circle,
                                        size: 18,
                                        color: const Color(0xFF2E6BFF),
                                      ),
                                      const SizedBox(width: 6),
                                      const Text(
                                        "Play Explainer",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: const Color(0xFF2E6BFF),
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ),
            )
          else if (isNext && !isCompleted)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.orange.shade300,
                  ),
                  const SizedBox(width: 6),
                  const Text(
                    "Awaiting student submission",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEvaluationCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade900, Colors.indigo.shade800],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Colors.black26,
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.psychology, color: Colors.white),
                    SizedBox(width: 12),
                    Text(
                      "AI Evaluation Report",
                      style: TextStyle(
                        color: const Color(0xFF0D1B3D),
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0x332E6BFF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${_evaluationResult!['totalScore']}/100",
                    style: const TextStyle(
                      color: const Color(0xFF0D1B3D),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "PAIR ANALYSIS",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5C6B8C),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _evaluationResult!['pairAnalysis'] ??
                      'No analysis available.',
                  style: const TextStyle(
                    fontSize: 14,
                    color: const Color(0xFF0D1B3D),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  "INDIVIDUAL SCORES",
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF5C6B8C),
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                ...(_evaluationResult!['studentEvaluations'] as List)
                    .map(
                      (eval) => Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black26,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFFF0F4FF)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  eval['name'],
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF0D1B3D),
                                  ),
                                ),
                                Text(
                                  "${eval['score']}/50",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF2E6BFF),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              eval['feedback'],
                              style: const TextStyle(
                                fontSize: 13,
                                color: const Color(0xFF5C6B8C),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                    .toList(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic timestamp) {
    try {
      if (timestamp is Timestamp) {
        return DateFormat('MMM d, h:mm a').format(timestamp.toDate());
      }
    } catch (e) {
      // Ignore formatting errors
    }
    return '';
  }
}





