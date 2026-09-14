import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io' if (dart.library.html) 'package:demo/services/_file_stub.dart';
import 'dart:typed_data';
import 'dart:math';
import 'class_automation_service.dart';
import 'package:demo/screens/teacher/pbl/services/gemini_service.dart';

class CreateClassResult {
  final String classId;
  final String classCode;
  final int autoEnrolledCount;
  final bool syllabusProcessed;

  const CreateClassResult({
    required this.classId,
    required this.classCode,
    required this.autoEnrolledCount,
    required this.syllabusProcessed,
  });
}

class ClassService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final ClassAutomationService _automationService = ClassAutomationService();

  /* ============================================================
     🔐 UTIL
  ============================================================ */

  String _generateClassCode() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final rnd = Random();
    return List.generate(6, (_) => chars[rnd.nextInt(chars.length)]).join();
  }

  User _requireUser() {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception("User not logged in");
    }
    return user;
  }

  /* ============================================================
     👨‍🏫 TEACHER
  ============================================================ */

  /// Create Class + Generate Code + Store in Firestore
  Future<CreateClassResult> createClass({
    required String className,
    required String subject,
    required String description,
    required int studentSem,
    required String studentDiv,
    required String collegeSchoolName,
    required String studentType,
    required bool autoAddStudents,
    required bool pblEnabled,
    required bool studentCanPost,
    File? syllabusFile,
    Uint8List? syllabusBytes,
    String? syllabusFileName,
  }) async {
    final teacher = _requireUser();

    final classCode = _generateClassCode();

    final hasSyllabus = (syllabusFile != null) || (syllabusBytes != null && syllabusBytes.isNotEmpty);

    final classDoc = await _firestore.collection('classes').add({
      'class_name': className,
      'subject': subject,
      'description': description,
      'class_code': classCode,
      'teacherId': teacher.uid,
      'student_count': 0,
      'studentSem': studentSem,
      'studentDiv': studentDiv,
      'collegeSchoolName': collegeSchoolName,
      'studentType': studentType,
      'enrollmentMode': autoAddStudents ? 'automatic' : 'manual',
      'autoAddStudents': autoAddStudents,
      'pblEnabled': pblEnabled,
      'studentCanPost': studentCanPost,
      'syllabusProvided': hasSyllabus,
      'created_at': FieldValue.serverTimestamp(),
    });

    var syllabusProcessed = false;
    if (hasSyllabus) {
      try {
        final resolvedName = syllabusFileName ?? (syllabusFile != null ? _fileNameFromPath(syllabusFile.path) : 'syllabus');
        final syllabus = await _extractSyllabusChapters(
          file: syllabusFile,
          bytes: syllabusBytes,
          fileName: resolvedName,
        );
        if (syllabus.isNotEmpty) {
          await _saveSyllabusChapters(
            classId: classDoc.id,
            syllabus: syllabus,
            createdBy: teacher.uid,
          );

          await classDoc.update({
            'hasSyllabusChapters': true,
            'syllabusExtractionStatus': 'completed',
            'syllabusFileName': resolvedName,
            'syllabusFileType': _fileTypeFromPath(resolvedName),
            'syllabusExtractedAt': FieldValue.serverTimestamp(),
          });
          syllabusProcessed = true;
        } else {
          await classDoc.update({
            'hasSyllabusChapters': false,
            'syllabusExtractionStatus': 'empty',
          });
        }
      } catch (e) {
        await classDoc.update({
          'hasSyllabusChapters': false,
          'syllabusExtractionStatus': 'failed',
          'syllabusExtractionError': e.toString(),
        });
      }
    }

    var autoEnrolledCount = 0;
    if (autoAddStudents) {
      // 🤖 Automatically enroll matching students
      try {
        autoEnrolledCount = await _automationService.autoEnrollStudents(
          classId: classDoc.id,
          studentSem: studentSem,
          studentDiv: studentDiv,
          collegeSchoolName: collegeSchoolName,
          studentType: studentType,
        );
      } catch (e) {
        print('Warning: Automatic enrollment failed: $e');
        // Don't throw - class creation should still succeed
      }
    }

    return CreateClassResult(
      classId: classDoc.id,
      classCode: classCode,
      autoEnrolledCount: autoEnrolledCount,
      syllabusProcessed: syllabusProcessed,
    );
  }

  Future<Map<String, List<String>>> _extractSyllabusChapters({
    File? file,
    Uint8List? bytes,
    String? fileName,
  }) async {
    final name = fileName ?? (file != null ? _fileNameFromPath(file.path) : '');
    final lower = name.toLowerCase();
    String extractedText = '';

    if (bytes != null && bytes.isNotEmpty) {
      if (lower.endsWith('.pdf')) {
        extractedText = await GeminiService.extractTextFromPdfBytes(bytes, name);
      } else if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
        extractedText = await GeminiService.extractTextFromDocBytes(bytes, name);
      } else if (lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.webp')) {
        extractedText = await GeminiService.extractTextFromImageBytes(bytes, name);
      }
    } else if (file != null) {
      if (lower.endsWith('.pdf')) {
        extractedText = await GeminiService.extractTextFromPdf(file);
      } else if (lower.endsWith('.doc') || lower.endsWith('.docx')) {
        extractedText = await GeminiService.extractTextFromDoc(file);
      } else if (lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.png') ||
          lower.endsWith('.webp')) {
        extractedText = await GeminiService.extractTextFromImage(file);
      }
    }

    if (extractedText.trim().isEmpty) {
      return {};
    }

    return GeminiService.extractChaptersAndConcepts(extractedText);
  }

  Future<void> _saveSyllabusChapters({
    required String classId,
    required Map<String, List<String>> syllabus,
    required String createdBy,
  }) async {
    final chaptersRef = _firestore
        .collection('classes')
        .doc(classId)
        .collection('chapters');

    final existing = await chaptersRef.limit(1).get();
    if (existing.docs.isNotEmpty) {
      return;
    }

    final batch = _firestore.batch();
    int order = 0;

    for (final entry in syllabus.entries) {
      final docRef = chaptersRef.doc();
      batch.set(docRef, {
        'chapterId': docRef.id,
        'name': entry.key,
        'title': entry.key,
        'order': order++,
        'concepts': entry.value,
        'source': 'syllabus_upload',
        'createdBy': createdBy,
        'isActive': true,
        'hasDiagnostic': false,
        'hasQuiz': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  String _fileNameFromPath(String path) {
    final parts = path.split(RegExp(r'[\\/]'));
    return parts.isNotEmpty ? parts.last : '';
  }

  String _fileTypeFromPath(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.pdf')) return 'pdf';
    if (lower.endsWith('.doc') || lower.endsWith('.docx')) return 'doc';
    if (lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png') ||
        lower.endsWith('.webp')) {
      return 'image';
    }
    return 'unknown';
  }

  /// Get classes created by logged-in teacher
  Stream<QuerySnapshot> getTeacherClasses() {
    final teacher = _auth.currentUser;
    if (teacher == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('classes')
        .where('teacherId', isEqualTo: teacher.uid)
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  /* ============================================================
     🎓 STUDENT
  ============================================================ */

  /// Join class using 6-digit code
  Future<void> joinClassByCode(String classCode) async {
    final student = _requireUser();

    // 1️⃣ Find class
    final query = await _firestore
        .collection('classes')
        .where('class_code', isEqualTo: classCode)
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw Exception("Invalid class code");
    }

    final classDoc = query.docs.first;
    final classId = classDoc.id;

    // 2️⃣ Prevent duplicate join
    final alreadyJoined = await _firestore
        .collection('class_students')
        .where('classId', isEqualTo: classId)
        .where('studentId', isEqualTo: student.uid)
        .limit(1)
        .get();

    if (alreadyJoined.docs.isNotEmpty) {
      throw Exception("You already joined this class");
    }

    // 3️⃣ Add student
    await _firestore.collection('class_students').add({
      'classId': classId,
      'studentId': student.uid,
      'joined_at': FieldValue.serverTimestamp(),
    });

    // 4️⃣ Increment student count
    await _firestore.collection('classes').doc(classId).update({
      'student_count': FieldValue.increment(1),
    });
  }

  /// Get classes joined by logged-in student
  Stream<List<QueryDocumentSnapshot>> getStudentClasses() {
    final student = _auth.currentUser;
    if (student == null) {
      return const Stream.empty();
    }

    return _firestore
        .collection('class_students')
        .where('studentId', isEqualTo: student.uid)
        .snapshots()
        .asyncMap((snapshot) async {
          final classIds = snapshot.docs
              .map((d) => d['classId'] as String)
              .toList();

          if (classIds.isEmpty) return [];

          final classes = await _firestore
              .collection('classes')
              .where(FieldPath.documentId, whereIn: classIds)
              .get();

          return classes.docs;
        });
  }
}
