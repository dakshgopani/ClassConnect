import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PblSupabaseClient {
  static SupabaseClient? _client;

  static SupabaseClient get client {
    if (_client != null) return _client!;

    final url = dotenv.env['SUPABASE_PBL_URL']?.trim() ?? '';
    final anonKey = dotenv.env['SUPABASE_PBL_ANON_KEY']?.trim() ?? '';

    if (url.isEmpty || !url.startsWith('http')) {
      throw StateError('SUPABASE_PBL_URL is missing or invalid in .env');
    }
    if (anonKey.isEmpty) {
      throw StateError('SUPABASE_PBL_ANON_KEY is missing in .env');
    }

    _client = SupabaseClient(url, anonKey);
    return _client!;
  }
}
