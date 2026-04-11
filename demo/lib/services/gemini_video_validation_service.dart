import 'dart:convert';
import 'package:http/http.dart' as http;

class GeminiVideoValidationService {
  static const String _baseUrl = "https://samyak000-amep.hf.space";
  static const String _url = "$_baseUrl/api/v1/validation/video";

  /// ⚠️ ADVISORY ONLY — NEVER BLOCK USER
  static Future<Map<String, dynamic>> validateVideoExplanation({
    required String conceptName,
    required String challengePhrase,
    required String transcript,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(_url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "conceptName": conceptName,
          "challengePhrase": challengePhrase,
          "transcript": transcript,
        }),
      );

      if (response.statusCode != 200) {
        return _fallback(); // ✅ FAIL OPEN
      }

      return Map<String, dynamic>.from(jsonDecode(response.body));
    } catch (e) {
      return _fallback(); // ✅ NEVER THROW
    }
  }

  /// 🔒 FALLBACK (USER ALWAYS PASSES)
  static Map<String, dynamic> _fallback() {
    return {"isRelevant": true, "phraseMatched": true, "confidence": 0.6};
  }
}
