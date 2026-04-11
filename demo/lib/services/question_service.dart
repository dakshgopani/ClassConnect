import 'package:demo/models/question.dart';
import 'package:demo/models/answer.dart';
import 'package:demo/models/tag.dart';
import 'package:demo/models/reaction.dart';

/// Service to manage all Q&A operations
class QuestionService {
  static final QuestionService _instance = QuestionService._internal();

  factory QuestionService() {
    return _instance;
  }

  QuestionService._internal();

  // Mock data storage
  final List<Question> _questions = [];
  final Map<String, List<Answer>> _answers = {};

  /// Initialize with mock data
  void initialize() {
    _generateMockData();
  }

  /// Get all questions sorted by creation date (newest first)
  List<Question> getAllQuestions() {
    return _questions..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  /// Get a specific question by ID
  Question? getQuestionById(String id) {
    try {
      return _questions.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get all answers for a specific question
  List<Answer> getAnswersForQuestion(String questionId) {
    return _answers[questionId] ?? [];
  }

  /// Add a new question
  Question addQuestion({
    required String userId,
    required String userName,
    required String userAvatar,
    required String title,
    required String description,
    required List<Tag> tags,
  }) {
    final question = Question(
      id: 'q_${DateTime.now().millisecondsSinceEpoch}',
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      title: title,
      description: description,
      tags: tags,
      createdAt: DateTime.now(),
      answerCount: 0,
    );

    _questions.add(question);
    _answers[question.id] = [];

    return question;
  }

  /// Add an answer to a question
  Answer addAnswer({
    required String questionId,
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
  }) {
    final answer = Answer(
      id: 'a_${DateTime.now().millisecondsSinceEpoch}',
      questionId: questionId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      createdAt: DateTime.now(),
    );

    if (!_answers.containsKey(questionId)) {
      _answers[questionId] = [];
    }

    _answers[questionId]!.add(answer);

    // Update answer count on question
    final question = getQuestionById(questionId);
    if (question != null) {
      final index = _questions.indexOf(question);
      _questions[index] = Question(
        id: question.id,
        userId: question.userId,
        userName: question.userName,
        userAvatar: question.userAvatar,
        title: question.title,
        description: question.description,
        tags: question.tags,
        createdAt: question.createdAt,
        updatedAt: question.updatedAt,
        reactions: question.reactions,
        views: question.views,
        answerCount: _answers[questionId]?.length ?? 0,
      );
    }

    return answer;
  }

  /// Add a reaction to a question
  void addReactionToQuestion(
    String questionId,
    String userId,
    ReactionType type,
  ) {
    final question = getQuestionById(questionId);
    if (question != null) {
      final index = _questions.indexOf(question);
      final reaction = Reaction(
        id: 'r_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: type,
        createdAt: DateTime.now(),
      );

      final updatedReactions = [...question.reactions, reaction];
      _questions[index] = Question(
        id: question.id,
        userId: question.userId,
        userName: question.userName,
        userAvatar: question.userAvatar,
        title: question.title,
        description: question.description,
        tags: question.tags,
        createdAt: question.createdAt,
        updatedAt: question.updatedAt,
        reactions: updatedReactions,
        views: question.views,
        answerCount: question.answerCount,
      );
    }
  }

  /// Remove a reaction from a question
  void removeReactionFromQuestion(
    String questionId,
    String userId,
    ReactionType type,
  ) {
    final question = getQuestionById(questionId);
    if (question != null) {
      final index = _questions.indexOf(question);
      final updatedReactions = question.reactions
          .where((r) => !(r.userId == userId && r.type == type))
          .toList();

      _questions[index] = Question(
        id: question.id,
        userId: question.userId,
        userName: question.userName,
        userAvatar: question.userAvatar,
        title: question.title,
        description: question.description,
        tags: question.tags,
        createdAt: question.createdAt,
        updatedAt: question.updatedAt,
        reactions: updatedReactions,
        views: question.views,
        answerCount: question.answerCount,
      );
    }
  }

  /// Add a reaction to an answer
  void addReactionToAnswer(String answerId, String userId, ReactionType type) {
    for (var answerList in _answers.values) {
      try {
        final answer = answerList.firstWhere((a) => a.id == answerId);
        final index = answerList.indexOf(answer);

        final reaction = Reaction(
          id: 'r_${DateTime.now().millisecondsSinceEpoch}',
          userId: userId,
          type: type,
          createdAt: DateTime.now(),
        );

        final updatedReactions = [...answer.reactions, reaction];
        answerList[index] = Answer(
          id: answer.id,
          questionId: answer.questionId,
          userId: answer.userId,
          userName: answer.userName,
          userAvatar: answer.userAvatar,
          content: answer.content,
          createdAt: answer.createdAt,
          updatedAt: answer.updatedAt,
          reactions: updatedReactions,
          views: answer.views,
        );
        break;
      } catch (e) {
        // Answer not found in this list, continue
      }
    }
  }

  /// Remove a reaction from an answer
  void removeReactionFromAnswer(
    String answerId,
    String userId,
    ReactionType type,
  ) {
    for (var answerList in _answers.values) {
      try {
        final answer = answerList.firstWhere((a) => a.id == answerId);
        final index = answerList.indexOf(answer);

        final updatedReactions = answer.reactions
            .where((r) => !(r.userId == userId && r.type == type))
            .toList();

        answerList[index] = Answer(
          id: answer.id,
          questionId: answer.questionId,
          userId: answer.userId,
          userName: answer.userName,
          userAvatar: answer.userAvatar,
          content: answer.content,
          createdAt: answer.createdAt,
          updatedAt: answer.updatedAt,
          reactions: updatedReactions,
          views: answer.views,
        );
        break;
      } catch (e) {
        // Answer not found in this list, continue
      }
    }
  }

  /// Increment view count for a question
  void incrementQuestionViews(String questionId) {
    final question = getQuestionById(questionId);
    if (question != null) {
      final index = _questions.indexOf(question);
      _questions[index] = Question(
        id: question.id,
        userId: question.userId,
        userName: question.userName,
        userAvatar: question.userAvatar,
        title: question.title,
        description: question.description,
        tags: question.tags,
        createdAt: question.createdAt,
        updatedAt: question.updatedAt,
        reactions: question.reactions,
        views: question.views + 1,
        answerCount: question.answerCount,
      );
    }
  }

  /// Search questions by title or description
  List<Question> searchQuestions(String query) {
    return _questions.where((q) {
      return q.title.toLowerCase().contains(query.toLowerCase()) ||
          q.description.toLowerCase().contains(query.toLowerCase());
    }).toList();
  }

  /// Filter questions by tag
  List<Question> filterByTag(String tagName) {
    return _questions
        .where((q) => q.tags.any((t) => t.name == tagName))
        .toList();
  }

  /// Generate mock data for demonstration
  void _generateMockData() {
    final tags = [
      Tag(id: 't1', name: 'Flutter', color: '#42A5F5'),
      Tag(id: 't2', name: 'Dart', color: '#AB47BC'),
      Tag(id: 't3', name: 'UI/UX', color: '#66BB6A'),
      Tag(id: 't4', name: 'Database', color: '#FFA726'),
      Tag(id: 't5', name: 'API', color: '#EC407A'),
    ];

    // Add sample questions
    final q1 = Question(
      id: 'q1',
      userId: 'user1',
      userName: 'Alice Johnson',
      userAvatar: '👩‍💻',
      title: 'How to properly use StatefulWidget in Flutter?',
      description:
          'I\'m trying to understand the difference between StatefulWidget and StatelessWidget. When should I use each one? Also, how does the lifecycle work?',
      tags: [tags[0], tags[1]],
      createdAt: DateTime.now().subtract(const Duration(days: 2)),
      answerCount: 3,
    );

    final q2 = Question(
      id: 'q2',
      userId: 'user2',
      userName: 'Bob Smith',
      userAvatar: '👨‍💻',
      title: 'Best practices for API integration in Flutter',
      description:
          'What are the best practices for handling API calls in Flutter? Should I use Provider, GetX, or Riverpod for state management?',
      tags: [tags[0], tags[4]],
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      answerCount: 5,
    );

    final q3 = Question(
      id: 'q3',
      userId: 'user3',
      userName: 'Carol White',
      userAvatar: '👩‍🔬',
      title: 'Database optimization tips for mobile apps',
      description:
          'I\'m experiencing slow database queries in my mobile app. What are some optimization techniques I can use?',
      tags: [tags[3], tags[0]],
      createdAt: DateTime.now().subtract(const Duration(hours: 12)),
      answerCount: 2,
    );

    final q4 = Question(
      id: 'q4',
      userId: 'user4',
      userName: 'David Brown',
      userAvatar: '👨‍🎨',
      title: 'Creating responsive layouts in Flutter',
      description:
          'How can I create responsive layouts that work well on both phones and tablets? Are there any packages that help?',
      tags: [tags[0], tags[2]],
      createdAt: DateTime.now().subtract(const Duration(hours: 6)),
      answerCount: 4,
    );

    _questions.addAll([q1, q2, q3, q4]);

    // Add sample answers
    _answers['q1'] = [
      Answer(
        id: 'a1',
        questionId: 'q1',
        userId: 'user2',
        userName: 'Bob Smith',
        userAvatar: '👨‍💻',
        content:
            'StatefulWidget is used when your widget needs to maintain mutable state. StatelessWidget is immutable and suitable for static content. The lifecycle includes createState(), build(), and setState() for updates.',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 20)),
        reactions: [
          Reaction(
            id: 'r1',
            userId: 'user5',
            type: ReactionType.like,
            createdAt: DateTime.now(),
          ),
          Reaction(
            id: 'r2',
            userId: 'user6',
            type: ReactionType.heart,
            createdAt: DateTime.now(),
          ),
        ],
      ),
      Answer(
        id: 'a2',
        questionId: 'q1',
        userId: 'user3',
        userName: 'Carol White',
        userAvatar: '👩‍🔬',
        content:
            'Also consider using StreamBuilder or FutureBuilder for handling asynchronous data in StatelessWidget. It\'s often cleaner than managing state manually.',
        createdAt: DateTime.now().subtract(const Duration(days: 1, hours: 10)),
        reactions: [
          Reaction(
            id: 'r3',
            userId: 'user5',
            type: ReactionType.like,
            createdAt: DateTime.now(),
          ),
        ],
      ),
    ];

    _answers['q2'] = [
      Answer(
        id: 'a3',
        questionId: 'q2',
        userId: 'user1',
        userName: 'Alice Johnson',
        userAvatar: '👩‍💻',
        content:
            'Provider is great for most use cases and is backed by the Flutter team. It\'s simple to learn and very powerful once you understand the basics.',
        createdAt: DateTime.now().subtract(const Duration(hours: 22)),
        reactions: [],
      ),
    ];

    _answers['q3'] = [];
    _answers['q4'] = [];
  }
}
