// Teacher dashboard screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/attendance/data/models/attendance_session_model.dart';
import 'package:track_app/features/homework/data/models/homework_model.dart';
import 'package:track_app/features/homework/data/models/submission_model.dart';
import 'package:track_app/core/navigation/app_routes.dart';
import 'package:track_app/features/auth/presentation/widgets/dashboard_drawer.dart';

class TeacherDashboardScreen extends StatefulWidget {
  const TeacherDashboardScreen({super.key});

  @override
  State<TeacherDashboardScreen> createState() => _TeacherDashboardScreenState();
}

class _TeacherDashboardScreenState extends State<TeacherDashboardScreen> with RouteAware {
  // State variables to hold dashboard data
  List<HomeworkModel> _assignedHomework = [];
  List<SubmissionModel> _pendingSubmissions = [];
  List<AttendanceSessionModel> _recentSessions = [];
  bool _isLoading = true;
  String? _loadedTeacherId;
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

    final teacherId = context.watch<AuthProvider>().currentUser?.id;

    // Initial data load
    if (teacherId != null && teacherId != _loadedTeacherId) {
      _loadedTeacherId = teacherId;
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
    // Set loading state
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final teacherId = context.read<AuthProvider>().currentUser?.id;
      if (teacherId == null) throw Exception("Current teacher not found.");

      // 1. Fetch subjects for the teacher
      final subjects = await locator.subjectRepository.getSubjectsByTeacher(teacherId);
      final subjectIds = subjects.map((s) => s.id).toList();

      final allHomework = <HomeworkModel>[];
      final allSessions = <AttendanceSessionModel>[];
      final allSubmissions = <SubmissionModel>[];

      if (subjectIds.isNotEmpty) {
        // 2. Fetch homework and sessions for all subjects
        // NOTE: This assumes repository methods `getHomeworkBySubject` and `getSessionsBySubject` exist and return Futures.
        final homeworkFutures = subjectIds.map((id) => locator.homeworkRepository.getHomeworkBySubject(id)).toList();
        final sessionFutures = subjectIds.map((id) => locator.attendanceSessionRepository.getSessionsBySubject(id)).toList();

        final homeworkResults = await Future.wait(homeworkFutures);
        for (final hwList in homeworkResults) {
          allHomework.addAll(hwList);
        }

        final sessionResults = await Future.wait(sessionFutures);
        for (final sessionList in sessionResults) {
          allSessions.addAll(sessionList);
        }
      }

      // 3. Fetch submissions for all fetched homework
      if (allHomework.isNotEmpty) {
        final submissionFutures = allHomework.map((hw) => locator.submissionRepository.getSubmissionsByHomework(hw.id)).toList();
        final submissionResults = await Future.wait(submissionFutures);
        for (final subList in submissionResults) {
          allSubmissions.addAll(subList);
        }
      }

      // 4. Filter and sort the data as needed
      final pendingSubmissions = allSubmissions.where((s) => s.status.value == 'submitted').toList();

      final cutoffDate = DateTime.now().subtract(const Duration(days: 7));
      final recentSessions = allSessions.where((s) => s.date.isAfter(cutoffDate)).toList()..sort((a, b) => b.date.compareTo(a.date));

      allHomework.sort((a, b) => b.dueDate.compareTo(a.dueDate));

      // 5. Update the state with the new data
      if (mounted) {
        setState(() {
          _assignedHomework = allHomework;
          _pendingSubmissions = pendingSubmissions;
          _recentSessions = recentSessions;
        });
      }
    } catch (e) {
      debugPrint('Error loading teacher dashboard data: $e');
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
        title: const Text('Teacher Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false, // Remove back button
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
      drawer: DashboardDrawer(title: 'Teacher Dashboard', userRole: userRole),
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
                      // Welcome message
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Text(
                            'Hello, ${authProvider.currentUser?.name ?? "Teacher"}!',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Quick stats from local state
                      _buildStatsCard(_assignedHomework, _pendingSubmissions),
                      const SizedBox(height: 16),

                      // Pending submissions from local state
                      const Text('Pending Submissions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _pendingSubmissions.isEmpty ? _buildEmptyCard('No pending submissions') : _buildPendingSubmissionsCard(_pendingSubmissions),
                      const SizedBox(height: 16),

                      // Recent attendance from local state
                      const Text('Recent Attendance Sessions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _recentSessions.isEmpty ? _buildEmptyCard('No recent attendance sessions') : _buildAttendanceCard(_recentSessions),
                      const SizedBox(height: 16),

                      // Assigned homework from local state
                      const Text('Assigned Homework', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _assignedHomework.isEmpty ? _buildEmptyCard('No assigned homework') : _buildHomeworkCard(_assignedHomework),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatsCard(List<HomeworkModel> assignedHomework, List<SubmissionModel> pendingSubmissions) {
    final homeworkCount = assignedHomework.length;
    final pendingSubmissionsCount = pendingSubmissions.length;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [_buildStatItem(homeworkCount, 'Homework', Colors.blue), _buildStatItem(pendingSubmissionsCount, 'Submissions', Colors.orange)],
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

  Widget _buildPendingSubmissionsCard(List<SubmissionModel> pendingSubmissions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children:
              pendingSubmissions
                  .take(3) // Show only the 3 most recent
                  .map(
                    (submission) => FutureBuilder(
                      future: _getHomeworkTitle(submission.homeworkId),
                      builder: (context, snapshot) {
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.pending_actions, color: Colors.orange),
                          ),
                          title: Text(snapshot.data ?? 'Loading homework...', style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: FutureBuilder(
                            future: _getStudentName(submission.studentId),
                            builder: (context, studentSnapshot) {
                              return Text('From: ${studentSnapshot.data ?? 'Loading...'}');
                            },
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard(List<AttendanceSessionModel> recentSessions) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children:
              recentSessions
                  .take(3) // Show only the 3 most recent
                  .map(
                    (session) => FutureBuilder(
                      future: _getSubjectName(session.subjectId),
                      builder: (context, snapshot) {
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: Colors.green.shade100, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.calendar_today, color: Colors.green),
                          ),
                          title: Text(snapshot.data ?? 'Loading subject...', style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text(DateFormat('MMM dd, yyyy - hh:mm a').format(session.date)),
                        );
                      },
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildHomeworkCard(List<HomeworkModel> assignedHomework) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children:
              assignedHomework
                  .take(3) // Show only the 3 most recent
                  .map(
                    (homework) => FutureBuilder(
                      future: _getSubjectName(homework.subjectId),
                      builder: (context, snapshot) {
                        return ListTile(
                          leading: Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(color: Colors.blue.shade100, borderRadius: BorderRadius.circular(20)),
                            child: const Icon(Icons.assignment, color: Colors.blue),
                          ),
                          title: Text(homework.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                          subtitle: Text('For: ${snapshot.data ?? 'Loading...'}'),
                          trailing:
                              homework.dueDate.isBefore(DateTime.now())
                                  ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(12)),
                                    child: const Text('PAST DUE', style: TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.w500)),
                                  )
                                  : Text(DateFormat('MMM dd').format(homework.dueDate), style: const TextStyle(color: Colors.grey)),
                        );
                      },
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

  Future<String> _getSubjectName(String subjectId) async {
    try {
      final subject = await locator.subjectRepository.getSubject(subjectId);
      return subject?.name ?? 'Unknown Subject';
    } catch (e) {
      return 'Unknown Subject';
    }
  }

  Future<String> _getStudentName(String studentId) async {
    try {
      final student = await locator.userRepository.getUser(studentId);
      return student?.name ?? 'Unknown Student';
    } catch (e) {
      return 'Unknown Student';
    }
  }

  Future<String> _getHomeworkTitle(String homeworkId) async {
    try {
      final homework = await locator.homeworkRepository.getHomework(homeworkId);
      return homework?.title ?? 'Unknown Homework';
    } catch (e) {
      return 'Unknown Homework';
    }
  }
}
