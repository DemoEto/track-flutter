// Teacher attendance detail screen showing detailed information for a specific attendance session
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/attendance/data/models/attendance_session_model.dart';
import 'package:track_app/features/attendance/data/models/attendance_record_model.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';

import 'package:track_app/core/enums.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TeacherAttendanceDetailScreen extends StatefulWidget {
  final AttendanceSessionModel session;

  const TeacherAttendanceDetailScreen({super.key, required this.session});

  @override
  State<TeacherAttendanceDetailScreen> createState() => _TeacherAttendanceDetailScreenState();
}

class _TeacherAttendanceDetailScreenState extends State<TeacherAttendanceDetailScreen> {
  SubjectModel? _subject;
  List<UserModel> _allStudentsInSubject = [];
  List<AttendanceRecordModel> _records = [];
  bool _isLoading = true;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadSubjectDetails();
    _loadAttendanceData();
    // Start a timer to refresh data periodically
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (Timer t) {
      _loadAttendanceData();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSubjectDetails() async {
    try {
      _subject = await locator.subjectRepository.getSubject(widget.session.subjectId);
      _loadStudentsForSubject();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading subject details: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _loadStudentsForSubject() async {
    try {
      // Get enrolled students for the subject
      final enrolledStudentIds = await locator.subjectRepository.getStudentIdsForSubject(widget.session.subjectId);
      final enrolledStudents = <UserModel>[];

      for (final studentId in enrolledStudentIds) {
        final student = await locator.userRepository.getUser(studentId);
        if (student != null) {
          enrolledStudents.add(student);
        }
      }

      if (mounted) {
        setState(() {
          _allStudentsInSubject = enrolledStudents;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading students: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _loadAttendanceData() async {
    try {
      _records = await locator.attendanceRecordRepository.getRecordsBySession(widget.session.id);
      setState(() {
        // Only update loading status on the first load
        if (_isLoading) {
          _isLoading = false;
        }
      });
    } catch (e) {
      // Only set loading to false on error if it was loading initially
      if (_isLoading) {
        setState(() {
          _isLoading = false;
        });
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading attendance records: $e'), backgroundColor: Colors.red));
      }
    }
  }

  AttendanceStatus _getStudentAttendanceStatus(String studentId) {
    final record = _records.firstWhere(
      (r) => r.studentId == studentId,
      orElse:
          () => AttendanceRecordModel(
            id: '',
            sessionId: widget.session.id,
            studentId: studentId,
            scanTime: DateTime.now(),
            status: AttendanceStatus.absent,
            createdAt: DateTime.now(),
          ),
    );
    return record.status;
  }

  Color _getStatusColor(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return Colors.green;
      case AttendanceStatus.late:
        return Colors.orange;
      case AttendanceStatus.absent:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
      default:
        return 'Unknown';
    }
  }

  int _getAttendanceCount(AttendanceStatus status) {
    return _records.where((record) => record.status == status).length;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: Text('Attendance - ${_subject?.name ?? 'Subject'}'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final presentCount = _getAttendanceCount(AttendanceStatus.present);
    final lateCount = _getAttendanceCount(AttendanceStatus.late);
    final absentCount = _allStudentsInSubject.length - presentCount - lateCount; // Students without records are absent
    final totalStudents = _allStudentsInSubject.length;

    return Scaffold(
      appBar: AppBar(title: Text('Attendance - ${_subject?.name ?? 'Subject'}'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: RefreshIndicator(
        onRefresh: _loadAttendanceData,
        child: CustomScrollView(
          slivers: [
            // Stats header - always show this
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), spreadRadius: 1, blurRadius: 5, offset: const Offset(0, 2))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Session Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        Text('${widget.session.date.toString().split('.')[0]}', style: const TextStyle(fontSize: 16, color: Colors.grey)), //-- show date time
                      ],
                    ),
                    const SizedBox(height: 12),
                    // QR Code section
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(8)),
                      child: Center(
                        child: Column(
                          children: [
                            const Text('Session QR Code', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: QrImageView(data: widget.session.qrCode, version: QrVersions.auto, size: 150.0, gapless: false),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'QR: ${widget.session.qrCode}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(presentCount, 'Present', Colors.green, totalStudents),
                        _buildStatItem(lateCount, 'Late', Colors.orange, totalStudents),
                        _buildStatItem(absentCount, 'Absent', Colors.red, totalStudents),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text('Total Students: $totalStudents', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
            ),

            // Students List
            if (_allStudentsInSubject.isNotEmpty)
              SliverList(
                delegate: SliverChildBuilderDelegate((context, index) {
                  final student = _allStudentsInSubject[index];
                  final attendanceStatus = _getStudentAttendanceStatus(student.id);
                  final record = _records.firstWhere(
                    (r) => r.studentId == student.id,
                    orElse:
                        () => AttendanceRecordModel(
                          id: '',
                          sessionId: widget.session.id,
                          studentId: student.id,
                          scanTime: DateTime.now(),
                          status: AttendanceStatus.absent,
                          createdAt: DateTime.now(),
                        ),
                  );

                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                    child: ListTile(
                      leading: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color:
                              attendanceStatus == AttendanceStatus.present
                                  ? Colors.green
                                  : attendanceStatus == AttendanceStatus.late
                                  ? Colors.orange
                                  : Colors.red,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Center(
                          child: Text(
                            attendanceStatus.value[0].toUpperCase(),
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      title: Text(student.name),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${attendanceStatus.value.toUpperCase()}'),
                          if (attendanceStatus != AttendanceStatus.absent)
                            Text('Time: ${record.scanTime.hour.toString().padLeft(2, '0')}:${record.scanTime.minute.toString().padLeft(2, '0')}'),
                        ],
                      ),
                      trailing: Icon(
                        attendanceStatus == AttendanceStatus.present
                            ? Icons.check_circle
                            : attendanceStatus == AttendanceStatus.late
                            ? Icons.access_time
                            : Icons.cancel,
                        color:
                            attendanceStatus == AttendanceStatus.present
                                ? Colors.green
                                : attendanceStatus == AttendanceStatus.late
                                ? Colors.orange
                                : Colors.red,
                      ),
                    ),
                  );
                }, childCount: _allStudentsInSubject.length),
              )
            else
              SliverToBoxAdapter(
                child: Container(
                  margin: const EdgeInsets.all(16.0),
                  padding: const EdgeInsets.all(16.0),
                  child: const Center(child: Text('No students enrolled in this subject yet.', textAlign: TextAlign.center)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(int count, String label, Color color, int totalStudents) {
    final percentage = totalStudents > 0 ? ((count / totalStudents) * 100).round() : 0;
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Column(
            children: [
              Text(count.toString(), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
              Text('$percentage%', style: TextStyle(fontSize: 12, color: color)),
            ],
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }
}
