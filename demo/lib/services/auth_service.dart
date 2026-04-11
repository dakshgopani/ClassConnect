import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

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

  // ---------------- GOOGLE SIGN IN (IMPORTANT) ----------------

  Future<User?> signInWithGoogle({required String role}) async {
    try {
      print("➡️ Starting Google Sign-In for role: $role");
      await _googleSignIn.signOut();
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        print("❌ Google Sign-In cancelled by user");
        return null;
      }

      print("✅ Google account selected: ${googleUser.email}");

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      print("🔑 Google Auth Tokens received");

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCred = await _auth.signInWithCredential(credential);

      User user = userCred.user!;
      print("✅ Firebase Auth success: UID = ${user.uid}");

      await _storeUserData(user, role);

      print("💾 User data stored in Firestore as $role");

      return user;
    } catch (e) {
      print("🔥 Google Sign-In Error: $e");
      return null;
    }
  }

  // ---------------- PROFILE COMPLETION CHECK ----------------
  // (Previously parent-only, now checks ALL onboarding fields)

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
    final docRef = role == 'student'
        ? _db.collection('students').doc(user.uid)
        : _db.collection('teachers').doc(user.uid);

    final doc = await docRef.get();

    // ✅ FIRST TIME STUDENT (UNCHANGED LOGIC + ADDED FIELDS)
    if (!doc.exists && role == 'student') {
      await docRef.set({
        // 🔑 basic identity (YOUR CODE)
        'uid': user.uid,
        'name': user.displayName ?? '',
        'email': user.email ?? '',
        'photoUrl': user.photoURL ?? '',
        'role': role,

        // 🔽 ADDED: student one-time fields
        'studentRollNo': null,
        'studentSem': null,
        'studentType': null,
        'studentClass': null,
        'studentDepartment': null,
        'collegeSchoolName': null,

        // 👨‍👩‍👧 parent (YOUR CODE)
        'parentEmail': null,
        'parentPhoneNumber': null,

        // ⏱ system (YOUR CODE)
        'createdAt': FieldValue.serverTimestamp(),
      });

      print("🆕 New student document created with full schema");
      return;
    }

    // ✅ FIRST TIME TEACHER (UNCHANGED)
    if (!doc.exists && role == 'teacher') {
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

      print("🆕 New teacher document created");
      return;
    }

    // ♻️ EXISTING USER → SAFE UPDATE (UNCHANGED)
    await docRef.set({
      'name': user.displayName ?? '',
      'email': user.email ?? '',
      'photoUrl': user.photoURL ?? '',
    }, SetOptions(merge: true));

    print("♻️ Existing $role document updated safely");
  }

  // ---------------- SIGN OUT ----------------

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _googleSignIn.signOut();

      try {
        await _googleSignIn.disconnect();
      } catch (_) {
        print("ℹ️ Google disconnect skipped (already disconnected)");
      }

      print("✅ User fully signed out");
    } catch (e) {
      print("❌ Firebase sign out error: $e");
    }
  }

  // ---------------- AUTH STATE ----------------

  Stream<User?> get user => _auth.authStateChanges();
}
