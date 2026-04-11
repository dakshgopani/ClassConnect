import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/teacher_task_service.dart';

class PlanWorkloadScreen extends StatefulWidget {
  const PlanWorkloadScreen({super.key});

  @override
  State<PlanWorkloadScreen> createState() => _PlanWorkloadScreenState();
}

class _PlanWorkloadScreenState extends State<PlanWorkloadScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _service = TeacherTaskService();
  final _titleController = TextEditingController();
  final _minutesController = TextEditingController(text: '30');

  DateTime _selectedDate = DateTime.now();
  DateTime? _dueDate;
  bool _planWeekly = false;
  bool _saving = false;

  String _title = '';
  String _taskType = 'lesson_plan';
  String _priority = 'medium';
  int _estimatedMinutes = 30;

  late AnimationController _heroAnim;
  late Animation<double> _heroFade;

  // Quick templates
  static const _templates = [
    _TaskTemplate('📚', 'Lesson Prep', 'lesson_plan', 45, 'medium'),
    _TaskTemplate('📝', 'Quiz Review', 'quiz_review', 20, 'high'),
    _TaskTemplate('🎯', 'PBL Review', 'pbl_review', 60, 'high'),
    _TaskTemplate('👨‍🏫', 'Student Help', 'student_support', 30, 'medium'),
    _TaskTemplate('📋', 'Admin Work', 'admin', 15, 'low'),
  ];

  final List<String> _priorities = ['low', 'medium', 'high'];

  final List<String> _taskTypes = [
    'lesson_plan',
    'quiz_review',
    'pbl_review',
    'student_support',
    'admin',
    'custom',
  ];

  final Map<int, bool> _weekDays = {
    1: true,
    2: true,
    3: true,
    4: true,
    5: true,
    6: false,
    7: false,
  };

  // Design palette — matches the teacher dashboard system
  static const _bg = Color(0xFFF4F8FF);
  static const _surface = Colors.white;
  static const _surfaceLight = Color(0xFFF0F4FF);
  static const _accent = Color(0xFF2E6BFF);
  static const _accentCyan = Color(0xFF00D4AA);
  static const _cardRadius = BorderRadius.all(Radius.circular(20));

  @override
  void initState() {
    super.initState();
    _heroAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _heroFade = CurvedAnimation(parent: _heroAnim, curve: Curves.easeOut);
    _heroAnim.forward();
  }

  @override
  void dispose() {
    _heroAnim.dispose();
    _titleController.dispose();
    _minutesController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _readableDate(DateTime d) {
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
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }

  List<String> _generateWeekDates(DateTime start, Map<int, bool> selected) {
    final dates = <String>[];
    for (int i = 0; i < 7; i++) {
      final d = start.add(Duration(days: i));
      if (selected[d.weekday] == true) dates.add(_formatDate(d));
    }
    return dates;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _quickTemplatesSection(),
                      const SizedBox(height: 20),
                      _sectionCard(
                        icon: Icons.edit_note,
                        title: 'Task Details',
                        children: [
                          _buildTitleField(),
                          const SizedBox(height: 14),
                          _taskTypeSelector(),
                          const SizedBox(height: 14),
                          _buildMinutesSlider(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        icon: Icons.calendar_month,
                        title: 'Schedule',
                        children: [
                          _buildDatePicker(),
                          const SizedBox(height: 12),
                          _buildWeeklyToggle(),
                          if (_planWeekly) ...[
                            const SizedBox(height: 12),
                            _weekdaySelector(),
                          ],
                          const SizedBox(height: 12),
                          _buildDueDatePicker(),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _sectionCard(
                        icon: Icons.flag_outlined,
                        title: 'Priority',
                        children: [_prioritySelector()],
                      ),
                      const SizedBox(height: 16),
                      _reviewSummary(),
                      const SizedBox(height: 24),
                      _submitButton(),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SLIVER APP BAR
  // ═══════════════════════════════════════════

  Widget _buildSliverAppBar() {
    final modeLabel = _planWeekly ? 'Weekly' : 'Single day';
    return SliverAppBar(
      expandedHeight: 200,
      pinned: true,
      backgroundColor: Colors.white,
      foregroundColor: const Color(0xFF0D1B3D),
      elevation: 2,
      shadowColor: const Color(0xFF2E6BFF).withOpacity(0.1),
      title: const Text(
        'Plan Workload',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 17),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: FadeTransition(
          opacity: _heroFade,
          child: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF667EEA), Color(0xFF764BA2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 100, 24, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Plan Your Workload',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Block focused time and stay ahead of deadlines.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _heroPill(
                      Icons.calendar_today,
                      _readableDate(_selectedDate),
                    ),
                    _heroPill(Icons.repeat, modeLabel),
                    _heroPill(Icons.timer, _formatMins(_estimatedMinutes)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _heroPill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Color(0xFF0D1B3D)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF0D1B3D),
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // QUICK TEMPLATES
  // ═══════════════════════════════════════════

  Widget _quickTemplatesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 10, top: 8),
          child: Row(
            children: [
              Icon(Icons.bolt, color: _accent, size: 20),
              SizedBox(width: 6),
              Text(
                'Quick Start',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0D1B3D),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _templates.length,
            separatorBuilder: (_, i) => const SizedBox(width: 10),
            itemBuilder: (context, i) => _templateCard(_templates[i]),
          ),
        ),
      ],
    );
  }

  Widget _templateCard(_TaskTemplate t) {
    final isSelected = _taskType == t.type;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() {
          _taskType = t.type;
          _estimatedMinutes = t.minutes;
          _minutesController.text = t.minutes.toString();
          _priority = t.priority;
          _titleController.text = t.label;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 110,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected ? _accent : _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? _accent : _surfaceLight,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _accent.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(t.emoji, style: const TextStyle(fontSize: 22)),
            const Spacer(),
            Text(
              t.label,
              style: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF0D1B3D),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${t.minutes}m',
              style: TextStyle(
                color: isSelected ? Colors.white60 : const Color(0xFF8DA6D8),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SECTION CARD
  // ═══════════════════════════════════════════

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: _cardRadius,
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF2E6BFF).withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
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
                child: Icon(icon, color: _accent, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B3D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // TASK DETAILS
  // ═══════════════════════════════════════════

  Widget _buildTitleField() {
    return TextFormField(
      controller: _titleController,
      decoration: InputDecoration(
        hintText: 'What do you need to do?',
        hintStyle: const TextStyle(color: Color(0xFFC5D1E8)),
        prefixIcon: const Icon(Icons.title, color: _accentCyan, size: 20),
        filled: true,
        fillColor: _surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0x1A2E6BFF)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _accentCyan, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: const TextStyle(color: Color(0xFF0D1B3D), fontSize: 15),
      validator: (v) => v == null || v.isEmpty ? 'Give your task a name' : null,
      onSaved: (v) => _title = v!,
    );
  }

  Widget _taskTypeSelector() {
    final typeIcons = {
      'lesson_plan': Icons.menu_book,
      'quiz_review': Icons.quiz,
      'pbl_review': Icons.science,
      'student_support': Icons.people,
      'admin': Icons.admin_panel_settings,
      'custom': Icons.add_circle_outline,
    };

    final typeLabels = {
      'lesson_plan': 'Lesson',
      'quiz_review': 'Quiz',
      'pbl_review': 'PBL',
      'student_support': 'Support',
      'admin': 'Admin',
      'custom': 'Custom',
    };

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _taskTypes.map((type) {
        final selected = _taskType == type;
        final icon = typeIcons[type] ?? Icons.task;
        final label = typeLabels[type] ?? type;
        return GestureDetector(
          onTap: () => setState(() => _taskType = type),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: selected ? _accent.withValues(alpha: 0.15) : _surfaceLight,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? _accent : Colors.transparent,
                width: 1.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 16,
                  color: selected ? _accent : Color(0xFF8DA6D8),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? _accent : Color(0xFF5C6B8C),
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMinutesSlider() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.timer_outlined, color: _accentCyan, size: 18),
            const SizedBox(width: 8),
            const Text(
              'Estimated time',
              style: TextStyle(
                color: Color(0xFF5C6B8C),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _accentCyan.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _formatMins(_estimatedMinutes),
                style: const TextStyle(
                  color: _accentCyan,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _accentCyan,
            inactiveTrackColor: _surfaceLight,
            thumbColor: _accentCyan,
            overlayColor: _accentCyan.withValues(alpha: 0.15),
            trackHeight: 6,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
          ),
          child: Slider(
            value: _estimatedMinutes.clamp(5, 240).toDouble(),
            min: 5,
            max: 240,
            divisions: 47,
            onChanged: (v) {
              setState(() {
                _estimatedMinutes = v.round();
                _minutesController.text = _estimatedMinutes.toString();
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '5m',
                style: TextStyle(color: Color(0xFF8DA6D8), fontSize: 11),
              ),
              Text(
                '4h',
                style: TextStyle(color: Color(0xFF8DA6D8), fontSize: 11),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _formatMins(int m) => m < 60 ? '${m}m' : '${m ~/ 60}h ${m % 60}m';

  // ═══════════════════════════════════════════
  // SCHEDULE
  // ═══════════════════════════════════════════

  Widget _buildDatePicker() {
    final isToday = _isSameDay(_selectedDate, DateTime.now());
    final isTomorrow = _isSameDay(
      _selectedDate,
      DateTime.now().add(const Duration(days: 1)),
    );
    final badge = isToday
        ? 'Today'
        : isTomorrow
        ? 'Tomorrow'
        : null;

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pickDate(
        initial: _selectedDate,
        firstDate: DateTime.now().subtract(const Duration(days: 7)),
        lastDate: DateTime.now().add(const Duration(days: 45)),
        onPicked: (d) => setState(() => _selectedDate = d),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surfaceLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.event, color: _accent, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Planned day',
                        style: TextStyle(
                          color: Color(0xFF8DA6D8),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      if (badge != null) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _accentCyan.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            badge,
                            style: const TextStyle(
                              color: _accentCyan,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _readableDate(_selectedDate),
                    style: const TextStyle(
                      color: Color(0xFF0D1B3D),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF8DA6D8), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDueDatePicker() {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => _pickDate(
        initial: _dueDate ?? _selectedDate,
        firstDate: _selectedDate,
        lastDate: _selectedDate.add(const Duration(days: 60)),
        onPicked: (d) => setState(() => _dueDate = d),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _surfaceLight,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.flag, color: Colors.amber, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Due date',
                    style: TextStyle(
                      color: Color(0xFF8DA6D8),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _dueDate == null
                        ? 'Not set (optional)'
                        : _readableDate(_dueDate!),
                    style: TextStyle(
                      color: _dueDate == null
                          ? Color(0xFF8DA6D8)
                          : Color(0xFF0D1B3D),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (_dueDate != null)
              GestureDetector(
                onTap: () => setState(() => _dueDate = null),
                child: const Icon(
                  Icons.close,
                  color: Color(0xFF8DA6D8),
                  size: 18,
                ),
              )
            else
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF8DA6D8),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyToggle() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _surfaceLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF764BA2).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.repeat, color: Color(0xFF764BA2), size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Repeat weekly',
                  style: TextStyle(
                    color: Color(0xFF0D1B3D),
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Create on selected weekdays',
                  style: TextStyle(color: Color(0xFF5C6B8C), fontSize: 12),
                ),
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: _planWeekly,
              activeTrackColor: _accentCyan,
              onChanged: (v) => setState(() => _planWeekly = v),
            ),
          ),
        ],
      ),
    );
  }

  Widget _weekdaySelector() {
    const labels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const fullLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: _weekDays.keys.map((day) {
        final selected = _weekDays[day] ?? false;
        return Tooltip(
          message: fullLabels[day - 1],
          child: GestureDetector(
            onTap: () => setState(() => _weekDays[day] = !selected),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? _accent : _surfaceLight,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? _accent : Color(0xFFE8ECFF),
                  width: 1.5,
                ),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: _accent.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Text(
                labels[day - 1],
                style: TextStyle(
                  color: selected ? Colors.white : Color(0xFF8DA6D8),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════
  // PRIORITY SELECTOR
  // ═══════════════════════════════════════════

  Widget _prioritySelector() {
    final priorityConfig = {
      'low': _PriorityStyle(
        icon: Icons.arrow_downward,
        color: Colors.blueGrey,
        label: 'Low',
        desc: 'Do when free',
      ),
      'medium': _PriorityStyle(
        icon: Icons.remove,
        color: Colors.amber,
        label: 'Medium',
        desc: 'Standard task',
      ),
      'high': _PriorityStyle(
        icon: Icons.arrow_upward,
        color: Colors.redAccent,
        label: 'High',
        desc: 'Urgent priority',
      ),
    };

    return Row(
      children: _priorities.map((p) {
        final selected = _priority == p;
        final style = priorityConfig[p]!;
        return Expanded(
          child: GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _priority = p);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: EdgeInsets.only(
                left: p == 'low' ? 0 : 6,
                right: p == 'high' ? 0 : 6,
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              decoration: BoxDecoration(
                color: selected
                    ? style.color.withValues(alpha: 0.15)
                    : _surfaceLight,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: selected ? style.color : Colors.transparent,
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(style.icon, color: style.color, size: 22),
                  const SizedBox(height: 4),
                  Text(
                    style.label,
                    style: TextStyle(
                      color: selected ? style.color : Color(0xFF5C6B8C),
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    style.desc,
                    style: const TextStyle(
                      color: Color(0xFF8DA6D8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ═══════════════════════════════════════════
  // REVIEW SUMMARY
  // ═══════════════════════════════════════════

  Widget _reviewSummary() {
    final selectedDayCount = _weekDays.values.where((v) => v).length;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [_surface, _surfaceLight.withValues(alpha: 0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: _cardRadius,
        border: Border.all(color: _accent.withValues(alpha: 0.25)),
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
                child: const Icon(Icons.checklist, color: _accent, size: 18),
              ),
              const SizedBox(width: 10),
              const Text(
                'Review',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0D1B3D),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _reviewItem(Icons.event, 'Date', _readableDate(_selectedDate)),
          _reviewItem(
            Icons.repeat,
            'Mode',
            _planWeekly ? 'Weekly ($selectedDayCount days)' : 'Single day',
          ),
          _reviewItem(Icons.timer, 'Effort', _formatMins(_estimatedMinutes)),
          _reviewItem(
            Icons.flag,
            'Priority',
            '${_priority[0].toUpperCase()}${_priority.substring(1)}',
          ),
          _reviewItem(
            Icons.event_available,
            'Due',
            _dueDate == null ? 'Not set' : _readableDate(_dueDate!),
          ),
        ],
      ),
    );
  }

  Widget _reviewItem(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFF8DA6D8)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(color: Color(0xFF5C6B8C), fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF0D1B3D),
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════
  // SUBMIT BUTTON
  // ═══════════════════════════════════════════

  Widget _submitButton() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 56,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _saving ? _surfaceLight : _accentCyan,
          foregroundColor: Colors.black,
          disabledBackgroundColor: _surfaceLight,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: _saving ? 0 : 8,
          shadowColor: _accentCyan.withValues(alpha: 0.4),
        ),
        onPressed: _saving ? null : _saveTask,
        child: _saving
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Color(0xFF0D1B3D),
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: const [
                  Icon(Icons.add_task, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Add to Plan',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
      ),
    );
  }

  // ═══════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════

  void _pickDate({
    required DateTime initial,
    required DateTime firstDate,
    required DateTime lastDate,
    required ValueChanged<DateTime> onPicked,
  }) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: _accentCyan,
              onPrimary: Colors.black,
              surface: Color(0xFF0F1C3F),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) onPicked(picked);
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  Future<void> _saveTask() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _saving = true);

    try {
      if (_planWeekly) {
        final dates = _generateWeekDates(_selectedDate, _weekDays);
        await _service.createWeeklyPlannedTasks(
          plannedDates: dates,
          taskType: _taskType,
          title: _title,
          estimatedMinutes: _estimatedMinutes,
          priority: _priority,
          dueDate: _dueDate,
        );
      } else {
        await _service.createManualPlannedTask(
          plannedForDate: _formatDate(_selectedDate),
          taskType: _taskType,
          title: _title,
          estimatedMinutes: _estimatedMinutes,
          priority: _priority,
          dueDate: _dueDate,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: const [
              Icon(Icons.check_circle, color: _accentCyan, size: 20),
              SizedBox(width: 10),
              Text('Task added to your plan'),
            ],
          ),
          backgroundColor: _surface,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          duration: const Duration(seconds: 2),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      setState(() => _saving = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }
}

// ═══════════════════════════════════════════
// DATA CLASSES
// ═══════════════════════════════════════════

class _TaskTemplate {
  final String emoji;
  final String label;
  final String type;
  final int minutes;
  final String priority;

  const _TaskTemplate(
    this.emoji,
    this.label,
    this.type,
    this.minutes,
    this.priority,
  );
}

class _PriorityStyle {
  final IconData icon;
  final Color color;
  final String label;
  final String desc;

  const _PriorityStyle({
    required this.icon,
    required this.color,
    required this.label,
    required this.desc,
  });
}
