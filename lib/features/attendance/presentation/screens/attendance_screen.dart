import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';

// Import the specific attendance screens
import 'student/student_attendance_screen.dart';
import 'teacher/teacher_attendance_screen.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      return const Scaffold(body: Center(child: Text('User not authenticated')));
    }

    // If user is a student, show student-specific options
    if (currentUser.role.value == 'student') {
      return const StudentAttendanceScreen();
    }
    // If user is a teacher, show teacher-specific options
    else if (currentUser.role.value == 'teacher') {
      return const TeacherAttendanceScreen();
    } else {
      return const Scaffold(body: Center(child: Text('User role not recognized')));
    }
  }
}
