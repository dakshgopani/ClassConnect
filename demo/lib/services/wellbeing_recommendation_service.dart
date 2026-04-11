import 'dart:convert';
import 'package:demo/config/groq_env.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:demo/models/wellbeing_data.dart';

/// Generates AI-powered wellbeing recommendations via Groq API.
class WellbeingRecommendationService {
  static const String _baseUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  /// Generate personalized recommendations for a student based on their
  /// wellbeing data, risk level, and alert categories.
  static Future<List<WellbeingRecommendation>> getRecommendations({
    required StudentWellbeing wellbeing,
    List<String> weakConcepts = const [],
  }) async {
    try {
      final alertSummary = wellbeing.alerts
          .map((a) => '- ${a.categoryLabel}: ${a.message}')
          .join('\n');

      final prompt =
          '''
You are an expert educational psychologist and student wellbeing advisor.
A teacher needs actionable recommendations for a student who is showing signs of difficulty.

STUDENT DATA:
- Name: ${wellbeing.studentName}
- Wellbeing Score: ${wellbeing.wellbeingScore.toStringAsFixed(0)}/100
- Risk Level: ${wellbeing.riskLabel}
- Quiz Average: ${wellbeing.quizAvg.toStringAsFixed(0)}%
- Attendance: ${wellbeing.attendanceRate.toStringAsFixed(0)}%
- Assignment Completion: ${wellbeing.assignmentCompletion.toStringAsFixed(0)}%
- Community Engagement: ${wellbeing.communityScore.toStringAsFixed(0)} points
- XP: ${wellbeing.xp.toStringAsFixed(0)}
- Trend: ${wellbeing.trendDirection}
${weakConcepts.isNotEmpty ? '- Weak Concepts: ${weakConcepts.join(', ')}' : ''}

DETECTED ALERTS:
${alertSummary.isNotEmpty ? alertSummary : 'General low wellbeing score'}

REQUIREMENTS:
1. Provide exactly 4 actionable recommendations.
2. Each recommendation must be specific, not generic.
3. Include a mix of: content adjustment, engagement strategy, emotional support, and motivation.
4. Be empathetic and student-centered.
5. Return ONLY valid JSON array. No markdown. No extra text.

FORMAT:
[
  {
    "title": "Short action title (max 6 words)",
    "description": "Specific, actionable description for the teacher (2-3 sentences max)",
    "actionType": "content|engagement|motivation|support",
    "icon": "📝|🤝|💪|🎯|📖|🧘|🏆|💡"
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
                  'You are a student wellbeing advisor. Output JSON only.',
            },
            {'role': 'user', 'content': prompt},
          ],
          'temperature': 0.4,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] as String;

        // Clean markdown artifacts
        final cleaned = content
            .replaceAll('```json', '')
            .replaceAll('```', '')
            .trim();
        final List<dynamic> jsonList = jsonDecode(cleaned);

        return jsonList.map((item) {
          return WellbeingRecommendation(
            title: item['title'] ?? 'Recommendation',
            description: item['description'] ?? '',
            actionType: item['actionType'] ?? 'support',
            icon: item['icon'] ?? '💡',
          );
        }).toList();
      } else {
        debugPrint('Groq API error: ${response.statusCode} ${response.body}');
        return _fallbackRecommendations(wellbeing);
      }
    } catch (e) {
      debugPrint('Recommendation error: $e');
      return _fallbackRecommendations(wellbeing);
    }
  }

  /// Fallback recommendations when API is unavailable.
  static List<WellbeingRecommendation> _fallbackRecommendations(
    StudentWellbeing wb,
  ) {
    List<WellbeingRecommendation> recs = [];

    if (wb.quizAvg < 40) {
      recs.add(
        const WellbeingRecommendation(
          title: 'Assign Easier Content',
          description:
              'Provide simplified study materials and practice problems that build confidence before moving to harder topics.',
          actionType: 'content',
          icon: '📖',
        ),
      );
    }

    if (wb.attendanceRate < 60) {
      recs.add(
        const WellbeingRecommendation(
          title: 'Initiate 1-on-1 Check-in',
          description:
              'Schedule a private conversation to understand barriers to attendance and offer support.',
          actionType: 'engagement',
          icon: '🤝',
        ),
      );
    }

    if (wb.communityScore < 10) {
      recs.add(
        const WellbeingRecommendation(
          title: 'Encourage Peer Interaction',
          description:
              'Pair with an engaged student for group work. Assign a community question to answer for bonus points.',
          actionType: 'motivation',
          icon: '💬',
        ),
      );
    }

    recs.add(
      const WellbeingRecommendation(
        title: 'Suggest a Break',
        description:
            'Recommend a short break or lighter workload this week to reduce stress and improve focus.',
        actionType: 'support',
        icon: '🧘',
      ),
    );

    return recs.take(4).toList();
  }
}
