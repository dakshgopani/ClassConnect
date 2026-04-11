import 'package:flutter/material.dart';
import 'community/questions_list_screen.dart';
import 'community/ask_question_screen.dart';
import 'package:demo/screens/student/community/leaderboard_screen.dart';
import 'package:demo/widgets/ui/cc_decorated_background.dart';

class StudentCommunityPage extends StatelessWidget {
  const StudentCommunityPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      body: CcDecoratedBackground(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // const Text(
              //   "🌍 Community",
              //   style: TextStyle(
              //     fontSize: 26,
              //     fontWeight: FontWeight.bold,
              //     color: Colors.white,
              //   ),
              // ),
              const SizedBox(height: 8),

              const Text(
                "Discussion, doubts, and announcements.",
                style: TextStyle(color: Color(0xFF5C6B8C)),
              ),

              const SizedBox(height: 30),

              // 🏆 Leaderboard Button
              _card(
                icon: Icons.leaderboard,
                title: "Leaderboard",
                subtitle: "View student rankings & stats",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const LeaderboardScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // ✅ ASK QUESTION (old /ask-question)
              _card(
                icon: Icons.edit,
                title: "Ask a Question",
                subtitle: "Post your doubt to the community",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AskQuestionScreen(),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // ✅ VIEW QUESTIONS (old /questions)
              _card(
                icon: Icons.forum,
                title: "All Questions",
                subtitle: "Browse community discussions",
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          const QuestionsListScreen(showAppBar: true),
                    ),
                  );
                },
              ),

              const SizedBox(height: 16),

              // ✅ EXAMPLE DETAIL NAV (old /question-detail)
              // _card(
              //   icon: Icons.question_answer,
              //   title: "Open Sample Question",
              //   subtitle: "Navigate to a question detail",
              //   onTap: () {
              //     Navigator.push(
              //       context,
              //       MaterialPageRoute(
              //         builder: (_) =>
              //             QuestionDetailScreen(questionId: "sample_id"),
              //       ),
              //     );
              //   },
              // ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0x1A2E6BFF)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF2E6BFF), size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF0D1B3D),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Color(0xFF5C6B8C)),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Color(0xFF7A89A8),
            ),
          ],
        ),
      ),
    );
  }
}
