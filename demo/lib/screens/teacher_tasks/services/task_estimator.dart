int estimateTaskMinutes(String taskType, int studentCount) {
  switch (taskType) {
    case 'lesson_plan':
      return 20;
    case 'pbl_creation':
      return 30;
    case 'pbl_review':
      return studentCount * 5;
    case 'quiz_review':
      return 10 + studentCount;
    case 'student_support':
      return 5;
    case 'community_moderation':
      return 3;
    default:
      return 10;
  }
}
