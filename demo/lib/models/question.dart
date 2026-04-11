import 'package:demo/models/tag.dart';
import 'package:demo/models/reaction.dart';

class Question {
  final String id;
  final String userId;
  final String userName;
  final String userAvatar;
  final String title;
  final String description;
  final List<Tag> tags;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final List<Reaction> reactions;
  final int views;
  final int answerCount;

  Question({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.title,
    required this.description,
    required this.tags,
    required this.createdAt,
    this.updatedAt,
    this.reactions = const [],
    this.views = 0,
    this.answerCount = 0,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['id'] as String,
      userId: json['userId'] as String,
      userName: json['userName'] as String,
      userAvatar: json['userAvatar'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      tags: (json['tags'] as List<dynamic>? ?? [])
          .map((e) => Tag.fromJson(e as Map<String, dynamic>))
          .toList(),
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
      answerCount: json['answerCount'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'userAvatar': userAvatar,
    'title': title,
    'description': description,
    'tags': tags.map((e) => e.toJson()).toList(),
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt?.millisecondsSinceEpoch,
    'reactions': reactions.map((r) => r.toJson()).toList(),
    'views': views,
    'answerCount': answerCount,
  };

  int get likeCount =>
      reactions.where((r) => r.type == ReactionType.like).length;

  int get heartCount =>
      reactions.where((r) => r.type == ReactionType.heart).length;
}
