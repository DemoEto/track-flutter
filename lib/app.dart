import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/core/constants.dart';
import 'package:track_app/core/navigation/app_routes.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/notification/logic/notification_provider.dart';
import 'package:track_app/features/homework/logic/homework_provider.dart';
import 'package:track_app/features/attendance/logic/attendance_provider.dart';
import 'package:track_app/features/attendance/logic/subject_provider.dart';
import 'package:track_app/features/subject/logic/subject_enrollment_provider.dart';
import 'package:track_app/features/driver/logic/driver_provider.dart';

// Global RouteObserver
final RouteObserver<PageRoute> routeObserver = RouteObserver<PageRoute>();

class TrackApp extends StatelessWidget {
  const TrackApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => NotificationProvider()),
        ChangeNotifierProvider(create: (context) => HomeworkProvider()),
        ChangeNotifierProvider(create: (context) => AttendanceProvider()),
        ChangeNotifierProvider(create: (context) => SubjectProvider()),
        ChangeNotifierProvider(create: (context) => SubjectEnrollmentProvider()),
        ChangeNotifierProvider(create: (context) => DriverProvider()),
        // Provide the RouteObserver to the widget tree
        Provider<RouteObserver<PageRoute>>.value(value: routeObserver),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        themeMode: ThemeMode.system,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generateRoute,
        // Register the RouteObserver
        navigatorObservers: [routeObserver],
      ),
    );
  }
}
