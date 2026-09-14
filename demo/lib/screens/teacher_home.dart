import 'package:flutter/material.dart';
import 'package:demo/services/auth_service.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:demo/theme/app_radius.dart';
import 'package:demo/widgets/ui/cc_floating_nav_item.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'teacher/teacher_dashboard_screen.dart';
import 'teacher/teacher_classes_screen.dart';
import 'teacher/teacher_settings_screen.dart';
import 'teacher/create_class_screen.dart';
import 'teacher_tasks/screens/teacher_task_screen.dart';
import 'package:demo/utils/responsive_breakpoints.dart';

class TeacherHome extends StatefulWidget {
  const TeacherHome({super.key});

  @override
  State<TeacherHome> createState() => _TeacherHomeState();
}

class _TeacherHomeState extends State<TeacherHome> {
  int _currentIndex = 0;
  final AuthService _auth = AuthService();

  static const List<Color> _navAccentColors = [
    Color(0xFF2E6BFF),
    Color(0xFF2E6BFF),
    Color(0xFF2E6BFF),
    Color(0xFF2E6BFF),
  ];

  final List<Widget> _pages = const [
    TeacherDashboardScreen(),
    TeacherTaskScreen(),
    TeacherClassesPage(),
    TeacherSettingsScreen(),
  ];

