// Parent dashboard screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/attendance/data/models/attendance_record_model.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';
import 'package:track_app/features/homework/data/models/homework_model.dart';
import 'package:track_app/features/homework/data/models/submission_model.dart';
import 'package:track_app/features/attendance/data/models/attendance_session_model.dart';
import 'package:track_app/core/navigation/app_routes.dart';
import 'package:track_app/features/auth/presentation/widgets/dashboard_drawer.dart';

class ParentDashboardScreen extends StatefulWidget {
  const ParentDashboardScreen({super.key});

  @override
  State<ParentDashboardScreen> createState() => _ParentDashboardScreenState();
}

class _ParentDashboardScreenState extends State<ParentDashboardScreen> with RouteAware {
  List<UserModel> _children = [];
  List<HomeworkModel> _childrenHomework = [];
  List<AttendanceSessionModel> _childrenAttendance = [];
  int _completedHomeworkCount = 0;
  int _totalAttendanceCount = 0;
  int _attendedSessionsCount = 0;
  int _absentSessionsCount = 0;
  int _lateSessionsCount = 0;
  bool _isLoading = true;
  String? _loadedParentId;
  RouteObserver<PageRoute>? _routeObserver;

  @override
  void initState() {
    super.initState();
    // Data is now loaded in didChangeDependencies and didPopNext.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the route observer to detect when we navigate back to this screen.
    // This requires a RouteObserver to be provided in the widget tree (usually in main.dart).
    _routeObserver = Provider.of<RouteObserver<PageRoute>>(context, listen: false);
    _routeObserver?.subscribe(this, ModalRoute.of(context)! as PageRoute);

    final parentId = context.watch<AuthProvider>().currentUser?.id;

    // Initial data load when the widget is first built.
    if (parentId != null && parentId != _loadedParentId) {
      _loadedParentId = parentId;
      _loadDashboardData();
      _startListeningToNotifications(parentId);
    }
  }

