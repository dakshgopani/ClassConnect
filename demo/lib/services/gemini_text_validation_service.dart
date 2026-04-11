import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiTextValidationService {
  static const String _baseUrl = "https://samyak000-amep.hf.space";
  static const String _url = "$_baseUrl/api/v1/validation/text";

  /// 🔍 VALIDATE TEXT EXPLANATION
  static Future<Map<String, dynamic>> validateTextExplanation({
    required String conceptName,
    required String explanation,
  }) async {
    final response = await http.post(
      Uri.parse(_url),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "conceptName": conceptName,
        "explanation": explanation,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception("Text validation API failed");
    }

    return Map<String, dynamic>.from(jsonDecode(response.body));
  }
}
