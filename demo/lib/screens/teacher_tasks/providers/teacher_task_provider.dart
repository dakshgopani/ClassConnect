import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/teacher_task.dart';

class TeacherTaskProvider {
  final _db = FirebaseFirestore.instance;

  /// Resolve the current teacher's ID from Firebase Auth.
  /// Fallback to the previous hardcoded ID only if no user is signed in.
  String get _teacherId => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<TeacherTask>> getTeacherTasks() {
    debugPrint('TeacherTaskProvider:getTeacherTasks -> teacherId=$_teacherId');
    return _db
        .collection('teacher_tasks')
        .where('teacherId', isEqualTo: _teacherId)
        .orderBy('dueDate')
        .snapshots()
        .map((snapshot) {
          debugPrint(
            'TeacherTaskProvider: fetched ${snapshot.docs.length} tasks for teacherId=$_teacherId',
          );
          for (final doc in snapshot.docs) {
            final data = doc.data();
            debugPrint(
              ' • docId=${doc.id} title=${data['title']} status=${data['status']}',
            );
          }
          return snapshot.docs.map((doc) => TeacherTask.fromDoc(doc)).toList();
        });
  }
}
