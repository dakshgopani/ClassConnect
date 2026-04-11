import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:record/record.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class PblSubmissionSheet extends StatefulWidget {
  final Map<String, dynamic> pblData;

  const PblSubmissionSheet({super.key, required this.pblData});

  @override
  State<PblSubmissionSheet> createState() => _PblSubmissionSheetState();
}

class _PblSubmissionSheetState extends State<PblSubmissionSheet> {
  static const _surface = Colors.white;
  static const _surfaceLight = Color(0xFFF0F4FF);
  static const _accent = Color(0xFF2E6BFF);
  static const _textPrimary = Color(0xFF0D1B3D);
  static const _textSecondary = Color(0xFF5C6B8C);

  PlatformFile? _selectedFile;
  bool _isUploading = false;

  // Audio Recording State
  late final AudioRecorder _audioRecorder;
  late final AudioPlayer _audioPlayer;
  bool _isRecording = false;
  String? _audioPath;
  int _recordDuration = 0;
  Timer? _timer;
  bool _isPlaying = false;
  StreamSubscription? _playerStateSubscription;
  StreamSubscription? _playerCompleteSubscription;

  // Milestone State
  String? _activeMilestoneName;
  Map<String, bool> _milestoneChecklist = {};
  Map<String, String> _milestoneFeedback = {};
  Set<String> _submittedMilestones = {};
  bool _isLoadingMilestones = true;

  final List<String> _milestoneNames = [
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
    _fetchMilestoneStatus();
    _loadMySubmissions();
    _audioRecorder = AudioRecorder();
    _audioPlayer = AudioPlayer();

    _playerStateSubscription = _audioPlayer.onPlayerStateChanged.listen((
      state,
    ) {
      if (mounted) {
        setState(() {
          _isPlaying = state == PlayerState.playing;
        });
      }
    });

    // Reset player on completion
    _playerCompleteSubscription = _audioPlayer.onPlayerComplete.listen((event) {
      if (mounted) {
        setState(() {
          _isPlaying = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _playerStateSubscription?.cancel();
    _playerCompleteSubscription?.cancel();
    _audioRecorder.dispose();
    _audioPlayer.dispose();
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchMilestoneStatus() async {
    try {
      final classId = widget.pblData['classId'];
      final pblId = widget.pblData['pblId'];
      final pairNumber = widget.pblData['pairNumber'] ?? 0;

      final doc = await FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('PBL')
          .doc(pblId)
          .collection('milestones')
          .doc('pair_$pairNumber')
          .get();

      if (mounted) {
        final data = doc.data() ?? {};
        final feedbackMap = <String, String>{};
        final checklistMap = <String, bool>{};

        data.forEach((key, value) {
          if (key.startsWith('feedback_')) {
            // key format: feedback_Milestone Name
            final milestoneName = key.substring('feedback_'.length);
            feedbackMap[milestoneName] = value.toString();
          } else if (value is bool) {
            checklistMap[key] = value;
          }
        });

        setState(() {
          _milestoneChecklist = checklistMap;
          _milestoneFeedback = feedbackMap;
          _isLoadingMilestones = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching milestones: $e");
      if (mounted) setState(() => _isLoadingMilestones = false);
    }
  }

  void _loadMySubmissions() {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final pairStudents =
          widget.pblData['pairStudents'] as List<dynamic>? ?? [];
      final myData = pairStudents.firstWhere(
        (s) => s['uid'] == user.uid,
        orElse: () => null,
      );

      if (myData != null && myData['milestone_submissions'] != null) {
        final submissions = Map<String, dynamic>.from(
          myData['milestone_submissions'],
        );
        setState(() {
          _submittedMilestones = submissions.keys.toSet();
        });
      }
    } catch (e) {
      debugPrint("Error loading my submissions: $e");
    }
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'ppt', 'pptx'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        _selectedFile = result.files.single;
      });
    }
  }

  Future<void> _startRecording() async {
    try {
      if (await _audioRecorder.hasPermission()) {
        final directory = await getTemporaryDirectory();
        final path =
            '${directory.path}/submission_explanation_${DateTime.now().millisecondsSinceEpoch}.m4a';

        await _audioRecorder.start(const RecordConfig(), path: path);

        setState(() {
          _isRecording = true;
          _recordDuration = 0;
          _audioPath = null;
        });

        _timer?.cancel();
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          setState(() {
            _recordDuration++;
          });
        });
      }
    } catch (e) {
      debugPrint('Error starting record: $e');
    }
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _audioRecorder.stop();
      _timer?.cancel();

      setState(() {
        _isRecording = false;
        _audioPath = path;
      });
    } catch (e) {
      debugPrint('Error stopping record: $e');
    }
  }

  void _deleteRecording() {
    _audioPlayer.stop();
    setState(() {
      _audioPath = null;
      _recordDuration = 0;
      _isPlaying = false;
    });
  }

  Future<void> _toggleAudioPlayback() async {
    if (_audioPath == null) return;

    if (_isPlaying) {
      await _audioPlayer.pause();
    } else {
      await _audioPlayer.play(DeviceFileSource(_audioPath!));
    }
  }

  String _formatDuration(int seconds) {
    final min = (seconds ~/ 10).toString().padLeft(2, '0');
    final sec = (seconds % 10).toString().padLeft(2, '0');
    return '$min:$sec';
  }

  Future<void> _submitWork() async {
    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please attach a submission file.')),
      );
      return;
    }

    if (_audioPath == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please record a voice explanation.')),
      );
      return;
    }

