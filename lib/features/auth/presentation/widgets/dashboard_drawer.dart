// Reusable dashboard drawer widget
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/core/navigation/app_routes.dart';

class DashboardDrawer extends StatelessWidget {
  final String title;
  final String? userRole;

  const DashboardDrawer({Key? key, required this.title, this.userRole}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primary),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text('TrackApp', style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(title, style: TextStyle(color: Colors.white70, fontSize: 16)),
              ],
            ),
          ),
          ListTile(
            leading: Icon(Icons.home),
            title: Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
              // Navigate to appropriate dashboard based on role
              if (userRole == 'student') {
                Navigator.pushNamed(context, AppRoutes.studentDashboard);
              } else if (userRole == 'teacher') {
                Navigator.pushNamed(context, AppRoutes.teacherDashboard);
              } else if (userRole == 'parent') {
                Navigator.pushNamed(context, AppRoutes.parentDashboard);
              } else if (userRole == 'driver') {
                Navigator.pushNamed(context, AppRoutes.driverDashboard);
              } else {
                Navigator.pushNamed(context, AppRoutes.home);
              }
            },
          ),

          // Role-specific menu items
          if (userRole == 'student') ...[
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Attendance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.attendance);
              },
            ),
            ListTile(
              leading: Icon(Icons.assignment),
              title: Text('Homework'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.homework);
              },
            ),
            ListTile(
              leading: Icon(Icons.summarize_rounded),
              title: Text('Summerize'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.summerize);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final authProvider = context.read<AuthProvider>();
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                }
              },
            ),
          ],
          if (userRole == 'teacher') ...[
            ListTile(
              leading: Icon(Icons.calendar_today),
              title: Text('Attendance'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.attendance);
              },
            ),
            ListTile(
              leading: Icon(Icons.assignment),
              title: Text('Homework'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.homework);
              },
            ),
            ListTile(
              leading: Icon(Icons.subject),
              title: Text('Manage Subjects'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.subjectManagement);
              },
            ),
            ListTile(
              leading: Icon(Icons.summarize_rounded),
              title: Text('Summerize'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.summerize);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final authProvider = context.read<AuthProvider>();
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                }
              },
            ),
          ],
          if (userRole == 'parent') ...[
            ListTile(
              leading: Icon(Icons.people),
              title: Text('Manage Children'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.parentChildrenEdit);
              },
            ),
            ListTile(
              leading: Icon(Icons.summarize_rounded),
              title: Text('Summerize'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.summerize);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final authProvider = context.read<AuthProvider>();
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                }
              },
            ),
          ],
          if (userRole == 'driver') ...[
            ListTile(
              leading: Icon(Icons.directions_bus),
              title: Text('My Bus Rides'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRoutes.busRides);
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text('Logout', style: TextStyle(color: Colors.red)),
              onTap: () async {
                final authProvider = context.read<AuthProvider>();
                await authProvider.signOut();
                if (context.mounted) {
                  Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (route) => false);
                }
              },
            ),
          ],
        ],
      ),
    );
  }
}
