import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/models/question.dart';
import 'package:demo/models/answer.dart';
import 'package:demo/models/tag.dart';
import 'package:demo/models/reaction.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service to handle all Firestore operations for community Q&A
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Hardcoded user ID as per requirement
  // static const String CURRENT_USER_ID = 'YHwoxbzYvcP3j3wYzm6J1XvLFfL2';

  // Collection references
  CollectionReference get _communityCollection =>
      _firestore.collection('community');

  CollectionReference get _studentsCollection =>
      _firestore.collection('students');

  /// Update user score
  /// Shifts the storage from global 'students' collection to 'class_leaderboard'
  /// Updates 'community_score' for the student in all classes they have joined.
  Future<void> updateUserScore(String userId, int points) async {
    try {
      // 0. Get User Data
      final userDoc = await _studentsCollection.doc(userId).get();
      String studentName = 'Student';
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        studentName = data['name'] ?? 'Student';
      }

      // 1. Find all classes the student has joined
      final classesSnapshot = await _firestore
          .collection('class_students')
          .where('studentId', isEqualTo: userId)
          .get();

      if (classesSnapshot.docs.isEmpty) return;

      final batch = _firestore.batch();

      // 2. Update 'community_score' in each class leaderboard
      for (var doc in classesSnapshot.docs) {
        final classId = doc['classId'] as String;
        final leaderboardRef = _firestore
            .collection('class_leaderboard')
            .doc(classId)
            .collection('students')
            .doc(userId);

        batch.set(leaderboardRef, {
          'community_score': FieldValue.increment(points),
          'studentId': userId,
          'studentName': studentName,
          'lastUpdated': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      await batch.commit();
    } catch (e) {
      print('Error updating user score: $e');
    }
  }

  /// Update user PBL Score (for academic achievements like PBL)
  Future<void> updateStudentPblScore(
    String userId,
    int points,
    String classId,
  ) async {
    try {
      // 0. Get User Data
      final userDoc = await _studentsCollection.doc(userId).get();
      String studentName = 'Student';
      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;
        studentName = data['name'] ?? 'Student';
      }

      final leaderboardRef = _firestore
          .collection('class_leaderboard')
          .doc(classId)
          .collection('students')
          .doc(userId);

      await leaderboardRef.set({
        'pbl_score': FieldValue.increment(points),
        'studentId': userId,
        'studentName': studentName,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      print('Error updating student PBL Score: $e');
    }
  }

  // ============= QUESTION OPERATIONS =============

  /// Get all questions from Firestore
  Stream<List<Question>> getQuestionsStream() {
    return _communityCollection
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            data['id'] = doc.id;
            return Question.fromJson(data);
          }).toList(),
        );
  }

  String get currentUserId {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    return user.uid;
  }

  /// Get a specific question by ID
  Future<Question?> getQuestionById(String questionId) async {
    try {
      final doc = await _communityCollection.doc(questionId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Question.fromJson(data);
      }
      return null;
    } catch (e) {
      print('Error getting question: $e');
      return null;
    }
  }

  /// Add a new question to Firestore
  Future<Question> addQuestion({
    required String userId,
    required String userName,
    required String userAvatar,
    required String title,
    required String description,
    required List<Tag> tags,
  }) async {
    final docRef = _communityCollection.doc();

    final question = Question(
      id: docRef.id,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      title: title,
      description: description,
      tags: tags,
      createdAt: DateTime.now(),
      answerCount: 0,
      views: 0,
    );

    await docRef.set(question.toJson());

    // +2 points for creating a post
    await updateUserScore(userId, 2);

    return question;
  }

  /// Increment question views
  Future<void> incrementQuestionViews(String questionId) async {
    try {
      await _communityCollection.doc(questionId).update({
        'views': FieldValue.increment(1),
      });
    } catch (e) {
      print('Error incrementing views: $e');
    }
  }

  /// Search questions
  Future<List<Question>> searchQuestions(String query) async {
    try {
      final snapshot = await _communityCollection.get();
      final questions = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        return Question.fromJson(data);
      }).toList();

      return questions.where((q) {
        return q.title.toLowerCase().contains(query.toLowerCase()) ||
            q.description.toLowerCase().contains(query.toLowerCase());
      }).toList();
    } catch (e) {
      print('Error searching questions: $e');
      return [];
    }
  }

  // ============= ANSWER OPERATIONS =============

  /// Get answers for a specific question
  Stream<List<Answer>> getAnswersStream(String questionId) {
    return _communityCollection
        .doc(questionId)
        .collection('answers')
        .orderBy('createdAt', descending: false)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs.map((doc) {
            final data = doc.data();
            data['id'] = doc.id;
            return Answer.fromJson(data);
          }).toList(),
        );
  }

  /// Add an answer to a question
  Future<Answer> addAnswer({
    required String questionId,
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
  }) async {
    final answerRef = _communityCollection
        .doc(questionId)
        .collection('answers')
        .doc();

    final answer = Answer(
      id: answerRef.id,
      questionId: questionId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      createdAt: DateTime.now(),
      views: 0,
    );

    // Add answer
    await answerRef.set(answer.toJson());

    // +1 point for adding a comment (answer)
    await updateUserScore(userId, 1);

    // Increment answer count on question
    await _communityCollection.doc(questionId).update({
      'answerCount': FieldValue.increment(1),
    });

    return answer;
  }

  /// Add a system/AI answer without affecting leaderboard score.
  Future<Answer> addSystemAnswer({
    required String questionId,
    required String userId,
    required String userName,
    required String userAvatar,
    required String content,
  }) async {
    final answerRef = _communityCollection
        .doc(questionId)
        .collection('answers')
        .doc();

    final answer = Answer(
      id: answerRef.id,
      questionId: questionId,
      userId: userId,
      userName: userName,
      userAvatar: userAvatar,
      content: content,
      createdAt: DateTime.now(),
      views: 0,
    );

    await answerRef.set(answer.toJson());

    await _communityCollection.doc(questionId).update({
      'answerCount': FieldValue.increment(1),
    });

    return answer;
  }

  // ============= REACTION OPERATIONS =============

  /// Add reaction to a question
  Future<void> addReactionToQuestion(
    String questionId,
    String userId,
    ReactionType type,
  ) async {
    try {
      final reaction = Reaction(
        id: 'r_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: type,
        createdAt: DateTime.now(),
      );

      await _communityCollection.doc(questionId).update({
        'reactions': FieldValue.arrayUnion([reaction.toJson()]),
      });

      // +10 points if post gets an upvote
      if (type == ReactionType.like) {
        final questionDoc = await _communityCollection.doc(questionId).get();
        if (questionDoc.exists) {
          final qData = questionDoc.data() as Map<String, dynamic>;
          final authorId = qData['userId'] as String;
          // Don't award points if user upvotes their own post (optional check, but good practice)
          if (authorId != userId) {
            await updateUserScore(authorId, 10);
          }
        }
      }
    } catch (e) {
      print('Error adding reaction to question: $e');
    }
  }

  /// Remove reaction from a question
  Future<void> removeReactionFromQuestion(
    String questionId,
    String userId,
    ReactionType type,
  ) async {
    try {
      final doc = await _communityCollection.doc(questionId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final reactions = (data['reactions'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();

        reactions.removeWhere(
          (r) => r['userId'] == userId && r['type'] == type.name,
        );

        await _communityCollection.doc(questionId).update({
          'reactions': reactions,
        });
      }
    } catch (e) {
      print('Error removing reaction from question: $e');
    }
  }

  /// Add reaction to an answer
  Future<void> addReactionToAnswer(
    String questionId,
    String answerId,
    String userId,
    ReactionType type,
  ) async {
    try {
      final reaction = Reaction(
        id: 'r_${DateTime.now().millisecondsSinceEpoch}',
        userId: userId,
        type: type,
        createdAt: DateTime.now(),
      );

      await _communityCollection
          .doc(questionId)
          .collection('answers')
          .doc(answerId)
          .update({
            'reactions': FieldValue.arrayUnion([reaction.toJson()]),
          });

      // +3 points if comment (answer) gets an upvote
      if (type == ReactionType.like) {
        final answerDoc = await _communityCollection
            .doc(questionId)
            .collection('answers')
            .doc(answerId)
            .get();

        if (answerDoc.exists) {
          final aData = answerDoc.data()!;
          final authorId = aData['userId'] as String;
          if (authorId != userId) {
            await updateUserScore(authorId, 3);
          }
        }
      }
    } catch (e) {
      print('Error adding reaction to answer: $e');
    }
  }

  /// Remove reaction from an answer
  Future<void> removeReactionFromAnswer(
    String questionId,
    String answerId,
    String userId,
    ReactionType type,
  ) async {
    try {
      final doc = await _communityCollection
          .doc(questionId)
          .collection('answers')
          .doc(answerId)
          .get();

      if (doc.exists) {
        final data = doc.data()!;
        final reactions = (data['reactions'] as List<dynamic>? ?? [])
            .map((e) => e as Map<String, dynamic>)
            .toList();

        reactions.removeWhere(
          (r) => r['userId'] == userId && r['type'] == type.name,
        );

        await _communityCollection
            .doc(questionId)
            .collection('answers')
            .doc(answerId)
            .update({'reactions': reactions});
      }
    } catch (e) {
      print('Error removing reaction from answer: $e');
    }
  }

  /// Mark answer as helpful
  Future<void> markAnswerAsHelpful(String questionId, String answerId) async {
    try {
      final answerRef = _communityCollection
          .doc(questionId)
          .collection('answers')
          .doc(answerId);

      await answerRef.update({'isHelpful': true});

      // +15 points for answer marked as helpful
      final doc = await answerRef.get();
      if (doc.exists) {
        final data = doc.data()!;
        final authorId = data['userId'] as String;
        await updateUserScore(authorId, 15);
      }
    } catch (e) {
      print('Error marking answer as helpful: $e');
    }
  }

  // ============= UTILITY METHODS =============

  /// Get top users by score
  /// Fetches all users first to ensure we include those with 0 points (who might be missing the score field)
  Future<List<Map<String, dynamic>>> getTopUsers({int? limit}) async {
    try {
      final snapshot = await _studentsCollection.get();

      final users = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        data['id'] = doc.id;
        // Default score to 0 if missing
        if (!data.containsKey('score')) {
          data['score'] = 0;
        }
        return data;
      }).toList();

      // Sort by score descending
      users.sort((a, b) {
        final scoreA = (a['score'] ?? 0) as int;
        final scoreB = (b['score'] ?? 0) as int;
        return scoreB.compareTo(scoreA);
      });

      // Apply limit if provided
      if (limit != null && users.length > limit) {
        return users.sublist(0, limit);
      }

      return users;
    } catch (e) {
      print('Error getting top users: $e');
      return [];
    }
  }

  /// Get user data from students collection
  Future<Map<String, dynamic>?> getUserData(String userId) async {
    try {
      final doc = await _firestore.collection('students').doc(userId).get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      print('Error getting user data: $e');
      return null;
    }
  }
}
