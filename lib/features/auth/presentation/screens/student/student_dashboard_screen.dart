// Student dashboard screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/attendance/data/models/attendance_record_model.dart';
import 'package:track_app/features/homework/data/models/homework_model.dart';
import 'package:track_app/features/notification/data/models/notification_model.dart';
import 'package:track_app/features/attendance/logic/attendance_provider.dart';
import 'package:track_app/features/homework/logic/homework_provider.dart';
import 'package:track_app/features/notification/logic/notification_provider.dart';
import 'package:track_app/core/enums.dart';
import 'package:track_app/core/navigation/app_routes.dart';
import 'package:track_app/features/auth/presentation/widgets/dashboard_drawer.dart';

class StudentDashboardScreen extends StatefulWidget {
  const StudentDashboardScreen({super.key});

  @override
  State<StudentDashboardScreen> createState() => _StudentDashboardScreenState();
}

class _StudentDashboardScreenState extends State<StudentDashboardScreen> with RouteAware {
  List<AttendanceRecordModel> _recentAttendance = [];
  List<HomeworkModel> _upcomingHomework = [];
  List<NotificationModel> _recentNotifications = [];
  bool _isLoading = true;
  String? _loadedStudentId;
  RouteObserver<PageRoute>? _routeObserver;

  @override
  void initState() {
    super.initState();
    // Data is now loaded in didChangeDependencies and didPopNext.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _routeObserver = Provider.of<RouteObserver<PageRoute>>(context, listen: false);
    _routeObserver?.subscribe(this, ModalRoute.of(context)! as PageRoute);

    final studentId = context.watch<AuthProvider>().currentUser?.id;

    // Initial data load
    if (studentId != null && studentId != _loadedStudentId) {
      _loadedStudentId = studentId;
      _loadDashboardData();
    }
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // Reload data when returning to this screen
    _loadDashboardData();
  }

  @override
  void didPush() {}
  @override
  void didPop() {}
  @override
  void didPushNext() {}

  Future<void> _loadDashboardData() async {
    final studentId = context.read<AuthProvider>().currentUser?.id ?? "";

    setState(() {
      _isLoading = true;
    });

    try {
      // Load recent attendance records
      final attendanceRecords = await locator.attendanceRecordRepository.getRecordsByStudent(studentId);
      _recentAttendance = attendanceRecords.reversed.take(10).toList(); // Get most recent 10 records

      // Load upcoming homework
      final allHomework = await locator.homeworkRepository.getHomeworkByStudent(studentId);
      _upcomingHomework = allHomework.where((hw) => hw.dueDate.isAfter(DateTime.now())).toList()..sort((a, b) => a.dueDate.compareTo(b.dueDate));

      // Load recent notifications
      _recentNotifications = await locator.notificationRepository.getNotificationsByUser(studentId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading dashboard data: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<AuthProvider>().userRole;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Student Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.notifications);
            },
          ),
        ],
      ),
      drawer: DashboardDrawer(title: 'Student Dashboard', userRole: userRole),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Text(
                            'Welcome back, ${authProvider.currentUser?.name ?? "Student"}!',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildStatsCard(_recentAttendance, _upcomingHomework),
                      const SizedBox(height: 16),
                      const Text('Recent Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _recentAttendance.isEmpty ? _buildEmptyCard('No recent attendance records') : _buildAttendanceCard(_recentAttendance),
                      const SizedBox(height: 16),
                      const Text('Upcoming Homework', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _upcomingHomework.isEmpty ? _buildEmptyCard('No upcoming homework') : _buildHomeworkCard(_upcomingHomework),
                      const SizedBox(height: 16),
                      const Text('Recent Notifications', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _recentNotifications.isEmpty ? _buildEmptyCard('No recent notifications') : _buildNotificationsCard(_recentNotifications),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatsCard(List<AttendanceRecordModel> recentAttendance, List<HomeworkModel> upcomingHomework) {
    final presentCount = recentAttendance.where((record) => record.status.value == 'present').length;
    final absentCount = recentAttendance.where((record) => record.status.value == 'absent').length;
    final lateCount = recentAttendance.where((record) => record.status.value == 'late').length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatItem(presentCount, 'Present', Colors.green),
            _buildStatItem(absentCount, 'Absent', Colors.red),
            _buildStatItem(lateCount, 'Late', Colors.orange),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(int count, String label, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildAttendanceCard(List<AttendanceRecordModel> recentAttendance) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children:
              recentAttendance.reversed
                  .take(3) // Show only the 3 most recent
                  .map(
                    (record) => ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              record.status.value == 'present'
                                  ? Colors.green.shade100
                                  : record.status.value == 'late'
                                  ? Colors.orange.shade100
                                  : Colors.red.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            record.status.value[0].toUpperCase(),
                            style: TextStyle(
                              color:
                                  record.status.value == 'present'
                                      ? Colors.green
                                      : record.status.value == 'late'
                                      ? Colors.orange
                                      : Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        'Attendance',
                        style: TextStyle(
                          color:
                              record.status.value == 'present'
                                  ? Colors.green
                                  : record.status.value == 'late'
                                  ? Colors.orange
                                  : Colors.red,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      subtitle: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(record.scanTime)),
                      trailing: Icon(
                        record.status.value == 'present'
                            ? Icons.check_circle
                            : record.status.value == 'late'
                            ? Icons.access_time
                            : Icons.cancel,
                        color:
                            record.status.value == 'present'
                                ? Colors.green
                                : record.status.value == 'late'
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildHomeworkCard(List<HomeworkModel> upcomingHomework) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children:
              upcomingHomework
                  .take(3) // Show only the 3 most urgent
                  .map(
                    (homework) => ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(20)),
                        child: const Icon(Icons.assignment, color: Colors.blue),
                      ),
                      title: Text(homework.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                      subtitle: Text('Due: ${DateFormat('MMM dd, yyyy').format(homework.dueDate)}'),
                      trailing:
                          homework.dueDate.isBefore(DateTime.now().add(const Duration(days: 1)))
                              ? Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: Colors.red.shade100, borderRadius: BorderRadius.circular(12)),
                                child: const Text('URGENT', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold)),
                              )
                              : null,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildNotificationsCard(List<NotificationModel> recentNotifications) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children:
              recentNotifications
                  .map(
                    (notification) => ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: notification.isRead ? Colors.grey.shade100 : Colors.blue.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(
                          notification.type == NotificationType.attendance
                              ? Icons.calendar_today
                              : notification.type == NotificationType.homework
                              ? Icons.assignment
                              : Icons.notifications,
                          color: notification.isRead ? Colors.grey : Colors.blue,
                        ),
                      ),
                      title: Text(
                        notification.message.length > 50 ? '${notification.message.substring(0, 50)}...' : notification.message,
                        style: TextStyle(fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold),
                      ),
                      subtitle: Text(DateFormat('MMM dd, hh:mm a').format(notification.timestamp)),
                      trailing:
                          !notification.isRead
                              ? Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))
                              : null,
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildEmptyCard(String message) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(child: Text(message, style: const TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))),
      ),
    );
  }
}
