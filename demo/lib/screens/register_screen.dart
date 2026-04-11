import 'dart:ui';

import 'package:demo/screens/parent_details_screen.dart';
import 'package:demo/screens/student_home.dart';
import 'package:demo/screens/teacher_details_screen.dart';
import 'package:demo/screens/teacher_home.dart';
import 'package:demo/services/auth_service.dart';
import 'package:demo/widgets/ui/cc_button.dart';
import 'package:demo/widgets/ui/cc_text_field.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final AuthService _auth = AuthService();

  bool isLoading = false;
  bool isGoogleLoading = false;
  String _selectedRole = 'student';

  static const String _backgroundImage =
      'assets/images/2cd3b578-1dbc-4ce1-bd31-c09c896021c51.jpg';

  static const Color _ink = Color(0xFF0D1B3D);
  static const Color _accent = Color(0xFF2E6BFF);
  static const Color _student = Color(0xFF3A7BFF);
  static const Color _teacher = Color(0xFF1FB58E);

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
                    const Color(0xFF060F26).withValues(alpha: 0.74),
                    const Color(0xFF0B1B43).withValues(alpha: 0.92),
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
                            _buildRegisterCard(),
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
            IconButton(
              onPressed: () => Navigator.pop(context),
              style: IconButton.styleFrom(
                backgroundColor: Colors.white.withValues(alpha: 0.2),
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.arrow_back_rounded),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Create New Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                      letterSpacing: 0.1,
                    ),
                  ),
                  Text(
                    'Choose your role and continue',
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

  Widget _buildRegisterCard() {
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
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.5),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.18),
                  blurRadius: 26,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: const Text(
                    'SIGN UP',
                    style: TextStyle(
                      color: _accent,
                      fontWeight: FontWeight.w800,
                      fontSize: 10,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Text(
                      'Google Sign-Up',
                      style: TextStyle(
                        fontSize: 15,
                        color: _ink,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.15,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _accent.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Fast Setup',
                        style: TextStyle(
                          color: _accent,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  'Select a role before continuing with Google',
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                _RoleSelector(
                  selectedRole: _selectedRole,
                  studentColor: _student,
                  teacherColor: _teacher,
                  onRoleChanged: (role) {
                    setState(() => _selectedRole = role);
                  },
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [_ink, const Color(0xFF1A326A)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _ink.withValues(alpha: 0.28),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.transparent,
                        shadowColor: Colors.transparent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: isGoogleLoading ? null : _registerWithGoogle,
                      child: isGoogleLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Image.asset(
                                  'assets/icons/google_icon.png',
                                  height: 16,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Continue with Google ($_selectedRole)',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
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
                Text(
                  'Create with email',
                  style: TextStyle(
                    color: Colors.grey[800],
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
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
                  helperText: 'Minimum 6 characters',
                ),
                const SizedBox(height: 12),
                CcButton(
                  label: 'Sign Up',
                  isLoading: isLoading,
                  onPressed: _registerUser,
                ),
                const SizedBox(height: 4),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Already have an account? Login',
                      style: TextStyle(
                        color: _accent,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
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

  Future<void> _registerWithGoogle() async {
    setState(() => isGoogleLoading = true);

    try {
      final user = await _auth.signInWithGoogle(role: _selectedRole);

      if (!mounted || user == null) {
        return;
      }

      if (_selectedRole == 'student') {
        final hasParentDetails = await _auth.isParentDetailsFilled(user.uid);

        if (!mounted) {
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
            MaterialPageRoute(
              builder: (_) => ParentDetailsScreen(uid: user.uid),
            ),
          );
        }
      } else {
        final hasTeacherDetails = await _auth.isTeacherDetailsFilled(user.uid);

        if (!mounted) {
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
            MaterialPageRoute(
              builder: (_) => TeacherDetailsScreen(uid: user.uid),
            ),
          );
        }
      }
    } finally {
      if (mounted) {
        setState(() => isGoogleLoading = false);
      }
    }
  }

  Future<void> _registerUser() async {
    if (emailController.text.isEmpty || passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid email and password')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = await _auth.registerWithEmail(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) {
        return;
      }

      if (user != null) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Registration failed')));
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
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

class _RoleSelector extends StatelessWidget {
  const _RoleSelector({
    required this.selectedRole,
    required this.studentColor,
    required this.teacherColor,
    required this.onRoleChanged,
  });

  final String selectedRole;
  final Color studentColor;
  final Color teacherColor;
  final ValueChanged<String> onRoleChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withValues(alpha: 0.85),
        border: Border.all(color: Colors.grey.shade300, width: 1.1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _RoleRadioTile(
              title: 'Student',
              value: 'student',
              selectedValue: selectedRole,
              color: studentColor,
              icon: Icons.school_rounded,
              onChanged: onRoleChanged,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _RoleRadioTile(
              title: 'Teacher',
              value: 'teacher',
              selectedValue: selectedRole,
              color: teacherColor,
              icon: Icons.co_present_rounded,
              onChanged: onRoleChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _RoleRadioTile extends StatelessWidget {
  const _RoleRadioTile({
    required this.title,
    required this.value,
    required this.selectedValue,
    required this.color,
    required this.icon,
    required this.onChanged,
  });

  final String title;
  final String value;
  final String selectedValue;
  final Color color;
  final IconData icon;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selectedValue;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? color.withValues(alpha: 0.12) : Colors.white,
          border: Border.all(
            color: isSelected
                ? color.withValues(alpha: 0.45)
                : Colors.grey.shade300,
            width: 1.1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? color : Colors.grey.shade500,
                  width: 2,
                ),
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? color : Colors.transparent,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Icon(icon, size: 17, color: isSelected ? color : Colors.grey[700]),
            const SizedBox(width: 5),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? color : Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
