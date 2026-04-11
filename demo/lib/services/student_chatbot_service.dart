import 'dart:convert';

import 'package:demo/config/groq_env.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class StudentChatbotService {
  static const String _groqModel = 'openai/gpt-oss-120b';

  static Future<String> sendMessage({
    required String message,
    List<Map<String, String>> history = const [],
    String? studentName,
    String? className,
  }) async {
    final safeHistory = history
        .where(
          (item) =>
              (item['role']?.trim().isNotEmpty ?? false) &&
              (item['content']?.trim().isNotEmpty ?? false),
        )
        .toList();

    final historyText = safeHistory
        .take(safeHistory.length > 8 ? 8 : safeHistory.length)
        .map((item) => '${item['role']}: ${item['content']}')
        .join('\n');

    final prompt =
        '''
  You are a helpful student assistant for the ClassConnect mobile app.
  Keep answers concise, practical, and friendly.
  If asked for cheating or unsafe help, refuse and suggest a legitimate study path.

  Student name: ${studentName ?? 'Student'}
  Class name: ${className ?? 'ClassConnect'}

  Conversation history:
  $historyText

  Latest user message:
  $message
  ''';

    debugPrint(
      'GROQ_CHAT_REQUEST model=$_groqModel promptLen=${prompt.length}',
    );

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/responses'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${GroqEnv.chatApiKey}',
      },
      body: jsonEncode({'input': prompt, 'model': _groqModel}),
    );

    debugPrint('GROQ_CHAT_RESPONSE status=${response.statusCode}');

    if (response.statusCode < 200 || response.statusCode >= 300) {
      debugPrint('GROQ_CHAT_ERROR_BODY ${response.body}');
      throw Exception(
        'Groq call failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final responseId = decoded['id'] as String?;
    if (responseId != null && responseId.isNotEmpty) {
      debugPrint('GROQ_CHAT_RESPONSE_ID $responseId');
    }

    final outputText = decoded['output_text'] as String?;
    if (outputText != null && outputText.trim().isNotEmpty) {
      return outputText.trim();
    }

    final output = decoded['output'] as List<dynamic>?;
    if (output != null && output.isNotEmpty) {
      for (final item in output) {
        if (item is! Map<String, dynamic>) {
          continue;
        }

        final content = item['content'] as List<dynamic>?;
        if (content == null || content.isEmpty) {
          continue;
        }

        for (final part in content) {
          if (part is! Map<String, dynamic>) {
            continue;
          }

          final partType = part['type'] as String?;
          final text = part['text'] as String?;
          if ((partType == 'output_text' || partType == 'text') &&
              text != null &&
              text.trim().isNotEmpty) {
            return text.trim();
          }
        }
      }
    }

    return '';
  }
}
