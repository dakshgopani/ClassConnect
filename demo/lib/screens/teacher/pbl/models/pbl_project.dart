class PblProject {
  final String title;
  final String problemStatement;
  final List<Map<String, String>> miniProjects;
  final List<String> learningObjectives;
  final List<String> milestones;
  final List<Map<String, dynamic>> rubric;

  PblProject({
    required this.title,
    required this.problemStatement,
    required this.learningObjectives,
    required this.milestones,
    required this.rubric,
    this.miniProjects = const [],
  });

  factory PblProject.fromJson(Map<String, dynamic> json) {
    return PblProject(
      title: (json['title'] ?? '') as String,
      problemStatement: (json['problemStatement'] ?? '') as String,
      learningObjectives: _parseStringList(json['learningObjectives']),
      milestones: _parseStringList(json['milestones']),
      rubric: _parseRubric(json['rubric']),
      miniProjects: _parseMiniProjects(json['miniProjects']),
    );
  }

  /// Helper to safely parse string lists from JSON
  static List<String> _parseStringList(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data
          .map((item) {
        if (item is String) return item;
        if (item is Map) {
          // If it's a map, try to extract a meaningful string
          return item.toString();
        }
        return item.toString();
      })
          .toList()
          .cast<String>();
    }
    return [];
  }

  /// Helper to safely parse rubric from JSON
  static List<Map<String, dynamic>> _parseRubric(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) {
        if (item is Map) return Map<String, dynamic>.from(item);
        return <String, dynamic>{};
      }).toList();
    }
    return [];
  }

  /// Helper to safely parse mini projects from JSON
  static List<Map<String, String>> _parseMiniProjects(dynamic data) {
    if (data == null) return [];
    if (data is List) {
      return data.map((item) {
        if (item is Map) {
          return Map<String, String>.from(
            item.map((k, v) => MapEntry(k.toString(), v?.toString() ?? '')),
          );
        }
        return <String, String>{};
      }).toList();
    }
    return [];
  }
}



