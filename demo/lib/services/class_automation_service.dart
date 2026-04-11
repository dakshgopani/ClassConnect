import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to automate class-related operations
/// Particularly, automatically adding students to classes based on semester and division matching
class ClassAutomationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /* ============================================================
     🤖 AUTOMATIC STUDENT ENROLLMENT
  ============================================================ */

  /// Automatically add all matching students to a newly created class
  /// Matches students with same semester, division, college, and type
  Future<int> autoEnrollStudents({
    required String classId,
    required int studentSem,
    required String studentDiv,
    required String collegeSchoolName,
    required String studentType,
  }) async {
    try {
      int enrolledCount = 0;

      // 1️⃣ Find all students matching semester, division, college, and type
      final matchingStudents = await _firestore
          .collection('students')
          .where('studentSem', isEqualTo: studentSem)
          .where('studentClass', isEqualTo: studentDiv)
          .where('collegeSchoolName', isEqualTo: collegeSchoolName)
          .where('studentType', isEqualTo: studentType)
          .get();

      if (matchingStudents.docs.isEmpty) {
        print(
          'No matching students found for Sem: $studentSem, Div: $studentDiv, College: $collegeSchoolName, Type: $studentType',
        );
        return 0;
      }

      print(
        'Found ${matchingStudents.docs.length} matching students for Sem: $studentSem, Div: $studentDiv, College: $collegeSchoolName, Type: $studentType',
      );

      // 2️⃣ Add each student to the class
      for (var studentDoc in matchingStudents.docs) {
        final studentId = studentDoc.id;

        // Check if student is already enrolled
        final alreadyEnrolled = await _firestore
            .collection('class_students')
            .where('classId', isEqualTo: classId)
            .where('studentId', isEqualTo: studentId)
            .limit(1)
            .get();

        if (alreadyEnrolled.docs.isNotEmpty) {
          print('Student $studentId already enrolled in class $classId');
          continue;
        }

        // Enroll the student
        try {
          await _firestore.collection('class_students').add({
            'classId': classId,
            'studentId': studentId,
            'joined_at': FieldValue.serverTimestamp(),
          });

          enrolledCount++;
          print('Student $studentId enrolled in class $classId');
        } catch (e) {
          print('Error enrolling student $studentId: $e');
        }
      }

      // 3️⃣ Update student count in class
      if (enrolledCount > 0) {
        await _firestore.collection('classes').doc(classId).update({
          'student_count': FieldValue.increment(enrolledCount),
        });
        print('Updated class $classId with $enrolledCount new students');
      }

      return enrolledCount;
    } catch (e) {
      print('Error in autoEnrollStudents: $e');
      rethrow;
    }
  }

  /* ============================================================
     🔄 STUDENT UPDATE AUTOMATION
  ============================================================ */

  /// When a student's semester, division, college, or type changes,
  /// automatically enroll them in matching classes
  Future<void> autoEnrollStudentInMatchingClasses({
    required String studentId,
    required int newSem,
    required String newDiv,
    required String newCollegeSchoolName,
    required String newStudentType,
  }) async {
    try {
      // Find all classes matching the new semester, division, college, and type
      final matchingClasses = await _firestore
          .collection('classes')
          .where('studentSem', isEqualTo: newSem)
          .where('studentDiv', isEqualTo: newDiv)
          .where('collegeSchoolName', isEqualTo: newCollegeSchoolName)
          .where('studentType', isEqualTo: newStudentType)
          .get();

      if (matchingClasses.docs.isEmpty) {
        print(
          'No matching classes found for Sem: $newSem, Div: $newDiv, College: $newCollegeSchoolName, Type: $newStudentType',
        );
        return;
      }

      print(
        'Found ${matchingClasses.docs.length} matching classes for Sem: $newSem, Div: $newDiv, College: $newCollegeSchoolName, Type: $newStudentType',
      );

      // Add student to each matching class
      for (var classDoc in matchingClasses.docs) {
        final classId = classDoc.id;
        final classData = classDoc.data();
        final enrollmentMode = classData['enrollmentMode'] as String?;
        final autoAddStudents = classData['autoAddStudents'] as bool?;
        final shouldAutoEnroll =
            autoAddStudents ?? (enrollmentMode != 'manual');

        if (!shouldAutoEnroll) {
          continue;
        }

        // Check if already enrolled
        final alreadyEnrolled = await _firestore
            .collection('class_students')
            .where('classId', isEqualTo: classId)
            .where('studentId', isEqualTo: studentId)
            .limit(1)
            .get();

        if (alreadyEnrolled.docs.isNotEmpty) {
          print('Student already enrolled in class $classId');
          continue;
        }

        // Enroll student
        try {
          await _firestore.collection('class_students').add({
            'classId': classId,
            'studentId': studentId,
            'joined_at': FieldValue.serverTimestamp(),
          });

          // Update student count
          await _firestore.collection('classes').doc(classId).update({
            'student_count': FieldValue.increment(1),
          });

          print('Student $studentId enrolled in class $classId');
        } catch (e) {
          print('Error enrolling student $studentId in class $classId: $e');
        }
      }
    } catch (e) {
      print('Error in autoEnrollStudentInMatchingClasses: $e');
      rethrow;
    }
  }

  /* ============================================================
     🧹 CLEANUP ON CLASS DELETION
  ============================================================ */

  /// Get the count of students that will be automatically enrolled
  /// (for preview before class creation)
  Future<int> previewEnrollmentCount({
    required int studentSem,
    required String studentDiv,
    required String collegeSchoolName,
    required String studentType,
  }) async {
    try {
      final query = await _firestore
          .collection('students')
          .where('studentSem', isEqualTo: studentSem)
          .where('studentClass', isEqualTo: studentDiv)
          .where('collegeSchoolName', isEqualTo: collegeSchoolName)
          .where('studentType', isEqualTo: studentType)
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      print('Error in previewEnrollmentCount: $e');
      return 0;
    }
  }

  /* ============================================================
     👤 NEW STUDENT SIGNUP AUTOMATION
  ============================================================ */

  /// When a student creates an account, automatically enroll them in
  /// all matching classes based on their semester, division, college, and type
  Future<int> autoEnrollNewStudent({
    required String studentId,
    required int studentSem,
    required String studentDiv,
    required String collegeSchoolName,
    required String studentType,
  }) async {
    try {
      int enrolledCount = 0;

      // 1️⃣ Find all classes matching the student's semester, division, college, and type
      final matchingClasses = await _firestore
          .collection('classes')
          .where('studentSem', isEqualTo: studentSem)
          .where('studentDiv', isEqualTo: studentDiv)
          .where('collegeSchoolName', isEqualTo: collegeSchoolName)
          .where('studentType', isEqualTo: studentType)
          .get();

      if (matchingClasses.docs.isEmpty) {
        print(
          'No matching classes found for student Sem: $studentSem, Div: $studentDiv, College: $collegeSchoolName, Type: $studentType',
        );
        return 0;
      }

      print(
        'Found ${matchingClasses.docs.length} matching classes for new student Sem: $studentSem, Div: $studentDiv, College: $collegeSchoolName, Type: $studentType',
      );

      // 2️⃣ Add student to each matching class
      for (var classDoc in matchingClasses.docs) {
        final classId = classDoc.id;
        final classData = classDoc.data();
        final enrollmentMode = classData['enrollmentMode'] as String?;
        final autoAddStudents = classData['autoAddStudents'] as bool?;
        final shouldAutoEnroll =
            autoAddStudents ?? (enrollmentMode != 'manual');

        if (!shouldAutoEnroll) {
          continue;
        }

        // Check if student is already enrolled
        final alreadyEnrolled = await _firestore
            .collection('class_students')
            .where('classId', isEqualTo: classId)
            .where('studentId', isEqualTo: studentId)
            .limit(1)
            .get();

        if (alreadyEnrolled.docs.isNotEmpty) {
          print('Student $studentId already enrolled in class $classId');
          continue;
        }

        // Enroll the student
        try {
          await _firestore.collection('class_students').add({
            'classId': classId,
            'studentId': studentId,
            'joined_at': FieldValue.serverTimestamp(),
          });

          // Update student count in class
          await _firestore.collection('classes').doc(classId).update({
            'student_count': FieldValue.increment(1),
          });

          enrolledCount++;
          print('Student $studentId enrolled in class $classId');
        } catch (e) {
          print('Error enrolling new student $studentId in class $classId: $e');
        }
      }

      return enrolledCount;
    } catch (e) {
      print('Error in autoEnrollNewStudent: $e');
      rethrow;
    }
  }
}
