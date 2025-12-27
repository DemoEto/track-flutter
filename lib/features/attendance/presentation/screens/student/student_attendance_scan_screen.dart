// Student attendance scan screen for scanning QR codes
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'package:uuid/uuid.dart';

import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/attendance/data/models/attendance_record_model.dart';
import 'package:track_app/features/attendance/data/models/attendance_session_model.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';

import 'package:track_app/core/enums.dart';
import 'package:track_app/features/notification/data/models/notification_model.dart';

class StudentAttendanceScanScreen extends StatefulWidget {
  const StudentAttendanceScanScreen({super.key});

  @override
  State<StudentAttendanceScanScreen> createState() => _StudentAttendanceScanScreenState();
}

class _StudentAttendanceScanScreenState extends State<StudentAttendanceScanScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  Barcode? result;
  QRViewController? controller;
  String? _lastScannedCode;
  DateTime? _lastScanTime;
  AttendanceSessionModel? _attendanceSession;
  SubjectModel? _subject;
  bool _attendanceProcessed = false;
  String? _errorMessage;
  AttendanceStatus? _attendanceStatus;

  // In order to get hot reload to work we need to pause the camera if the platform
  // is android, or resume the camera if the platform is iOS.
  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    } else if (Platform.isIOS) {
      controller!.resumeCamera();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Attendance QR'),
        leading:
            _attendanceProcessed
                ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
                : null,
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 5,
            child:
                _attendanceProcessed
                    ? Container(
                      color: Colors.black,
                      child: Center(
                        child: SingleChildScrollView(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  _attendanceStatus == AttendanceStatus.present
                                      ? Icons.check_circle
                                      : _attendanceStatus == AttendanceStatus.late
                                      ? Icons.warning
                                      : Icons.cancel,
                                  size: 64,
                                  color:
                                      _attendanceStatus == AttendanceStatus.present
                                          ? Colors.green
                                          : _attendanceStatus == AttendanceStatus.late
                                          ? Colors.orange
                                          : Colors.red,
                                ),
                                const SizedBox(height: 16),
                                const Text('Attendance Marked', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                                const SizedBox(height: 8),
                                if (_attendanceSession != null) ...[
                                  Text('Subject: ${getSubjectName(_attendanceSession!.subjectId)}', style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('Date: ${formatDate(_attendanceSession!.date)}', style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text('Time: ${formatTime(_attendanceSession!.date)}', style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Status: ${getStatusText(_attendanceStatus!)}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color:
                                          _attendanceStatus == AttendanceStatus.present
                                              ? Colors.green
                                              : _attendanceStatus == AttendanceStatus.late
                                              ? Colors.orange
                                              : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Session is ${isSessionTimeValid(_attendanceSession!.date) ? "within" : "outside"} time range',
                                    style: TextStyle(fontSize: 16, color: isSessionTimeValid(_attendanceSession!.date) ? Colors.green : Colors.red),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    )
                    : QRView(
                      key: qrKey,
                      onQRViewCreated: _onQRViewCreated,
                      // 👇 ใส่กรอบสแกนตรงนี้
                      overlay: QrScannerOverlayShape(
                        borderColor: Colors.blueAccent, // สีของขอบกรอบ
                        borderRadius: 12, // มุมโค้ง
                        borderLength: 35, // ความยาวขอบเส้น
                        borderWidth: 8, // ความหนาของเส้น
                        cutOutSize: MediaQuery.of(context).size.width * 0.7, // ขนาดกรอบ
                      ),
                    ),
          ),
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.all(12.0),
              child: Center(
                child:
                    _attendanceProcessed
                        ? ElevatedButton(
                          onPressed: _goToDashboard,
                          style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                          child: const Text('Done'),
                        )
                        : Container(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (result != null)
                                Text('Scanning: ${result!.code}', style: TextStyle(fontSize: 18), textAlign: TextAlign.center)
                              else
                                const Text('Scan a QR code to mark attendance', textAlign: TextAlign.center),
                            ],
                          ),
                        ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getSubjectName(String subjectId) {
    // If we have the subject information, return its name
    if (_subject != null && _subject!.id == subjectId) {
      return _subject!.name;
    }
    // Otherwise return subject id
    return subjectId;
  }

  String formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String formatTime(DateTime date) {
    return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String getStatusText(AttendanceStatus status) {
    switch (status) {
      case AttendanceStatus.present:
        return 'Present';
      case AttendanceStatus.late:
        return 'Late';
      case AttendanceStatus.absent:
        return 'Absent';
    }
  }

  bool isSessionTimeValid(DateTime sessionTime) {
    DateTime now = DateTime.now();
    Duration timeDifference = now.difference(sessionTime);

    // Check if current time is within 30 minutes after session time or 15 minutes before session time
    return timeDifference.inMinutes >= -15 && timeDifference.inMinutes <= 30;
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (mounted) {
        setState(() {
          result = scanData;
        });

        // Process the scanned QR code only if it's different from the last one
        // or if enough time has passed since the last scan to prevent duplicates
        String currentCode = scanData.code ?? '';
        DateTime now = DateTime.now();

        bool isDuplicate =
            _lastScannedCode != null &&
            _lastScannedCode == currentCode &&
            _lastScanTime != null &&
            now.difference(_lastScanTime!) < const Duration(seconds: 10);

        if (!isDuplicate) {
          _lastScannedCode = currentCode;
          _lastScanTime = now;

          await _processAttendance(currentCode);
        }
      }
    });
  }

  Future<void> _processAttendance(String qrCode) async {
    final authProvider = context.read<AuthProvider>();
    final studentId = authProvider.currentUser?.id;

    if (studentId == null) {
      if (mounted) {
        setState(() {
          _errorMessage = 'User not authenticated';
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('User not authenticated'), backgroundColor: Colors.red));
      }
      return;
    }

    try {
      // Get all attendance sessions in the time range
      final allSessions = await locator.attendanceSessionRepository.getSessionsByDateRangeAllSubjects(
        DateTime.now().subtract(const Duration(hours: 1)), // Last hour
        DateTime.now().add(const Duration(hours: 1)), // Next hour
      );

      // Find sessions that match the scanned QR code
      final matchingSessions = allSessions.where((s) => s.qrCode == qrCode).toList();

      if (matchingSessions.isEmpty) {
        throw Exception('No matching session found for QR code');
      }

      // Find the session with the closest time to now (or use the first match if multiple sessions have same QR code)
      final session = matchingSessions.reduce((a, b) {
        Duration diffA = (DateTime.now().difference(a.date)).abs();
        Duration diffB = (DateTime.now().difference(b.date)).abs();
        return diffA < diffB ? a : b;
      });

      // Check if student has already scanned for this session (prevent duplicate scans)
      final existingRecords = await locator.attendanceRecordRepository.getRecordsBySession(session.id);
      final existingRecord = existingRecords.firstWhere(
        (r) => r.studentId == studentId,
        orElse:
            () => AttendanceRecordModel(
              id: 'NEW_RECORD', // Use a special ID to identify new records
              sessionId: session.id,
              studentId: studentId,
              scanTime: DateTime.now(),
              status: AttendanceStatus.present,
              createdAt: DateTime.now(),
            ),
      );

      // Check if the student already has an attendance record for this session
      // If the existingRecord is not the default one we created in orElse, then it's a duplicate
      if (existingRecord.id != 'NEW_RECORD') {
        // Student has already been marked for this session, show duplicate scan dialog
        if (mounted) {
          await _showDuplicateScanDialog();
          Navigator.of(context).pop(); // Navigate back to previous screen
        }
        return;
      }

      // Calculate the time difference to determine attendance status
      DateTime sessionTime = session.date;
      Duration timeDifference = DateTime.now().difference(sessionTime);
      int timeDifferenceInMinutes = timeDifference.inMinutes;

      // Check if the session is within the allowed time range (before marking attendance)
      bool isWithinTimeRange = timeDifferenceInMinutes >= -15 && timeDifferenceInMinutes <= 30;

      // Show modal warning if outside allowed time range
      if (!isWithinTimeRange) {
        bool? confirmAttendance = await _showTimeWarningDialogWithResult(timeDifferenceInMinutes, session);

        // If user doesn't confirm attendance, return early
        if (confirmAttendance != true) {
          if (mounted) return; // Exit early if user doesn't confirm
        }
      }

      // Get subject details to find the teacher
      final subject = await locator.subjectRepository.getSubject(session.subjectId);

      // Determine attendance status based on time thresholds
      // 15 minutes late threshold, 30 minutes absent (absent) threshold
      AttendanceStatus attendanceStatus;
      if (timeDifferenceInMinutes < -15) {
        // Student arrived more than 15 minutes before session time (early)
        attendanceStatus = AttendanceStatus.present;
      } else if (timeDifferenceInMinutes <= 15) {
        // Student arrived within 15 minutes before or up to 15 minutes after session time (on time)
        attendanceStatus = AttendanceStatus.present;
      } else if (timeDifferenceInMinutes <= 30) {
        // Student arrived between 15 and 30 minutes after session time (late)
        attendanceStatus = AttendanceStatus.late;
      } else {
        // Student arrived more than 30 minutes after session time (absent)
        attendanceStatus = AttendanceStatus.absent;
      }

      // Create a new attendance record
      final newRecord = AttendanceRecordModel(
        id: const Uuid().v4(),
        sessionId: session.id,
        studentId: studentId,
        scanTime: DateTime.now(),
        status: attendanceStatus,
        createdAt: DateTime.now(),
      );
      await locator.attendanceRecordRepository.createRecord(newRecord);

      // Note: Teacher notifications for attendance are now handled by Firebase Functions
      // when attendance records are created in the Firestore database

      if (mounted) {
        setState(() {
          _attendanceSession = session;
          _subject = subject;
          _attendanceStatus = attendanceStatus;
          _attendanceProcessed = true;
          _errorMessage = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Attendance marked successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Error marking attendance: $e';
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error marking attendance: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<bool?> _showTimeWarningDialogWithResult(int minutesDifference, AttendanceSessionModel session) async {
    bool? confirmAttendance = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        String warningMessage;

        if (minutesDifference < 0) {
          int minutesEarly = minutesDifference.abs();
          warningMessage = 'You are scanning attendance $minutesEarly minutes before the session starts.';
        } else {
          warningMessage = 'You are scanning attendance $minutesDifference minutes after the session started.';
        }

        return AlertDialog(
          title: const Text('Time Warning'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(warningMessage),
              const SizedBox(height: 8),
              Text('Session: ${_subject?.name ?? 'Unknown Subject'}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Scheduled Time: ${formatDate(session.date)} at ${formatTime(session.date)}'),
              const SizedBox(height: 8),
              Text(
                'Status will be marked as: ${minutesDifference.abs() > 30
                    ? 'Absent'
                    : minutesDifference > 15
                    ? 'Late'
                    : 'Present'}',
                style: TextStyle(
                  color:
                      minutesDifference.abs() > 30
                          ? Colors.red
                          : minutesDifference > 15
                          ? Colors.orange
                          : Colors.green,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false); // Don't confirm attendance
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true); // Confirm attendance
              },
              child: const Text('Continue'),
            ),
          ],
        );
      },
    );

    return confirmAttendance;
  }

  void _goToDashboard() {
    // Navigate back to the appropriate dashboard screen instead of popping to first route
    // This prevents redirecting to login screen
    Navigator.of(context).pop(); // Pop only this screen

    // Alternative: Navigate explicitly to the appropriate dashboard based on user role
    // You can uncomment and use the approach below if the above doesn't work properly:
    /*
    final authProvider = context.read<AuthProvider>();
    final userRole = authProvider.currentUser?.role;
    
    if (userRole == 'student') {
      Navigator.of(context).pushNamedAndRemoveUntil('/student_dashboard', (route) => false);
    } else if (userRole == 'teacher') {
      Navigator.of(context).pushNamedAndRemoveUntil('/teacher_dashboard', (route) => false);
    } else if (userRole == 'parent') {
      Navigator.of(context).pushNamedAndRemoveUntil('/parent_dashboard', (route) => false);
    } else {
      // Fallback to pop to avoid login redirect
      Navigator.of(context).pop(); 
    }
    */
  }

  Future<void> _showDuplicateScanDialog() async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // User must tap button to close
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Duplicate Scan Detected'),
          content: const SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Icon(Icons.warning, color: Colors.orange, size: 48.0),
                SizedBox(height: 16.0),
                Text('You have already scanned attendance for this session.'),
                SizedBox(height: 8.0),
                Text('Scanning multiple times is not allowed.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('OK'),
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    // QRViewController self-disposes when QRView is unmounted
    // We should not manually dispose the controller
    super.dispose();
  }
}
