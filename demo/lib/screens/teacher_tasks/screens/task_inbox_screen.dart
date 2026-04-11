import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/teacher_task.dart';
import '../services/teacher_task_query_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TaskInboxScreen extends StatelessWidget {
  const TaskInboxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final queryService = TeacherTaskQueryService();
    final _db = FirebaseFirestore.instance;
    final teacherId = FirebaseAuth.instance.currentUser!.uid;

    void _showPlanDialog(BuildContext context, TeacherTask task) {
      DateTime selectedDate = DateTime.now();

      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: const Text('Plan this task'),
            content: ListTile(
              title: Text(
                'Planned for: ${selectedDate.toLocal().toString().split(' ')[0]}',
              ),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 30)),
                );
                if (picked != null) {
                  selectedDate = picked;
                }
              },
            ),
            actions: [
              TextButton(
                child: const Text('Cancel'),
                onPressed: () => Navigator.pop(ctx),
              ),
              TextButton(
                child: const Text('Plan'),
                onPressed: () async {
                  await FirebaseFirestore.instance
                      .collection('teacher_tasks')
                      .doc(task.id)
                      .update({
                        'planningType': 'manual',
                        'plannedForDate': selectedDate.toIso8601String().split(
                          'T',
                        )[0],
                      });
                  Navigator.pop(ctx);
                },
              ),
            ],
          );
        },
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Task Inbox')),
      body: StreamBuilder<List<TeacherTask>>(
        stream: queryService.getInboxTasks(teacherId: teacherId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No suggested tasks'));
          }

          final tasks = snapshot.data!;

          return ListView.builder(
            itemCount: tasks.length,
            itemBuilder: (context, i) {
              final task = tasks[i];
              return Card(
                child: ListTile(
                  title: Text(task.title),
                  subtitle: Text(
                    '${task.taskType} • ${task.estimatedMinutes} min',
                  ),
                  trailing: TextButton(
                    child: const Text('Plan'),
                    onPressed: () {
                      _showPlanDialog(context, task);
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
