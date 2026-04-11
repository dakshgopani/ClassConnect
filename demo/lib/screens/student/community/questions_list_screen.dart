import 'package:demo/screens/student/community/leaderboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:demo/services/firestore_service.dart';
import 'package:demo/models/question.dart';
import 'package:demo/models/reaction.dart';
import 'package:demo/widgets/question_card.dart';
import 'package:demo/widgets/common_widgets.dart';
import 'package:demo/widgets/ui/cc_decorated_background.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'question_detail_screen.dart';
import 'ask_question_screen.dart';

class QuestionsListScreen extends StatefulWidget {
  final bool showAppBar;

  const QuestionsListScreen({super.key, this.showAppBar = false});

  @override
  State<QuestionsListScreen> createState() => _QuestionsListScreenState();
}

class _QuestionsListScreenState extends State<QuestionsListScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();
  late final String _currentUserId;
  List<Question>? _searchResults;

  void _searchQuestions(String query) async {
    if (query.isEmpty) {
      setState(() {
        _searchResults = null;
      });
    } else {
      final results = await _firestoreService.searchQuestions(query);
      setState(() {
        _searchResults = results;
      });
    }
  }

  void _onQuestionReaction(Question question, ReactionType type) {
    final hasReaction = question.reactions.any(
      (r) => r.userId == _currentUserId && r.type == type,
    );

    if (hasReaction) {
      _firestoreService.removeReactionFromQuestion(
        question.id,
        _currentUserId,
        type,
      );
    } else {
      _firestoreService.addReactionToQuestion(
        question.id,
        _currentUserId,
        type,
      );
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: widget.showAppBar
          ? AppBar(
              backgroundColor: const Color(0xFFF4F8FF),
              elevation: 0,
              foregroundColor: const Color(0xFF0D1B3D),
              title: const Text(
                'Community Questions',
                style: TextStyle(
                  color: Color(0xFF0D1B3D),
                  fontWeight: FontWeight.w700,
                ),
              ),
            )
          : null,
      // appBar: AppBar(
      //   title: const Text('Questions', style: TextStyle(color: Colors.white)),
      //   backgroundColor: const Color(0xFFF4F8FF),
      //   elevation: 0,
      //   centerTitle: true,
      //   leading: IconButton(
      //     icon: const Icon(
      //       Icons.arrow_back_ios_new_rounded,
      //     ), // Modern rounded back icon
      //     color: Colors.white, // Matching your Cyan accent
      //     onPressed: () {
      //       if (Navigator.canPop(context)) {
      //         Navigator.pop(context);
      //       }
      //     },
      //   ),
      // ),
      body: CcDecoratedBackground(
        child: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: SearchBar(
                controller: _searchController,
                onChanged: _searchQuestions,
                backgroundColor: MaterialStateProperty.all(Colors.white),
                surfaceTintColor: MaterialStateProperty.all(Colors.white),
                shadowColor: MaterialStateProperty.all(const Color(0x1A2E6BFF)),
                leading: const Icon(Icons.search, color: Color(0xFF5C6B8C)),
                hintText: 'Search questions...',
                hintStyle: MaterialStateProperty.all(
                  const TextStyle(color: Color(0xFF7A89A8)),
                ),
                textStyle: MaterialStateProperty.all(
                  const TextStyle(color: Color(0xFF0D1B3D)),
                ),
                trailing: [
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.clear, color: Color(0xFF5C6B8C)),
                      onPressed: () {
                        _searchController.clear();
                        _searchQuestions('');
                      },
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.leaderboard_rounded,
                      label: 'Leaderboard',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LeaderboardScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _QuickActionCard(
                      icon: Icons.add_circle_outline_rounded,
                      label: 'Ask Question',
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AskQuestionScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Questions list
            Expanded(
              child: _searchResults != null
                  ? _buildQuestionsList(_searchResults!)
                  : StreamBuilder<List<Question>>(
                      stream: _firestoreService.getQuestionsStream(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }

                        if (snapshot.hasError) {
                          return EmptyStateWidget(
                            title: 'Error',
                            message:
                                'Failed to load questions: ${snapshot.error}',
                            icon: Icons.error_outline,
                          );
                        }

                        final questions = snapshot.data ?? [];
                        return _buildQuestionsList(questions);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsList(List<Question> questions) {
    if (questions.isEmpty) {
      return EmptyStateWidget(
        title: 'No Questions',
        message: _searchController.text.isEmpty
            ? 'No questions yet. Be the first to ask!'
            : 'No questions match your search.',
        icon: Icons.help_outline,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 110),
      itemCount: questions.length,
      itemBuilder: (context, index) {
        final question = questions[index];
        return QuestionCard(
          question: question,
          onTap: () {
            _firestoreService.incrementQuestionViews(question.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuestionDetailScreen(questionId: question.id),
              ),
            );
          },
          currentUserId: _currentUserId,
          onReaction: (type) => _onQuestionReaction(question, type),
        );
      },
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0x1A2E6BFF)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: const Color(0xFF2E6BFF)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0D1B3D),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
