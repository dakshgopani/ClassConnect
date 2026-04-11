import 'package:flutter/material.dart';
import 'package:demo/services/auth_service.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:demo/theme/app_radius.dart';
import 'package:demo/widgets/ui/cc_floating_nav_item.dart';
import 'teacher/teacher_dashboard_screen.dart';
import 'teacher/teacher_classes_screen.dart';
import 'teacher/teacher_settings_screen.dart';
import 'teacher/create_class_screen.dart';
import 'teacher_tasks/screens/teacher_task_screen.dart';

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

  // Updated pages to match your new Nav Bar order
  final List<Widget> _pages = const [
    TeacherDashboardPage(), // 0

    TeacherTaskScreen(), // 1 → Workload

    TeacherClassesPage(), // 2 → Classes

    TeacherSettingsScreen(), // 3
  ];

  AppBar _buildAppBar() {
    // Theme constants
    const appBarBgColor = Color(0xFFF4F8FF);
    const accentColor = Color(0xFF2E6BFF);

    switch (_currentIndex) {
      // ================= ACTIVITY (Dashboard) =================
      case 0:
        return AppBar(
          backgroundColor: appBarBgColor,
          foregroundColor: const Color(0xFF0D1B3D),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              
              SizedBox(width: 8),
              Text("Dashboard", style: TextStyle(color: Color(0xFF0D1B3D))),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async => await _auth.signOut(),
            ),
          ],
        );

      // ================= Workload =================
      case 1:
        return AppBar(
          backgroundColor: const Color(0xFFF4F8FF),
          foregroundColor: const Color(0xFF0D1B3D),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(width:8),
              Text("Workload", style: TextStyle(color: Color(0xFF0D1B3D))),
            ],
          ),
        );

      // ================= Class =================
      case 2:
        return AppBar(
          backgroundColor: appBarBgColor,
          foregroundColor: const Color(0xFF0D1B3D),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(width: 8),
              Text("Classes", style: TextStyle(color: Color(0xFF0D1B3D))),
            ],
          ),
          actions: [
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'Create Class') {
                  _navigateToCreateClassPage(context);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'Create Class',
                  child: Text('Create Class'),
                ),
              ],
            ),
          ],
        );

      // ================= SETTINGS =================
      case 3:
        return AppBar(
          backgroundColor: appBarBgColor,
          foregroundColor: const Color(0xFF0D1B3D),
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          centerTitle: true,
          title: Row(
            mainAxisSize: MainAxisSize.min,
            children: const [
              SizedBox(width: 8),
              Text("Settings", style: TextStyle(color: Color(0xFF0D1B3D))),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _auth.signOut();
                if (mounted) Navigator.pushReplacementNamed(context, '/login');
              },
            ),
          ],
        );

      default:
        return AppBar(
          backgroundColor: appBarBgColor,
          title: const Text("Teacher"),
        );
    }
  }

  void _navigateToCreateClassPage(BuildContext context) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateClassPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final navAccent = _navAccentColors[_currentIndex];
    final navSurface = const Color(0xFF0F1C3F).withValues(alpha: 0.90);

    return Scaffold(
      appBar: _buildAppBar(),
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
