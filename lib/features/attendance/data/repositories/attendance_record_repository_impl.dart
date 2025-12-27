// Firebase implementation of AttendanceRecordRepository
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_app/features/attendance/data/models/attendance_record_model.dart';
import 'package:track_app/features/attendance/data/repositories/attendance_record_repository.dart';
import 'package:track_app/core/constants.dart';

class FirebaseAttendanceRecordRepository implements AttendanceRecordRepository {
  final FirebaseFirestore _firestore;

  FirebaseAttendanceRecordRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createRecord(AttendanceRecordModel record) async {
    await _firestore.collection(AppConstants.attendanceRecordsCollection).doc(record.id).set(record.toFirestore());
  }

  @override
  Future<AttendanceRecordModel?> getRecord(String recordId) async {
    final recordDoc = await _firestore.collection(AppConstants.attendanceRecordsCollection).doc(recordId).get();
    if (recordDoc.exists) {
      return AttendanceRecordModel.fromFirestore(recordDoc);
    }
    return null;
  }

  @override
  Future<void> updateRecord(AttendanceRecordModel record) async {
    await _firestore
        .collection(AppConstants.attendanceRecordsCollection)
        .doc(record.id)
        .update(
          record.toFirestore()
            ..remove('id')
            ..remove('createdAt'),
        );
  }

  @override
  Future<void> deleteRecord(String recordId) async {
    await _firestore.collection(AppConstants.attendanceRecordsCollection).doc(recordId).delete();
  }

  @override
  Stream<AttendanceRecordModel?> recordChanges(String recordId) {
    return _firestore
        .collection(AppConstants.attendanceRecordsCollection)
        .doc(recordId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? AttendanceRecordModel.fromFirestore(snapshot) : null);
  }

  @override
  Stream<List<AttendanceRecordModel>> getRecordsByStudentStream(String studentId) {
    return _firestore
        .collection(AppConstants.attendanceRecordsCollection)
        .where('studentId', isEqualTo: studentId)
        .orderBy('scanTime', descending: true) // Most recent first
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AttendanceRecordModel.fromFirestore(doc)).toList());
  }

  @override
  Stream<List<AttendanceRecordModel>> getRecordsBySessionStream(String sessionId) {
    return _firestore
        .collection(AppConstants.attendanceRecordsCollection)
        .where('sessionId', isEqualTo: sessionId)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AttendanceRecordModel.fromFirestore(doc)).toList());
  }

  @override
  Future<List<AttendanceRecordModel>> getRecordsBySession(String sessionId) async {
    final querySnapshot = await _firestore.collection(AppConstants.attendanceRecordsCollection).where('sessionId', isEqualTo: sessionId).get();

    return querySnapshot.docs.map((doc) => AttendanceRecordModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<AttendanceRecordModel>> getRecordsByStudent(String studentId) async {
    final querySnapshot = await _firestore.collection(AppConstants.attendanceRecordsCollection).where('studentId', isEqualTo: studentId).get();

    return querySnapshot.docs.map((doc) => AttendanceRecordModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<AttendanceRecordModel>> getRecordsByDateRange(String studentId, DateTime startDate, DateTime endDate) async {
    final querySnapshot =
        await _firestore
            .collection(AppConstants.attendanceRecordsCollection)
            .where('studentId', isEqualTo: studentId)
            .where('scanTime', isGreaterThanOrEqualTo: startDate)
            .where('scanTime', isLessThanOrEqualTo: endDate)
            .get();

    return querySnapshot.docs.map((doc) => AttendanceRecordModel.fromFirestore(doc)).toList();
  }

  @override
  Future<AttendanceRecordModel?> getLatestRecord(String studentId) async {
    final querySnapshot =
        await _firestore
            .collection(AppConstants.attendanceRecordsCollection)
            .where('studentId', isEqualTo: studentId)
            .orderBy('scanTime', descending: true)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      return AttendanceRecordModel.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }
}
