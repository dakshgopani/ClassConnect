import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqEnv {
  static String get apiKey {
    final key = dotenv.env['GROQ_API_KEY'];
    if (key == null || key.isEmpty) {
      throw StateError('GROQ_API_KEY is not set in .env');
    }
    return key;
  }

  static String get chatApiKey {
    final key = dotenv.env['GROQ_CHAT_API_KEY'] ?? dotenv.env['GROQ_API_KEY'];
    if (key == null || key.isEmpty) {
      throw StateError('GROQ_CHAT_API_KEY is not set in .env');
    }
    return key;
  }
}
