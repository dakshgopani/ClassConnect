import 'package:demo/screens/student/community/questions_list_screen.dart';
import 'package:demo/screens/student/student_activity_screen.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:demo/services/auth_service.dart';
import 'package:demo/services/class_service.dart';
import 'student/student_class_screen.dart';
import 'package:demo/screens/student/student_settings_screen.dart';
import 'package:demo/theme/app_radius.dart';
import 'package:demo/widgets/ui/cc_dialog.dart';
import 'package:demo/widgets/ui/cc_floating_nav_item.dart';
import 'package:demo/widgets/ui/cc_text_field.dart';
import 'package:demo/main.dart'; // for AuthWrapper
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo/utils/responsive_breakpoints.dart';

class StudentHome extends StatefulWidget {
  const StudentHome({super.key});

  @override
  State<StudentHome> createState() => _StudentHomeState();
}

class _StudentHomeState extends State<StudentHome> {
  int _currentIndex = 0;

  static const List<Color> _navAccentColors = [
    Color(0xFF2E6BFF),
    Color(0xFF2E6BFF),
    Color(0xFF2E6BFF),
    Color(0xFF2E6BFF),
  ];

  final AuthService _auth = AuthService();
  final ClassService _classService = ClassService();

  // Pages for bottom navigation
  final List<Widget> _pages = const [
    StudentActivityScreen(),
    // StudentPblScreen(),
    StudentClassesPage(),
    QuestionsListScreen(),
    StudentSettingsScreen(),
  ];

  // Dynamic AppBar title
  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return "Class Activity";
      // case 1:
      //   return "PBL";
      case 1:
        return "My Classes";
      case 2:
        return "Community";
      case 3:
        return "Settings";
      default:
        return "Student";
    }
  }

  // ================= JOIN CLASS =================

  Future<void> _joinClassByCode(String code) async {
    try {
      await _classService.joinClassByCode(code);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Joined class successfully")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      }
    }
  }

  Future<void> _showJoinClassDialog() async {
    final TextEditingController codeController = TextEditingController();

    await showCcDialog(
      context: context,
      title: 'Join Class',
      content: CcTextField(
        controller: codeController,
        label: 'Enter 6-digit class code',
        icon: Icons.key_rounded,
        maxLength: 6,
        textCapitalization: TextCapitalization.characters,
        onChanged: (value) {
          if (value != value.toUpperCase()) {
            codeController.value = TextEditingValue(
              text: value.toUpperCase(),
              selection: TextSelection.collapsed(offset: value.length),
            );
          }
        },
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            final code = codeController.text.trim();
            if (code.length != 6) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Please enter a valid 6-digit code'),
                ),
              );
              return;
            }

            Navigator.pop(context);
            await _joinClassByCode(code);
          },
          child: const Text('Join'),
        ),
      ],
    );

    codeController.dispose();
  }

  // ================= UI =================

  @override
  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (isDesktop) {
      return _buildDesktopLayout();
    }

    return _buildMobileLayout();
  }

  Widget _buildDesktopLayout() {
    final width = MediaQuery.of(context).size.width;
    final sidebarWidth = width < 1050 ? 230.0 : 260.0;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Row(
        children: [
          _buildSidebar(sidebarWidth),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _pages[_currentIndex]),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(double width) {
    return Container(
      width: width,
      height: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF1E293B),
            Color(0xFF0F172A),
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
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF2563EB), Color(0xFF38BDF8)],
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
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: const Color(0xFF38BDF8).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text(
              'Student Portal',
              style: TextStyle(
                color: Color(0xFF38BDF8),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebarNavItems() {
    final navItems = [
      {'icon': Icons.insights_rounded, 'label': 'Activity Feed'},
      {'icon': Icons.class_rounded, 'label': 'My Classes'},
      {'icon': Icons.groups_rounded, 'label': 'Community'},
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
              ? const Color(0xFF2E6BFF).withValues(alpha: 0.16)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF2E6BFF)
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
                  color: selected ? Colors.white : const Color(0xFF94A3B8),
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
                  color: Color(0xFF2E6BFF),
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
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(
            color: Color(0xFF334155),
            width: 1,
          ),
        ),
      ),
      child: InkWell(
        onTap: () async {
          final navigator = Navigator.of(context);
          await _auth.signOut();
          if (!mounted) return;
          navigator.pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
        },
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
    const subtitles = [
      'Real-time updates, announcements, and assignments from your courses',
      'Manage enrolled courses, syllabi, and class resources',
      'Peer discussions, questions, and academic collaborations',
      'Manage account preferences and profile information',
    ];

    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: Color(0xFFE2E8F0), width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _getTitle(),
                  style: const TextStyle(
                    color: Color(0xFF0D1B3D),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitles[_currentIndex],
                  style: const TextStyle(
                    color: Color(0xFF64748B),
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton.icon(
            onPressed: _showJoinClassDialog,
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Join Class'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2E6BFF),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(
                horizontal: 18,
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
    );
  }

  Widget _buildUserProfile() {
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? 'Student';
    final initial = email.isNotEmpty ? email[0].toUpperCase() : 'S';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: const Color(0xFF2E6BFF),
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            email.split('@').first,
            style: const TextStyle(
              color: Color(0xFF1E293B),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout() {
    final navAccent = _navAccentColors[_currentIndex];
    final navSurface = const Color(0xFF0F1C3F).withValues(alpha: 0.90);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _getTitle(),
          style: const TextStyle(
            color: Color(0xFF0D1B3D),
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        actions: [
          if (_currentIndex == 1)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF0D1B3D)),
              onSelected: (value) {
                if (value == 'join') {
                  Future<void>.microtask(_showJoinClassDialog);
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'join', child: Text('Join Class')),
              ],
            ),
          if (_currentIndex == 3)
            IconButton(
              icon: const Icon(Icons.logout, color: Color(0xFF0D1B3D)),
              onPressed: () async {
                final navigator = Navigator.of(context);
                await _auth.signOut();
                if (!mounted) return;
                navigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const AuthWrapper()),
                  (route) => false,
                );
              },
            ),
        ],
      ),
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
                            icon: Icons.insights_rounded,
                            label: "Activity",
                            selected: _currentIndex == 0,
                            onTap: () => setState(() => _currentIndex = 0),
                          ),
                          _FloatingNavItem(
                            icon: Icons.class_rounded,
                            label: "Classes",
                            selected: _currentIndex == 1,
                            onTap: () => setState(() => _currentIndex = 1),
                          ),
                          _FloatingNavItem(
                            icon: Icons.groups_rounded,
                            label: "Community",
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
