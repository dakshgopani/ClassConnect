import 'package:demo/screens/login_screen.dart';
import 'package:demo/screens/register_screen.dart';
import 'package:demo/theme/app_theme.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:demo/widgets/ui/cc_loading_animation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:demo/screens/student_home.dart';
import 'package:demo/screens/teacher_home.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide User;
import 'package:demo/screens/student/student_report/services/weekly_report_scheduler.dart';
import 'package:demo/screens/parent_details_screen.dart';
import 'package:demo/screens/teacher_details_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp();
  final supabaseUrl = dotenv.env['SUPABASE_URL']?.trim() ?? '';
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY']?.trim() ?? '';

  if (supabaseUrl.isEmpty || !supabaseUrl.startsWith('http')) {
    throw StateError('SUPABASE_URL is missing or invalid in .env');
  }
  if (supabaseAnonKey.isEmpty) {
    throw StateError('SUPABASE_ANON_KEY is missing in .env');
  }

  await Supabase.initialize(url: supabaseUrl, anonKey: supabaseAnonKey);
  WeeklyReportScheduler.initialize();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ClassConnect',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,

      // 1. The Home is the entry point logic
      home: const AuthWrapper(),

      // 2. Add this routes table so Navigator knows where to find '/register'
      routes: {
        '/register': (context) => const RegisterScreen(),
        '/login': (context) => LoginScreen(),
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      // This stream listens to Firebase's auth state changes
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        // 1. If the connection is still being established, show a spinner
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F8FF),
            body: Center(
              child: CcLoadingAnimation(color: Colors.white30),
            ),
          );
        }

        // 2. If the snapshot has user data, the user is logged in
        if (snapshot.hasData) {
          return const RoleRouter();
        }

        // 3. Otherwise, they are logged out (or just registered but not yet "seen" by the app)
        return LoginScreen();
      },
    );
  }
}

class RoleRouter extends StatelessWidget {
  const RoleRouter({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('students').doc(uid).get(),
      builder: (context, studentSnapshot) {
        // 🔄 Loading student doc
        if (studentSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF4F8FF),
            body: Center(
              child: CcLoadingAnimation(color: Colors.white30),
            ),
          );
        }

        // ❌ Error
        if (studentSnapshot.hasError) {
          return const Scaffold(
            body: Center(child: Text("Something went wrong")),
          );
        }

        // ✅ STUDENT EXISTS
        if (studentSnapshot.hasData && studentSnapshot.data!.exists) {
          final data = studentSnapshot.data!.data() as Map<String, dynamic>;

          // 👨‍👩‍👧 Parent details
          final parentEmail = data['parentEmail'];
          final parentPhone = data['parentPhoneNumber'];

          // 🎓 Student academic details
          final rollNo = data['studentRollNo'];
          final sem = data['studentSem'];
          final type = data['studentType'];
          final studentClass = data['studentClass'];

          final hasParentDetails =
              parentEmail is String &&
              parentPhone is String &&
              parentEmail.trim().isNotEmpty &&
              parentPhone.trim().isNotEmpty;

          final hasStudentDetails =
              rollNo is String &&
              rollNo.trim().isNotEmpty &&
              sem is int &&
              type is String &&
              type.trim().isNotEmpty &&
              studentClass is String &&
              studentClass.trim().isNotEmpty;

          if (hasParentDetails && hasStudentDetails) {
            return const StudentHome();
          } else {
            return ParentDetailsScreen(uid: uid);
          }
        }

        // 🔁 STUDENT NOT FOUND → CHECK TEACHER
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('teachers')
              .doc(uid)
              .get(),
          builder: (context, teacherSnapshot) {
            if (teacherSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                backgroundColor: Color(0xFFF4F8FF),
                body: Center(
                  child: CcLoadingAnimation(color: Colors.white30),
                ),
              );
            }

            if (teacherSnapshot.hasError) {
              return const Scaffold(
                body: Center(child: Text("Something went wrong")),
              );
            }

            if (teacherSnapshot.hasData && teacherSnapshot.data!.exists) {
              final teacherData =
                  teacherSnapshot.data!.data() as Map<String, dynamic>;

              // 🏫 Teacher professional details
              final collegeName = teacherData['collegeName'];
              final teacherDepartment = teacherData['teacherDepartment'];

              final hasTeacherDetails =
                  collegeName is String &&
                  teacherDepartment is String &&
                  collegeName.trim().isNotEmpty &&
                  teacherDepartment.trim().isNotEmpty;

              if (hasTeacherDetails) {
                return const TeacherHome();
              } else {
                return TeacherDetailsScreen(uid: uid);
              }
            }

            // ❌ SAFETY FALLBACK
            return LoginScreen();
          },
        );
      },
    );
  }
}
