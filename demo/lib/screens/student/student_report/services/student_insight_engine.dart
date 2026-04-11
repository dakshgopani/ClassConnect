import '../models/student_report.dart';
import '../models/student_insight.dart';

class StudentInsightEngine {
  static StudentInsight generate(StudentReport r) {
    final strengths = <String>[];
    final concerns = <String>[];
    final recommendations = <String>[];

    // ===== ATTENDANCE =====
    if (r.attendancePercent >= 90) {
      strengths.add('Excellent class attendance');
    } else if (r.attendancePercent < 75) {
      concerns.add('Low class attendance');
      recommendations.add(
        'Ensure regular attendance to improve conceptual understanding',
      );
    }

    // ===== QUIZ PERFORMANCE =====
    if (r.avgQuizScore >= 80) {
      strengths.add('Strong academic performance in quizzes');
    } else if (r.avgQuizScore < 60) {
      concerns.add('Low quiz performance');
      recommendations.add(
        'Focus on revising weak concepts through practice quizzes',
      );
    }

    // ===== WEAK CONCEPTS =====
    if (r.weakConcepts.isNotEmpty) {
      concerns.add(
        'Difficulty in concepts like ${r.weakConcepts.take(3).join(', ')}',
      );
      recommendations.add(
        'Targeted revision and guided homework for weak concepts',
      );
    }

    // ===== ENGAGEMENT =====
    if (r.communityPosts + r.communityAnswers >= 5) {
      strengths.add('Actively participates in community discussions');
    } else {
      recommendations.add(
        'Encourage participation in peer discussions and doubt forums',
      );
    }

    // ===== PBL =====
    if (r.pblSubmitted > 0) {
      strengths.add('Has submitted project-based learning assignments');
    } else {
      concerns.add('No PBL submissions yet');
      recommendations.add(
        'Complete project-based tasks to improve practical understanding',
      );
    }

    final headline = _buildHeadline(strengths, concerns);

    return StudentInsight(
      headline: headline,
      strengths: strengths,
      concerns: concerns,
      recommendations: recommendations,
    );
  }

  static String _buildHeadline(
    List<String> strengths,
    List<String> concerns,
  ) {
    if (strengths.isNotEmpty && concerns.isEmpty) {
      return 'Student is performing consistently well across activities';
    }
    if (strengths.isNotEmpty && concerns.isNotEmpty) {
      return 'Student shows good potential with areas that need improvement';
    }
    return 'Student requires focused academic support';
  }
}
