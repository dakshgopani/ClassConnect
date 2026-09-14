import 'dart:async';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo/models/wellbeing_data.dart';
import 'package:demo/services/wellbeing_service.dart';
import 'package:demo/services/wellbeing_recommendation_service.dart';
import 'package:demo/widgets/ui/cc_loading_animation.dart';
import 'package:demo/utils/responsive_breakpoints.dart';
import 'teacher_class_detail_screen.dart';
import 'create_class_screen.dart';

typedef TeacherDashboardPage = TeacherDashboardScreen;

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WellbeingService _wellbeingService = WellbeingService();
  Timer? _refreshTimer;

  bool _isLoading = true;

  // Dashboard Data
  List<Map<String, dynamic>> students = [];
  late List<Map<String, dynamic>> _filteredStudents;
  List<Map<String, String>> _teacherClasses = [];
  String _selectedClassId = 'all';

  int _totalClasses = 0;
  int _totalPBLs = 0;
  double _avgQuizScore = 0.0;
  double _avgCommunityScore = 0.0;
  double _avgPBLScore = 0.0;

  List<Map<String, dynamic>> _weakConcepts = [];

  // Wellbeing Data
  List<StudentWellbeing> _wellbeingData = [];
  List<StudentWellbeing> _atRiskStudents = [];

  // Expanded card tracking
  final Set<String> _expandedCards = {};

  // Cached recommendations per student
  final Map<String, List<WellbeingRecommendation>> _recommendations = {};
  final Set<String> _loadingRecommendations = {};

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _filteredStudents = [];
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboardData();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _searchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final teacherId = FirebaseAuth.instance.currentUser?.uid;
      if (teacherId == null) return;

      await Future.wait([
        _fetchClassesData(teacherId),
        _fetchStudentsData(teacherId),
        _fetchWeakConcepts(teacherId),
      ]);

      // Compute wellbeing after student data is loaded
      _wellbeingData = await _wellbeingService.computeAllStudentWellbeing(
        teacherId: teacherId,
      );
      _atRiskStudents = _wellbeingData.where((w) => w.isAtRisk).toList();
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _fetchClassesData(String teacherId) async {
    final classesSnapshot = await _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    _totalClasses = classesSnapshot.docs.length;
    _teacherClasses = classesSnapshot.docs
        .map(
          (d) => {
            'id': d.id,
            'name':
                (d.data()['class_name'] as String?)?.trim().isNotEmpty == true
                    ? d.data()['class_name'] as String
                    : 'Class ${d.id.substring(0, 6)}',
          },
        )
        .toList();
    _totalPBLs = 0;

    for (var classDoc in classesSnapshot.docs) {
      final pblSnapshot = await classDoc.reference.collection('pbl').get();
      _totalPBLs += pblSnapshot.docs.length;
    }
  }

  Future<void> _fetchStudentsData(String teacherId) async {
    final classesSnapshot = await _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    final classIds = classesSnapshot.docs.map((d) => d.id).toList();
    final classNamesById = {
      for (final c in classesSnapshot.docs)
        c.id: (c.data()['class_name'] as String?) ?? 'Untitled Class',
    };

    final Map<String, Set<String>> studentClassIds = {};
    for (final classId in classIds) {
      final classStudentsSnapshot = await _firestore
          .collection('class_students')
          .where('classId', isEqualTo: classId)
          .get();

      for (final doc in classStudentsSnapshot.docs) {
        final sid = doc['studentId'] as String;
        studentClassIds.putIfAbsent(sid, () => <String>{});
        studentClassIds[sid]!.add(classId);
      }
    }

    final studentIds = studentClassIds.keys.toSet();

    List<Map<String, dynamic>> loadedStudents = [];
    double totalQuiz = 0;
    double totalCommunity = 0;
    double totalPBL = 0;

    for (final studentId in studentIds) {
      final studentDoc = await _firestore
          .collection('students')
          .doc(studentId)
          .get();
      if (!studentDoc.exists) continue;

      final studentData = studentDoc.data()!;

      // Quiz performance
      final quizSnapshot = await _firestore
          .collection('quiz_attempts')
          .where('studentId', isEqualTo: studentId)
          .get();

      double avgQuizScore = 0;
      if (quizSnapshot.docs.isNotEmpty) {
        final scores = quizSnapshot.docs
            .where((q) {
              final data = q.data() as Map<String, dynamic>?;
              if (data == null) return false;
              final score = data['score'] as num?;
              final total = data['total'] as num?;
              return score != null && total != null && total != 0;
            })
            .map((q) {
              final data = q.data() as Map<String, dynamic>;
              return ((data['score'] as num) / (data['total'] as num)) * 100;
            })
            .toList();

        if (scores.isNotEmpty) {
          avgQuizScore = scores.reduce((a, b) => a + b) / scores.length;
        }
      }

      // Leaderboard data
      double communityScore = 0;
      double pblScore = 0;
      double xp = 0;

      for (final classDoc in classesSnapshot.docs) {
        final lbSnap = await _firestore
            .collection('class_leaderboard')
            .doc(classDoc.id)
            .collection('students')
            .doc(studentId)
            .get();
        if (lbSnap.exists) {
          final lbData = lbSnap.data()!;
          communityScore +=
              (lbData['community_score'] as num?)?.toDouble() ?? 0;
          pblScore += (lbData['pbl_score'] as num?)?.toDouble() ?? 0;
          xp += (lbData['xp'] as num?)?.toDouble() ?? 0;
        }
      }

      // Attendance
      double attendancePercentage = 0.0;
      final attendanceSnapshot = await _firestore
          .collection('attendance')
          .where('teacherId', isEqualTo: teacherId)
          .get();

      int presentCount = 0;
      int totalCount = 0;

      for (final att in attendanceSnapshot.docs) {
        final presentIds = att['presentStudentIds'] as List<dynamic>? ?? [];
        final absentIds = att['absentStudentIds'] as List<dynamic>? ?? [];

        if (presentIds.contains(studentId) || absentIds.contains(studentId)) {
          totalCount++;
          if (presentIds.contains(studentId)) presentCount++;
        }
      }

      if (totalCount > 0) {
        attendancePercentage = (presentCount / totalCount) * 100;
      }

      totalQuiz += avgQuizScore;
      totalCommunity += communityScore;
      totalPBL += pblScore;

      loadedStudents.add({
        'id': studentId,
        'name': studentData['name'] ?? 'Unknown',
        'email': studentData['email'] ?? '',
        'classIds': studentClassIds[studentId]?.toList() ?? <String>[],
        'classNames': (studentClassIds[studentId] ?? <String>{})
            .map((id) => classNamesById[id] ?? 'Unknown Class')
            .toList(),
        'quiz_score': avgQuizScore,
        'attendance': attendancePercentage,
        'xp': xp,
        'community_score': communityScore,
        'pbl_score': pblScore,
      });
    }

    if (loadedStudents.isNotEmpty) {
      _avgQuizScore = totalQuiz / loadedStudents.length;
      _avgCommunityScore = totalCommunity / loadedStudents.length;
      _avgPBLScore = totalPBL / loadedStudents.length;
    }

    if (mounted) {
      setState(() {
        students = loadedStudents;
      });
      _applyFilters();
    }
  }

  Future<void> _fetchWeakConcepts(String teacherId) async {
    final classesSnapshot = await _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: teacherId)
        .get();

    final classIds = classesSnapshot.docs.map((d) => d.id).toList();
    Set<String> studentIds = {};

    for (final classId in classIds) {
      final classStudents = await _firestore
          .collection('class_students')
          .where('classId', isEqualTo: classId)
          .get();

      for (final doc in classStudents.docs) {
        studentIds.add(doc['studentId']);
      }
    }

    Map<String, int> conceptFrequency = {};

    for (final studentId in studentIds) {
      final quizAttempts = await _firestore
          .collection('quiz_attempts')
          .where('studentId', isEqualTo: studentId)
          .get();

      for (var doc in quizAttempts.docs) {
        final weakConcepts = doc.data()['weakConcepts'] as List<dynamic>?;
        if (weakConcepts != null) {
          for (var concept in weakConcepts) {
            conceptFrequency[concept.toString()] =
                (conceptFrequency[concept.toString()] ?? 0) + 1;
          }
        }
      }
    }

    _weakConcepts =
        conceptFrequency.entries
            .map((e) => {'concept': e.key, 'count': e.value})
            .toList()
          ..sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

    _weakConcepts = _weakConcepts.take(8).toList();
  }

  void _applyFilters() {
    final query = _searchController.text.trim().toLowerCase();
    final selectedClassId = _selectedClassId;

    final filtered = students.where((student) {
      final classIds =
          (student['classIds'] as List<dynamic>? ?? const <dynamic>[])
              .map((e) => e.toString())
              .toList();

      final matchesClass =
          selectedClassId == 'all' || classIds.contains(selectedClassId);
      if (!matchesClass) return false;

      if (query.isEmpty) return true;

      final name = (student['name'] as String? ?? '').toLowerCase();
      final email = (student['email'] as String? ?? '').toLowerCase();
      return name.contains(query) || email.contains(query);
    }).toList();

    if (!mounted) return;
    setState(() {
      _filteredStudents = filtered;
    });
  }

  void _filterStudents(String _) => _applyFilters();

  void _onClassFilterChanged(String? classId) {
    if (classId == null) return;
    setState(() => _selectedClassId = classId);
    _applyFilters();
  }

  List<StudentWellbeing> _visibleWellbeing() {
    if (_selectedClassId == 'all') return _wellbeingData;
    final visibleIds = _filteredStudents.map((s) => s['id'] as String).toSet();
    return _wellbeingData
        .where((w) => visibleIds.contains(w.studentId))
        .toList();
  }

  List<Map<String, dynamic>> _getTopPerformers() {
    List<Map<String, dynamic>> ranked = List.from(_filteredStudents);
    ranked.sort((a, b) => (b['xp'] as double).compareTo(a['xp'] as double));
    return ranked.take(3).toList();
  }

  double _calculateAverage(String key) {
    if (_filteredStudents.isEmpty) return 0;
    double sum = 0;
    for (var student in _filteredStudents) {
      sum += student[key] as double;
    }
    return sum / _filteredStudents.length;
  }

  Future<void> _loadRecommendations(StudentWellbeing wb) async {
    if (_recommendations.containsKey(wb.studentId)) return;

    setState(() => _loadingRecommendations.add(wb.studentId));

    List<String> weakConcepts = [];
    final quizSnap = await _firestore
        .collection('quiz_attempts')
        .where('studentId', isEqualTo: wb.studentId)
        .get();
    for (var doc in quizSnap.docs) {
      final wc = doc.data()['weakConcepts'] as List<dynamic>?;
      if (wc != null) {
        for (var c in wc) {
          if (!weakConcepts.contains(c.toString())) {
            weakConcepts.add(c.toString());
          }
        }
      }
    }

    final recs = await WellbeingRecommendationService.getRecommendations(
      wellbeing: wb,
      weakConcepts: weakConcepts.take(5).toList(),
    );

    if (mounted) {
      setState(() {
        _recommendations[wb.studentId] = recs;
        _loadingRecommendations.remove(wb.studentId);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        color: const Color(0xFFF8FAFC),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CcLoadingAnimation(color: Color(0xFF2E6BFF)),
              SizedBox(height: 16),
              Text(
                'Loading dashboard analytics...',
                style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
              ),
            ],
          ),
        ),
      );
    }

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: canPop
          ? AppBar(
              backgroundColor: Colors.white,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1E293B)),
                onPressed: () => Navigator.pop(context),
                tooltip: 'Back',
              ),
              title: const Text(
                'Teacher Dashboard',
                style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700),
              ),
            )
          : null,
      body: isDesktop ? _buildDesktopLayout() : _buildMobileLayout(),
    );
  }

  // ==========================================
  // DESKTOP LAYOUT (Rich Web Feel, No Mobile Stretch)
  // ==========================================

  Widget _buildDesktopLayout() {
    final user = FirebaseAuth.instance.currentUser;
    final avgAttendance = _calculateAverage('attendance');

    return RefreshIndicator(
      color: const Color(0xFF2E6BFF),
      onRefresh: _loadDashboardData,
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDesktopHeader(user?.displayName ?? 'Teacher'),
                const SizedBox(height: 24),
                _buildQuickStatsGrid(isDesktop: true),
                const SizedBox(height: 20),

                if (_atRiskStudents.isNotEmpty) ...[
                  _buildAlertBanner(),
                  const SizedBox(height: 20),
                ],

                // Tabs
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TabBar(
                    controller: _tabController,
                    indicatorColor: const Color(0xFF2E6BFF),
                    indicatorSize: TabBarIndicatorSize.tab,
                    labelColor: const Color(0xFF2E6BFF),
                    unselectedLabelColor: const Color(0xFF64748B),
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                    dividerColor: Colors.transparent,
                    onTap: (_) => setState(() {}),
                    tabs: [
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.analytics_rounded, size: 18),
                            const SizedBox(width: 8),
                            const Text('Overview & Charts'),
                          ],
                        ),
                      ),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.health_and_safety_rounded, size: 18),
                            const SizedBox(width: 8),
                            const Text('Student Wellbeing'),
                            if (_atRiskStudents.isNotEmpty) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF4757),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_atRiskStudents.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Active Tab Content
                _tabController.index == 0
                    ? _buildDesktopOverviewContent(avgAttendance)
                    : _buildDesktopWellbeingContent(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDesktopHeader(String teacherName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2E6BFF), Color(0xFF5B8CFF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.dashboard_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Welcome back, ',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    Text(
                      '$teacherName!',
                      style: const TextStyle(
                        color: Color(0xFF1E293B),
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Comprehensive academic performance, real-time metrics & student wellbeing.',
                  style: TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 240,
            child: _buildClassFilter(),
          ),
          const SizedBox(width: 12),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFF2E6BFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2E6BFF)),
              onPressed: _loadDashboardData,
              tooltip: 'Refresh Data',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDesktopOverviewContent(double avgAttendance) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 3 Key Averages
        _buildStatsRow(isDesktop: true),
        const SizedBox(height: 28),

        // 2-Column: Performance Chart (Left) + Attendance Ring (Right)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Performance Overview'),
                  _buildGlassCard(
                    height: 290,
                    child: _performanceChart(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Class Attendance Rate'),
                  _buildGlassCard(
                    height: 290,
                    child: _attendanceWidget(avgAttendance),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 28),

        // 2-Column: Weak Concepts (Left) + Top Performers (Right)
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Weak Concepts Requiring Review'),
                  _weakConcepts.isEmpty
                      ? _buildGlassCard(
                          height: 180,
                          child: const Center(
                            child: Text(
                              'No weak concepts detected. All quizzes performing well!',
                              style: TextStyle(color: Color(0xFF64748B)),
                            ),
                          ),
                        )
                      : Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: const Color(0xFFE2E8F0)),
                          ),
                          child: _buildWeakConceptsSection(),
                        ),
                ],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sectionTitle('Top Performers'),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: _buildTopPerformersSection(),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),

        // Full Width: All Students Table
        _sectionTitle('All Students Roster & Score Distribution'),
        _buildSearchBar(),
        const SizedBox(height: 14),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: _buildStudentsTable(),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  Widget _buildDesktopWellbeingContent() {
    final visibleWellbeing = _visibleWellbeing();
    final visibleAtRisk = visibleWellbeing.where((w) => w.isAtRisk).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildWellbeingSummary(isDesktop: true),
        const SizedBox(height: 28),

        // Wellbeing Trend Chart
        _sectionTitle('Class Wellbeing Trend Analysis'),
        _buildGlassCard(
          height: 280,
          child: _buildWellbeingTrendChart(),
        ),
        const SizedBox(height: 28),

        // At-Risk Students Section
        if (visibleAtRisk.isNotEmpty) ...[
          _sectionTitle('At-Risk Students (${visibleAtRisk.length})'),
          ...visibleAtRisk.map(_buildAtRiskCard),
          const SizedBox(height: 28),
        ],

        // All Student Wellbeing Scores
        _sectionTitle('All Student Wellbeing Scores'),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: _buildAllWellbeingList(),
        ),
        const SizedBox(height: 48),
      ],
    );
  }

  // ==========================================
  // MOBILE LAYOUT (Stacked, Responsive)
  // ==========================================

  Widget _buildMobileLayout() {
    final user = FirebaseAuth.instance.currentUser;
    final avgAttendance = _calculateAverage('attendance');

    return RefreshIndicator(
      color: const Color(0xFF2E6BFF),
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMobileHeader(user?.displayName ?? 'Teacher'),
          const SizedBox(height: 16),
          _buildQuickStatsGrid(isDesktop: false),
          const SizedBox(height: 16),

          if (_atRiskStudents.isNotEmpty) ...[
            _buildAlertBanner(),
            const SizedBox(height: 16),
          ],

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0x1A2E6BFF)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: const Color(0xFF2E6BFF),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: const Color(0xFF2E6BFF),
              unselectedLabelColor: const Color(0xFF5C6B8C),
              labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              dividerColor: Colors.transparent,
              onTap: (_) => setState(() {}),
              tabs: [
                const Tab(text: 'Overview'),
                Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Wellbeing'),
                      if (_atRiskStudents.isNotEmpty) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF4757),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            '${_atRiskStudents.length}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          _tabController.index == 0
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildStatsRow(isDesktop: false),
                    const SizedBox(height: 20),
                    _sectionTitle('Performance Overview'),
                    _buildGlassCard(child: _performanceChart()),
                    const SizedBox(height: 20),
                    _sectionTitle('Attendance'),
                    _buildGlassCard(child: _attendanceWidget(avgAttendance)),
                    const SizedBox(height: 20),
                    if (_weakConcepts.isNotEmpty) ...[
                      _sectionTitle('Weak Concepts'),
                      _buildWeakConceptsSection(),
                      const SizedBox(height: 20),
                    ],
                    _sectionTitle('Top Performers'),
                    _buildTopPerformersSection(),
                    const SizedBox(height: 20),
                    _sectionTitle('All Students'),
                    _buildSearchBar(),
                    const SizedBox(height: 12),
                    _buildStudentsTable(),
                    const SizedBox(height: 32),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWellbeingSummary(isDesktop: false),
                    const SizedBox(height: 20),
                    _sectionTitle('Class Wellbeing Trend'),
                    _buildGlassCard(child: _buildWellbeingTrendChart()),
                    const SizedBox(height: 20),
                    if (_atRiskStudents.isNotEmpty) ...[
                      _sectionTitle('At-Risk Students (${_atRiskStudents.length})'),
                      ..._atRiskStudents.map(_buildAtRiskCard),
                      const SizedBox(height: 20),
                    ],
                    _sectionTitle('All Student Wellbeing'),
                    _buildAllWellbeingList(),
                    const SizedBox(height: 32),
                  ],
                ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(String teacherName) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF5C6B8C).withValues(alpha: 0.8),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    teacherName,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0D1B3D),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFF2E6BFF).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: IconButton(
                icon: const Icon(Icons.refresh_rounded, color: Color(0xFF2E6BFF)),
                onPressed: _loadDashboardData,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildClassFilter(),
      ],
    );
  }

  // ==========================================
  // REUSABLE CHARTS & CARDS (Exact match to mobile)
  // ==========================================

  Widget _buildClassFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: _selectedClassId,
          isExpanded: true,
          dropdownColor: Colors.white,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Color(0xFF2E6BFF)),
          style: const TextStyle(color: Color(0xFF1E293B), fontSize: 13, fontWeight: FontWeight.w500),
          items: [
            const DropdownMenuItem<String>(
              value: 'all',
              child: Text('All Classes'),
            ),
            ..._teacherClasses.map(
              (c) => DropdownMenuItem<String>(
                value: c['id']!,
                child: Text(c['name']!),
              ),
            ),
          ],
          onChanged: _onClassFilterChanged,
        ),
      ),
    );
  }

  Widget _buildQuickStatsGrid({required bool isDesktop}) {
    final visibleAtRisk = _visibleWellbeing().where((w) => w.isAtRisk).length;

    final cards = [
      _quickStatCard(
        'Classes',
        (_selectedClassId == 'all' ? _totalClasses : 1).toString(),
        Icons.class_rounded,
        const Color(0xFF2E6BFF),
      ),
      _quickStatCard(
        'Students',
        _filteredStudents.length.toString(),
        Icons.people_rounded,
        const Color(0xFF10B981),
      ),
      _quickStatCard(
        'Avg Score',
        '${_calculateAverage('quiz_score').toStringAsFixed(0)}%',
        Icons.trending_up_rounded,
        const Color(0xFFFF9F43),
      ),
      _quickStatCard(
        'At Risk',
        visibleAtRisk.toString(),
        Icons.warning_amber_rounded,
        visibleAtRisk == 0 ? const Color(0xFF10B981) : const Color(0xFFFF4757),
      ),
    ];

    if (!isDesktop) {
      return Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 5, bottom: 10),
                  child: cards[0],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5, bottom: 10),
                  child: cards[1],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 5),
                  child: cards[2],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 5),
                  child: cards[3],
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Row(
      children: cards.map((c) => Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: c,
      ))).toList(),
    );
  }

  Widget _quickStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
            ],
          ),
          const SizedBox(height: 10),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBanner() {
    final highRisk = _atRiskStudents.where((w) => w.riskLevel == RiskLevel.high).length;
    final medRisk = _atRiskStudents.where((w) => w.riskLevel == RiskLevel.medium).length;

    return GestureDetector(
      onTap: () {
        _tabController.animateTo(1);
        setState(() {});
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF4757).withValues(alpha: 0.12),
              const Color(0xFFFF6B81).withValues(alpha: 0.05),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFF4757).withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4757).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.health_and_safety_rounded, color: Color(0xFFFF4757), size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Wellbeing Alert',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFFFF4757)),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${highRisk > 0 ? '$highRisk high risk' : ''}${highRisk > 0 && medRisk > 0 ? ', ' : ''}${medRisk > 0 ? '$medRisk medium risk' : ''} student${_atRiskStudents.length > 1 ? 's' : ''} require attention. Click to review actionable interventions.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Color(0xFFFF4757)),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow({required bool isDesktop}) {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Quiz Average',
            value: '${_avgQuizScore.toStringAsFixed(1)}%',
            color: const Color(0xFFFF6B6B),
            icon: Icons.quiz_rounded,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statCard(
            title: 'Class Attendance',
            value: '${_calculateAverage('attendance').toStringAsFixed(0)}%',
            color: const Color(0xFF10B981),
            icon: Icons.how_to_reg_rounded,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _statCard(
            title: 'PBL Score Avg',
            value: _avgPBLScore.toStringAsFixed(1),
            color: const Color(0xFFFFD93D),
            icon: Icons.engineering_rounded,
          ),
        ),
      ],
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color.withValues(alpha: 0.9),
            color.withValues(alpha: 0.65),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.white70),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white),
          ),
        ],
      ),
    );
  }

  // --- Exact FL Chart Performance Chart ---
  Widget _performanceChart() {
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 25,
          getDrawingHorizontalLine: (value) => FlLine(
            color: const Color(0xFFE2E8F0),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['Quiz', 'Community', 'PBL'];
                if (value.toInt() < titles.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      titles[value.toInt()],
                      style: const TextStyle(
                        color: Color(0xFF64748B),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        barGroups: [
          _buildBarGroup(0, _avgQuizScore, const Color(0xFFFF6B6B)),
          _buildBarGroup(1, _avgCommunityScore, const Color(0xFF4ECDC4)),
          _buildBarGroup(2, _avgPBLScore, const Color(0xFFFFD93D)),
        ],
      ),
    );
  }

  BarChartGroupData _buildBarGroup(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y.clamp(0.0, 100.0),
          color: color,
          width: 38,
          borderRadius: BorderRadius.circular(8),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: const Color(0xFFF1F5F9),
          ),
        ),
      ],
    );
  }

  // --- Exact Attendance Widget ---
  Widget _attendanceWidget(double value) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: CircularProgressIndicator(
              value: (value / 100).clamp(0.0, 1.0),
              strokeWidth: 12,
              color: const Color(0xFF10B981),
              backgroundColor: const Color(0xFFE2E8F0),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${value.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Present',
                style: TextStyle(fontSize: 12, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- Exact Wellbeing Trend Chart ---
  Widget _buildWellbeingTrendChart() {
    final visibleWellbeing = _visibleWellbeing();

    if (visibleWellbeing.isEmpty) {
      return const Center(
        child: Text(
          'No wellbeing data recorded yet',
          style: TextStyle(color: Color(0xFF64748B)),
        ),
      );
    }

    List<double>? longestTrend;
    for (final wb in visibleWellbeing) {
      if (wb.trendScores.length > (longestTrend?.length ?? 0)) {
        longestTrend = wb.trendScores;
      }
    }

    if (longestTrend == null || longestTrend.isEmpty) {
      longestTrend = visibleWellbeing.map((w) => w.wellbeingScore).toList();
    }

    final spots = List.generate(
      longestTrend.length,
      (i) => FlSpot(i.toDouble(), longestTrend![i]),
    );

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 20,
          getDrawingHorizontalLine: (value) =>
              const FlLine(color: Color(0xFFE2E8F0), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 2 == 0) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Day ${value.toInt() + 1}',
                      style: const TextStyle(color: Color(0xFF64748B), fontSize: 11),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: 25,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 10),
              ),
            ),
          ),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: const Color(0xFF2E6BFF),
            barWidth: 3,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4,
                    color: const Color(0xFF2E6BFF),
                    strokeWidth: 2,
                    strokeColor: Colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF2E6BFF).withValues(alpha: 0.25),
                  const Color(0xFF2E6BFF).withValues(alpha: 0.02),
                ],
              ),
            ),
          ),
          // Risk threshold line (40)
          LineChartBarData(
            spots: List.generate(spots.length, (i) => FlSpot(i.toDouble(), 40)),
            isCurved: false,
            color: const Color(0xFFFF4757).withValues(alpha: 0.5),
            barWidth: 1.5,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
        ],
      ),
    );
  }

  Widget _buildWellbeingSummary({required bool isDesktop}) {
    final visibleWellbeing = _visibleWellbeing();
    final avgScore = visibleWellbeing.isEmpty
        ? 0.0
        : visibleWellbeing.fold<double>(0, (s, w) => s + w.wellbeingScore) /
            visibleWellbeing.length;
    final highRisk = visibleWellbeing.where((w) => w.riskLevel == RiskLevel.high).length;
    final medRisk = visibleWellbeing.where((w) => w.riskLevel == RiskLevel.medium).length;
    final lowRisk = visibleWellbeing.where((w) => w.riskLevel == RiskLevel.low).length;

    final cards = [
      _wellbeingSummaryCard(
        'Average Score',
        avgScore.toStringAsFixed(0),
        _riskColor(
          avgScore >= 70
              ? RiskLevel.low
              : avgScore >= 40
                  ? RiskLevel.medium
                  : RiskLevel.high,
        ),
        Icons.favorite_rounded,
      ),
      _wellbeingSummaryCard(
        'Low Risk',
        lowRisk.toString(),
        const Color(0xFF10B981),
        Icons.check_circle_rounded,
      ),
      _wellbeingSummaryCard(
        'Medium Risk',
        medRisk.toString(),
        const Color(0xFFFFD93D),
        Icons.warning_rounded,
      ),
      _wellbeingSummaryCard(
        'High Risk',
        highRisk.toString(),
        const Color(0xFFFF4757),
        Icons.error_rounded,
      ),
    ];

    return Row(
      children: cards.map((c) => Expanded(child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: c,
      ))).toList(),
    );
  }

  Widget _wellbeingSummaryCard(String label, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), fontWeight: FontWeight.w500),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWeakConceptsSection() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _weakConcepts.map((concept) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFF6B6B).withValues(alpha: 0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                concept['concept'],
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${concept['count']} students struggling',
                style: const TextStyle(fontSize: 11, color: Color(0xFFFF6B6B), fontWeight: FontWeight.w500),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTopPerformersSection() {
    final topThree = _getTopPerformers();
    if (topThree.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Text('No student data recorded', style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }

    const medals = ['🥇', '🥈', '🥉'];
    const colors = [Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFFCD7F32)];

    return Column(
      children: List.generate(topThree.length, (index) {
        final student = topThree[index];
        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: colors[index].withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors[index].withValues(alpha: 0.4), width: 1.5),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Text(medals[index], style: const TextStyle(fontSize: 22)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      student['name'] as String,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                    ),
                    Text(
                      'XP: ${(student['xp'] as double).toInt()} • Quiz: ${(student['quiz_score'] as double).toInt()}%',
                      style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: _searchController,
        onChanged: _filterStudents,
        style: const TextStyle(color: Color(0xFF1E293B)),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Color(0xFF64748B)),
          hintText: 'Search student by name or email...',
          hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
          border: InputBorder.none,
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF64748B)),
                  onPressed: () {
                    _searchController.clear();
                    _filterStudents('');
                  },
                )
              : null,
        ),
      ),
    );
  }

  Widget _buildStudentsTable() {
    if (_filteredStudents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text('No student records found matching filter.', style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF8FAFC)),
        dataRowMinHeight: 48,
        dataRowMaxHeight: 56,
        columns: const [
          DataColumn(label: Text('Student Name', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Quiz Avg', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Attendance', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700))),
          DataColumn(label: Text('PBL Score', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Total XP', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700))),
          DataColumn(label: Text('Wellbeing Index', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.w700))),
        ],
        rows: _filteredStudents.map((student) {
          final wb = _wellbeingData.where((w) => w.studentId == student['id']);
          final wbScore = wb.isNotEmpty ? wb.first.wellbeingScore : -1.0;
          final wbRisk = wb.isNotEmpty ? wb.first.riskLevel : RiskLevel.low;
          final wbColor = wbScore < 0 ? const Color(0xFF64748B) : _riskColor(wbRisk);

          return DataRow(
            cells: [
              DataCell(
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(student['name'] as String, style: const TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                    if ((student['email'] as String).isNotEmpty)
                      Text(student['email'] as String, style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              DataCell(
                Text('${(student['quiz_score'] as double).toInt()}%', style: const TextStyle(color: Color(0xFFFF6B6B), fontWeight: FontWeight.w600)),
              ),
              DataCell(
                Text('${(student['attendance'] as double).toInt()}%', style: const TextStyle(color: Color(0xFF10B981), fontWeight: FontWeight.w600)),
              ),
              DataCell(
                Text('${(student['pbl_score'] as double).toInt()}', style: const TextStyle(color: Color(0xFFFFD93D), fontWeight: FontWeight.w600)),
              ),
              DataCell(
                Text('${(student['xp'] as double).toInt()}', style: const TextStyle(color: Color(0xFFFF9F43), fontWeight: FontWeight.w600)),
              ),
              DataCell(
                wbScore < 0
                    ? const Text('—', style: TextStyle(color: Color(0xFF94A3B8)))
                    : Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: wbColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: wbColor.withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          wbScore.toStringAsFixed(0),
                          style: TextStyle(color: wbColor, fontWeight: FontWeight.w800, fontSize: 12),
                        ),
                      ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  // --- Exact At-Risk Card Implementation ---
  Widget _buildAtRiskCard(StudentWellbeing wb) {
    final isExpanded = _expandedCards.contains(wb.studentId);
    final riskColor = _riskColor(wb.riskLevel);
    final recs = _recommendations[wb.studentId];
    final isLoadingRec = _loadingRecommendations.contains(wb.studentId);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: riskColor.withValues(alpha: 0.35), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: riskColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedCards.remove(wb.studentId);
                } else {
                  _expandedCards.add(wb.studentId);
                  _loadRecommendations(wb);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  SizedBox(
                    width: 48,
                    height: 48,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CircularProgressIndicator(
                          value: (wb.wellbeingScore / 100).clamp(0.0, 1.0),
                          strokeWidth: 5,
                          color: riskColor,
                          backgroundColor: riskColor.withValues(alpha: 0.15),
                        ),
                        Text(
                          wb.wellbeingScore.toStringAsFixed(0),
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: riskColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          wb.studentName,
                          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF1E293B)),
                        ),
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _riskBadge(wb.riskLevel),
                            ...wb.alerts.take(2).map((a) => _alertCategoryChip(a)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (wb.trendScores.length >= 2)
                    SizedBox(
                      width: 60,
                      height: 28,
                      child: _miniSparkline(wb.trendScores, riskColor),
                    ),
                  const SizedBox(width: 8),
                  Icon(
                    isExpanded ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                    color: const Color(0xFF64748B),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              decoration: BoxDecoration(
                color: riskColor.withValues(alpha: 0.03),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(16),
                  bottomRight: Radius.circular(16),
                ),
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(height: 1),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      _metricChip('Quiz', '${wb.quizAvg.toStringAsFixed(0)}%', wb.quizAvg < 40 ? const Color(0xFFFF4757) : const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _metricChip('Attend', '${wb.attendanceRate.toStringAsFixed(0)}%', wb.attendanceRate < 60 ? const Color(0xFFFF4757) : const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _metricChip('PBL', '${wb.assignmentCompletion.toStringAsFixed(0)}%', wb.assignmentCompletion < 40 ? const Color(0xFFFFD93D) : const Color(0xFF10B981)),
                      const SizedBox(width: 8),
                      _metricChip('XP', wb.xp.toStringAsFixed(0), const Color(0xFF00D9FF)),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ...wb.alerts.map((a) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Text(a.categoryEmoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(a.message, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ),
                      ],
                    ),
                  )),
                  const SizedBox(height: 14),
                  const Text('AI Personalized Recommendations', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF2E6BFF))),
                  const SizedBox(height: 8),
                  if (isLoadingRec)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF2E6BFF)))),
                    )
                  else if (recs != null)
                    ...recs.map((rec) => _recommendationCard(rec))
                  else
                    const Text('Tap to load AI recommendations...', style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildAllWellbeingList() {
    final visibleWellbeing = _visibleWellbeing();

    if (visibleWellbeing.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No wellbeing data available', style: TextStyle(color: Color(0xFF64748B))),
        ),
      );
    }

    return Column(
      children: visibleWellbeing.map((wb) {
        final riskColor = _riskColor(wb.riskLevel);
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 38,
                height: 38,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: (wb.wellbeingScore / 100).clamp(0.0, 1.0),
                      strokeWidth: 4,
                      color: riskColor,
                      backgroundColor: riskColor.withValues(alpha: 0.15),
                    ),
                    Text(
                      wb.wellbeingScore.toStringAsFixed(0),
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: riskColor),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wb.studentName, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                    Text('Quiz: ${wb.quizAvg.toStringAsFixed(0)}% • Attend: ${wb.attendanceRate.toStringAsFixed(0)}% • XP: ${wb.xp.toStringAsFixed(0)}', style: const TextStyle(fontSize: 11, color: Color(0xFF94A3B8))),
                  ],
                ),
              ),
              _riskBadge(wb.riskLevel),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _miniSparkline(List<double> data, Color color) {
    final spots = List.generate(data.length, (i) => FlSpot(i.toDouble(), data[i]));
    return LineChart(
      LineChartData(
        gridData: const FlGridData(show: false),
        titlesData: const FlTitlesData(show: false),
        borderData: FlBorderData(show: false),
        lineTouchData: const LineTouchData(enabled: false),
        minY: 0,
        maxY: 100,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: color,
            barWidth: 2,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: color.withValues(alpha: 0.15),
            ),
          ),
        ],
      ),
    );
  }

  Widget _riskBadge(RiskLevel level) {
    final color = _riskColor(level);
    final label = level == RiskLevel.high ? 'HIGH RISK' : level == RiskLevel.medium ? 'MEDIUM RISK' : 'LOW RISK';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: color, letterSpacing: 0.5),
      ),
    );
  }

  Widget _alertCategoryChip(WellbeingAlert alert) {
    Color chipColor;
    switch (alert.category) {
      case AlertCategory.academicStress:
        chipColor = const Color(0xFFFF9F43);
        break;
      case AlertCategory.emotionalDistress:
        chipColor = const Color(0xFFFF4757);
        break;
      case AlertCategory.disengagement:
        chipColor = const Color(0xFF64748B);
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        '${alert.categoryEmoji} ${alert.categoryLabel}',
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: chipColor),
      ),
    );
  }

  Widget _metricChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
            Text(label, style: const TextStyle(fontSize: 9, color: Color(0xFF64748B))),
          ],
        ),
      ),
    );
  }

  Widget _recommendationCard(WellbeingRecommendation rec) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFF2E6BFF).withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(rec.icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(rec.title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1E293B))),
                const SizedBox(height: 3),
                Text(rec.description, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B), height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlassCard({required Widget child, double height = 240}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: SizedBox(height: height, child: child),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1E293B),
        ),
      ),
    );
  }

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return const Color(0xFF10B981);
      case RiskLevel.medium:
        return const Color(0xFFFFD93D);
      case RiskLevel.high:
        return const Color(0xFFFF4757);
    }
  }
}