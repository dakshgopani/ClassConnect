import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:demo/widgets/ui/cc_loading_animation.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/teacher_task.dart';
import '../models/productivity.dart';
import '../services/notification_service.dart';
import '../services/teacher_task_query_service.dart';
import '../services/teacher_task_service.dart';
import '../services/workload_calculator.dart';
import '../services/productivity_calculator.dart';
import '../services/productivity_tips_service.dart';
import 'plan_workload_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo/widgets/ui/cc_decorated_background.dart';

enum _TimeFilter { today, tomorrow, next7 }

class TeacherTaskScreen extends StatefulWidget {
  const TeacherTaskScreen({super.key});

  @override
  State<TeacherTaskScreen> createState() => _TeacherTaskScreenState();
}

class _TeacherTaskScreenState extends State<TeacherTaskScreen>
    with SingleTickerProviderStateMixin {
  final _queryService = TeacherTaskQueryService();
  final _notifService = NotificationService();
  final _taskService = TeacherTaskService();
  final _tipsService = ProductivityTipsService();
  late final String _teacherId;
  _TimeFilter _filter = _TimeFilter.today;
  final ScrollController _listController = ScrollController();
  late TabController _tabController;

  // Productivity tips cache
  List<ProductivityTip>? _cachedTips;
  bool _tipsLoading = false;

  // Design constants
  static const _bg = Color(0xFFF4F8FF);
  static const _surface = Colors.white;
  static const _surfaceLight = Color(0xFFF0F4FF);
  static const _accent = Color(0xFF2E6BFF);
  static const _accentCyan = Color(0xFF00D4AA);
  static const _textPrimary = Color(0xFF0D1B3D);
  static const _textSecondary = Color(0xFF5C6B8C);
  static const _cardRadius = BorderRadius.all(Radius.circular(20));

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() => setState(() {}));
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('Teacher not logged in');
    _teacherId = user.uid;
  }

  @override
  void dispose() {
    _listController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final isDesktop = MediaQuery.of(context).size.width >= 800;

    if (isDesktop) {
      return _buildDesktopLayout();
    }

    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: _bg,
      body: Column(
        children: [
          _buildHorizontalTabBar(),
          Expanded(
            child: CcDecoratedBackground(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDesktopTasksTab(),
                  _buildDesktopPlannerTab(),
                  _buildDesktopProductivityTab(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E6BFF).withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF3B82F6), Color(0xFF60A5FA)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.task_alt, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 16),
          const Text(
            'Workload Management',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B3D),
            ),
          ),
          const Spacer(),
          _buildTabButton(Icons.task_alt, 'Tasks', 0),
          const SizedBox(width: 8),
          _buildTabButton(Icons.calendar_month, 'Planner', 1),
          const SizedBox(width: 8),
          _buildTabButton(Icons.speed, 'Productivity', 2),
        ],
      ),
    );
  }

  Widget _buildTabButton(IconData icon, String label, int index) {
    final isSelected = _tabController.index == index;
    return GestureDetector(
      onTap: () => _tabController.animateTo(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _accent.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? _accent : Colors.transparent,
            width: 2,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? _accent : const Color(0xFF94A3B8),
              size: 18,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? _accent : const Color(0xFF94A3B8),
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        toolbarHeight: 0,
        titleSpacing: 0,
        centerTitle: false,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _accent,
          indicatorWeight: 3,
          labelColor: const Color(0xFF0D1B3D),
          unselectedLabelColor: const Color(0xFF5C6B8C),
          labelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
          tabs: const [
            Tab(
              icon: Icon(Icons.task_alt, color: _accent, size: 20),
              text: 'Tasks',
            ),
            Tab(
              icon: Icon(Icons.calendar_month, color: _accent, size: 20),
              text: 'Planner',
            ),
            Tab(
              icon: Icon(Icons.speed, color: _accent, size: 20),
              text: 'Productivity',
            ),
          ],
        ),
      ),
      body: CcDecoratedBackground(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTasksTab(),
            _buildPlannerTab(),
            _buildProductivityTab(),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // DESKTOP TAB WRAPPERS
  // ═══════════════════════════════════════════

  Widget _buildDesktopTasksTab() {
    return Column(
      children: [
        const SizedBox(height: 24),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: _quickActionsCard(),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Row(
            children: [
              _filterChip('Today', _TimeFilter.today, Icons.sunny),
              const SizedBox(width: 10),
              _filterChip('Tomorrow', _TimeFilter.tomorrow, Icons.upcoming),
              const SizedBox(width: 10),
              _filterChip('This Week', _TimeFilter.next7, Icons.calendar_view_week),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<TeacherTask>>(
            stream: _streamForFilter(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CcLoadingAnimation(color: _accent));
              }
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return _emptyTaskState();
              }

              final pending = tasks.where((t) => t.status != 'completed').toList();
              final completed = tasks.where((t) => t.status == 'completed').toList();
              final workload = calculateDailyWorkload(tasks, DateTime.now());

              return ListView(
                controller: _listController,
                padding: const EdgeInsets.fromLTRB(32, 16, 32, 32),
                children: [
                  _quickStatsHero(tasks, workload),
                  if (_filter == _TimeFilter.next7) _next7BarChart(tasks),
                  if (pending.isNotEmpty) ...[
                    _sectionTitle('Pending', pending.length, Icons.pending_actions, Colors.amber),
                    const SizedBox(height: 12),
                    ...pending.map(_taskCard),
                  ],
                  if (completed.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    _sectionTitle('Completed', completed.length, Icons.check_circle, Colors.green),
                    const SizedBox(height: 12),
                    ...completed.map(_taskCard),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopPlannerTab() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final end = now.add(const Duration(days: 30));

    return StreamBuilder<List<TeacherTask>>(
      stream: _queryService.getPlannedTasksInRange(
        teacherId: _teacherId,
        startDate: _fmt(start),
        endDate: _fmt(end),
      ),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        final events = <DateTime, List<TeacherTask>>{};
        for (final t in tasks) {
          if (t.plannedForDate == null) continue;
          final d = DateTime.parse(t.plannedForDate!);
          final key = DateTime(d.year, d.month, d.day);
          events.putIfAbsent(key, () => []);
          events[key]!.add(t);
        }

        DateTime focusedDay = now;
        DateTime selectedDay = now;

        return StatefulBuilder(
          builder: (context, setCalState) {
            final selectedKey = DateTime(selectedDay.year, selectedDay.month, selectedDay.day);
            final dayTasks = events[selectedKey] ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          color: _surface,
                          borderRadius: _cardRadius,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(8),
                          child: TableCalendar<TeacherTask>(
                            firstDay: start,
                            lastDay: end,
                            focusedDay: focusedDay,
                            selectedDayPredicate: (day) => isSameDay(day, selectedDay),
                            eventLoader: (day) => events[DateTime(day.year, day.month, day.day)] ?? [],
                            calendarStyle: CalendarStyle(
                              todayDecoration: BoxDecoration(
                                color: _accent.withValues(alpha: 0.6),
                                shape: BoxShape.circle,
                              ),
                              selectedDecoration: const BoxDecoration(
                                color: _accentCyan,
                                shape: BoxShape.circle,
                              ),
                              defaultTextStyle: const TextStyle(color: Color(0xFF0D1B3D)),
                              weekendTextStyle: const TextStyle(color: Color(0xFF5C6B8C)),
                              outsideTextStyle: const TextStyle(color: Color(0xFF8DA6D8)),
                              markerDecoration: BoxDecoration(
                                color: _accent,
                                shape: BoxShape.circle,
                              ),
                            ),
                            headerStyle: const HeaderStyle(
                              titleTextStyle: TextStyle(color: Color(0xFF0D1B3D), fontSize: 17),
                              leftChevronIcon: Icon(Icons.chevron_left, color: Color(0xFF0D1B3D)),
                              rightChevronIcon: Icon(Icons.chevron_right, color: Color(0xFF0D1B3D)),
                            ),
                            daysOfWeekStyle: const DaysOfWeekStyle(
                              weekdayStyle: TextStyle(color: Color(0xFF5C6B8C)),
                              weekendStyle: TextStyle(color: Color(0xFF5C6B8C)),
                            ),
                            onDaySelected: (sel, foc) {
                              setCalState(() {
                                selectedDay = sel;
                                focusedDay = foc;
                              });
                            },
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.event_note, color: _accent, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Tasks on ${selectedDay.toString().substring(0, 10)}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: Color(0xFF0D1B3D)),
                              ),
                              const Spacer(),
                              Text(
                                '${dayTasks.length} task${dayTasks.length == 1 ? '' : 's'}',
                                style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          if (dayTasks.isEmpty)
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                color: _surface,
                                borderRadius: _cardRadius,
                              ),
                              child: const Center(
                                child: Text('No tasks planned for this day.', style: TextStyle(color: Colors.black54)),
                              ),
                            )
                          else
                            ...dayTasks.map(_taskCard),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildDesktopProductivityTab() {
    final now = DateTime.now();
    final rangeStart = now.subtract(const Duration(days: 30));

    return StreamBuilder<List<TeacherTask>>(
      stream: _queryService.getPlannedTasksInRange(
        teacherId: _teacherId,
        startDate: _fmt(rangeStart),
        endDate: _fmt(now),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting && (snapshot.data == null || snapshot.data!.isEmpty)) {
          return const Center(child: CcLoadingAnimation(color: _accent));
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Complete some tasks to see\nyour productivity trends.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
              ],
            ),
          );
        }

        final weekly = calculateProductivity(tasks, now.subtract(const Duration(days: 7)));
        final monthly = calculateProductivity(tasks, now.subtract(const Duration(days: 30)));
        final missedTasks = tasksMissedDeadlines(tasks);
        final weeklyWorkload = calculateWeeklyWorkload(tasks, now.subtract(Duration(days: now.weekday - 1)));
        final overplannedDays = detectOverplannedDays(weeklyWorkload.minutesPerDay);

        _loadTipsIfNeeded(weekly, missedTasks.length, overplannedDays);

        return GridView(
          padding: const EdgeInsets.fromLTRB(32, 24, 32, 32),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 20,
            crossAxisSpacing: 20,
            childAspectRatio: 1.2,
          ),
          children: [
            _productivityScoreCard(weekly),
            _streakCard(weekly),
            _weeklyTrendChart(tasks),
            _metricsGrid(weekly, monthly),
            _taskTypeBreakdown(weekly),
            if (overplannedDays.isNotEmpty) _burnoutWarning(weeklyWorkload, overplannedDays),
            if (missedTasks.isNotEmpty) _deadlineWarning(missedTasks),
            _aiTipsSection(),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // TAB 1: TASKS
  // ═══════════════════════════════════════════

  Widget _buildTasksTab() {
    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _quickActionsCard(),
        ),
        const SizedBox(height: 14),
        // Filter chips
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              _filterChip('Today', _TimeFilter.today, Icons.sunny),
              const SizedBox(width: 10),
              _filterChip('Tomorrow', _TimeFilter.tomorrow, Icons.upcoming),
              const SizedBox(width: 10),
              _filterChip(
                'This Week',
                _TimeFilter.next7,
                Icons.calendar_view_week,
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<TeacherTask>>(
            stream: _streamForFilter(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CcLoadingAnimation(color: _accent));
              }
              final tasks = snapshot.data ?? [];
              if (tasks.isEmpty) {
                return _emptyTaskState();
              }

              final pending = tasks
                  .where((t) => t.status != 'completed')
                  .toList();
              final completed = tasks
                  .where((t) => t.status == 'completed')
                  .toList();
              final workload = calculateDailyWorkload(tasks, DateTime.now());

              return ListView(
                controller: _listController,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                children: [
                  _quickStatsHero(tasks, workload),
                  if (_filter == _TimeFilter.next7) _next7BarChart(tasks),
                  if (pending.isNotEmpty) ...[
                    _sectionTitle(
                      'Pending',
                      pending.length,
                      Icons.pending_actions,
                      Colors.amber,
                    ),
                    ...pending.map(_taskCard),
                  ],
                  if (completed.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _sectionTitle(
                      'Completed',
                      completed.length,
                      Icons.check_circle,
                      Colors.green,
                    ),
                    ...completed.map(_taskCard),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _quickActionsCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFFFFFF), Color(0xFFF5F9FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: _surfaceLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.grid_view_rounded, color: _accent),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Quick actions',
                  style: TextStyle(
                    color: Color(0xFF0D1B3D),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Plan new work or send nudges fast.',
                  style: TextStyle(color: Color(0xFF5C6B8C), fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          _actionBubble(
            icon: Icons.add_rounded,
            tooltip: 'Plan workload',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PlanWorkloadScreen()),
            ),
          ),
          const SizedBox(width: 8),
          _actionBubble(
            icon: Icons.notifications_active_outlined,
            tooltip: 'Send nudges',
            onTap: () => _showNudgeMenu(context),
          ),
        ],
      ),
    );
  }

  Widget _actionBubble({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: _accent.withValues(alpha: 0.1),
      shape: const CircleBorder(),
      child: Tooltip(
        message: tooltip,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 44,
            height: 44,
            child: Icon(icon, color: _accent),
          ),
        ),
      ),
    );
  }

  Future<void> _showNudgeMenu(BuildContext context) async {
    final choice = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.12),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _surfaceLight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
                const SizedBox(height: 16),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Send nudge',
                    style: TextStyle(
                      color: Color(0xFF0D1B3D),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _nudgeOption(
                  icon: Icons.wb_sunny_outlined,
                  title: 'Tomorrow',
                  subtitle: 'Remind students about work due tomorrow.',
                  onTap: () => Navigator.pop(sheetContext, 'tomorrow'),
                ),
                const SizedBox(height: 10),
                _nudgeOption(
                  icon: Icons.date_range_outlined,
                  title: 'Next 7 days',
                  subtitle: 'Send a reminder for the upcoming week.',
                  onTap: () => Navigator.pop(sheetContext, 'next7'),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (choice == 'tomorrow') {
      await _notifService.sendTomorrowNudge(teacherId: _teacherId);
    } else if (choice == 'next7') {
      await _notifService.sendNext7DaysNudge(teacherId: _teacherId);
    }
  }

  Widget _nudgeOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _bg,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: _accent),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0D1B3D),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF5C6B8C),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: _accent),
          ],
        ),
      ),
    );
  }

  Widget _emptyTaskState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: _accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.event_available, size: 48, color: _accent),
          ),
          const SizedBox(height: 16),
          const Text(
            'All clear!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF0D1B3D),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'No tasks planned for this window.\nTap + to plan something.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _quickStatsHero(List<TeacherTask> tasks, DailyWorkload workload) {
    final total = tasks.length;
    final done = tasks.where((t) => t.status == 'completed').length;
    final rate = total == 0 ? 0.0 : done / total;
    final estMin = tasks.fold(0, (acc, t) => acc + t.estimatedMinutes);
    final actMin = tasks.fold(0, (acc, t) => acc + t.actualMinutes);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: _cardRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withValues(alpha: 0.35),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: Colors.white, size: 22),
              const SizedBox(width: 8),
              Text(
                _greetingText(),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$done / $total tasks done',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 6),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: rate),
                      duration: const Duration(milliseconds: 600),
                      builder: (_, value, __) => ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: value.clamp(0.0, 1.0),
                          minHeight: 8,
                          backgroundColor: Colors.white24,
                          valueColor: const AlwaysStoppedAnimation(
                            Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Est ${_formatMins(estMin)} · Actual ${_formatMins(actMin)}',
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              _circularProgress(rate),
            ],
          ),
        ],
      ),
    );
  }

  Widget _circularProgress(double rate) {
    return SizedBox(
      width: 70,
      height: 70,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 70,
            height: 70,
            child: CircularProgressIndicator(
              value: rate.clamp(0, 1),
              strokeWidth: 6,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
          Text(
            '${(rate * 100).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  String _greetingText() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  String _formatMins(int mins) {
    if (mins < 60) return '${mins}m';
    return '${mins ~/ 60}h ${mins % 60}m';
  }

  Widget _sectionTitle(String title, int count, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            '$title ($count)',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _taskCard(TeacherTask task) {
    final due = _deadlineForTask(task);
    final statusColor = _statusColor(task.status);
    final isOverdue =
        due != null &&
        due.isBefore(DateTime.now()) &&
        task.status != 'completed';

    return Dismissible(
      key: Key(task.id),
      direction: task.status == 'completed'
          ? DismissDirection.endToStart
          : DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.green.shade600,
          borderRadius: _cardRadius,
        ),
        alignment: Alignment.centerLeft,
        child: const Icon(Icons.check, color: Colors.white, size: 28),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.red.shade600,
          borderRadius: _cardRadius,
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white, size: 28),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          await _taskService.updateTaskStatus(task.id, 'completed');
          return false; // Stream will handle the update
        } else {
          return await _confirmDelete(context);
        }
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _taskService.deleteTask(task.id);
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: _cardRadius,
          border: isOverdue
              ? Border.all(
                  color: Colors.redAccent.withValues(alpha: 0.6),
                  width: 1.5,
                )
              : Border.all(color: _surfaceLight.withValues(alpha: 0.5)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _priorityBadge(task.priority),
                const SizedBox(width: 8),
                _statusBadge(task.status, statusColor),
                if (isOverdue) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.warning_amber,
                          size: 12,
                          color: Colors.redAccent,
                        ),
                        SizedBox(width: 3),
                        Text(
                          'Overdue',
                          style: TextStyle(
                            color: Colors.redAccent,
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                // Time log button
                IconButton(
                  icon: const Icon(
                    Icons.timer_outlined,
                    color: _accentCyan,
                    size: 20,
                  ),
                  tooltip: 'Log time',
                  onPressed: () => _showTimeLogDialog(task),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              task.title,
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                color: _textPrimary,
                fontSize: 15,
              ),
            ),
            if (task.description.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                task.description,
                style: const TextStyle(color: _textSecondary, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _infoPill(Icons.schedule, _timeLabel(task)),
                if (due != null) _infoPill(Icons.event, _dueLabel(due)),
                _infoPill(
                  Icons.category_outlined,
                  task.taskType.replaceAll('_', ' '),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: task.status == 'completed'
                          ? _surfaceLight
                          : _accentCyan,
                      foregroundColor: task.status == 'completed'
                          ? Colors.black
                          : Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () async {
                      final newStatus = task.status == 'completed'
                          ? 'pending'
                          : 'completed';
                      await _taskService.updateTaskStatus(task.id, newStatus);
                    },
                    icon: Icon(
                      task.status == 'completed'
                          ? Icons.undo
                          : Icons.check_circle_outline,
                      size: 18,
                    ),
                    label: Text(
                      task.status == 'completed' ? 'Undo' : 'Done',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => _taskService.deleteTask(task.id),
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 20,
                  ),
                  tooltip: 'Delete task',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: _surface,
            shape: RoundedRectangleBorder(borderRadius: _cardRadius),
            title: const Text(
              'Delete task?',
              style: TextStyle(color: _textPrimary),
            ),
            content: const Text(
              'This action cannot be undone.',
              style: TextStyle(color: _textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showTimeLogDialog(TeacherTask task) {
    final controller = TextEditingController(
      text: task.actualMinutes > 0 ? task.actualMinutes.toString() : '',
    );
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _surface,
        shape: RoundedRectangleBorder(borderRadius: _cardRadius),
        title: const Text(
          'Log actual time',
          style: TextStyle(color: _textPrimary),
        ),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: const TextStyle(color: Color(0xFF0D1B3D)),
          decoration: InputDecoration(
            hintText: 'Minutes spent',
            hintStyle: const TextStyle(color: Color(0xFF8DA6D8)),
            filled: true,
            fillColor: _surfaceLight,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0x1A2E6BFF)),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              final mins = int.tryParse(controller.text);
              if (mins != null && mins > 0) {
                _taskService.updateActualMinutes(task.id, mins);
              }
              Navigator.pop(ctx);
            },
            child: const Text('Save', style: TextStyle(color: _accentCyan)),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TAB 2: PLANNER (Calendar)
  // ═══════════════════════════════════════════

  Widget _buildPlannerTab() {
    final now = DateTime.now();
    final start = now.subtract(const Duration(days: 30));
    final end = now.add(const Duration(days: 30));

    return StreamBuilder<List<TeacherTask>>(
      stream: _queryService.getPlannedTasksInRange(
        teacherId: _teacherId,
        startDate: _fmt(start),
        endDate: _fmt(end),
      ),
      builder: (context, snapshot) {
        final tasks = snapshot.data ?? [];
        final events = <DateTime, List<TeacherTask>>{};
        for (final t in tasks) {
          if (t.plannedForDate == null) continue;
          final d = DateTime.parse(t.plannedForDate!);
          final key = DateTime(d.year, d.month, d.day);
          events.putIfAbsent(key, () => []);
          events[key]!.add(t);
        }

        DateTime focusedDay = now;
        DateTime selectedDay = now;

        return StatefulBuilder(
          builder: (context, setCalState) {
            final selectedKey = DateTime(
              selectedDay.year,
              selectedDay.month,
              selectedDay.day,
            );
            final dayTasks = events[selectedKey] ?? [];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: _surface,
                    borderRadius: _cardRadius,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8),
                    child: TableCalendar<TeacherTask>(
                      firstDay: start,
                      lastDay: end,
                      focusedDay: focusedDay,
                      selectedDayPredicate: (day) =>
                          isSameDay(day, selectedDay),
                      eventLoader: (day) =>
                          events[DateTime(day.year, day.month, day.day)] ?? [],
                      calendarStyle: CalendarStyle(
                        todayDecoration: BoxDecoration(
                          color: _accent.withValues(alpha: 0.6),
                          shape: BoxShape.circle,
                        ),
                        selectedDecoration: const BoxDecoration(
                          color: _accentCyan,
                          shape: BoxShape.circle,
                        ),
                        defaultTextStyle: const TextStyle(
                          color: Color(0xFF0D1B3D),
                        ),
                        weekendTextStyle: const TextStyle(
                          color: Color(0xFF5C6B8C),
                        ),
                        outsideTextStyle: const TextStyle(
                          color: Color(0xFF8DA6D8),
                        ),
                        markerDecoration: BoxDecoration(
                          color: _accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: const HeaderStyle(
                        titleTextStyle: TextStyle(
                          color: Color(0xFF0D1B3D),
                          fontSize: 17,
                        ),
                        leftChevronIcon: Icon(
                          Icons.chevron_left,
                          color: Color(0xFF0D1B3D),
                        ),
                        rightChevronIcon: Icon(
                          Icons.chevron_right,
                          color: Color(0xFF0D1B3D),
                        ),
                      ),
                      daysOfWeekStyle: const DaysOfWeekStyle(
                        weekdayStyle: TextStyle(color: Color(0xFF5C6B8C)),
                        weekendStyle: TextStyle(color: Color(0xFF5C6B8C)),
                      ),
                      onDaySelected: (sel, foc) {
                        setCalState(() {
                          selectedDay = sel;
                          focusedDay = foc;
                        });
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    const Icon(Icons.event_note, color: _accent, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Tasks on ${selectedDay.toString().substring(0, 10)}',
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0D1B3D),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${dayTasks.length} task${dayTasks.length == 1 ? '' : 's'}',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (dayTasks.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: _surface,
                      borderRadius: _cardRadius,
                    ),
                    child: const Center(
                      child: Text(
                        'No tasks planned for this day.',
                        style: TextStyle(color: Colors.black54),
                      ),
                    ),
                  )
                else
                  ...dayTasks.map(_taskCard),
              ],
            );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════
  // TAB 3: PRODUCTIVITY
  // ═══════════════════════════════════════════

  Widget _buildProductivityTab() {
    final now = DateTime.now();
    final rangeStart = now.subtract(const Duration(days: 30));

    return StreamBuilder<List<TeacherTask>>(
      stream: _queryService.getPlannedTasksInRange(
        teacherId: _teacherId,
        startDate: _fmt(rangeStart),
        endDate: _fmt(now),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            (snapshot.data == null || snapshot.data!.isEmpty)) {
          return const Center(child: CcLoadingAnimation(color: _accent));
        }

        final tasks = snapshot.data ?? [];

        if (tasks.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.speed, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  'Complete some tasks to see\nyour productivity trends.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                ),
              ],
            ),
          );
        }

        final weekly = calculateProductivity(
          tasks,
          now.subtract(const Duration(days: 7)),
        );
        final monthly = calculateProductivity(
          tasks,
          now.subtract(const Duration(days: 30)),
        );
        final missedTasks = tasksMissedDeadlines(tasks);
        final weeklyWorkload = calculateWeeklyWorkload(
          tasks,
          now.subtract(Duration(days: now.weekday - 1)),
        );
        final overplannedDays = detectOverplannedDays(
          weeklyWorkload.minutesPerDay,
        );

        // Load AI tips on first render
        _loadTipsIfNeeded(weekly, missedTasks.length, overplannedDays);

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            _productivityScoreCard(weekly),
            const SizedBox(height: 16),
            _streakCard(weekly),
            const SizedBox(height: 16),
            _weeklyTrendChart(tasks),
            const SizedBox(height: 16),
            _metricsGrid(weekly, monthly),
            const SizedBox(height: 16),
            _taskTypeBreakdown(weekly),
            if (overplannedDays.isNotEmpty) ...[
              const SizedBox(height: 16),
              _burnoutWarning(weeklyWorkload, overplannedDays),
            ],
            if (missedTasks.isNotEmpty) ...[
              const SizedBox(height: 16),
              _deadlineWarning(missedTasks),
            ],
            const SizedBox(height: 16),
            _aiTipsSection(),
          ],
        );
      },
    );
  }

  Widget _productivityScoreCard(ProductivityMetrics metrics) {
    final score = metrics.productivityScore;
    final label = score >= 80
        ? 'Excellent'
        : score >= 60
        ? 'Good'
        : score >= 40
        ? 'Fair'
        : 'Needs focus';
    final color = score >= 80
        ? const Color(0xFF00D4AA)
        : score >= 60
        ? const Color(0xFF667EEA)
        : score >= 40
        ? Colors.amber
        : Colors.redAccent;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withValues(alpha: 0.9), color.withValues(alpha: 0.6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: _cardRadius,
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: 90,
                  height: 90,
                  child: CircularProgressIndicator(
                    value: (score / 100).clamp(0, 1),
                    strokeWidth: 8,
                    backgroundColor: Colors.white24,
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                  ),
                ),
                Text(
                  score.toStringAsFixed(0),
                  style: const TextStyle(
                    color: Colors.black,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productivity Score',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _miniMetricRow('Completion', metrics.completionRate),
                _miniMetricRow('On-time', metrics.onTimeRate),
                _miniMetricRow('Efficiency', metrics.efficiency.clamp(0, 1.5)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniMetricRow(String label, double ratio) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          SizedBox(
            width: 65,
            child: Text(
              label,
              style: const TextStyle(color: Colors.white, fontSize: 11),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: ratio.clamp(0, 1),
                minHeight: 4,
                backgroundColor: Colors.white24,
                valueColor: const AlwaysStoppedAnimation(Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '${(ratio * 100).clamp(0, 200).toStringAsFixed(0)}%',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _streakCard(ProductivityMetrics metrics) {
    final streak = metrics.currentStreak;
    final best = metrics.longestStreak;
    final emoji = streak >= 7
        ? '🔥'
        : streak >= 3
        ? '⚡'
        : streak >= 1
        ? '✨'
        : '💤';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: _cardRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 36)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '$streak day${streak == 1 ? '' : 's'}',
                      style: const TextStyle(
                        color: Colors.black,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'streak',
                      style: TextStyle(color: Colors.black54, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Personal best: $best day${best == 1 ? '' : 's'}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: streak > 0
                  ? _accentCyan.withValues(alpha: 0.15)
                  : Colors.white12,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              streak > 0 ? 'Active' : 'Start today',
              style: TextStyle(
                color: streak > 0 ? _accentCyan : Colors.black54,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weeklyTrendChart(List<TeacherTask> tasks) {
    final now = DateTime.now();
    final start = DateTime(
      now.year,
      now.month,
      now.day,
    ).subtract(const Duration(days: 6));
    final counts = List<int>.filled(7, 0);
    final completedCounts = List<int>.filled(7, 0);

    for (final task in tasks) {
      if (task.plannedForDate == null) continue;
      final date = DateTime.parse(task.plannedForDate!);
      final diff = date.difference(start).inDays;
      if (diff >= 0 && diff < 7) {
        counts[diff]++;
        if (task.status == 'completed') completedCounts[diff]++;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: _cardRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.bar_chart, color: _accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Last 7 Days',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx > 6) return const SizedBox.shrink();
                        final day = start.add(Duration(days: idx));
                        const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                        return Text(
                          dayNames[day.weekday - 1],
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: counts[i].toDouble(),
                        width: 14,
                        borderRadius: BorderRadius.circular(4),
                        color: Colors.white24,
                        rodStackItems: [
                          BarChartRodStackItem(
                            0,
                            completedCounts[i].toDouble(),
                            _accentCyan,
                          ),
                        ],
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _legendDot(_accentCyan, 'Completed'),
              const SizedBox(width: 16),
              _legendDot(Colors.white24, 'Total'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.black54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _metricsGrid(ProductivityMetrics weekly, ProductivityMetrics monthly) {
    return Row(
      children: [
        Expanded(
          child: _metricTile(
            'Weekly',
            '${weekly.completedTasks}/${weekly.totalTasks}',
            Icons.calendar_today,
            _accent,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricTile(
            'Monthly',
            '${monthly.completedTasks}/${monthly.totalTasks}',
            Icons.date_range,
            const Color(0xFF764BA2),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _metricTile(
            'Daily Avg',
            '${weekly.avgDailyMinutes.toStringAsFixed(0)}m',
            Icons.access_time,
            Colors.amber,
          ),
        ),
      ],
    );
  }

  Widget _metricTile(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: _cardRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(color: Colors.black54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _taskTypeBreakdown(ProductivityMetrics metrics) {
    if (metrics.tasksByType.isEmpty) return const SizedBox.shrink();

    final sorted = metrics.tasksByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold(0, (acc, e) => acc + e.value);

    final colors = [
      _accent,
      _accentCyan,
      const Color(0xFF764BA2),
      Colors.amber,
      Colors.redAccent,
      Colors.teal,
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: _cardRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.pie_chart_outline, color: _accent, size: 20),
              SizedBox(width: 8),
              Text(
                'Task Breakdown',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...sorted.take(5).toList().asMap().entries.map((entry) {
            final i = entry.key;
            final e = entry.value;
            final pct = total > 0 ? e.value / total : 0.0;
            final color = colors[i % colors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      e.key.replaceAll('_', ' '),
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${e.value}',
                    style: const TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 80,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: pct,
                        minHeight: 4,
                        backgroundColor: Colors.white12,
                        valueColor: AlwaysStoppedAnimation(color),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _burnoutWarning(
    WeeklyWorkload workload,
    List<String> overplannedDays,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: _cardRadius,
        border: Border.all(color: Colors.orange.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_fire_department, color: Colors.orange, size: 22),
              SizedBox(width: 8),
              Text(
                'Burnout Warning',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: overplannedDays.map((day) {
              final mins = workload.minutesPerDay[day] ?? 0;
              final hours = mins / 60;
              return Chip(
                avatar: Icon(Icons.warning, color: Colors.orange, size: 16),
                label: Text(
                  '$day • ${hours.toStringAsFixed(1)}h',
                  style: const TextStyle(color: Colors.black, fontSize: 12),
                ),
                backgroundColor: Colors.orange.withValues(alpha: 0.15),
                side: BorderSide.none,
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tip: Keep daily planned work under 6 hours to avoid burnout.',
            style: TextStyle(color: Colors.black54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _deadlineWarning(List<TeacherTask> lateTasks) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: _cardRadius,
        border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.event_busy, color: Colors.redAccent, size: 22),
              const SizedBox(width: 8),
              Text(
                '${lateTasks.length} missed deadline${lateTasks.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...lateTasks
              .take(3)
              .map(
                (task) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.circle,
                        color: Colors.redAccent,
                        size: 8,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          task.title,
                          style: const TextStyle(
                            color: Colors.black87,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          if (lateTasks.length > 3)
            Text(
              '+${lateTasks.length - 3} more',
              style: const TextStyle(
                color: Colors.black54,
                fontSize: 12,
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  // --- AI Tips ---

  void _loadTipsIfNeeded(
    ProductivityMetrics metrics,
    int missedDeadlines,
    List<String> overplannedDays,
  ) {
    if (_cachedTips != null || _tipsLoading) return;
    _tipsLoading = true;
    _tipsService
        .generateTips(
          metrics: metrics,
          missedDeadlines: missedDeadlines,
          overplannedDays: overplannedDays,
        )
        .then((tips) {
          if (mounted) {
            setState(() {
              _cachedTips = tips;
              _tipsLoading = false;
            });
          }
        });
  }

  Widget _aiTipsSection() {
    final tipIcons = {
      'time_management': Icons.schedule,
      'focus': Icons.center_focus_strong,
      'planning': Icons.event_note,
      'wellness': Icons.spa,
      'motivation': Icons.emoji_events,
    };

    final tipColors = {
      'time_management': _accent,
      'focus': _accentCyan,
      'planning': const Color(0xFF764BA2),
      'wellness': Colors.teal,
      'motivation': Colors.amber,
    };

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: _cardRadius,
        border: Border.all(color: _accent.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: _accent.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: _accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.auto_awesome, color: _accent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'AI Productivity Tips',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (_tipsLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: CcLoadingAnimation(color: _accent, strokeWidth: 2),
              ),
            )
          else if (_cachedTips != null)
            ..._cachedTips!.map((tip) {
              final icon = tipIcons[tip.category] ?? Icons.lightbulb;
              final color = tipColors[tip.category] ?? _accent;
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _surfaceLight,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: color.withValues(alpha: 0.15),
                      child: Icon(icon, color: color, size: 16),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tip.title,
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            tip.description,
                            style: const TextStyle(
                              color: Colors.black54,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            })
          else
            const Text(
              'Tips will load when data is available.',
              style: TextStyle(color: Colors.black54, fontSize: 13),
            ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SHARED HELPERS
  // ═══════════════════════════════════════════

  Widget _filterChip(String label, _TimeFilter value, IconData icon) {
    final selected = _filter == value;
    return GestureDetector(
      onTap: () => setState(() => _filter = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _accent.withValues(alpha: 0.12) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? _accent : const Color(0xFFE0E6F0),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? _accent : Colors.grey),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? _accent : const Color(0xFF5C6B8C),
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Stream<List<TeacherTask>> _streamForFilter() {
    final now = DateTime.now();
    switch (_filter) {
      case _TimeFilter.today:
        return _queryService.getTodaysPlannedTasks(teacherId: _teacherId);
      case _TimeFilter.tomorrow:
        final t = now.add(const Duration(days: 1));
        return _queryService.getPlannedTasksForDate(
          teacherId: _teacherId,
          plannedForDate: _fmt(t),
        );
      case _TimeFilter.next7:
        final start = DateTime(now.year, now.month, now.day);
        final end = start.add(const Duration(days: 7));
        return _queryService.getPlannedTasksInRange(
          teacherId: _teacherId,
          startDate: _fmt(start),
          endDate: _fmt(end),
        );
    }
  }

  Widget _next7BarChart(List<TeacherTask> tasks) {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, now.day);
    final counts = List<int>.filled(7, 0);

    for (final task in tasks) {
      if (task.plannedForDate == null) continue;
      final date = DateTime.parse(task.plannedForDate!);
      final diff = date.difference(start).inDays;
      if (diff >= 0 && diff < 7) counts[diff]++;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: _cardRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Week Ahead',
            style: TextStyle(
              color: Colors.black,
              fontSize: 15,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final idx = value.toInt();
                        if (idx < 0 || idx > 6) return const SizedBox.shrink();
                        final day = start.add(Duration(days: idx));
                        return Text(
                          '${day.month}/${day.day}',
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.black54,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: List.generate(7, (i) {
                  return BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: counts[i].toDouble(),
                        width: 16,
                        borderRadius: BorderRadius.circular(5),
                        gradient: const LinearGradient(
                          colors: [Color(0xFF667EEA), Color(0xFF00D4AA)],
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _surfaceLight,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _accentCyan),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _priorityBadge(String priority) {
    final color = priority.toLowerCase() == 'high'
        ? Colors.redAccent
        : priority.toLowerCase() == 'low'
        ? Colors.blueGrey
        : Colors.amber;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.flag, color: color, size: 12),
          const SizedBox(width: 3),
          Text(
            priority.toUpperCase(),
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 10,
        ),
      ),
    );
  }

  DateTime? _deadlineForTask(TeacherTask task) {
    if (task.dueDate != null) return task.dueDate!.toDate();
    if (task.plannedForDate != null) {
      final planned = DateTime.parse(task.plannedForDate!);
      return DateTime(planned.year, planned.month, planned.day, 23, 59, 59);
    }
    return null;
  }

  String _timeLabel(TeacherTask task) {
    return 'Est ${task.estimatedMinutes}m · Act ${task.actualMinutes}m';
  }

  String _dueLabel(DateTime due) {
    final now = DateTime.now();
    final diff = due.difference(now).inHours;
    if (diff >= 24) return 'Due in ${(diff / 24).ceil()}d';
    if (diff >= 0) return 'Due in ${diff}h';
    return 'Overdue';
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'in_progress':
        return Colors.amber;
      default:
        return Colors.orange;
    }
  }
}
