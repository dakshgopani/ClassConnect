import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to moderate user content using external API
class ModerationService {
  static final ModerationService _instance = ModerationService._internal();

  factory ModerationService() {
    return _instance;
  }

  ModerationService._internal();

  static const String _baseUrl =
      'https://samyak000-text-moderator.hf.space/moderate';

  /// Moderate a question
  /// Returns null if approved, error message if rejected
  Future<String?> moderateQuestion({
    required String title,
    required String description,
    String? userId = 'teacher_123',  // Default user_id
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/question'),  // Single endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': '$title\n$description',  // Combine title + description
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'rejected') {
          return 'Question flagged as inappropriate';
        }
        return null; // Approved
      } else {
        // If API fails, allow the content (fail-open approach)
        print('Moderation API failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Network error - allow content
      print('Moderation API error: $e');
      return null;
    }
  }

  /// Moderate an answer
  /// Returns null if approved, error message if rejected
  Future<String?> moderateAnswer({
    required String content,
    String? userId = 'teacher_123',  // Default user_id
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/answer'),  // Single endpoint
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': content,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'rejected') {
          return 'Answer flagged as inappropriate';
        }
        return null; // Approved
      } else {
        // If API fails, allow the content (fail-open approach)
        print('Moderation API failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Network error - allow content
      print('Moderation API error: $e');
      return null;
    }
  }

  /// Moderate a video
  /// Returns null if approved, error message if rejected
  Future<String?> moderateVideo({
    required String videoPath,
    String? userId = 'teacher_123',
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('https://samyak000-video-moderator.hf.space/moderate/free'),
      );

      // Add the video file
      request.files.add(
        await http.MultipartFile.fromPath('video', videoPath),
      );

      // Add user_id if needed
      if (userId != null) {
        request.fields['user_id'] = userId;
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'rejected') {
          return data['message'] ?? 'Video flagged as inappropriate';
        }
        return null; // Approved
      } else {
        // If API fails, allow the content (fail-open approach)
        print('Video moderation API failed with status: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      // Network error - allow content
      print('Video moderation API error: $e');
      return null;
    }
  }

  /// Moderate an image (placeholder for future implementation)
  Future<String?> moderateImage({
    required String imagePath,
    String? userId = 'teacher_123',
  }) async {
    // TODO: Implement when image moderation API is provided
    print('Image moderation not yet implemented');
    return null; // Allow for now
  }

  /// Moderate a document/PDF (placeholder for future implementation)
  Future<String?> moderateDocument({
    required String documentPath,
    String? userId = 'teacher_123',
  }) async {
    // TODO: Implement when document moderation API is provided
    print('Document moderation not yet implemented');
    return null; // Allow for now
  }
}
