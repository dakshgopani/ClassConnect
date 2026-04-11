class StudentReport {
  final String studentId;
  final String studentName;
  final String parentEmail;

  final double attendancePercent;
  final double avgQuizScore;
  final List<String> weakConcepts;

  final int pblSubmitted;
  final int communityPosts;
  final int communityAnswers;

  StudentReport({
    required this.studentId,
    required this.studentName,
    required this.parentEmail,
    required this.attendancePercent,
    required this.avgQuizScore,
    required this.weakConcepts,
    required this.pblSubmitted,
    required this.communityPosts,
    required this.communityAnswers,
  });
}
