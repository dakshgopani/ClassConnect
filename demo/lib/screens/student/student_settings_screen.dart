import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:demo/services/auth_service.dart';
import 'package:demo/widgets/ui/cc_button.dart';
import 'package:demo/widgets/ui/cc_card.dart';
import 'package:demo/widgets/ui/cc_decorated_background.dart';
import 'package:demo/widgets/ui/cc_section_header.dart';

class StudentSettingsScreen extends StatefulWidget {
  const StudentSettingsScreen({super.key});

  @override
  State<StudentSettingsScreen> createState() => _StudentSettingsScreenState();
}

class _StudentSettingsScreenState extends State<StudentSettingsScreen> {
  final AuthService _auth = AuthService();
  final User? user = FirebaseAuth.instance.currentUser;

  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      body: CcDecoratedBackground(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Profile Section
            const CcSectionHeader(
              title: 'Profile',
              subtitle: 'Manage your account details',
            ),
            const SizedBox(height: 12),
            CcCard(
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.blueAccent,
                    backgroundImage: user?.photoURL != null
                        ? NetworkImage(user!.photoURL!)
                        : null,
                    child: user?.photoURL == null
                        ? Text(
                            (user?.displayName ?? "S")[0].toUpperCase(),
                            style: const TextStyle(
                              fontSize: 24,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.displayName ?? "Student Name",
                          style: const TextStyle(
                            color: Color(0xFF0D1B3D),
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          user?.email ?? "student@example.com",
                          style: const TextStyle(
                            color: Color(0xFF5C6B8C),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Color(0xFF5C6B8C)),
                    onPressed: () {
                      // Navigate to edit profile or show dialog
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text("Edit Profile feature coming soon!"),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 30),

            // Account Settings
            const CcSectionHeader(
              title: 'Account Settings',
              subtitle: 'Update preferences and security',
            ),
            _buildSettingsTile(
              icon: Icons.lock_outline,
              title: "Change Password",
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Password reset email sent!")),
                );
              },
            ),
            _buildSwitchTile(
              icon: Icons.notifications_none,
              title: "Push Notifications",
              value: _notificationsEnabled,
              onChanged: (val) {
                setState(() => _notificationsEnabled = val);
              },
            ),
            _buildSettingsTile(
              icon: Icons.language,
              title: "Language",
              subtitle: "English",
              onTap: () {},
            ),

            const SizedBox(height: 30),

            // Support & About
            const CcSectionHeader(
              title: 'Support',
              subtitle: 'Help and app information',
            ),
            _buildSettingsTile(
              icon: Icons.help_outline,
              title: "Help Center",
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.info_outline,
              title: "About App",
              onTap: () {},
            ),
            _buildSettingsTile(
              icon: Icons.privacy_tip_outlined,
              title: "Privacy Policy",
              onTap: () {},
            ),

            const SizedBox(height: 40),

            // Logout Button
            CcButton(
              label: 'Sign Out',
              variant: CcButtonVariant.ghost,
              icon: const Icon(Icons.logout_rounded, size: 18),
              onPressed: () async {
                await _auth.signOut();
              },
            ),

            const SizedBox(height: 20),
            const Center(
              child: Text(
                "Version 1.0.0",
                style: TextStyle(color: Color(0xFF7A89A8), fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A2E6BFF)),
      ),
      child: ListTile(
        leading: Icon(icon, color: const Color(0xFF2E6BFF)),
        title: Text(title, style: const TextStyle(color: Color(0xFF0D1B3D))),
        subtitle: subtitle != null
            ? Text(subtitle, style: const TextStyle(color: Color(0xFF5C6B8C)))
            : null,
        trailing: const Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Color(0xFF7A89A8),
        ),
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0x1A2E6BFF)),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: const Color(0xFF2E6BFF)),
        title: Text(title, style: const TextStyle(color: Color(0xFF0D1B3D))),
        value: value,
        onChanged: onChanged,
        activeColor: const Color(0xFF2E6BFF),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
