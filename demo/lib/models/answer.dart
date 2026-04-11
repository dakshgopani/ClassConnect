import 'package:demo/models/reaction.dart';

class Answer {
  final String id;
  final String questionId;
  final String userId;
  final String userName;
  final String userAvatar;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Reaction> reactions;
  final int views;

  Answer({
    required this.id,
    required this.questionId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.reactions = const [],
    this.views = 0,
    this.isHelpful = false,
  });

  factory Answer.fromJson(Map<String, dynamic> json) {
    return Answer(
      id: json['id'] as String,
      questionId: json['questionId'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String,
      content: json['content'] as String,
      createdAt: json['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['updatedAt'])
          : DateTime.parse(json['updatedAt'] as String))
          : null,
      reactions: (json['reactions'] as List<dynamic>? ?? [])
          .map((e) => Reaction.fromJson(e as Map<String, dynamic>))
          .toList(),
      views: json['views'] as int? ?? 0,
      isHelpful: json['isHelpful'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'questionId': questionId,
    'userId': userId,
    'userName': userName,
    'userAvatar': userAvatar,
    'content': content,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
    'reactions': reactions.map((r) => r.toJson()).toList(),
    'views': views,
    'isHelpful': isHelpful,
  };

  int get likeCount =>
      reactions.where((r) => r.type == ReactionType.like).length;

  int get heartCount =>
      reactions.where((r) => r.type == ReactionType.heart).length;

  final bool isHelpful;
}