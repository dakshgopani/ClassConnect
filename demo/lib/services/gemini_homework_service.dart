import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiHomeworkService {
  static const String _baseUrl = "https://samyak000-amep.hf.space";
  static const String _generateUrl = "$_baseUrl/api/v1/homework/generate";
  static const String _evaluateUrl = "$_baseUrl/api/v1/homework/evaluate";

  static Future<Map<String, dynamic>> generateHomework({
    required List<String> weakConcepts,
    required String className,
  }) async {
    print("🚀 [HOMEWORK] Starting generation for: $weakConcepts");

    try {
      final response = await http.post(
        Uri.parse(_generateUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "weakConcepts": weakConcepts,
          "className": className,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Homework generate API failed with ${response.statusCode}",
        );
      }

      final body = jsonDecode(response.body);
      return Map<String, dynamic>.from(body);
    } catch (e) {
      print("❌ Error generating homework: $e");
      throw Exception("Failed to generate homework");
    }
  }

  /// 🔹 EVALUATE HOMEWORK
  static Future<Map<String, dynamic>> evaluateHomework({
    required List<Map<String, dynamic>> qna, // [{question, answer}]
    String? attachmentName,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_evaluateUrl),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"qna": qna, "attachmentName": attachmentName}),
      );

      if (response.statusCode != 200) {
        throw Exception(
          "Homework evaluate API failed with ${response.statusCode}",
        );
      }

      final body = jsonDecode(response.body);
      return Map<String, dynamic>.from(body);
    } catch (e) {
      print("❌ Error evaluating homework: $e");
      return {
        "score": 0,
        "feedback":
            "Error evaluating homework. Please wait for teacher review.",
        "corrections": [],
      };
    }
  }
}
