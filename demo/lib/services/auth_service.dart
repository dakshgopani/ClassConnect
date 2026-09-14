import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:demo/services/_google_sign_in_stub.dart' if (dart.library.io) 'package:google_sign_in/google_sign_in.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  // ---------------- EMAIL AUTH (Already OK) ----------------

  Future<User?> registerWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  Future<User?> signInWithEmail(String email, String password) async {
    try {
      UserCredential result = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return result.user;
    } catch (e) {
      print(e);
      return null;
    }
  }

  // Real Google Sign‑In implementation (works on Web, Android, iOS).
  Future<User?> signInWithGoogle({required String role}) async {
    try {
      if (kIsWeb) {
        // Web uses a popup sign‑in flow.
        final GoogleAuthProvider googleProvider = GoogleAuthProvider();
        final UserCredential cred = await _auth.signInWithPopup(googleProvider);
        final User? user = cred.user;
        if (user != null) {
          await _storeUserData(user, role);
        }
        return user;
      } else {
        // Mobile (Android / iOS) uses the native GoogleSignIn plugin.
        await _googleSignIn.signOut();
        final dynamic googleUser = await _googleSignIn.signIn();
        if (googleUser == null) {
          // User cancelled the sign‑in flow.
          return null;
        }
        final dynamic googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        final UserCredential userCred = await _auth.signInWithCredential(credential);
        final User? user = userCred.user;
        if (user != null) {
          await _storeUserData(user, role);
        }
        return user;
      }
    } catch (e) {
      debugPrint('❌ Google Sign‑In error: $e');
      return null;
    }
  }
  Future<bool> isParentDetailsFilled(String uid) async {
    final doc = await _db.collection('students').doc(uid).get();

    if (!doc.exists) return false;

    final data = doc.data();
    if (data == null) return false;

    // 👨‍👩‍👧 Parent
    final parentEmail = data['parentEmail'];
    final parentPhone = data['parentPhoneNumber'];

    // 🎓 Student academic
    final rollNo = data['studentRollNo'];
    final sem = data['studentSem'];
    final type = data['studentType'];
    final studentClass = data['studentClass'];
    final department = data['studentDepartment'];
    final collegeSchool = data['collegeSchoolName'];

    // ❌ NULL CHECK
    if (parentEmail == null ||
        parentPhone == null ||
        rollNo == null ||
        sem == null ||
        type == null ||
        studentClass == null ||
        department == null ||
        collegeSchool == null) {
      return false;
    }

    // ❌ TYPE CHECK
    if (parentEmail is! String ||
        parentPhone is! String ||
        rollNo is! String ||
        type is! String ||
        studentClass is! String ||
        department is! String ||
        collegeSchool is! String ||
        sem is! int) {
      return false;
    }

    // ❌ EMPTY STRING CHECK
    if (parentEmail.trim().isEmpty ||
        parentPhone.trim().isEmpty ||
        rollNo.trim().isEmpty ||
        studentClass.trim().isEmpty ||
        department.trim().isEmpty ||
        collegeSchool.trim().isEmpty ||
        type.trim().isEmpty) {
      return false;
    }

    return true;
  }

  Future<bool> isTeacherDetailsFilled(String uid) async {
    final doc = await _db.collection('teachers').doc(uid).get();

    if (!doc.exists) {
      print("🔴 Teacher document does not exist for uid: $uid");
      return false;
    }

    final data = doc.data();
    if (data == null) {
      print("🔴 Teacher document data is null");
      return false;
    }

    final department = data['teacherDepartment'];
    final collegeName = data['collegeName'];

    print(
      "📋 Teacher details check - Department: $department, College: $collegeName",
    );

    // ❌ NULL CHECK
    if (department == null || collegeName == null) {
      print(
        "🔴 Null fields found - Department: $department, College: $collegeName",
      );
      return false;
    }

    // ❌ TYPE CHECK
    if (department is! String || collegeName is! String) {
      print(
        "🔴 Type check failed - Department type: ${department.runtimeType}, College type: ${collegeName.runtimeType}",
      );
      return false;
    }

    // ❌ EMPTY STRING CHECK
    if (department.trim().isEmpty || collegeName.trim().isEmpty) {
      print(
        "🔴 Empty fields found - Department empty: ${department.trim().isEmpty}, College empty: ${collegeName.trim().isEmpty}",
      );
      return false;
    }

    print("✅ Teacher details are complete!");
    return true;

  }

  // ---------------- STORE USER DATA ----------------
  // (ONLY ADDITIONS: student fields initialized as null)

  Future<void> _storeUserData(User user, String role) async {
    // Check if user already exists in either collection to avoid overwriting existing role
    final teacherDoc = await _db.collection('teachers').doc(user.uid).get();
    final studentDoc = await _db.collection('students').doc(user.uid).get();

    if (teacherDoc.exists) {
      await _db.collection('teachers').doc(user.uid).set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
      }, SetOptions(merge: true));
      return;
    }

    if (studentDoc.exists) {
      await _db.collection('students').doc(user.uid).set({
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
      }, SetOptions(merge: true));
      return;
    }

    // Brand new user: initialize full document for chosen role
    final docRef = role == 'student'
        ? _db.collection('students').doc(user.uid)
        : _db.collection('teachers').doc(user.uid);

    if (role == 'student') {
      await docRef.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'role': role,
        'studentRollNo': null,
        'studentSem': null,
        'studentType': null,
        'studentClass': null,
        'studentDepartment': null,
        'collegeSchoolName': null,
        'parentEmail': null,
        'parentPhoneNumber': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    if (role == 'teacher') {
      await docRef.set({
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'role': role,
        'teacherDepartment': null,
        'collegeName': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }
  }

  // ---------------- SIGN OUT ----------------

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();
      try {
        await _googleSignIn.disconnect();
      } catch (_) {}
      debugPrint('✅ User signed out');
    } catch (e) {
      debugPrint('❌ Sign out error: $e');
    }
  }

  // ---------------- AUTH STATE ----------------

  Stream<User?> get user => _auth.authStateChanges();
}
