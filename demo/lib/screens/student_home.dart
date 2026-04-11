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
  Widget build(BuildContext context) {
    final navAccent = _navAccentColors[_currentIndex];
    final navSurface = const Color(0xFF0F1C3F).withValues(alpha: 0.90);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),

      // 🔹 APP BAR
      appBar: AppBar(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          _getTitle(),
          style: const TextStyle(
            color: Color(0xFF0D1B3D),
            fontWeight: FontWeight
                .w600, // Optional: adds boldness for better visibility
          ),
        ),
        backgroundColor: const Color(0xFFF4F8FF),
        actions: [
          // 👇 3-dot menu only on "My Classes"
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

          // 👇 Logout only in Settings tab
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