  void _navigateToCreateClassPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateClassPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (isDesktop) {
      return _buildDesktopLayout();
    }

    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Container(
              color: const Color(0xFFF8FAFC),
              child: Column(
                children: [
                  _buildTopBar(),
                  Expanded(child: _pages[_currentIndex]),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    final width = MediaQuery.of(context).size.width;
    final sidebarWidth = width < 1050 ? 230.0 : 260.0;

    return Container(
      width: sidebarWidth,
      height: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E293B),
            const Color(0xFF0F172A),
          ],
        ),
      ),
      child: Column(
        children: [
          _buildSidebarHeader(),
          const SizedBox(height: 24),
          _buildSidebarNavItems(),
          const Spacer(),
          _buildSidebarFooter(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Container(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF3B82F6),
                  const Color(0xFF60A5FA),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.school_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'ClassConnect',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Teacher Portal',
            style: TextStyle(
              color: Color(0xFF94A3B8),
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItems() {
    final navItems = [
      {'icon': Icons.dashboard_rounded, 'label': 'Dashboard'},
      {'icon': Icons.work_outline_rounded, 'label': 'Workload'},
      {'icon': Icons.class_rounded, 'label': 'Classes'},
      {'icon': Icons.settings_rounded, 'label': 'Settings'},
    ];

    return Column(
      children: List.generate(navItems.length, (index) {
        final isSelected = _currentIndex == index;
        final item = navItems[index];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: _buildNavItem(
            icon: item['icon'] as IconData,
            label: item['label'] as String,
            selected: isSelected,
            onTap: () => setState(() => _currentIndex = index),
          ),
        );
      }),
    );
  }

  Widget _buildNavItem({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF3B82F6).withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF3B82F6)
                    : const Color(0xFF334155),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: selected ? Colors.white : const Color(0xFF94A3B8),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Colors.white
                      : const Color(0xFF94A3B8),
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
            if (selected)
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: Color(0xFF3B82F6),
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebarFooter() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: const Color(0xFF334155),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: () async => await _auth.signOut(),
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.logout_rounded,
                  color: Colors.red,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Sign Out',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    const titles = ['Dashboard', 'Workload', 'Classes', 'Settings'];

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFFE2E8F0),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titles[_currentIndex],
              style: const TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 24,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.5,
              ),
            ),
          ),
          Row(
            children: [
              if (_currentIndex == 2)
                ElevatedButton.icon(
                  onPressed: () => _navigateToCreateClassPage(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Create Class'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 0,
                  ),
                ),
              const SizedBox(width: 16),
              _buildUserProfile(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUserProfile() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('teachers')
          .doc(FirebaseAuth.instance.currentUser!.uid)
          .get(),
      builder: (context, snapshot) {
        final teacherName = snapshot.hasData && snapshot.data!.exists
            ? (snapshot.data!.data() as Map<String, dynamic>)['teacherName'] as String?
            : 'Teacher';
        final initials = teacherName?.isNotEmpty == true
            ? teacherName!.split(' ').map((n) => n[0]).take(2).join().toUpperCase()
            : 'T';

        return Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF3B82F6),
                    const Color(0xFF60A5FA),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Text(
              teacherName ?? 'Teacher',
              style: const TextStyle(
                color: Color(0xFF475569),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildMobileLayout() {
    final navAccent = _navAccentColors[_currentIndex];
    final navSurface = const Color(0xFF0F1C3F).withValues(alpha: 0.90);

    return Scaffold(
      appBar: _buildMobileAppBar(),
      body: BottomBar(
        borderRadius: BorderRadius.circular(AppRadius.full),
        duration: const Duration(seconds: 1),
        curve: Curves.decelerate,
        showIcon: true,
        iconHeight: 35,
        iconWidth: 35,
        start: 2,
        end: 0,
        reverse: false,
        hideOnScroll: true,
        scrollOpposite: false,
        respectSafeArea: true,
        onBottomBarHidden: () {},
        onBottomBarShown: () {},
        barAlignment: Alignment.bottomCenter,
        offset: 10,
        width: MediaQuery.of(context).size.width * 0.8,
        barColor: Colors.transparent,
        iconDecoration: BoxDecoration(
          color: navAccent.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: navAccent.withValues(alpha: 0.35),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        icon: (width, height) => Icon(
          Icons.keyboard_arrow_up_rounded,
          size: width,
          color: Colors.white,
        ),
        barDecoration: BoxDecoration(
          color: navSurface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.14),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        body: (context, scrollController) => PrimaryScrollController(
          controller: scrollController,
          child: _pages[_currentIndex],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _FloatingNavItem(
                icon: Icons.dashboard_rounded,
                label: "Dashboard",
                selected: _currentIndex == 0,
                onTap: () => setState(() => _currentIndex = 0),
              ),
              _FloatingNavItem(
                icon: Icons.work_outline_rounded,
                label: "Workload",
                selected: _currentIndex == 1,
                onTap: () => setState(() => _currentIndex = 1),
              ),
              _FloatingNavItem(
                icon: Icons.class_rounded,
                label: "Classes",
                selected: _currentIndex == 2,
                onTap: () => setState(() => _currentIndex = 2),
              ),
              _FloatingNavItem(
                icon: Icons.settings_rounded,
                label: "Settings",
                selected: _currentIndex == 3,
                onTap: () => setState(() => _currentIndex = 3),
              ),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildMobileAppBar() {
    const titles = ['Dashboard', 'Workload', 'Classes', 'Settings'];

    return AppBar(
      backgroundColor: const Color(0xFFF4F8FF),
      foregroundColor: const Color(0xFF0D1B3D),
      elevation: 0,
      scrolledUnderElevation: 0,
      surfaceTintColor: Colors.transparent,
      centerTitle: true,
      title: Text(
        titles[_currentIndex],
        style: const TextStyle(color: Color(0xFF0D1B3D)),
      ),
      actions: [
        if (_currentIndex == 2)
          IconButton(
            icon: const Icon(Icons.add, color: Color(0xFF2E6BFF)),
            onPressed: () => _navigateToCreateClassPage(context),
          ),
        IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () async => await _auth.signOut(),
        ),
      ],
    );
  }
}

class _FloatingNavItem extends StatelessWidget {
  const _FloatingNavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return CcFloatingNavItem(
      icon: icon,
      label: label,
      selected: selected,
      onTap: onTap,
      activeColor: const Color(0xFF2E6BFF),
      inactiveColor: Colors.white60,
    );
  }
}