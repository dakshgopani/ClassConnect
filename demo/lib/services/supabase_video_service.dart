import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseVideoService {
  static final SupabaseClient _client = Supabase.instance.client;

  /// 🔹 Uploads video to Supabase Storage
  static Future<String> uploadVideoToSupabase({
    required File videoFile,
    required String studentId,
    required String conceptName,
  }) async {
    final String filePath =
        'concept_videos/$studentId/${DateTime.now().millisecondsSinceEpoch}_$conceptName.mp4';

    await _client.storage
        .from('concept_videos') // 👈 BUCKET NAME
        .upload(
      filePath,
      videoFile,
      fileOptions: const FileOptions(
        upsert: true,
        contentType: 'video/mp4',
      ),
    );

    /// 🔹 Get public URL
    final publicUrl = _client.storage
        .from('concept_videos')
        .getPublicUrl(filePath);

    return publicUrl;
  }

  /// 🔹 Save metadata in table
  static Future<void> saveVideoMetadata({
    required String studentId,
    required String studentName,
    required String classId,
    required String conceptName,
    required String videoUrl,
  }) async {
    await _client.from('concept_videos').insert({
      'student_id': studentId,
      'student_name': studentName,
      'class_id': classId,
      'concept_name': conceptName,
      'video_url': videoUrl,
      'created_at': DateTime.now().toIso8601String(),
    });
  }
}