    if (_recordDuration < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Voice explanation must be at least 1 minute.'),
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final pblId = widget.pblData['pblId'];
      final classId = widget.pblData['classId'];

      // 1. Read file bytes
      final file = File(_selectedFile!.path!);
      final fileBytes = await file.readAsBytes();

      // 2. Create unique path with milestone folder
      final sanitizedMilestone = _activeMilestoneName!.toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9]'),
        '_',
      );
      final filePath =
          '${user.uid}/$pblId/$sanitizedMilestone/${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.name}';

      // 3. Upload to Supabase
      final supabase = Supabase.instance.client;
      await supabase.storage
          .from('PBL - PROJECTS')
          .uploadBinary(
            filePath,
            fileBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      // 4. Get Public URL
      final fileUrl = supabase.storage
          .from('PBL - PROJECTS')
          .getPublicUrl(filePath);

      // 4b. Upload Voice Recording
      final voiceFile = File(_audioPath!);
      final voiceBytes = await voiceFile.readAsBytes();
      final voicePath =
          '${user.uid}/$pblId/$sanitizedMilestone/voice_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await supabase.storage
          .from('PBL - PROJECTS')
          .uploadBinary(
            voicePath,
            voiceBytes,
            fileOptions: const FileOptions(upsert: true),
          );

      final voiceUrl = supabase.storage
          .from('PBL - PROJECTS')
          .getPublicUrl(voicePath);

      // 5. Update Firestore
      // We need to update the specific student's record inside the nested arrays
      final pblRef = FirebaseFirestore.instance
          .collection('classes')
          .doc(classId)
          .collection('PBL')
          .doc(pblId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(pblRef);
        if (!snapshot.exists) {
          throw Exception("PBL Document not found");
        }

        final data = snapshot.data()!;
        final studentAssignments = List<Map<String, dynamic>>.from(
          data['studentAssignments'] ?? [],
        );

        bool updated = false;

        // Iterate to find the student and update their record
        final updatedAssignments = studentAssignments.map((assignment) {
          final students = List<dynamic>.from(assignment['students'] ?? []);
          final updatedStudents = students.map((student) {
            if (student is Map && student['uid'] == user.uid) {
              updated = true;
              return {
                ...student,
                'submission': {
                  'fileUrl': fileUrl,
                  'fileName': _selectedFile!.name,
                  'voiceUrl': voiceUrl,
                  'voiceDuration': _recordDuration,
                  'submittedAt': Timestamp.now(),
                  'milestone': _activeMilestoneName,
                },
                'milestone_submissions': {
                  ...?student['milestone_submissions'],
                  _activeMilestoneName!: {
                    'fileUrl': fileUrl,
                    'fileName': _selectedFile!.name,
                    'voiceUrl': voiceUrl,
                    'voiceDuration': _recordDuration,
                    'submittedAt': Timestamp.now(),
                  },
                },
              };
            }
            return student;
          }).toList();

          return {...assignment, 'students': updatedStudents};
        }).toList();

        if (updated) {
          transaction.update(pblRef, {
            'studentAssignments': updatedAssignments,
          });
        }
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Submission successful!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
        // Clear state after submission
        setState(() {
          if (_activeMilestoneName != null) {
            _submittedMilestones.add(_activeMilestoneName!);
          }
          _activeMilestoneName = null;
          _selectedFile = null;
          _audioPath = null;
          _recordDuration = 0;
        });
      }
    } catch (e) {
      debugPrint('Submission error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error submitting: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.pblData['title'] as String? ?? 'Untitled';
    final problemStatement =
        widget.pblData['problemStatement'] as String? ?? 'No problem statement';
    final objectives =
        widget.pblData['learningObjectives'] as List<dynamic>? ?? [];
    final milestones = widget.pblData['milestones'] as List<dynamic>? ?? [];
    final pairNumber = widget.pblData['pairNumber'] as int? ?? 0;
    final pairStudents = widget.pblData['pairStudents'] as List<dynamic>? ?? [];

    final deadlineTimestamp = widget.pblData['deadline'] as Timestamp?;
    final deadlineDate = deadlineTimestamp?.toDate();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important for bottom sheet
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: _textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, color: _textPrimary),
                ),
              ],
            ),

            if (deadlineDate != null)
              Container(
                margin: const EdgeInsets.only(top: 8, bottom: 8),
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.orangeAccent.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.orangeAccent.withOpacity(0.5),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.timer,
                      color: Colors.orangeAccent,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Deadline: ${DateFormat('MMM d, yyyy - h:mm a').format(deadlineDate)}',
                      style: const TextStyle(
                        color: Colors.orangeAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),

            // Problem Statement
            const Text(
              'Problem Statement',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              problemStatement,
              style: const TextStyle(fontSize: 13, color: _textSecondary),
            ),
            const SizedBox(height: 16),

            // Objectives
            if (objectives.isNotEmpty) ...[
              const Text(
                'Learning Objectives',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              ...objectives.map(
                (obj) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '• ',
                        style: TextStyle(
                          color: _accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Expanded(
                        child: Text(
                          obj.toString(),
                          style: const TextStyle(
                            fontSize: 13,
                            color: _textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // // Milestones
            // if (milestones.isNotEmpty) ...[
            //   const Text(
            //     'Milestones',
            //     style: TextStyle(
            //       fontSize: 14,
            //       fontWeight: FontWeight.w600,
            //       color: Colors.white,
            //     ),
            //   ),
            //   const SizedBox(height: 8),
            //   ...milestones.asMap().entries.map(
            //         (entry) => Padding(
            //           padding: const EdgeInsets.only(bottom: 8),
            //           child: Row(
            //             crossAxisAlignment: CrossAxisAlignment.start,
            //             children: [
            //               Container(
            //                 width: 24,
            //                 height: 24,
            //                 decoration: BoxDecoration(
            //                   shape: BoxShape.circle,
            //                   color: Colors.indigo.shade700,
            //                 ),
            //                 child: Center(
            //                   child: Text(
            //                     '${entry.key + 1}',
            //                     style: const TextStyle(
            //                       color: Colors.white,
            //                       fontSize: 12,
            //                       fontWeight: FontWeight.bold,
            //                     ),
            //                   ),
            //                 ),
            //               ),
            //               const SizedBox(width: 8),
            //               Expanded(
            //                 child: Column(
            //                   crossAxisAlignment: CrossAxisAlignment.start,
            //                   children: [
            //                     Text(
            //                       'Phase ${entry.key + 1}',
            //                       style: const TextStyle(
            //                         fontWeight: FontWeight.bold,
            //                         color: Colors.cyan,
            //                         fontSize: 13,
            //                       ),
            //                     ),
            //                     Text(
            //                       // Logic to handle Map/String and remove "Phase X" prefix
            //                       () {
            //                           final rawText = entry.value is Map
            //                               ? (entry.value['name'] ??
            //                                   entry.value['description'] ??
            //                                   entry.value.toString())
            //                               : entry.value.toString();

            //                           // Remove "Phase 1:", "Phase 1 -", etc. from the start
            //                           return rawText.replaceAll(RegExp(r'^Phase\s*\d+[:\s-]*', caseSensitive: false), '').trim();
            //                       }(),
            //                       maxLines: 1,
            //                       overflow: TextOverflow.ellipsis,
            //                       style: const TextStyle(
            //                         fontSize: 13,
            //                         color: Colors.white70,
            //                       ),
            //                     ),
            //                   ],
            //                 ),
            //               ),
            //             ],
            //           ),
            //         ),
            //       ),
            //   const SizedBox(height: 16),
            // ],

            // Milestones Section
            if (_activeMilestoneName == null) ...[
              if (_isLoadingMilestones)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Colors.cyan),
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _milestoneNames.length,
                  itemBuilder: (context, index) {
                    final name = _milestoneNames[index];
                    final isCompleted = _milestoneChecklist[name] ?? false;
                    final isSubmitted = _submittedMilestones.contains(name);

                    // 1st (index 0) is always unlocked. Others unlocked if previous is Completed.
                    bool isUnlocked =
                        index == 0 ||
                        (_milestoneChecklist[_milestoneNames[index - 1]] ??
                            false);

                    // Status Text & Color
                    String? subtitle;
                    Color statusColor = Colors.grey;
                    if (isCompleted) {
                      // Done
                    } else if (isSubmitted) {
                      subtitle = "Awaiting Teacher Response";
                      statusColor = Colors.orangeAccent;
                      isUnlocked =
                          false; // "Lock" it so they can't re-submit while waiting
                    } else if (isUnlocked) {
                      subtitle = "Open for Submission";
                      statusColor = Colors.cyanAccent;
                    } else {
                      statusColor = Colors.grey.shade700;
                    }

                    return Card(
                      color: isUnlocked ? _surface : _surfaceLight,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(
                          color: isSubmitted
                              ? Colors.orangeAccent.withOpacity(0.5)
                              : (isUnlocked
                                    ? _accent.withOpacity(0.25)
                                    : const Color(0x1A2E6BFF)),
                        ),
                      ),
                      child: Column(
                        children: [
                          ListTile(
                            onTap: (isUnlocked && !isCompleted && !isSubmitted)
                                ? () {
                                    setState(() {
                                      _activeMilestoneName = name;
                                      _selectedFile = null;
                                      _audioPath = null;
                                      _recordDuration = 0;
                                    });
                                  }
                                : null,
                            leading: CircleAvatar(
                              backgroundColor: isCompleted
                                  ? Colors.green
                                  : (isSubmitted
                                        ? Colors.orangeAccent.withOpacity(0.2)
                                        : (isUnlocked ? _accent : Colors.grey)),
                              radius: 16,
                              child: Icon(
                                isCompleted
                                    ? Icons.check
                                    : (isSubmitted
                                          ? Icons.access_time
                                          : (isUnlocked
                                                ? Icons.lock_open
                                                : Icons.lock)),
                                color: isSubmitted
                                    ? Colors.orangeAccent
                                    : _surface,
                                size: 16,
                              ),
                            ),
                            title: Text(
                              name,
                              style: TextStyle(
                                color: isUnlocked || isSubmitted
                                    ? _textPrimary
                                    : _textSecondary,
                                fontWeight: (isUnlocked || isSubmitted)
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            subtitle: subtitle != null
                                ? Text(
                                    subtitle,
                                    style: TextStyle(
                                      color: statusColor,
                                      fontSize: 12,
                                    ),
                                  )
                                : null,
                            trailing:
                                (isUnlocked && !isCompleted && !isSubmitted)
                                ? const Icon(
                                    Icons.arrow_forward_ios,
                                    size: 14,
                                    color: _accent,
                                  )
                                : null,
                          ),
                          if (isCompleted &&
                              _milestoneFeedback.containsKey(name) &&
                              (_milestoneFeedback[name]?.isNotEmpty ?? false))
                            Container(
                              width: double.infinity,
                              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.green.withOpacity(0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Row(
                                    children: [
                                      Icon(
                                        Icons.comment,
                                        size: 14,
                                        color: Colors.greenAccent,
                                      ),
                                      SizedBox(width: 6),
                                      Text(
                                        "Teacher Feedback:",
                                        style: TextStyle(
                                          color: Colors.greenAccent,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _milestoneFeedback[name]!,
                                    style: const TextStyle(
                                      color: _textSecondary,
                                      fontSize: 13,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),
            ],

            if (_activeMilestoneName != null) ...[
              ElevatedButton.icon(
                onPressed: () => setState(() => _activeMilestoneName = null),
                icon: const Icon(Icons.arrow_back),
                label: const Text("Back to Milestones"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: _textPrimary,
                  side: const BorderSide(color: Color(0x1A2E6BFF)),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accent.withOpacity(0.25)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.flag, color: _accent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Submitting for:",
                            style: TextStyle(color: _accent, fontSize: 12),
                          ),
                          Text(
                            _activeMilestoneName!,
                            style: const TextStyle(
                              color: _textPrimary,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],

            // Team & Submission Section
            if (_activeMilestoneName != null)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _surfaceLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _accent.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Your Team - Pair #$pairNumber',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _accent,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...pairStudents.map(
                      (student) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _accent,
                              ),
                              child: Center(
                                child: Text(
                                  (student['name'] as String? ?? 'U')
                                      .characters
                                      .first,
                                  style: const TextStyle(
                                    color: _surface,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        student['name'] ?? 'Unknown',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w500,
                                          color: _textPrimary,
                                        ),
                                      ),
                                      if (student['submission'] != null &&
                                          student['submission']['fileUrl'] !=
                                              null) ...[
                                        const SizedBox(width: 6),
                                        const Icon(
                                          Icons.check_circle,
                                          size: 14,
                                          color: Colors.green,
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    student['email'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: _textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0x1A2E6BFF)),
                    const SizedBox(height: 16),

                    // VOICE RECORDING SECTION
                    Text(
                      'Voice Explanation (Min 60s)',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_audioPath == null)
                      SizedBox(
                        width: double.infinity,
                        child: _isRecording
                            ? OutlinedButton.icon(
                                onPressed: _stopRecording,
                                icon: const Icon(
                                  Icons.stop,
                                  color: Colors.redAccent,
                                ),
                                label: Text(
                                  'Stop Recording (${_formatDuration(_recordDuration)})',
                                  style: const TextStyle(
                                    color: Colors.redAccent,
                                  ),
                                ),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(
                                    color: Colors.redAccent,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              )
                            : OutlinedButton.icon(
                                onPressed: _startRecording,
                                icon: const Icon(Icons.mic, color: _accent),
                                label: const Text('Start Recording'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: _accent,
                                  side: const BorderSide(color: _accent),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                ),
                              ),
                      )
                    else
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x1A2E6BFF)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              icon: Icon(
                                _isPlaying
                                    ? Icons.pause_circle_filled
                                    : Icons.play_circle_filled,
                                color: _accent,
                              ),
                              onPressed: _toggleAudioPlayback,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Voice Note (${_formatDuration(_recordDuration)})',
                                style: const TextStyle(
                                  color: Color(0xFF5C6B8C),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.redAccent,
                              ),
                              onPressed: _deleteRecording,
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),
                    const Divider(color: Color(0x1A2E6BFF)),
                    const SizedBox(height: 16),

                    // ATTACHMENT SECTION
                    Text(
                      'File Submission',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _textPrimary,
                      ),
                    ),
                    const SizedBox(height: 12),

                    if (_selectedFile != null)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFF),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0x1A2E6BFF)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.insert_drive_file,
                              color: _accent,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedFile!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Color(0xFF5C6B8C),
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.close,
                                color: Colors.redAccent,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _selectedFile = null;
                                });
                              },
                            ),
                          ],
                        ),
                      ),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _isUploading ? null : _pickFile,
                            icon: const Icon(Icons.attach_file),
                            label: Text(
                              _selectedFile == null
                                  ? 'Attach File'
                                  : 'Change File',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF2E6BFF),
                              side: const BorderSide(color: Color(0xFF2E6BFF)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: (_selectedFile == null || _isUploading)
                                ? null
                                : _submitWork,
                            icon: _isUploading
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.black,
                                    ),
                                  )
                                : const Icon(Icons.send),
                            label: Text(
                              _isUploading ? 'Submitting...' : 'Submit',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _accent,
                              foregroundColor: Colors.white,
                              disabledBackgroundColor: Colors.grey.shade300,
                              disabledForegroundColor: Colors.grey.shade700,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
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
  }
}
