// Teacher attendance screen showing attendance sessions and student details
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/attendance/data/models/attendance_session_model.dart';
import 'package:track_app/features/attendance/data/models/attendance_record_model.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';

import 'teacher_attendance_detail_screen.dart';
import 'teacher_attendance_create_screen.dart';

class TeacherAttendanceScreen extends StatefulWidget {
  const TeacherAttendanceScreen({super.key});

  @override
  State<TeacherAttendanceScreen> createState() => _TeacherAttendanceScreenState();
}

class _TeacherAttendanceScreenState extends State<TeacherAttendanceScreen> {
  List<AttendanceSessionModel> _sessions = [];
  List<SubjectModel> _subjects = [];
  Map<String, List<AttendanceRecordModel>> _sessionRecords = {};
  Map<String, List<UserModel>> _students = {};
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
    // Start a timer to refresh data periodically
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (Timer t) {
      _loadAttendanceData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
    // clear previous data
    _sessions.clear();
    _subjects.clear();
    _sessionRecords.clear();
    _students.clear();
  }

  Future<void> _loadAttendanceData() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    try {
      setState(() {
        _isLoading = true;
      });

      // โหลดรายวิชาที่สอน
      final subjects = await locator.subjectRepository.getSubjectsByTeacher(currentUser.id);

      // โหลด session ใหม่ของแต่ละวิชา
      for (final subject in subjects) {
        final subjectSessions = await locator.attendanceSessionRepository.getSessionsBySubject(subject.id);

        for (final session in subjectSessions) {
          // ✅ ตรวจสอบว่า session นี้โหลดแล้วหรือยัง
          final alreadyLoaded = _sessions.any((s) => s.id == session.id);
          if (alreadyLoaded) continue;

          // ยังไม่เคยโหลด → โหลดข้อมูล session นี้
          _sessions.add(session);

          // โหลด attendance records
          final records = await locator.attendanceRecordRepository.getRecordsBySession(session.id);
          _sessionRecords[session.id] = records;

          // โหลดข้อมูลนักเรียนของแต่ละ record
          final sessionStudents = <UserModel>[];
          for (final record in records) {
            final student = await locator.userRepository.getUser(record.studentId);
            if (student != null) {
              sessionStudents.add(student);
            }
          }
          _students[session.id] = sessionStudents;
        }
      }

      if (mounted) {
        setState(() {
          _subjects = subjects;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading attendance data: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _getSubjectName(String subjectId) {
    final subject = _subjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => SubjectModel(id: subjectId, name: 'Unknown Subject', teacherId: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
    );
    return subject.name;
  }

  int _getPresentCount(String sessionId) {
    final records = _sessionRecords[sessionId] ?? [];
    return records.where((record) => record.status.value == 'present' || record.status.value == 'late').length;
  }

  int _getAbsentCount(String sessionId) {
    final records = _sessionRecords[sessionId] ?? [];
    return records.where((record) => record.status.value == 'absent').length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Attendance Sessions'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const TeacherAttendanceCreateScreen()));
          // Refresh data after returning from create screen
          setState(() {
            _isLoading = true;
          });
          await _loadAttendanceData();
        },
        child: const Icon(Icons.add),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _sessions.isEmpty
              ? const Center(child: Text('No attendance sessions found', style: TextStyle(fontSize: 16)))
              : RefreshIndicator(
                onRefresh: _loadAttendanceData,
                child: ListView.builder(
                  itemCount: _sessions.length,
                  itemBuilder: (context, index) {
                    final session = _sessions[index];
                    final presentCount = _getPresentCount(session.id);
                    final absentCount = _getAbsentCount(session.id);
                    final totalStudents = presentCount + absentCount;

                    return Card(
                      margin: const EdgeInsets.all(8.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(_getSubjectName(session.subjectId)),
                        subtitle: Text(
                          'Date: ${session.date.toString().split(' ')[0]} Time: ${session.date.toString().split(' ')[1].split('.')[0]}\n'
                          'Present: $presentCount | Absent: $absentCount | Total: $totalStudents',
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${presentCount}/${totalStudents}', style: const TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            Text(
                              '${totalStudents > 0 ? ((presentCount / totalStudents) * 100).round() : 0}% attended',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                        onTap: () {
                          Navigator.push(context, MaterialPageRoute(builder: (context) => TeacherAttendanceDetailScreen(session: session)));
                        },
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
