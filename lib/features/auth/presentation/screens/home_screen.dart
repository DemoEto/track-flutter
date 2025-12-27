// Home screen that redirects to appropriate dashboard based on user role
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/core/navigation/app_routes.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        final userRole = authProvider.userRole;
        if (userRole == null) {
          // ยังโหลด user ไม่เสร็จ
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }
        WidgetsBinding.instance.addPostFrameCallback((_) {
          String route;
          switch (userRole) {
            case 'teacher':
              route = AppRoutes.teacherDashboard;
              break;
            case 'student':
              route = AppRoutes.studentDashboard;
              break;
            case 'parent':
              route = AppRoutes.parentDashboard;
              break;
            case 'driver':
              route = AppRoutes.driverDashboard;
              break;
            default:
              route = AppRoutes.login;
          }
          if (ModalRoute.of(context)?.settings.name != route) {
            Navigator.pushReplacementNamed(context, route);
          }
        });
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      },
    );
  }
}
