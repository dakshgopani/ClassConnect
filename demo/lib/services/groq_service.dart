import 'dart:convert';
import 'package:demo/config/groq_env.dart';
import 'package:http/http.dart' as http;

class GroqService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Generates concept-aligned micro-steps for a mini project.
  /// Returns a list of steps, where each step is a Map with 'title' and 'description'.
  static Future<List<Map<String, String>>> generateProjectSteps({
    required String title,
    required String description,
    required String subject,
  }) async {
    try {
      final prompt =
          '''
      You are an expert educational curriculum designer. 
      Create a step-by-step guide for a student to complete the following project:
      
      Project Title: $title
      Project Description: $description
      Subject: $subject
      
      Requirements:
      1. Break the project into micro-level, concept-aligned steps.
      2. Each step must represent one core concept of the subject.
      3. The steps should logically lead to the completion of the project.
      4. Provide 5 to 8 steps.
      5. Return ONLY valid JSON in the following format, with no extra text or markdown:
      [
        {
          "title": "Step Title (Concept Name)",
          "description": "Detailed instruction on what to do for this step."
        }
      ]
      ''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${GroqEnv.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content':
                  'You are a helpful educational assistant that outputs JSON only.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.3,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        // Clean up markdown code blocks if present
        final cleanedContent = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();

        final List<dynamic> jsonList = jsonDecode(cleanedContent);

        return jsonList
            .map(
              (item) => {
                'title': item['title'].toString(),
                'description': item['description'].toString(),
              },
            )
            .toList();
      } else {
        throw Exception(
          'Failed to generate steps: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error calling Groq API: $e');
    }
  }

  /// Transcribes audio using Groq's Whisper model.
  static Future<String> _transcribeAudio(String url) async {
    try {
      // 1. Download audio file
      final audioResponse = await http.get(Uri.parse(url));
      if (audioResponse.statusCode != 200) return "Audio file download failed.";

      // 2. Prepare Multipart Request for Groq
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('https://api.groq.com/openai/v1/audio/transcriptions'),
      );
      request.headers['Authorization'] = 'Bearer ${GroqEnv.apiKey}';
      request.fields['model'] = 'whisper-large-v3';
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          audioResponse.bodyBytes,
          filename: 'audio.m4a', // Common format, Whisper handles most
        ),
      );

      // 3. Send
      final streamdResponse = await request.send();
      final response = await http.Response.fromStream(streamdResponse);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['text'] ?? "No speech detected.";
      }
      return "Transcription failed: ${response.statusCode}";
    } catch (e) {
      return "Error transcribing: $e";
    }
  }

  /// Fetches text content from a URL (if text-based).
  static Future<String> _fetchFileContent(String url, String fileName) async {
    final lowerName = fileName.toLowerCase();
    final isText =
        lowerName.endsWith('.dart') ||
        lowerName.endsWith('.txt') ||
        lowerName.endsWith('.md') ||
        lowerName.endsWith('.js') ||
        lowerName.endsWith('.html') ||
        lowerName.endsWith('.css') ||
        lowerName.endsWith('.json');

    if (!isText)
      return "Non-text file (Image/PDF/Zip). Evaluate based on filename relevance only.";

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        // Limit to 2000 chars to save context window
        final body = response.body;
        return body.length > 2000
            ? body.substring(0, 2000) + "...(truncated)"
            : body;
      }
      return "Failed to download file.";
    } catch (e) {
      return "Error reading file: $e";
    }
  }

  /// Evaluates PBL submissions for a pair of students.
  /// Returns a Map with 'pairAnalysis', 'totalScore', and 'studentEvaluations'.
  static Future<Map<String, dynamic>> evaluatePblSubmission({
    required String problemStatement,
    required List<Map<String, dynamic>> studentSubmissions,
  }) async {
    try {
      // Prepare detailed data with transcripts and content
      final List<Map<String, dynamic>> detailedSubmissions = [];

      for (var s in studentSubmissions) {
        String transcript = "No voice voice message.";
        String fileContent = "No file submitted.";

        // Voice
        if (s['submission']?['voiceUrl'] != null) {
          transcript = await _transcribeAudio(s['submission']['voiceUrl']);
        }

        // File
        if (s['submission']?['fileUrl'] != null) {
          final fName = s['submission']['fileName'] ?? 'unknown';
          fileContent = await _fetchFileContent(
            s['submission']['fileUrl'],
            fName,
          );
        }

        detailedSubmissions.add({
          'name': s['name'],
          'submitted': s['submission'] != null,
          'fileName': s['submission']?['fileName'] ?? 'No file',
          'transcript': transcript,
          'fileContent': fileContent,
        });
      }

      final prompt =
          '''
      You are a strict academic evaluator. Evaluate the following PBL pair submission.
      
      Problem Statement: "$problemStatement"
      
      Submissions Data:
      ${jsonEncode(detailedSubmissions)}
      
      Strict Guidelines:
      1. Evaluate ONLY the students listed above. If there is only 1 student, evaluate ONLY that 1 student. Do NOT invent a second student.
      2. Check if the "fileContent" and "transcript" actually solve the Problem Statement.
      3. If the content is irrelevant (e.g., random text, unrelated code), giving a LOW score (0-10) is mandatory.
      4. If "fileContent" says "Non-text file", judge based on the "fileName" relevance.
      5. "transcript" validates the student's understanding. If it contradicts the work or is nonsense, penalize.
      6. Provide a score out of 50 for each student.
      7. Total Score is the sum of individual scores (max 100 for a pair, max 50 if solitary).
      
      Return ONLY valid JSON:
      {
        "pairAnalysis": "Combined feedback...",
        "totalScore": 75,
        "studentEvaluations": [
          {
            "name": "Student Name",
            "score": 35,
            "feedback": "Specific feedback on their code/voice..."
          }
        ]
      }
      ''';

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Authorization': 'Bearer ${GroqEnv.apiKey}',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b-versatile',
          'messages': [
            {
              'role': 'system',
              'content': 'You are a strict evaluator. Output JSON only.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature':
              0.2, // Lower temperature for more consistent/strict results
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];

        final cleanedContent = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        return jsonDecode(cleanedContent);
      } else {
        throw Exception(
          'Failed to evaluate: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      throw Exception('Error calling Groq API: $e');
    }
  }
}
