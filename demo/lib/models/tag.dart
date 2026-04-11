class Tag {
  final String id;
  final String name;
  final String color;

  Tag({
    required this.id,
    required this.name,
    required this.color,
  });

  factory Tag.fromJson(Map<String, dynamic> json) {
    return Tag(
      id: json['id'] as String,
      name: json['name'] as String,
      color: json['color'] as String? ?? '#2196F3',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'color': color,
      };
}
