String todayDate() {
  final now = DateTime.now();
  return "${now.year.toString().padLeft(4, '0')}-"
      "${now.month.toString().padLeft(2, '0')}-"
      "${now.day.toString().padLeft(2, '0')}";
}

DateTime startOfWeek(DateTime date) {
  return date.subtract(Duration(days: date.weekday - 1));
}

DateTime endOfWeek(DateTime date) {
  return startOfWeek(date).add(const Duration(days: 6));
}
