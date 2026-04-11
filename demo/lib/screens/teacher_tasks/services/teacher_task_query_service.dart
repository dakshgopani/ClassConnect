import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_task.dart';

class TeacherTaskQueryService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ================================
  // PLANNED WORKLOAD (INTENT)
  // ================================

  Stream<List<TeacherTask>> getPlannedTasksForDate({
    required String teacherId,
    required String plannedForDate, // YYYY-MM-DD
  }) {
    return _db
        .collection('teacher_tasks')
        .where('teacherId', isEqualTo: teacherId)
        .where('planningType', isEqualTo: 'manual')
        .where('plannedForDate', isEqualTo: plannedForDate)
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) => TeacherTask.fromDoc(doc)).toList();
        });
  }

  // Range query: plannedForDate within [startDate, endDate]
  // plannedForDate stored as 'YYYY-MM-DD' strings so lexicographic compare works.
  Stream<List<TeacherTask>> getPlannedTasksInRange({
    required String teacherId,
    required String startDate, // YYYY-MM-DD
    required String endDate, // YYYY-MM-DD
  }) {
    return _db
        .collection('teacher_tasks')
        .where('teacherId', isEqualTo: teacherId)
        .where('planningType', isEqualTo: 'manual')
        .where('plannedForDate', isGreaterThanOrEqualTo: startDate)
        .where('plannedForDate', isLessThanOrEqualTo: endDate)
        .orderBy('plannedForDate')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((d) => TeacherTask.fromDoc(d)).toList(),
        );
  }

  // ================================
  // TODAY'S EXECUTION VIEW
  // ================================

  Stream<List<TeacherTask>> getTodaysPlannedTasks({required String teacherId}) {
    final now = DateTime.now();
    final today =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    return getPlannedTasksForDate(teacherId: teacherId, plannedForDate: today);
  }

  // ================================
  // INBOX / SYSTEM TASKS
  // ================================

  Stream<List<TeacherTask>> getInboxTasks({required String teacherId}) {
    return _db
        .collection('teacher_tasks')
        .where('teacherId', isEqualTo: teacherId)
        .where('planningType', isEqualTo: 'system')
        .where('status', isNotEqualTo: 'completed')
        .orderBy('status')
        .orderBy('dueDate')
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((d) => TeacherTask.fromDoc(d)).toList(),
        );
  }

  // ================================
  // ALL TASKS (OPTIONAL)
  // ================================

  Stream<List<TeacherTask>> getAllTasks({required String teacherId}) {
    return _db
        .collection('teacher_tasks')
        .where('teacherId', isEqualTo: teacherId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) =>
              snapshot.docs.map((d) => TeacherTask.fromDoc(d)).toList(),
        );
  }
}