  void _startListeningToNotifications(String parentId) {
    // Use NotificationService to listen for new notifications
    locator.notificationRepository.getNotificationsByUserStream(parentId).listen((newNotifications) {
      if (mounted) {
        setState(() {
          _loadDashboardData();
        });
      }
    });
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  /// Called when the top route has been popped off, and this screen is now visible.
  @override
  void didPopNext() {
    debugPrint('Returning to Parent Dashboard, reloading data...');
    _loadDashboardData();
  }

  /// Called when the current route has been pushed.
  @override
  void didPush() {}

  /// Called when the current route has been popped off.
  @override
  void didPop() {}

  /// Called when a new route has been pushed, and the current route is no longer visible.
  @override
  void didPushNext() {}

  Future<void> _loadDashboardData() async {
    // Set loading state, unless it's the very first load (where isLoading is already true)
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final parentId = context.read<AuthProvider>().currentUser?.id;
      if (parentId != null) {
        debugPrint('Loading dashboard data for parent: $parentId');
        _children = await locator.userRepository.getChildrenForParent(parentId);
        debugPrint('Loaded ${_children.length} children');
        await _loadChildrenData();
        debugPrint('Loaded ${_childrenHomework.length} homework items and ${_childrenAttendance.length} attendance sessions');
        await _calculateHomeworkStats();
        debugPrint('Calculated homework stats: $_completedHomeworkCount completed');
        await _calculateAttendanceStats(); // Update to await the async function
        debugPrint('Calculated attendance stats: $_attendedSessionsCount attended out of $_totalAttendanceCount total');
      }
    } catch (e) {
      debugPrint('Error loading parent dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _loadChildrenData() async {
    final List<HomeworkModel> allHomework = [];
    final List<AttendanceSessionModel> allAttendance = [];

    debugPrint('Starting to load children data for ${_children.length} children');

    for (final child in _children) {
      // Load homework for each child
      try {
        debugPrint('Loading homework for child: ${child.name} (${child.id})');
        final homeworkList = await locator.homeworkRepository.getHomeworkByStudent(child.id);
        debugPrint('Found ${homeworkList.length} homework items for ${child.name}');

        // Add homework items only if they don't already exist in the list to avoid duplicates
        for (final homework in homeworkList) {
          if (!allHomework.any((item) => item.id == homework.id)) {
            allHomework.add(homework);
          }
        }
      } catch (e) {
        debugPrint('Error loading homework for child ${child.id}: $e');
      }

      // Load attendance for each child
      try {
        debugPrint('Loading attendance for child: ${child.name} (${child.id})');
        final records = await locator.attendanceRecordRepository.getRecordsByStudent(child.id);
        debugPrint('Found ${records.length} attendance records for ${child.name}');
        for (final record in records) {
          // Get the session details
          final session = await locator.attendanceSessionRepository.getSession(record.sessionId);
          if (session != null) {
            debugPrint('Loaded session ${session.id} for child ${child.name}');
            // Check if this session is already in the list by ID to avoid duplicates
            if (!allAttendance.any((item) => item.id == session.id)) {
              allAttendance.add(session);
            }
          }
        }
      } catch (e) {
        debugPrint('Error loading attendance for child ${child.id}: $e');
      }
    }

    setState(() {
      _childrenHomework = allHomework..sort((a, b) => b.dueDate.compareTo(a.dueDate)); // Sort by due date (newest first)
      _childrenAttendance = allAttendance..sort((a, b) => b.date.compareTo(a.date));
      debugPrint('Final: ${_childrenHomework.length} homework items, ${_childrenAttendance.length} attendance sessions');
    });
  }

  Future<void> _calculateHomeworkStats() async {
    int completedCount = 0;

    for (final child in _children) {
      try {
        final submissions = await locator.submissionRepository.getSubmissionsByStudent(child.id);
        completedCount += submissions.length;
      } catch (e) {
        debugPrint('Error calculating homework stats for child ${child.id}: $e');
      }
    }

    setState(() {
      _completedHomeworkCount = completedCount;
    });
  }

  Future<void> _calculateAttendanceStats() async {
    int totalAttendance = 0;
    int attendedCount = 0;
    int absentCount = 0;
    int lateCount = 0;

    debugPrint('Starting attendance stats calculation for ${_children.length} children');

    for (final child in _children) {
      try {
        debugPrint('Calculating attendance stats for child: ${child.name} (${child.id})');
        final records = await locator.attendanceRecordRepository.getRecordsByStudent(child.id);
        debugPrint('Found ${records.length} records for ${child.name}');
        totalAttendance += records.length;

        // Count sessions by status
        for (final record in records) {
          String statusValue = record.status.toString().split('.').last.toLowerCase();
          debugPrint('Record status: $statusValue');
          if (statusValue == 'present') {
            attendedCount++;
          } else if (statusValue == 'absent') {
            absentCount++;
          } else if (statusValue == 'late') {
            lateCount++;
          }
        }
      } catch (e) {
        debugPrint('Error calculating attendance stats for child ${child.id}: $e');
      }
    }

    setState(() {
      _totalAttendanceCount = totalAttendance;
      _attendedSessionsCount = attendedCount;
      _absentSessionsCount = absentCount;
      _lateSessionsCount = lateCount;
      debugPrint(
        'Attendance stats: $_attendedSessionsCount attended, $_absentSessionsCount absent, $_lateSessionsCount late out of $_totalAttendanceCount total',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<AuthProvider>().userRole;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Parent Dashboard'),
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
      drawer: DashboardDrawer(title: 'Parent Dashboard', userRole: userRole), // Fixed placement
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: () async {
                  await _loadDashboardData();
                },
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Welcome message
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Text(
                            'Hello, ${authProvider.currentUser?.name ?? "Parent"}!',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      const SizedBox(height: 16),

                      // Number of children
                      if (_children.isNotEmpty)
                        Text(
                          'You are responsible for ${_children.length} ${_children.length == 1 ? 'child' : 'children'}',
                          style: const TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      const SizedBox(height: 16),

                      // Children selection if multiple children
                      if (_children.length > 1) _buildChildrenSelector(),
                      const SizedBox(height: 16),

                      // Quick stats - updated to show more detailed information
                      _buildDetailedStatsCard(),
                      const SizedBox(height: 16),

                      // Recent homework
                      const Text('Recent Homework', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _childrenHomework.isNotEmpty
                          ? _buildHomeworkCard()
                          : const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: Text('No recent homework found.', style: TextStyle(color: Colors.grey))),
                            ),
                          ),
                      const SizedBox(height: 16),

                      // Recent attendance
                      const Text('Recent Attendance', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      _childrenAttendance.isNotEmpty
                          ? _buildAttendanceCard()
                          : const Card(
                            child: Padding(
                              padding: EdgeInsets.all(16.0),
                              child: Center(child: Text('No recent attendance found.', style: TextStyle(color: Colors.grey))),
                            ),
                          ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildChildrenSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children:
              _children
                  .map(
                    (child) => ListTile(
                      title: Text(child.name),
                      subtitle: Text(child.email),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                      onTap: () {
                        // TODO: Navigate to specific child's details
                      },
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildDetailedStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12.0), // Reduced padding
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(_children.length, 'Students', Colors.blue),
                _buildStatItem(_childrenHomework.length, 'Homework', Colors.orange),
                _buildStatItem(_completedHomeworkCount, 'Completed', Colors.green),
              ],
            ),
            const SizedBox(height: 12), // Reduced height
            const Divider(), // Added divider for clarity
            const SizedBox(height: 12), // Reduced height
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(_attendedSessionsCount, 'Present', Colors.purple),
                _buildStatItem(_lateSessionsCount, 'Late', Colors.amber),
                _buildStatItem(_absentSessionsCount, 'Absent', Colors.red),
              ],
            ),
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

  Widget _buildHomeworkCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children:
              _childrenHomework
                  .take(5) // Show only the 5 most recent
                  .map(
                    (homework) => FutureBuilder(
                      future: _getHomeworkSubject(homework.subjectId),
                      builder: (context, subjectSnapshot) {
                        return FutureBuilder(
                          future: _getChildNamesForHomework(homework.id),
                          builder: (context, childSnapshot) {
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: Colors.blue.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                                child: const Icon(Icons.assignment, color: Colors.blue),
                              ),
                              title: Text(homework.title, style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Subject: ${subjectSnapshot.data ?? 'Loading...'}'),
                                  Text('Assigned to: ${childSnapshot.data?.join(', ') ?? 'Loading...'}'),
                                ],
                              ),
                              trailing:
                                  homework.dueDate.isBefore(DateTime.now())
                                      ? Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                                        child: const Text('PAST DUE', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500)),
                                      )
                                      : Text(DateFormat('MMM dd').format(homework.dueDate), style: const TextStyle(color: Colors.grey)),
                            );
                          },
                        );
                      },
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Widget _buildAttendanceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children:
              _childrenAttendance
                  .take(5) // Show only the 5 most recent
                  .map(
                    (session) => FutureBuilder(
                      future: _getSubjectName(session.subjectId),
                      builder: (context, subjectSnapshot) {
                        return FutureBuilder(
                          future: _getChildAttendanceStatusForSession(session.id),
                          builder: (context, attendanceSnapshot) {
                            return ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(20)),
                                child: const Icon(Icons.calendar_today, color: Colors.green),
                              ),
                              title: Text(subjectSnapshot.data ?? 'Loading subject...', style: const TextStyle(fontWeight: FontWeight.w500)),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(DateFormat('MMM dd, yyyy - hh:mm a').format(session.date)),
                                  if (attendanceSnapshot.hasData)
                                    ...attendanceSnapshot.data!.map((item) {
                                      Color statusColor = Colors.grey;
                                      String statusText = 'Unknown';

                                      if (item['status'] == 'present' || item['status'] == 'Present') {
                                        statusColor = Colors.green;
                                        statusText = 'Present';
                                      } else if (item['status'] == 'absent' || item['status'] == 'Absent') {
                                        statusColor = Colors.red;
                                        statusText = 'Absent';
                                      } else if (item['status'] == 'late' || item['status'] == 'Late') {
                                        statusColor = Colors.orange;
                                        statusText = 'Late';
                                      }

                                      return Container(
                                        margin: const EdgeInsets.only(top: 4.0),
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('${item['childName']}: ', style: const TextStyle(fontWeight: FontWeight.w500)),
                                            Text(statusText, style: TextStyle(color: statusColor)),
                                          ],
                                        ),
                                      );
                                    }).toList()
                                  else
                                    const Text('Loading attendance...'),
                                ],
                              ),
                            );
                          },
                        );
                      },
                    ),
                  )
                  .toList(),
        ),
      ),
    );
  }

  Future<String?> _getHomeworkSubject(String subjectId) async {
    try {
      final subject = await locator.subjectRepository.getSubject(subjectId);
      return subject?.name ?? 'Unknown Subject';
    } catch (e) {
      return 'Unknown Subject';
    }
  }

  Future<List<String>> _getChildNamesForHomework(String homeworkId) async {
    try {
      final submissions = await locator.submissionRepository.getSubmissionsByHomework(homeworkId);
      final childIds = submissions.map((sub) => sub.studentId).toSet().toList();
      final childNames = <String>[];

      for (final childId in childIds) {
        final child = await locator.userRepository.getUser(childId);
        if (child != null && _children.any((c) => c.id == child.id)) {
          childNames.add(child.name);
        }
      }

      return childNames;
    } catch (e) {
      return ['Unknown'];
    }
  }

  Future<List<String>> _getChildNamesForAttendance(String sessionId) async {
    try {
      final records = await locator.attendanceRecordRepository.getRecordsBySession(sessionId);
      final childIds = records.map((record) => record.studentId).toSet().toList();
      final childNames = <String>[];

      for (final childId in childIds) {
        if (_children.any((c) => c.id == childId)) {
          final child = await locator.userRepository.getUser(childId);
          if (child != null) {
            childNames.add(child.name);
          }
        }
      }

      return childNames;
    } catch (e) {
      return ['Unknown'];
    }
  }

  Future<String?> _getSubjectName(String subjectId) async {
    try {
      final subject = await locator.subjectRepository.getSubject(subjectId);
      return subject?.name ?? 'Unknown Subject';
    } catch (e) {
      return 'Unknown Subject';
    }
  }

  Future<List<Map<String, String>>> _getChildAttendanceStatusForSession(String sessionId) async {
    try {
      debugPrint('Getting attendance status for session: $sessionId');
      final records = await locator.attendanceRecordRepository.getRecordsBySession(sessionId);
      debugPrint('Found ${records.length} records for session $sessionId');
      final attendanceList = <Map<String, String>>[];

      for (final record in records) {
        debugPrint('Processing record for student: ${record.studentId}');
        // Only include records for children that this parent is responsible for
        if (_children.any((child) => child.id == record.studentId)) {
          debugPrint('Student ${record.studentId} is one of the parent\'s children');
          final child = await locator.userRepository.getUser(record.studentId);
          if (child != null) {
            debugPrint('Adding attendance for child ${child.name}: ${record.status.toString().split('.').last}');
            attendanceList.add({
              'childName': child.name,
              'status': record.status.toString().split('.').last, // Convert enum to string
            });
          } else {
            debugPrint('Could not find child with id ${record.studentId}');
          }
        } else {
          debugPrint('Student ${record.studentId} is not one of the parent\'s children');
        }
      }

      // Sort by child name for consistent display
      attendanceList.sort((a, b) => a['childName']!.compareTo(b['childName']!));

      debugPrint('Returning ${attendanceList.length} attendance records for session $sessionId');
      return attendanceList;
    } catch (e) {
      debugPrint('Error getting attendance status for session $sessionId: $e');
      return [];
    }
  }
}
