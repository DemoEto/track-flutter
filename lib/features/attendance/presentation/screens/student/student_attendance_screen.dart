// Student attendance screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/attendance/data/models/attendance_record_model.dart';
import 'package:track_app/features/attendance/data/models/attendance_session_model.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';

import 'package:track_app/features/attendance/presentation/screens/student/student_attendance_scan_screen.dart';

class StudentAttendanceScreen extends StatefulWidget {
  const StudentAttendanceScreen({super.key});

  @override
  State<StudentAttendanceScreen> createState() => _StudentAttendanceScreenState();
}

class _StudentAttendanceScreenState extends State<StudentAttendanceScreen> {
  List<AttendanceRecordModel> _attendanceRecords = [];
  List<AttendanceSessionModel> _sessions = [];
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAttendanceData();
  }

  Future<void> _loadAttendanceData() async {
    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) return;

    try {
      if (currentUser.role.value == 'student') {
        // Load attendance records for the student
        _attendanceRecords = await locator.attendanceRecordRepository.getRecordsByStudent(currentUser.id);

        // Filter out records that don't have valid sessions (for deleted sessions)
        final validRecords = <AttendanceRecordModel>[];
        for (final record in _attendanceRecords) {
          final session = await locator.attendanceSessionRepository.getSession(record.sessionId);
          if (session != null) {
            validRecords.add(record);
            _sessions.add(session);

            // Also load the related subject
            final subject = await locator.subjectRepository.getSubject(session.subjectId);
            if (subject != null) {
              _subjects.add(subject);
            }
          }
        }
        _attendanceRecords = validRecords;
      } else if (currentUser.role.value == 'teacher') {
        // Load subjects for the teacher
        _subjects = await locator.subjectRepository.getSubjectsByTeacher(currentUser.id);

        // Load sessions for those subjects
        for (final subject in _subjects) {
          final subjectSessions = await locator.attendanceSessionRepository.getSessionsBySubject(subject.id);
          _sessions.addAll(subjectSessions);
        }

        // Load attendance records for those sessions
        for (final session in _sessions) {
          final sessionRecords = await locator.attendanceRecordRepository.getRecordsBySession(session.id);
          _attendanceRecords.addAll(sessionRecords);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        String errorMessage = e.toString();
        if (e is Exception) {
          errorMessage = e.toString();
        } else if (e is Error) {
          errorMessage = e.toString();
        } else {
          errorMessage = 'Error loading attendance data: $e';
        }
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(errorMessage), backgroundColor: Colors.red));
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Attendance'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(MaterialPageRoute(builder: (context) => const StudentAttendanceScanScreen()));
          // Refresh data after returning from scan screen
          setState(() {
            _isLoading = true;
          });
          await _loadAttendanceData();
        },
        child: const Icon(Icons.qr_code_scanner),
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _attendanceRecords.isEmpty
              ? const Center(child: Text('No attendance records found', style: TextStyle(fontSize: 16)))
              : Padding(
                padding: const EdgeInsets.all(8.0),
                child: ListView.builder(
                  itemCount: _attendanceRecords.length,
                  itemBuilder: (context, index) {
                    final record = _attendanceRecords[index];
                    final session = _sessions.firstWhere(
                      (s) => s.id == record.sessionId,
                      orElse:
                          () => AttendanceSessionModel(
                            id: record.sessionId,
                            subjectId: 'unknown',
                            date: DateTime.now(),
                            qrCode: 'unknown',
                            createdAt: DateTime.now(),
                          ),
                    );

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color:
                                record.status.value == 'present'
                                    ? Colors.green
                                    : record.status.value == 'late'
                                    ? Colors.orange
                                    : Colors.red,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              record.status.value[0].toUpperCase(),
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        title: Text(_getSubjectName(session.subjectId)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Date: ${session.date.toString().split(' ')[0]}'),
                            Text('Time: ${session.date.toString().split(' ')[1].substring(0, 5)}'),
                            Text('Status: ${record.status.value.toUpperCase()}'),
                          ],
                        ),
                        trailing: Text(
                          '${record.scanTime.hour.toString().padLeft(2, '0')}:${record.scanTime.minute.toString().padLeft(2, '0')}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
