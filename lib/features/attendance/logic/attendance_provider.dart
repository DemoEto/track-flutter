// Attendance provider for state management
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/attendance/data/models/attendance_session_model.dart';
import 'package:track_app/features/attendance/data/models/attendance_record_model.dart';
import 'package:track_app/core/enums.dart';

class AttendanceProvider extends ChangeNotifier {
  List<AttendanceSessionModel> _sessions = [];
  List<AttendanceRecordModel> _records = [];

  List<AttendanceSessionModel> get sessions => _sessions;
  List<AttendanceRecordModel> get records => _records;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadSessions() async {
    _isLoading = true;
    notifyListeners();

    try {
      // For now, we'll load sessions for the current teacher - in a real app you'd pass teacherId
      // Since we don't have context here, we'll just load empty list for now
      _sessions = [];
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();

    try {
      // For now, we'll load records for the current student - in a real app you'd pass studentId
      // Since we don't have context here, we'll just load empty list for now
      _records = [];
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createAttendanceSession({required String subjectId, required DateTime date, required String qrCode}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final session = AttendanceSessionModel(id: const Uuid().v4(), subjectId: subjectId, date: date, qrCode: qrCode, createdAt: DateTime.now());

      await locator.attendanceSessionRepository.createSession(session);
      _sessions.add(session);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAttendance({required String sessionId, required String studentId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final record = AttendanceRecordModel(
        id: const Uuid().v4(),
        sessionId: sessionId,
        studentId: studentId,
        scanTime: DateTime.now(),
        status: AttendanceStatus.present,
        createdAt: DateTime.now(),
      );

      await locator.attendanceRecordRepository.createRecord(record);
      _records.add(record);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSessionsBySubject(String subjectId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _sessions = await locator.attendanceSessionRepository.getSessionsBySubject(subjectId);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecordsByStudent(String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _records = await locator.attendanceRecordRepository.getRecordsByStudent(studentId);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadRecordsBySession(String sessionId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _records = await locator.attendanceRecordRepository.getRecordsBySession(sessionId);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }
}
