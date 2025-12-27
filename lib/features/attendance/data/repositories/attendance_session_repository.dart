// Attendance session repository interface
import 'package:track_app/features/attendance/data/models/attendance_session_model.dart';

abstract class AttendanceSessionRepository {
  Future<void> createSession(AttendanceSessionModel session);
  Future<AttendanceSessionModel?> getSession(String sessionId);
  Future<void> updateSession(AttendanceSessionModel session);
  Future<void> deleteSession(String sessionId);
  Stream<AttendanceSessionModel?> sessionChanges(String sessionId);
  Stream<List<AttendanceSessionModel>> sessionsBySubject(String subjectId);
  Future<List<AttendanceSessionModel>> getSessionsBySubject(String subjectId);
  Future<List<AttendanceSessionModel>> getSessionsByDateRange(String subjectId, DateTime startDate, DateTime endDate);
  Future<List<AttendanceSessionModel>> getSessionsByDateRangeAllSubjects(DateTime startDate, DateTime endDate);
  Future<AttendanceSessionModel?> getLatestSession(String subjectId);
  Future<AttendanceSessionModel?> getActiveSession(String subjectId);
}
