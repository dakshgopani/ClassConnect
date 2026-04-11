import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:demo/screens/student/resources/student_resources_screen.dart';
import 'package:demo/screens/student/pbl/student_pbl_selection_screen.dart';
import 'package:demo/screens/student/student_class_detail_screen.dart';

class StudentActivityScreen extends StatefulWidget {
  const StudentActivityScreen({super.key});

  @override
  State<StudentActivityScreen> createState() => _StudentActivityScreenState();
}

class _StudentActivityScreenState extends State<StudentActivityScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  StreamSubscription<QuerySnapshot>? _classSubscription;
  final Map<String, StreamSubscription<QuerySnapshot>> _postSubscriptions = {};
  final Map<String, StreamSubscription<QuerySnapshot>> _updateSubscriptions =
      {};
  final Map<String, StreamSubscription<QuerySnapshot>>
  _announcementSubscriptions = {};
  final Map<String, StreamSubscription<QuerySnapshot>> _resourceSubscriptions =
      {};
  final Map<String, StreamSubscription<QuerySnapshot>> _pblSubscriptions = {};

  final Map<String, _StudentAlert> _alertMap = {};
  final Map<String, String> _classNames = {};
  final Map<String, int> _miniProjectCountByClass =
      {}; // Track mini project count per class
  final Map<String, String> _assignedPblIdByClass =
      {}; // Latest assigned PBL id per class for routing mini projects

  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _listenToJoinedClasses();
  }

  @override
  void dispose() {
    _classSubscription?.cancel();
    for (final sub in _postSubscriptions.values) {
      sub.cancel();
    }
    for (final sub in _updateSubscriptions.values) {
      sub.cancel();
    }
    for (final sub in _announcementSubscriptions.values) {
      sub.cancel();
    }
    for (final sub in _resourceSubscriptions.values) {
      sub.cancel();
    }
    for (final sub in _pblSubscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  void _listenToJoinedClasses() {
    final user = _auth.currentUser;
    if (user == null) {
      setState(() => _loading = false);
      return;
    }

    _classSubscription = _firestore
        .collection('class_students')
        .where('studentId', isEqualTo: user.uid)
        .snapshots()
        .listen((snapshot) async {
          final classIds = snapshot.docs
              .map((d) => d['classId'] as String)
              .toList();

          // Clean up removed classes
          final currentIds = classIds.toSet();
          final removedPosts = _postSubscriptions.keys
              .where((id) => !currentIds.contains(id))
              .toList();
          for (final id in removedPosts) {
            _postSubscriptions.remove(id)?.cancel();
          }
          final removedUpdates = _updateSubscriptions.keys
              .where((id) => !currentIds.contains(id))
              .toList();
          for (final id in removedUpdates) {
            _updateSubscriptions.remove(id)?.cancel();
          }
          final removedAnnouncements = _announcementSubscriptions.keys
              .where((id) => !currentIds.contains(id))
              .toList();
          for (final id in removedAnnouncements) {
            _announcementSubscriptions.remove(id)?.cancel();
          }

          final removedResources = _resourceSubscriptions.keys
              .where((id) => !currentIds.contains(id))
              .toList();
          for (final id in removedResources) {
            _resourceSubscriptions.remove(id)?.cancel();
          }

          final removedPbl = _pblSubscriptions.keys
              .where((id) => !currentIds.contains(id))
              .toList();
          for (final id in removedPbl) {
            _pblSubscriptions.remove(id)?.cancel();
          }

          // Clear alerts for removed classes
          _alertMap.removeWhere(
            (key, _) => !currentIds.contains(key.split('|').first),
          );

          // Attach listeners for new classes
          for (final classId in currentIds) {
            if (!_classNames.containsKey(classId)) {
              _fetchClassName(classId);
            }
            if (!_postSubscriptions.containsKey(classId)) {
              _postSubscriptions[classId] = _firestore
                  .collection('classes')
                  .doc(classId)
                  .collection('posts')
                  .snapshots()
                  .listen(
                    (s) => _handleSnapshot(classId, 'post', s),
                    onError: (e) => debugPrint('Posts listener error: $e'),
                  );
            }
            if (!_updateSubscriptions.containsKey(classId)) {
              _updateSubscriptions[classId] = _firestore
                  .collection('classes')
                  .doc(classId)
                  .collection('updates')
                  .orderBy('created_at', descending: true)
                  .snapshots()
                  .listen((s) => _handleSnapshot(classId, 'update', s));
            }
            if (!_announcementSubscriptions.containsKey(classId)) {
              _announcementSubscriptions[classId] = _firestore
                  .collection('classes')
                  .doc(classId)
                  .collection('announcements')
                  .orderBy('created_at', descending: true)
                  .snapshots()
                  .listen((s) => _handleSnapshot(classId, 'announcement', s));
            }
            if (!_resourceSubscriptions.containsKey(classId)) {
              _resourceSubscriptions[classId] = _firestore
                  .collection('classes')
                  .doc(classId)
                  .collection('resources')
                  .orderBy('createdAt', descending: true)
                  .snapshots()
                  .listen((s) => _handleSnapshot(classId, 'resource', s));
            }
            if (!_pblSubscriptions.containsKey(classId)) {
              _pblSubscriptions[classId] = _firestore
                  .collection('classes')
                  .doc(classId)
                  .collection('PBL')
                  .snapshots()
                  .listen(
                    (s) => _handleSnapshot(classId, 'pbl', s),
                    onError: (e) => debugPrint('PBL listener error: $e'),
                  );
            }
          }

          setState(() => _loading = false);
          _emitAlerts();
        });
  }

  Future<void> _fetchClassName(String classId) async {
    try {
      final doc = await _firestore.collection('classes').doc(classId).get();
      if (doc.exists) {
        final data = doc.data() ?? {};
        final name = (data['class_name'] ?? data['name'] ?? 'Class') as String;
        setState(() => _classNames[classId] = name);
      }
    } catch (_) {
      // ignore lookup errors
    }
  }

  void _handleSnapshot(String classId, String type, QuerySnapshot snapshot) {
    for (final doc in snapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final timestamp =
          (data['created_at'] ?? data['createdAt'] ?? data['timestamp'])
              as Timestamp?;
      final createdAt = timestamp?.toDate() ?? DateTime.now();

      String title = (data['title'] ?? data['headline'] ?? data['type'] ?? '')
          .toString();
      String message =
          (data['description'] ??
                  data['details'] ??
                  data['content'] ??
                  data['message'] ??
                  '')
              .toString();

      // Allow overriding alert type based on content
      var effectiveType = type;

      if (type == 'resource') {
        final url = (data['url'] ?? '').toString();
        if (title.isEmpty) {
          title = (data['description'] ?? 'New resource').toString();
        }
        if (message.isEmpty) {
          message = url;
        }
      } else if (type == 'post') {
        // Posts typically have description as content
        if (title.isEmpty) {
          title = 'Post';
        }
        if (message.isEmpty) {
          message =
              (data['description'] ?? data['body'] ?? data['content'] ?? '')
                  .toString();
        }

        // Classify certain posts as assignments to keep routing empty
        final subtype = (data['type'] ?? '').toString();
        if (subtype == 'chapter_quiz' ||
            subtype == 'assignment' ||
            subtype == 'homework') {
          effectiveType = 'assignment';
        }

        // Include deadline if present
        final dlRaw = data['deadline'];
        DateTime? deadline;
        if (dlRaw is Timestamp) {
          deadline = dlRaw.toDate();
        } else if (dlRaw is String) {
          deadline = DateTime.tryParse(dlRaw);
        }
        if (deadline != null) {
          final dlText = _formatDate(deadline);
          message = message.isNotEmpty
              ? '$message • Deadline: $dlText'
              : 'Deadline: $dlText';
        }
      } else if (type == 'pbl') {
        final currentUserId = _auth.currentUser?.uid;
        if (currentUserId == null) continue; // Skip if not logged in

        // Check if current student is assigned to this PBL
        bool isAssigned = false;

        // Check studentAssignments array for student with matching uid
        final studentAssignments =
            (data['studentAssignments'] as List?) ?? const [];

        for (final assignment in studentAssignments) {
          if (assignment is Map<String, dynamic>) {
            final students = (assignment['students'] as List?) ?? const [];
            for (final student in students) {
              if (student is Map<String, dynamic>) {
                final studentUid = student['uid'];
                if (studentUid == currentUserId) {
                  isAssigned = true;
                  break;
                }
              }
            }
            if (isAssigned) break;
          }
        }

        // Skip if not assigned
        if (!isAssigned) {
          continue;
        }

        // Track latest assigned PBL id for this class for mini project routing
        _assignedPblIdByClass[classId] = doc.id;

        if (title.isEmpty) {
          title = (data['title'] ?? 'PBL Project').toString();
        }

        if (message.isEmpty) {
          final mp = (data['miniProjects'] as List?) ?? const [];
          final fallback = (data['problemStatement'] ?? data['overview'] ?? '')
              .toString();
          if (mp.isNotEmpty) {
            message =
                '${mp.length} mini project${mp.length == 1 ? '' : 's'} available';
          } else {
            message = fallback;
          }
        }

        // Track mini project count for this class and only alert if there ARE mini projects
        final mp = (data['miniProjects'] as List?) ?? const [];
        if (mp.isNotEmpty) {
          final currentCount = _miniProjectCountByClass[classId] ?? 0;
          if (mp.length > currentCount) {
            _miniProjectCountByClass[classId] = mp.length;
            // Add a mini projects alert for this class (only if mp exist)
            final miniProjectKey = _alertKey(classId, 'miniproject', 'all');
            if (!_alertMap.containsKey(miniProjectKey)) {
              _alertMap[miniProjectKey] = _StudentAlert(
                id: 'all',
                classId: classId,
                type: 'miniproject',
                title: 'Mini Projects Available',
                message:
                    '${mp.length} mini project${mp.length == 1 ? '' : 's'} ready to select',
                createdAt: createdAt,
              );
            }
          }
        }
      }

      if (title.isEmpty) title = 'Update';

      final key = _alertKey(classId, effectiveType, doc.id);
      _alertMap[key] = _StudentAlert(
        id: doc.id,
        classId: classId,
        type: effectiveType,
        title: title,
        message: message,
        createdAt: createdAt,
      );
    }
    _emitAlerts();
  }

  void _emitAlerts() {
    final alerts = _alertMap.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() => _sortedAlerts = alerts);
  }

  List<_StudentAlert> _sortedAlerts = [];

  String _alertKey(String classId, String type, String docId) =>
      '$classId|$type|$docId';

  Color _typeTint(String type) {
    switch (type) {
      case 'announcement':
        return const Color(0xFFFF8B3D);
      case 'resource':
        return const Color(0xFF1FB58E);
      case 'assignment':
        return const Color(0xFF2E6BFF);
      case 'post':
      case 'update':
        return const Color(0xFF00A3FF);
      case 'pbl':
        return const Color(0xFF8B5CF6);
      case 'miniproject':
        return const Color(0xFF14B8A6);
      default:
        return const Color(0xFF2E6BFF);
    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'announcement':
        return Icons.campaign_rounded;
      case 'resource':
        return Icons.folder_special_rounded;
      case 'assignment':
        return Icons.assignment_turned_in_rounded;
      case 'post':
      case 'update':
        return Icons.dynamic_feed_rounded;
      case 'pbl':
        return Icons.lightbulb_rounded;
      case 'miniproject':
        return Icons.extension_rounded;
      default:
        return Icons.notifications_active_rounded;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'announcement':
        return 'Announcement';
      case 'resource':
        return 'Resource';
      case 'assignment':
        return 'Assignment';
      case 'post':
        return 'Post';
      case 'update':
        return 'Post';
      case 'pbl':
        return 'PBL';
      case 'miniproject':
        return 'Mini Projects';
      default:
        return 'Post';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFF7FAFF),
                    Color(0xFFEAF3FF),
                    Color(0xFFFDFEFF),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: _SoftBlob(
              color: const Color(0xFF7CCBFF).withValues(alpha: 0.20),
              size: 220,
            ),
          ),
          Positioned(
            top: 110,
            left: -70,
            child: _SoftBlob(
              color: const Color(0xFF7EE7C4).withValues(alpha: 0.18),
              size: 180,
            ),
          ),
          SafeArea(
            child: _loading
                ? _buildLoadingState()
                : AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    switchInCurve: Curves.easeOutCubic,
                    switchOutCurve: Curves.easeInCubic,
                    child: _sortedAlerts.isEmpty
                        ? _buildEmptyState()
                        : _buildContent(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Container(
        width: 220,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.82),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: const Color(0xFF2E6BFF).withValues(alpha: 0.10),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2E6BFF).withValues(alpha: 0.08),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 36,
              height: 36,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            SizedBox(height: 16),
            Text(
              'Loading your class activity',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Color(0xFF0D1B3D),
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 6),
            Text(
              'Pulling the latest updates from your classes.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Color(0xFF5C6B8C), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: const Color(0xFF2E6BFF).withValues(alpha: 0.08),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF2E6BFF).withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2E6BFF), Color(0xFF00D9FF)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Icon(
                  Icons.auto_graph_rounded,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'No activity yet',
                style: TextStyle(
                  color: Color(0xFF0D1B3D),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'When your teachers post updates, resources, or assignments, they will appear here in real time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Color(0xFF5C6B8C), height: 1.45),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      key: const ValueKey('activity-content'),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
      children: [
        _buildStatsRow(),
        const SizedBox(height: 20),
        Row(
          children: [
            const Expanded(
              child: Text(
                'Latest Activity',
                style: TextStyle(
                  color: Color(0xFF0D1B3D),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${_sortedAlerts.length} items',
              style: const TextStyle(color: Color(0xFF5C6B8C), fontSize: 12),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...List.generate(
          _sortedAlerts.length,
          (index) => _buildAlertCard(_sortedAlerts[index], index),
        ),
      ],
    );
  }

  Widget _buildStatsRow() {
    final totalClasses = _classNames.length;
    final announcements = _sortedAlerts
        .where((item) => item.type == 'announcement')
        .length;
    final resources = _sortedAlerts
        .where((item) => item.type == 'resource')
        .length;
    final projects = _sortedAlerts
        .where((item) => item.type == 'pbl' || item.type == 'miniproject')
        .length;

    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            'Classes',
            totalClasses.toString(),
            Icons.class_rounded,
            const Color(0xFF2E6BFF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            'Alerts',
            _sortedAlerts.length.toString(),
            Icons.notifications_active_rounded,
            const Color(0xFF00A693),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            'Updates',
            (announcements + resources + projects).toString(),
            Icons.auto_awesome_rounded,
            const Color(0xFFFF8B3D),
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile(String label, String value, IconData icon, Color tint) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tint.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: tint.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: tint, size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0D1B3D),
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Color(0xFF5C6B8C), fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertCard(_StudentAlert alert, int index) {
    final className = _classNames[alert.classId] ?? 'Class';
    final tint = _typeTint(alert.type);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 300 + (index * 70)),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _navigateToAlert(context, alert, className),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: tint.withValues(alpha: 0.12)),
                boxShadow: [
                  BoxShadow(
                    color: tint.withValues(alpha: 0.10),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [tint, tint.withValues(alpha: 0.70)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(
                          _typeIcon(alert.type),
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: tint.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    _typeLabel(alert.type),
                                    style: TextStyle(
                                      color: tint,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  _formatTimeAgo(alert.createdAt),
                                  style: const TextStyle(
                                    color: Color(0xFF7B88A6),
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Text(
                              alert.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Color(0xFF0D1B3D),
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                height: 1.2,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              className,
                              style: const TextStyle(
                                color: Color(0xFF49607D),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  if (alert.message.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      alert.message,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Color(0xFF51637F),
                        height: 1.45,
                      ),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        'Open details',
                        style: TextStyle(
                          color: tint,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      Icon(Icons.arrow_forward_rounded, color: tint, size: 18),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAlert(
    BuildContext context,
    _StudentAlert alert,
    String className,
  ) async {
    debugPrint(
      'DEBUG: Navigating to alert type: ${alert.type}, id: ${alert.id}',
    );

    switch (alert.type) {
      case 'resource':
        debugPrint('DEBUG: Navigating to Resources');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => StudentResourcesScreen(
              classId: alert.classId,
              className: className,
            ),
          ),
        );
        break;
      case 'assignment':
        // Keep assignment routing empty for now
        debugPrint('DEBUG: Assignment routing kept empty');
        return;
      case 'post':
        debugPrint('DEBUG: Navigating to Class Detail (Post)');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StudentClassDetailScreen(classId: alert.classId),
          ),
        );
        break;
      case 'pbl':
        debugPrint('DEBUG: Navigating to PBL Selection');
        // Fetch full PBL data before navigating
        try {
          final pblDoc = await _firestore
              .collection('classes')
              .doc(alert.classId)
              .collection('PBL')
              .doc(alert.id)
              .get();

          if (!pblDoc.exists) {
            if (context.mounted) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('PBL not found')));
            }
            return;
          }

          final pblData = pblDoc.data()!;
          final miniProjects =
              (pblData['miniProjects'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [];

          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentPblSelectionScreen(
                  classId: alert.classId,
                  pblId: alert.id,
                  title: pblData['title'] ?? 'PBL Project',
                  problemStatement: pblData['problemStatement'] ?? '',
                  miniProjects: miniProjects,
                ),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text('Error loading PBL: $e')));
          }
        }
        break;
      case 'miniproject':
        debugPrint(
          'DEBUG: Navigating to Mini Projects (Assigned PBL Selection)',
        );
        final assignedPblId = _assignedPblIdByClass[alert.classId];
        if (assignedPblId == null) {
          debugPrint(
            'DEBUG: No assigned PBL id found for class ${alert.classId}',
          );
          return;
        }
        try {
          final pblDoc = await _firestore
              .collection('classes')
              .doc(alert.classId)
              .collection('PBL')
              .doc(assignedPblId)
              .get();
          if (!pblDoc.exists) return;
          final pblData = pblDoc.data()!;
          final miniProjects =
              (pblData['miniProjects'] as List<dynamic>?)
                  ?.map((e) => e as Map<String, dynamic>)
                  .toList() ??
              [];
          if (context.mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => StudentPblSelectionScreen(
                  classId: alert.classId,
                  pblId: assignedPblId,
                  title: pblData['title'] ?? 'PBL Project',
                  problemStatement: pblData['problemStatement'] ?? '',
                  miniProjects: miniProjects,
                ),
              ),
            );
          }
        } catch (_) {
          // swallow navigation errors
        }
        break;
      case 'announcement':
      case 'update':
      default:
        debugPrint('DEBUG: Navigating to Class Detail (default)');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                StudentClassDetailScreen(classId: alert.classId),
          ),
        );
        break;
    }
  }

  String _formatTimeAgo(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  String _formatDate(DateTime dt) {
    // Simple date format: Jan 31, 2026 12:00 AM
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final m = months[dt.month - 1];
    final day = dt.day.toString().padLeft(2, '0');
    final year = dt.year;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$m $day, $year $hour:$minute $ampm';
  }
}

class _SoftBlob extends StatelessWidget {
  const _SoftBlob({required this.color, required this.size});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return AnimatedScale(
      scale: 1,
      duration: const Duration(milliseconds: 900),
      curve: Curves.easeOut,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(shape: BoxShape.circle, color: color),
      ),
    );
  }
}

class _StudentAlert {
  final String id;
  final String classId;
  final String type; // 'update' or 'announcement'
  final String title;
  final String message;
  final DateTime createdAt;

  _StudentAlert({
    required this.id,
    required this.classId,
    required this.type,
    required this.title,
    required this.message,
    required this.createdAt,
  });
}
