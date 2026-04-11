import 'dart:ui';

import 'package:demo/screens/parent_details_screen.dart';
import 'package:demo/screens/teacher_details_screen.dart';
import 'package:demo/services/auth_service.dart';
import 'package:demo/widgets/ui/cc_button.dart';
import 'package:demo/widgets/ui/cc_text_field.dart';
import 'package:flutter/material.dart';
import 'package:demo/screens/student_home.dart';
import 'package:demo/screens/teacher_home.dart';

class LoginScreen extends StatelessWidget {
  LoginScreen({super.key});

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _auth = AuthService();

  static const String _backgroundImage =
      'assets/images/2cd3b578-1dbc-4ce1-bd31-c09c896021c51.jpg';

  static const Color _ink = Color(0xFF0D1B3D);
  static const Color _accent = Color(0xFF2E6BFF);
  static const Color _student = Color(0xFF3A7BFF);
  static const Color _teacher = Color(0xFF1FB58E);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(_backgroundImage, fit: BoxFit.cover),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF060F26).withValues(alpha: 0.72),
                    const Color(0xFF0B1B43).withValues(alpha: 0.9),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            left: -50,
            top: -40,
            child: _GlowBlob(
              size: 190,
              color: const Color(0xFF77A7FF).withValues(alpha: 0.25),
            ),
          ),
          Positioned(
            right: -56,
            bottom: -28,
            child: _GlowBlob(
              size: 210,
              color: const Color(0xFF5CF0C3).withValues(alpha: 0.2),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            _buildHeroHeader(),
                            const SizedBox(height: 12),
                            _buildAuthCard(context),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroHeader() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 450),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 12),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.17),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.32),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Image.asset(
                  'assets/icons/logo.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                      letterSpacing: 0.1,
                    ),
                  ),
                  Text(
                    'Adaptive mastery starts here',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
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

  Widget _buildAuthCard(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 560),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, (1 - value) * 20),
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 24,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Text(
                      'Google Sign-In',
                      style: TextStyle(
                        fontSize: 14,
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'One Tap',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _GoogleRoleButton(
                  title: 'Continue as Student',
                  subtitle: 'Class feed, quizzes, community',
                  icon: Icons.school_rounded,
                  color: _student,
                  onTap: () => _handleStudentGoogleLogin(context),
                ),
                const SizedBox(height: 8),
                _GoogleRoleButton(
                  title: 'Continue as Teacher',
                  subtitle: 'Dashboard, classes, workload',
                  icon: Icons.co_present_rounded,
                  color: _teacher,
                  onTap: () => _handleTeacherGoogleLogin(context),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Divider(color: Colors.grey[350], thickness: 1),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        'OR WITH EMAIL',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Divider(color: Colors.grey[350], thickness: 1),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CcTextField(
                  controller: emailController,
                  label: 'Email',
                  icon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 9),
                CcTextField(
                  controller: passwordController,
                  label: 'Password',
                  icon: Icons.lock_outline_rounded,
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                CcButton(
                  label: 'Login',
                  onPressed: () async {
                    await _auth.signInWithEmail(
                      emailController.text.trim(),
                      passwordController.text.trim(),
                    );
                  },
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: RichText(
                      text: TextSpan(
                        text: 'New user? ',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        children: const [
                          TextSpan(
                            text: 'Create an account',
                            style: TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.w800,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handleStudentGoogleLogin(BuildContext context) async {
    final user = await _auth.signInWithGoogle(role: 'student');

    if (!context.mounted || user == null) {
      return;
    }

    final hasParentDetails = await _auth.isParentDetailsFilled(user.uid);

    if (!context.mounted) {
      return;
    }

    if (hasParentDetails) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => StudentHome()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => ParentDetailsScreen(uid: user.uid)),
      );
    }
  }

  Future<void> _handleTeacherGoogleLogin(BuildContext context) async {
    final user = await _auth.signInWithGoogle(role: 'teacher');

    if (!context.mounted || user == null) {
      return;
    }

    final hasTeacherDetails = await _auth.isTeacherDetailsFilled(user.uid);

    if (!context.mounted) {
      return;
    }

    if (hasTeacherDetails) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TeacherHome()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => TeacherDetailsScreen(uid: user.uid)),
      );
    }
  }
}

class _GlowBlob extends StatelessWidget {
  const _GlowBlob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color, Colors.transparent]),
        ),
      ),
    );
  }
}

class _GoogleRoleButton extends StatelessWidget {
  const _GoogleRoleButton({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color.withValues(alpha: 0.2), color.withValues(alpha: 0.08)],
        ),
        border: Border.all(color: color.withValues(alpha: 0.28), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.16),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: LoginScreen._ink,
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 10.5,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Image.asset('assets/icons/google_icon.png', height: 14),
                      const SizedBox(width: 5),
                      const Icon(
                        Icons.arrow_forward_rounded,
                        size: 14,
                        color: LoginScreen._ink,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
