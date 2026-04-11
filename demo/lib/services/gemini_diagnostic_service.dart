import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiDiagnosticQuizService {
  static const String _baseUrl = "https://samyak000-amep.hf.space";
  static const String _url = "$_baseUrl/api/v1/quiz/diagnostic";

  static Future<List<Map<String, dynamic>>> generateDiagnosticQuiz({
    required List<String> concepts,
  }) async {
    print("🚀 [DIAGNOSTIC] Starting quiz generation");
    print("📚 Concepts count: ${concepts.length}");
    print("📚 Concepts: $concepts");

    final response = await http.post(
      Uri.parse(_url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"concepts": concepts}),
    );

    print("🌐 Gemini status code: ${response.statusCode}");

    if (response.statusCode != 200) {
      throw Exception("❌ Diagnostic quiz API failed");
    }

    final body = jsonDecode(response.body);
    final decoded = body['questions'];

    if (decoded is! List || decoded.isEmpty) {
      throw Exception("❌ Diagnostic API returned empty quiz");
    }

    print("✅ Parsed diagnostic questions: ${decoded.length}");

    return List<Map<String, dynamic>>.from(decoded);
  }
}
