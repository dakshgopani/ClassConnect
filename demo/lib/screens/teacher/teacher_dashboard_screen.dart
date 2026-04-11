import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/widgets/ui/cc_decorated_background.dart';
import 'package:demo/models/wellbeing_data.dart';
import 'package:demo/services/wellbeing_service.dart';
import 'package:demo/services/wellbeing_recommendation_service.dart';

class TeacherDashboardPage extends StatefulWidget {
  const TeacherDashboardPage({super.key});

  @override
  State<TeacherDashboardPage> createState() => _TeacherDashboardPageState();
}

class _TeacherDashboardPageState extends State<TeacherDashboardPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final WellbeingService _wellbeingService = WellbeingService();
  Timer? _refreshTimer;

  bool _isLoading = true;

  // Dashboard Data
  List<Map<String, dynamic>> students = [];
  late List<Map<String, dynamic>> _filteredStudents;

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

    Set<String> studentIds = {};
    for (final classId in classIds) {
      final classStudentsSnapshot = await _firestore
          .collection('class_students')
          .where('classId', isEqualTo: classId)
          .get();

      for (final doc in classStudentsSnapshot.docs) {
        studentIds.add(doc['studentId']);
      }
    }

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

    setState(() {
      students = loadedStudents;
      _filteredStudents = List.from(students);
    });
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

  void _filterStudents(String query) {
    setState(() {
      if (query.trim().isEmpty) {
        _filteredStudents = List.from(students);
      } else {
        _filteredStudents = students
            .where(
              (student) => (student['name'] as String).toLowerCase().contains(
                query.toLowerCase(),
              ),
            )
            .toList();
      }
    });
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

    // Gather weak concepts for this student
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

  // =================== BUILD ===================

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: CcDecoratedBackground(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Color(0xFF2E6BFF)),
                SizedBox(height: 16),
                Text(
                  'Loading dashboard...',
                  style: TextStyle(color: Color(0xFF5C6B8C), fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      body: CcDecoratedBackground(
        child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(user?.displayName ?? 'Teacher'),
                      const SizedBox(height: 24),
                      _buildQuickStatsGrid(),
                      const SizedBox(height: 24),

                      // Wellbeing Alert Banner
                      if (_atRiskStudents.isNotEmpty) _buildAlertBanner(),
                      if (_atRiskStudents.isNotEmpty)
                        const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0x1A2E6BFF)),
                    ),
                    child: TabBar(
                      controller: _tabController,
                      indicatorColor: const Color(0xFF2E6BFF),
                      indicatorSize: TabBarIndicatorSize.tab,
                      labelColor: const Color(0xFF2E6BFF),
                      unselectedLabelColor: const Color(0xFF5C6B8C),
                      labelStyle: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                      dividerColor: Colors.transparent,
                      tabs: [
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.analytics_rounded, size: 18),
                              const SizedBox(width: 6),
                              const Text('Overview'),
                            ],
                          ),
                        ),
                        Tab(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.health_and_safety_rounded,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              const Text('Wellbeing'),
                              if (_atRiskStudents.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
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
                ),
              ),
            ];
          },
          body: TabBarView(
            controller: _tabController,
            children: [_buildOverviewTab(), _buildWellbeingTab()],
          ),
        ),
      ),
    );
  }

  // =================== HEADER ===================

  Widget _buildHeader(String teacherName) {
    return Row(
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
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1B3D),
                ),
              ),
            ],
          ),
        ),
        // Refresh button
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
    );
  }

  // =================== QUICK STATS ===================

  Widget _buildQuickStatsGrid() {
    final avgAttendance = _calculateAverage('attendance');
    return Row(
      children: [
        Expanded(
          child: _quickStatCard(
            'Classes',
            _totalClasses.toString(),
            Icons.class_rounded,
            const Color(0xFF2E6BFF),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickStatCard(
            'Students',
            students.length.toString(),
            Icons.people_rounded,
            const Color(0xFF6BCB77),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickStatCard(
            'Avg Score',
            '${_avgQuizScore.toStringAsFixed(0)}%',
            Icons.trending_up_rounded,
            const Color(0xFFFF9F43),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _quickStatCard(
            'At Risk',
            _atRiskStudents.length.toString(),
            Icons.warning_amber_rounded,
            _atRiskStudents.isEmpty
                ? const Color(0xFF6BCB77)
                : const Color(0xFFFF4757),
          ),
        ),
      ],
    );
  }

  Widget _quickStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF5C6B8C)),
          ),
        ],
      ),
    );
  }

  // =================== ALERT BANNER ===================

  Widget _buildAlertBanner() {
    final highRisk = _atRiskStudents
        .where((w) => w.riskLevel == RiskLevel.high)
        .length;
    final medRisk = _atRiskStudents
        .where((w) => w.riskLevel == RiskLevel.medium)
        .length;

    return GestureDetector(
      onTap: () => _tabController.animateTo(1),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFFFF4757).withValues(alpha: 0.15),
              const Color(0xFFFF6B81).withValues(alpha: 0.08),
            ],
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: const Color(0xFFFF4757).withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFFF4757).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.health_and_safety_rounded,
                color: Color(0xFFFF4757),
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Student Wellbeing Alert',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF4757),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${highRisk > 0 ? '$highRisk high risk' : ''}${highRisk > 0 && medRisk > 0 ? ', ' : ''}${medRisk > 0 ? '$medRisk medium risk' : ''} student${_atRiskStudents.length > 1 ? 's' : ''} need attention',
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF5C6B8C),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios_rounded,
              size: 14,
              color: Color(0xFFFF4757),
            ),
          ],
        ),
      ),
    );
  }

  // =================== OVERVIEW TAB ===================

  Widget _buildOverviewTab() {
    final avgAttendance = _calculateAverage('attendance');

    return RefreshIndicator(
      color: const Color(0xFF2E6BFF),
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Key Averages Row
          _buildStatsRow(),
          const SizedBox(height: 24),

          // Performance Overview Chart
          _sectionTitle('Performance Overview'),
          _buildGlassCard(child: _performanceChart()),
          const SizedBox(height: 24),

          // Attendance & PBL side by side
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 600) {
                return Column(
                  children: [
                    _sectionTitle('Attendance'),
                    _buildGlassCard(child: _attendanceWidget(avgAttendance)),
                    const SizedBox(height: 24),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sectionTitle('Attendance'),
                        _buildGlassCard(
                          child: _attendanceWidget(avgAttendance),
                        ),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),

          // Weak Concepts
          if (_weakConcepts.isNotEmpty) ...[
            _sectionTitle('Weak Concepts'),
            _buildWeakConceptsSection(),
            const SizedBox(height: 24),
          ],

          // Top Performers
          _sectionTitle('Top Performers'),
          _buildTopPerformersSection(),
          const SizedBox(height: 24),

          // Search & Student Table
          _sectionTitle('All Students'),
          _buildSearchBar(),
          const SizedBox(height: 12),
          _buildStudentsTable(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  // =================== WELLBEING TAB ===================

  Widget _buildWellbeingTab() {
    return RefreshIndicator(
      color: const Color(0xFF2E6BFF),
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Class Wellbeing Summary
          _buildWellbeingSummary(),
          const SizedBox(height: 24),

          // Wellbeing Trend Chart
          _sectionTitle('Class Wellbeing Trend'),
          _buildGlassCard(child: _buildWellbeingTrendChart()),
          const SizedBox(height: 24),

          // At-Risk Students
          if (_atRiskStudents.isNotEmpty) ...[
            _sectionTitle('At-Risk Students (${_atRiskStudents.length})'),
            ..._atRiskStudents.map(_buildAtRiskCard),
            const SizedBox(height: 24),
          ],

          // All Student Wellbeing Scores
          _sectionTitle('All Student Wellbeing'),
          _buildAllWellbeingList(),
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildWellbeingSummary() {
    final avgScore = _wellbeingData.isEmpty
        ? 0.0
        : _wellbeingData.fold<double>(0, (s, w) => s + w.wellbeingScore) /
              _wellbeingData.length;
    final highRisk = _wellbeingData
        .where((w) => w.riskLevel == RiskLevel.high)
        .length;
    final medRisk = _wellbeingData
        .where((w) => w.riskLevel == RiskLevel.medium)
        .length;
    final lowRisk = _wellbeingData
        .where((w) => w.riskLevel == RiskLevel.low)
        .length;

    return Row(
      children: [
        Expanded(
          child: _wellbeingSummaryCard(
            'Avg Score',
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
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _wellbeingSummaryCard(
            'Low Risk',
            lowRisk.toString(),
            const Color(0xFF6BCB77),
            Icons.check_circle_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _wellbeingSummaryCard(
            'Medium',
            medRisk.toString(),
            const Color(0xFFFFD93D),
            Icons.warning_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _wellbeingSummaryCard(
            'High Risk',
            highRisk.toString(),
            const Color(0xFFFF4757),
            Icons.error_rounded,
          ),
        ),
      ],
    );
  }

  Widget _wellbeingSummaryCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(fontSize: 10, color: Color(0xFF5C6B8C)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildWellbeingTrendChart() {
    if (_wellbeingData.isEmpty) {
      return const Center(
        child: Text(
          'No wellbeing data yet',
          style: TextStyle(color: Color(0xFF5C6B8C)),
        ),
      );
    }

    // Use the longest available trend
    List<double>? longestTrend;
    for (final wb in _wellbeingData) {
      if (wb.trendScores.length > (longestTrend?.length ?? 0)) {
        longestTrend = wb.trendScores;
      }
    }

    // If no historical data, create from current scores
    if (longestTrend == null || longestTrend.isEmpty) {
      longestTrend = _wellbeingData.map((w) => w.wellbeingScore).toList();
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
              FlLine(color: const Color(0x1A2E6BFF), strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                if (value.toInt() % 3 == 0) {
                  return Text(
                    'D${value.toInt() + 1}',
                    style: const TextStyle(
                      color: Color(0xFF5C6B8C),
                      fontSize: 10,
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
                style: const TextStyle(color: Color(0xFF5C6B8C), fontSize: 10),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
                    radius: 3,
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
          // Risk threshold line
          LineChartBarData(
            spots: List.generate(spots.length, (i) => FlSpot(i.toDouble(), 40)),
            isCurved: false,
            color: const Color(0xFFFF4757).withValues(alpha: 0.4),
            barWidth: 1,
            dotData: const FlDotData(show: false),
            dashArray: [5, 5],
          ),
        ],
      ),
    );
  }

  // =================== AT-RISK CARD ===================

  Widget _buildAtRiskCard(StudentWellbeing wb) {
    final isExpanded = _expandedCards.contains(wb.studentId);
    final riskColor = _riskColor(wb.riskLevel);
    final recs = _recommendations[wb.studentId];
    final isLoadingRec = _loadingRecommendations.contains(wb.studentId);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: riskColor.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: riskColor.withValues(alpha: 0.1),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header Row
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
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Score circle
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          CircularProgressIndicator(
                            value: wb.wellbeingScore / 100,
                            strokeWidth: 5,
                            color: riskColor,
                            backgroundColor: riskColor.withValues(alpha: 0.15),
                          ),
                          Text(
                            wb.wellbeingScore.toStringAsFixed(0),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: riskColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Name & alerts
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            wb.studentName,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF0D1B3D),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: [
                              _riskBadge(wb.riskLevel),
                              ...wb.alerts
                                  .take(2)
                                  .map((a) => _alertCategoryChip(a)),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Sparkline
                    if (wb.trendScores.length >= 2)
                      SizedBox(
                        width: 60,
                        height: 30,
                        child: _miniSparkline(wb.trendScores, riskColor),
                      ),
                    const SizedBox(width: 8),

                    Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: const Color(0xFF5C6B8C),
                    ),
                  ],
                ),
              ),
            ),

            // Expanded Detail
            if (isExpanded)
              Container(
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.04),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 12),

                    // Metrics row
                    Row(
                      children: [
                        _metricChip(
                          'Quiz',
                          '${wb.quizAvg.toStringAsFixed(0)}%',
                          wb.quizAvg < 40
                              ? const Color(0xFFFF4757)
                              : const Color(0xFF6BCB77),
                        ),
                        const SizedBox(width: 8),
                        _metricChip(
                          'Attend',
                          '${wb.attendanceRate.toStringAsFixed(0)}%',
                          wb.attendanceRate < 60
                              ? const Color(0xFFFF4757)
                              : const Color(0xFF6BCB77),
                        ),
                        const SizedBox(width: 8),
                        _metricChip(
                          'PBL',
                          '${wb.assignmentCompletion.toStringAsFixed(0)}%',
                          wb.assignmentCompletion < 40
                              ? const Color(0xFFFFD93D)
                              : const Color(0xFF6BCB77),
                        ),
                        const SizedBox(width: 8),
                        _metricChip(
                          'XP',
                          wb.xp.toStringAsFixed(0),
                          const Color(0xFF00D9FF),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Alert messages
                    ...wb.alerts.map(
                      (a) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.categoryEmoji,
                              style: const TextStyle(fontSize: 14),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                a.message,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF5C6B8C),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // AI Recommendations
                    const Text(
                      'AI Recommendations',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF2E6BFF),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (isLoadingRec)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF2E6BFF),
                            ),
                          ),
                        ),
                      )
                    else if (recs != null)
                      ...recs.map((rec) => _recommendationCard(rec))
                    else
                      const Text(
                        'Tap to load AI recommendations...',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF5C6B8C),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Quick Actions
                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1B3D),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _quickActionBtn(
                            'Assign Easier Content',
                            Icons.auto_stories_rounded,
                            const Color(0xFF2E6BFF),
                          ),
                          const SizedBox(width: 8),
                          _quickActionBtn(
                            'Give Revision Tasks',
                            Icons.replay_rounded,
                            const Color(0xFF6BCB77),
                          ),
                          const SizedBox(width: 8),
                          _quickActionBtn(
                            'Schedule 1-on-1',
                            Icons.person_rounded,
                            const Color(0xFFFF9F43),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _miniSparkline(List<double> data, Color color) {
    final spots = List.generate(
      data.length,
      (i) => FlSpot(i.toDouble(), data[i]),
    );
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
    final label = level == RiskLevel.high
        ? 'HIGH'
        : level == RiskLevel.medium
        ? 'MEDIUM'
        : 'LOW';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
          letterSpacing: 0.5,
        ),
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
        chipColor = const Color(0xFF5C6B8C);
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
        style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: chipColor,
        ),
      ),
    );
  }

  Widget _metricChip(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
            Text(
              label,
              style: const TextStyle(fontSize: 9, color: Color(0xFF5C6B8C)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _recommendationCard(WellbeingRecommendation rec) {
    Color actionColor;
    switch (rec.actionType) {
      case 'content':
        actionColor = const Color(0xFF2E6BFF);
        break;
      case 'engagement':
        actionColor = const Color(0xFF6BCB77);
        break;
      case 'motivation':
        actionColor = const Color(0xFFFFD93D);
        break;
      default:
        actionColor = const Color(0xFF8B5CF6);
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: actionColor.withValues(alpha: 0.2)),
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
                  Text(
                    rec.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D1B3D),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    rec.description,
                    style: const TextStyle(
                      fontSize: 11,
                      color: Color(0xFF5C6B8C),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _quickActionBtn(String label, IconData icon, Color color) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$label action triggered'),
              backgroundColor: color,
              duration: const Duration(seconds: 2),
            ),
          );
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================== ALL WELLBEING LIST ===================

  Widget _buildAllWellbeingList() {
    if (_wellbeingData.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No wellbeing data available',
            style: TextStyle(color: Color(0xFF5C6B8C)),
          ),
        ),
      );
    }

    return Column(
      children: _wellbeingData.map((wb) {
        final riskColor = _riskColor(wb.riskLevel);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: riskColor.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                // Score indicator
                SizedBox(
                  width: 40,
                  height: 40,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: wb.wellbeingScore / 100,
                        strokeWidth: 4,
                        color: riskColor,
                        backgroundColor: riskColor.withValues(alpha: 0.15),
                      ),
                      Text(
                        wb.wellbeingScore.toStringAsFixed(0),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: riskColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wb.studentName,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D1B3D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Quiz: ${wb.quizAvg.toStringAsFixed(0)}% • Attend: ${wb.attendanceRate.toStringAsFixed(0)}% • XP: ${wb.xp.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: Color(0xFF5C6B8C),
                        ),
                      ),
                    ],
                  ),
                ),
                _riskBadge(wb.riskLevel),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // =================== SHARED WIDGETS ===================

  Color _riskColor(RiskLevel level) {
    switch (level) {
      case RiskLevel.low:
        return const Color(0xFF6BCB77);
      case RiskLevel.medium:
        return const Color(0xFFFFD93D);
      case RiskLevel.high:
        return const Color(0xFFFF4757);
    }
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF2E6BFF),
        ),
      ),
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0x1A2E6BFF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E6BFF).withValues(alpha: 0.08),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(height: 220, child: child),
      ),
    );
  }

  Widget _buildStatsRow() {
    return Row(
      children: [
        Expanded(
          child: _statCard(
            title: 'Quiz Avg',
            value: _avgQuizScore.toStringAsFixed(1),
            color: const Color(0xFFFF6B6B),
            icon: Icons.quiz_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            title: 'Attendance',
            value: '${_calculateAverage('attendance').toStringAsFixed(0)}%',
            color: const Color(0xFF6BCB77),
            icon: Icons.how_to_reg_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _statCard(
            title: 'PBL Avg',
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
            color.withValues(alpha: 0.85),
            color.withValues(alpha: 0.55),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: Colors.white.withValues(alpha: 0.9), size: 22),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _performanceChart() {
    return BarChart(
      BarChartData(
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                const titles = ['Quiz', 'Community', 'PBL'];
                if (value.toInt() < titles.length) {
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      titles[value.toInt()],
                      style: const TextStyle(
                        color: Color(0xFF5C6B8C),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
              interval: 20,
              getTitlesWidget: (value, meta) => Text(
                '${value.toInt()}',
                style: const TextStyle(color: Color(0xFF5C6B8C), fontSize: 10),
              ),
            ),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
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
          toY: y,
          color: color,
          width: 36,
          borderRadius: BorderRadius.circular(8),
          backDrawRodData: BackgroundBarChartRodData(
            show: true,
            toY: 100,
            color: Colors.white.withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _attendanceWidget(double value) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: CircularProgressIndicator(
              value: value / 100,
              strokeWidth: 8,
              color: const Color(0xFF6BCB77),
              backgroundColor: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${value.toStringAsFixed(1)}%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0D1B3D),
                ),
              ),
              const Text(
                'Present',
                style: TextStyle(fontSize: 11, color: Color(0xFF5C6B8C)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A2E6BFF)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: TextField(
        controller: _searchController,
        onChanged: _filterStudents,
        style: const TextStyle(color: Color(0xFF0D1B3D)),
        decoration: InputDecoration(
          icon: const Icon(Icons.search, color: Color(0xFF5C6B8C)),
          hintText: 'Search student...',
          hintStyle: const TextStyle(color: Color(0xFF7A89A8)),
          border: InputBorder.none,
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, color: Color(0xFF5C6B8C)),
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

  Widget _buildWeakConceptsSection() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _weakConcepts.take(6).map((concept) {
          return Container(
            margin: const EdgeInsets.only(right: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFF6B6B).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: const Color(0xFFFF6B6B).withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  concept['concept'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0D1B3D),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${concept['count']} students',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Color(0xFF5C6B8C),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTopPerformersSection() {
    final topThree = _getTopPerformers();
    if (topThree.isEmpty) {
      return const Center(
        child: Text(
          'No student data',
          style: TextStyle(color: Color(0xFF5C6B8C)),
        ),
      );
    }

    const medals = ['🥇', '🥈', '🥉'];
    const colors = [Color(0xFFFFD700), Color(0xFFC0C0C0), Color(0xFFCD7F32)];

    return Column(
      children: List.generate(topThree.length, (index) {
        final student = topThree[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Container(
            decoration: BoxDecoration(
              color: colors[index].withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: colors[index].withValues(alpha: 0.4),
                width: 1.5,
              ),
            ),
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: colors[index],
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        student['name'] as String,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF0D1B3D),
                        ),
                      ),
                      Text(
                        'XP: ${(student['xp'] as double).toInt()} • Quiz: ${(student['quiz_score'] as double).toInt()}%',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Color(0xFF5C6B8C),
                        ),
                      ),
                    ],
                  ),
                ),
                Text(medals[index], style: const TextStyle(fontSize: 20)),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStudentsTable() {
    if (_filteredStudents.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No student data',
            style: TextStyle(color: Color(0xFF5C6B8C)),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(
          const Color(0xFF2E6BFF).withValues(alpha: 0.06),
        ),
        columns: const [
          DataColumn(
            label: Text(
              'Student',
              style: TextStyle(
                color: Color(0xFF0D1B3D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Quiz %',
              style: TextStyle(
                color: Color(0xFF0D1B3D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Attend %',
              style: TextStyle(
                color: Color(0xFF0D1B3D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'PBL',
              style: TextStyle(
                color: Color(0xFF0D1B3D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'XP',
              style: TextStyle(
                color: Color(0xFF0D1B3D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          DataColumn(
            label: Text(
              'Wellbeing',
              style: TextStyle(
                color: Color(0xFF0D1B3D),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        rows: _filteredStudents.map((student) {
          // Find wellbeing for this student
          final wb = _wellbeingData.where((w) => w.studentId == student['id']);
          final wbScore = wb.isNotEmpty ? wb.first.wellbeingScore : -1.0;
          final wbRisk = wb.isNotEmpty ? wb.first.riskLevel : RiskLevel.low;
          final wbColor = wbScore < 0
              ? const Color(0xFF5C6B8C)
              : _riskColor(wbRisk);

          return DataRow(
            cells: [
              DataCell(
                Text(
                  student['name'] as String,
                  style: const TextStyle(
                    color: Color(0xFF0D1B3D),
                    fontSize: 12,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${(student['quiz_score'] as double).toInt()}',
                  style: const TextStyle(
                    color: Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${(student['attendance'] as double).toInt()}%',
                  style: const TextStyle(
                    color: Color(0xFF6BCB77),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${(student['pbl_score'] as double).toInt()}',
                  style: const TextStyle(
                    color: Color(0xFFFFD93D),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                Text(
                  '${(student['xp'] as double).toInt()}',
                  style: const TextStyle(
                    color: Color(0xFFFF9F43),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              DataCell(
                wbScore < 0
                    ? const Text(
                        '—',
                        style: TextStyle(color: Color(0xFF5C6B8C)),
                      )
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: wbColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          wbScore.toStringAsFixed(0),
                          style: TextStyle(
                            color: wbColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}
