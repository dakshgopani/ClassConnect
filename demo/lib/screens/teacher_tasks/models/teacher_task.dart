import 'package:cloud_firestore/cloud_firestore.dart';

class TeacherTask {
  final String id;
  final String teacherId;
  final String? classId;

  final String taskType;
  final String? sourceType;
  final String? sourceId;

  // ✅ NEW
  final String planningType;     // manual | system
  final String? plannedForDate;  // YYYY-MM-DD

  final String title;
  final String description;

  final int estimatedMinutes;
  final int actualMinutes;

  final String status;
  final String priority;

  final Timestamp? dueDate;
  final Timestamp createdAt;
  final Timestamp? completedAt;

  TeacherTask({
    required this.id,
    required this.teacherId,
    this.classId,
    required this.taskType,
    this.sourceType,
    this.sourceId,

    // ✅ NEW
    required this.planningType,
    this.plannedForDate,

    required this.title,
    required this.description,
    required this.estimatedMinutes,
    required this.actualMinutes,
    required this.status,
    required this.priority,
    this.dueDate,
    required this.createdAt,
    this.completedAt,
  });

  factory TeacherTask.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return TeacherTask(
      id: doc.id,
      teacherId: data['teacherId'],
      classId: data['classId'],

      taskType: data['taskType'],
      sourceType: data['sourceType'],
      sourceId: data['sourceId'],

      // ✅ BACKWARD-SAFE DEFAULTS
      planningType: data['planningType'] ?? 'system',
      plannedForDate: data['plannedForDate'],

      title: data['title'],
      description: data['description'],
      estimatedMinutes: data['estimatedMinutes'],
      actualMinutes: data['actualMinutes'] ?? 0,
      status: data['status'],
      priority: data['priority'] ?? 'medium',
      dueDate: data['dueDate'],
      createdAt: data['createdAt'],
      completedAt: data['completedAt'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'teacherId': teacherId,
      'classId': classId,

      'taskType': taskType,
      'sourceType': sourceType,
      'sourceId': sourceId,

      // ✅ NEW
      'planningType': planningType,
      'plannedForDate': plannedForDate,

      'title': title,
      'description': description,
      'estimatedMinutes': estimatedMinutes,
      'actualMinutes': actualMinutes,
      'status': status,
      'priority': priority,
      'dueDate': dueDate,
      'createdAt': createdAt,
      'completedAt': completedAt,
    };
  }
}
