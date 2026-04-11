import 'dart:convert';
import 'package:demo/config/groq_env.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/productivity.dart';

/// Generates AI-powered productivity tips using Groq API.
class ProductivityTipsService {
  static const _model = 'llama-3.3-70b-versatile';
  static const _endpoint = 'https://api.groq.com/openai/v1/chat/completions';

  /// Returns a list of 3 actionable productivity tips.
  Future<List<ProductivityTip>> generateTips({
    required ProductivityMetrics metrics,
    required int missedDeadlines,
    required List<String> overplannedDays,
  }) async {
    try {
      final prompt = _buildPrompt(
        metrics: metrics,
        missedDeadlines: missedDeadlines,
        overplannedDays: overplannedDays,
      );

      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: {
              'Content-Type': 'application/json',
              'Authorization': 'Bearer ${GroqEnv.apiKey}',
            },
            body: jsonEncode({
              'model': _model,
              'messages': [
                {
                  'role': 'system',
                  'content':
                      'You are a teacher productivity coach. Respond ONLY with valid JSON, no markdown.',
                },
                {'role': 'user', 'content': prompt},
              ],
              'temperature': 0.7,
              'max_tokens': 600,
            }),
          )
          .timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final content = body['choices'][0]['message']['content'] as String;
        return _parseTips(content);
      }
      debugPrint('Groq productivity tips failed: ${response.statusCode}');
      return _fallbackTips(metrics);
    } catch (e) {
      debugPrint('Groq productivity tips error: $e');
      return _fallbackTips(metrics);
    }
  }

  String _buildPrompt({
    required ProductivityMetrics metrics,
    required int missedDeadlines,
    required List<String> overplannedDays,
  }) {
    final topTypes = metrics.tasksByType.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final typeStr = topTypes
        .take(4)
        .map((e) => '${e.key}: ${e.value}')
        .join(', ');

    return '''
Analyze this teacher's productivity data and give exactly 3 actionable tips.

PRODUCTIVITY DATA:
- Productivity Score: ${metrics.productivityScore.toStringAsFixed(0)}/100
- Tasks Completed: ${metrics.completedTasks}/${metrics.totalTasks}
- Completion Rate: ${(metrics.completionRate * 100).toStringAsFixed(0)}%
- On-Time Rate: ${(metrics.onTimeRate * 100).toStringAsFixed(0)}%
- Efficiency: ${(metrics.efficiency * 100).toStringAsFixed(0)}%
- Current Streak: ${metrics.currentStreak} days
- Longest Streak: ${metrics.longestStreak} days
- Avg Daily Work: ${metrics.avgDailyMinutes.toStringAsFixed(0)} min
- Missed Deadlines: $missedDeadlines
- Overplanned Days: ${overplannedDays.length}
- Task Types: $typeStr

Return JSON array with exactly 3 objects:
[
  {
    "title": "short title",
    "description": "1-2 sentence actionable advice",
    "category": "one of: time_management, focus, planning, wellness, motivation"
  }
]
''';
  }

  List<ProductivityTip> _parseTips(String raw) {
    try {
      // Extract JSON array from response
      final jsonStart = raw.indexOf('[');
      final jsonEnd = raw.lastIndexOf(']');
      if (jsonStart == -1 || jsonEnd == -1) return _fallbackTips(null);

      final jsonStr = raw.substring(jsonStart, jsonEnd + 1);
      final List<dynamic> items = jsonDecode(jsonStr);

      return items.take(3).map((item) {
        return ProductivityTip(
          title: item['title'] ?? 'Tip',
          description: item['description'] ?? '',
          category: item['category'] ?? 'planning',
        );
      }).toList();
    } catch (e) {
      debugPrint('Failed to parse productivity tips: $e');
      return _fallbackTips(null);
    }
  }

  List<ProductivityTip> _fallbackTips(ProductivityMetrics? metrics) {
    final tips = <ProductivityTip>[];

    if (metrics != null && metrics.completionRate < 0.5) {
      tips.add(
        const ProductivityTip(
          title: 'Start with quick wins',
          description:
              'Complete 2-3 small tasks first to build momentum before tackling larger ones.',
          category: 'motivation',
        ),
      );
    } else {
      tips.add(
        const ProductivityTip(
          title: 'Batch similar tasks',
          description:
              'Group similar tasks (e.g., all quiz reviews together) to reduce context switching.',
          category: 'focus',
        ),
      );
    }

    tips.add(
      const ProductivityTip(
        title: 'Use time blocks',
        description:
            'Allocate 25-minute focused blocks with 5-minute breaks for deep work tasks.',
        category: 'time_management',
      ),
    );

    tips.add(
      const ProductivityTip(
        title: 'Review weekly on Sunday',
        description:
            'Spend 15 minutes each Sunday planning the week ahead to stay ahead of deadlines.',
        category: 'planning',
      ),
    );

    return tips;
  }
}

class ProductivityTip {
  final String title;
  final String description;
  final String category;

  const ProductivityTip({
    required this.title,
    required this.description,
    required this.category,
  });
}
