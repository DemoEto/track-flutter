import 'package:flutter/material.dart';

// Auth screens

import 'package:track_app/features/auth/presentation/screens/forgot_password_screen.dart';
import 'package:track_app/features/auth/presentation/screens/home_screen.dart';
import 'package:track_app/features/auth/presentation/screens/login_screen.dart';
import 'package:track_app/features/auth/presentation/screens/sign_up_screen.dart';
import 'package:track_app/features/auth/presentation/screens/splash_screen.dart';
import 'package:track_app/features/auth/presentation/screens/student/student_dashboard_screen.dart';
import 'package:track_app/features/auth/presentation/screens/teacher/teacher_dashboard_screen.dart';
import 'package:track_app/features/auth/presentation/screens/parent/parent_dashboard_screen.dart';
import 'package:track_app/features/parent/presentation/screens/parent/parent_children_edit_screen.dart';

// Driver screens
import 'package:track_app/features/auth/presentation/screens/driver/driver_dashboard_screen.dart';
import 'package:track_app/features/driver/presentation/screens/driver_bus_ride_screen.dart';

// Attendance screens
import 'package:track_app/features/attendance/presentation/screens/attendance_screen.dart';

// Homework screens
import 'package:track_app/features/homework/presentation/screens/homework_screen.dart';

// Notification screens
import 'package:track_app/features/notification/presentation/screens/notification_screen.dart';

// Subject screens
import 'package:track_app/features/subject/presentation/screens/teacher/teacher_subject_management_screen.dart';

// Sumerized 
import 'package:track_app/features/summerize/presentation/screens/summerize_screen.dart';

class AppRoutes {
  // Attendance Routes
  static const String attendance = '/attendance';
  static const String teacherAttendanceEdit = '/attendance/teacher/edit';

  // Core/Auth Routes
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String login = '/login';
  static const String signup = '/signup';
  static const String splash = '/splash';

  // Dashboard Routes
  static const String studentDashboard = '/student';
  static const String teacherDashboard = '/teacher';
  static const String parentDashboard = '/parent';
  static const String driverDashboard = '/driver';

  // Parent specific routes
  static const String parentChildrenEdit = '/parent/children/edit';

  // Homework Routes
  static const String homework = '/homework';
  static const String homeworkCreate = '/homework/create';
  static const String homeworkEdit = '/homework/edit';
  static const String homeworkReview = '/homework/review';

  // Notification Routes
  static const String notifications = '/notifications';

  // Driver Routes
  static const String busRides = '/driver/rides';

  // Subject Routes
  static const String subjectManagement = '/subjects';

  static const String summerize = '/summerize';

  // Routes with arguments

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      // Core/Auth Routes
      case forgotPassword:
        return MaterialPageRoute(builder: (context) => const ForgotPasswordScreen());
      case home:
        return MaterialPageRoute(builder: (context) => const HomeScreen());
      case login:
        return MaterialPageRoute(builder: (context) => const LoginScreen());
      case signup:
        return MaterialPageRoute(builder: (context) => const SignUpScreen());
      case splash:
        return MaterialPageRoute(builder: (context) => const SplashScreen());

      // Dashboard Routes
      case studentDashboard:
        return MaterialPageRoute(builder: (context) => const StudentDashboardScreen());
      case teacherDashboard:
        return MaterialPageRoute(builder: (context) => const TeacherDashboardScreen());
      case parentDashboard:
        return MaterialPageRoute(builder: (context) => const ParentDashboardScreen());
      case driverDashboard:
        return MaterialPageRoute(builder: (context) => const DriverDashboardScreen());

      // Homework Routes
      case AppRoutes.homework:
        return MaterialPageRoute(builder: (context) => const HomeworkScreen());

      // Attendance Routes
      case AppRoutes.attendance:
        return MaterialPageRoute(builder: (context) => const AttendanceScreen());

      // Driver Routes
      case AppRoutes.busRides:
        return MaterialPageRoute(builder: (context) => const DriverBusRideScreen());

      // Parent Routes
      case AppRoutes.parentChildrenEdit:
        return MaterialPageRoute(builder: (context) => const ParentChildrenEditScreen());

      // Notification Routes
      case notifications:
        return MaterialPageRoute(builder: (context) => const NotificationScreen());

      // Subject Routes
      case AppRoutes.subjectManagement:
        return MaterialPageRoute(builder: (context) => const TeacherSubjectManagementScreen());

      case AppRoutes.summerize:
        return MaterialPageRoute(builder: (context) => const SummerizeScreen());

      default:
        return MaterialPageRoute(builder: (context) => const LoginScreen());
    }
  }
}
