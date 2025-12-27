// Generic homework screen that adapts based on user role
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/core/enums.dart';
import 'package:track_app/features/homework/presentation/screens/student/student_homework_screen.dart';
import 'package:track_app/features/homework/presentation/screens/teacher/teacher_homework_screen.dart';

class HomeworkScreen extends StatelessWidget {
  const HomeworkScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<AuthProvider>().userRole ?? 'guest';

    switch (userRole) {
      case 'student':
        return const StudentHomeworkScreen();
      case 'teacher':
        return const TeacherHomeworkScreen();

      default:
        return Scaffold(
          appBar: AppBar(title: const Text('Homework'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
          body: const Center(child: Text('Access denied. Please log in.')),
        );
    }
  }
}
