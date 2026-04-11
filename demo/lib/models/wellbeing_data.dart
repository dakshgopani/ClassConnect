/// Data models for Student Wellbeing Monitoring System
library;

enum RiskLevel { low, medium, high }

enum AlertCategory { academicStress, emotionalDistress, disengagement }

class StudentWellbeing {
  final String studentId;
  final String studentName;
  final double wellbeingScore; // 0-100
  final RiskLevel riskLevel;
  final List<WellbeingAlert> alerts;
  final WellbeingBreakdown breakdown;
  final List<double> trendScores; // last 7-30 days
  final DateTime computedAt;

  // Raw metrics (kept for reference)
  final double quizAvg;
  final double attendanceRate;
  final double assignmentCompletion;
  final double communityScore;
  final double xp;

  const StudentWellbeing({
    required this.studentId,
    required this.studentName,
    required this.wellbeingScore,
    required this.riskLevel,
    required this.alerts,
    required this.breakdown,
    required this.trendScores,
    required this.computedAt,
    required this.quizAvg,
    required this.attendanceRate,
    required this.assignmentCompletion,
    required this.communityScore,
    required this.xp,
  });

  bool get isAtRisk => riskLevel == RiskLevel.medium || riskLevel == RiskLevel.high;

  String get riskLabel {
    switch (riskLevel) {
      case RiskLevel.low:
        return 'Low';
      case RiskLevel.medium:
        return 'Medium';
      case RiskLevel.high:
        return 'High';
    }
  }

  String get trendDirection {
    if (trendScores.length < 2) return 'stable';
    final recent = trendScores.last;
    final earlier = trendScores.first;
    if (recent > earlier + 5) return 'improving';
    if (recent < earlier - 5) return 'declining';
    return 'stable';
  }

  Map<String, dynamic> toFirestore() => {
    'studentId': studentId,
    'studentName': studentName,
    'wellbeingScore': wellbeingScore,
    'riskLevel': riskLevel.name,
    'quizAvg': quizAvg,
    'attendanceRate': attendanceRate,
    'assignmentCompletion': assignmentCompletion,
    'communityScore': communityScore,
    'xp': xp,
    'computedAt': DateTime.now().toIso8601String(),
  };
}

class WellbeingAlert {
  final AlertCategory category;
  final String title;
  final String message;
  final double severity; // 0-1
  final DateTime detectedAt;

  const WellbeingAlert({
    required this.category,
    required this.title,
    required this.message,
    required this.severity,
    required this.detectedAt,
  });

  String get categoryLabel {
    switch (category) {
      case AlertCategory.academicStress:
        return 'Academic Stress';
      case AlertCategory.emotionalDistress:
        return 'Emotional Distress';
      case AlertCategory.disengagement:
        return 'Disengagement';
    }
  }

  String get categoryEmoji {
    switch (category) {
      case AlertCategory.academicStress:
        return '📚';
      case AlertCategory.emotionalDistress:
        return '💔';
      case AlertCategory.disengagement:
        return '😶';
    }
  }
}

class WellbeingBreakdown {
  final double quizComponent;       // 0-25
  final double attendanceComponent; // 0-20
  final double assignmentComponent; // 0-15
  final double communityComponent;  // 0-15
  final double xpComponent;         // 0-15
  final double consistencyComponent;// 0-10

  const WellbeingBreakdown({
    required this.quizComponent,
    required this.attendanceComponent,
    required this.assignmentComponent,
    required this.communityComponent,
    required this.xpComponent,
    required this.consistencyComponent,
  });
}

class WellbeingRecommendation {
  final String title;
  final String description;
  final String actionType; // 'content', 'engagement', 'motivation'
  final String icon;

  const WellbeingRecommendation({
    required this.title,
    required this.description,
    required this.actionType,
    required this.icon,
  });
}