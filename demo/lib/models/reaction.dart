enum ReactionType { like, heart }

class Reaction {
  final String id;
  final String userId;
  final ReactionType type;
  final DateTime createdAt;

  Reaction({
    required this.id,
    required this.userId,
    required this.type,
    required this.createdAt,
  });

  factory Reaction.fromJson(Map<String, dynamic> json) {
    return Reaction(
      id: json['id'] as String,
      userId: json['userId'] as String,
      type: ReactionType.values.byName(json['type'] as String),
      createdAt: json['createdAt'] is int
          ? DateTime.fromMillisecondsSinceEpoch(json['createdAt'])
          : DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'type': type.name,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };
}
