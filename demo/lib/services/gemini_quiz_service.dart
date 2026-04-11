import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiQuizService {
  static const String _baseUrl = "https://samyak000-amep.hf.space";
  static const String _conceptUrl = "$_baseUrl/api/v1/quiz/concept";
  static const String _chapterUrl = "$_baseUrl/api/v1/quiz/chapter";

  // ============================================================
  // 🔹 CONCEPT-WISE QUIZ (UNCHANGED)
  // ============================================================
  static Future<List<Map<String, dynamic>>> generateQuizForConcept({
    required String conceptName,
  }) async {
    final response = await http.post(
      Uri.parse(_conceptUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"conceptName": conceptName}),
    );

    if (response.statusCode != 200) {
      throw Exception("Concept quiz API failed: ${response.body}");
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> parsed = List<dynamic>.from(decoded['questions'] ?? []);

    return parsed.map((q) {
      return {
        'question': q['question'],
        'options': List<String>.from(q['options']),
        'correctAnswer': q['correctAnswer'],
        'difficulty': q['difficulty'],
        // concept-wise quiz already knows the concept
        'concept': conceptName,
      };
    }).toList();
  }

  // ============================================================
  // 🔥 CHAPTER-WISE QUIZ (CONCEPT-AWARE)
  // ============================================================
  static Future<List<Map<String, dynamic>>> generateQuizForChapter({
    required String chapterName,
    required List<String> concepts,
  }) async {
    final response = await http.post(
      Uri.parse(_chapterUrl),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"chapterName": chapterName, "concepts": concepts}),
    );

    if (response.statusCode != 200) {
      throw Exception("Chapter quiz API failed: ${response.body}");
    }

    final decoded = jsonDecode(response.body);
    final List<dynamic> parsed = List<dynamic>.from(decoded['questions'] ?? []);

    return parsed.map((q) {
      return {
        'question': q['question'],
        'options': List<String>.from(q['options']),
        'correctAnswer': q['correctAnswer'],
        'difficulty': q['difficulty'],
        // 🔥 THIS IS CRITICAL FOR WEAK CONCEPT LOGIC
        'concept': q['concept'],
        // Optional but useful later
        'chapter': chapterName,
      };
    }).toList();
  }
}
