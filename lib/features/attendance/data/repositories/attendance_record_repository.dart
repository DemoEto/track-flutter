// Attendance record repository interface
import 'package:track_app/features/attendance/data/models/attendance_record_model.dart';

abstract class AttendanceRecordRepository {
  Future<void> createRecord(AttendanceRecordModel record);
  Future<AttendanceRecordModel?> getRecord(String recordId);
  Future<void> updateRecord(AttendanceRecordModel record);
  Future<void> deleteRecord(String recordId);
  Stream<AttendanceRecordModel?> recordChanges(String recordId);
  Stream<List<AttendanceRecordModel>> getRecordsByStudentStream(String studentId);
  Stream<List<AttendanceRecordModel>> getRecordsBySessionStream(String sessionId);
  Future<List<AttendanceRecordModel>> getRecordsBySession(String sessionId);
  Future<List<AttendanceRecordModel>> getRecordsByStudent(String studentId);
  Future<List<AttendanceRecordModel>> getRecordsByDateRange(
     String subjectId,
    String studentId,
    DateTime startDate,
    DateTime endDate,
  );
  Future<AttendanceRecordModel?> getLatestRecord(String studentId);
}
