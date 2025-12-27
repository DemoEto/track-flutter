// Firebase implementation of AttendanceSessionRepository
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_app/features/attendance/data/models/attendance_session_model.dart';
import 'package:track_app/features/attendance/data/repositories/attendance_session_repository.dart';
import 'package:track_app/core/constants.dart';

class FirebaseAttendanceSessionRepository implements AttendanceSessionRepository {
  final FirebaseFirestore _firestore;

  FirebaseAttendanceSessionRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createSession(AttendanceSessionModel session) async {
    await _firestore.collection(AppConstants.attendanceSessionsCollection).doc(session.id).set(session.toFirestore());
  }

  @override
  Future<AttendanceSessionModel?> getSession(String sessionId) async {
    final sessionDoc = await _firestore.collection(AppConstants.attendanceSessionsCollection).doc(sessionId).get();
    if (sessionDoc.exists) {
      return AttendanceSessionModel.fromFirestore(sessionDoc);
    }
    return null;
  }

  @override
  Future<void> updateSession(AttendanceSessionModel session) async {
    await _firestore
        .collection(AppConstants.attendanceSessionsCollection)
        .doc(session.id)
        .update(
          session.toFirestore()
            ..remove('id')
            ..remove('createdAt'),
        );
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _firestore.collection(AppConstants.attendanceSessionsCollection).doc(sessionId).delete();
  }

  @override
  Stream<AttendanceSessionModel?> sessionChanges(String sessionId) {
    return _firestore
        .collection(AppConstants.attendanceSessionsCollection)
        .doc(sessionId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? AttendanceSessionModel.fromFirestore(snapshot) : null);
  }

  @override
  Stream<List<AttendanceSessionModel>> sessionsBySubject(String subjectId) {
    return _firestore
        .collection(AppConstants.attendanceSessionsCollection)
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('date', descending: true) // Most recent first
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => AttendanceSessionModel.fromFirestore(doc)).toList());
  }

  @override
  Future<List<AttendanceSessionModel>> getSessionsBySubject(String subjectId) async {
    final querySnapshot = await _firestore.collection(AppConstants.attendanceSessionsCollection).where('subjectId', isEqualTo: subjectId).get();

    return querySnapshot.docs.map((doc) => AttendanceSessionModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<AttendanceSessionModel>> getSessionsByDateRange(String subjectId, DateTime startDate, DateTime endDate) async {
    final querySnapshot =
        await _firestore
            .collection(AppConstants.attendanceSessionsCollection)
            .where('subjectId', isEqualTo: subjectId)
            .where('date', isGreaterThanOrEqualTo: startDate)
            .where('date', isLessThanOrEqualTo: endDate)
            .get();

    return querySnapshot.docs.map((doc) => AttendanceSessionModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<AttendanceSessionModel>> getSessionsByDateRangeAllSubjects(DateTime startDate, DateTime endDate) async {
    final querySnapshot =
        await _firestore
            .collection(AppConstants.attendanceSessionsCollection)
            .where('date', isGreaterThanOrEqualTo: startDate)
            .where('date', isLessThanOrEqualTo: endDate)
            .get();

    return querySnapshot.docs.map((doc) => AttendanceSessionModel.fromFirestore(doc)).toList();
  }

  @override
  Future<AttendanceSessionModel?> getLatestSession(String subjectId) async {
    final querySnapshot =
        await _firestore
            .collection(AppConstants.attendanceSessionsCollection)
            .where('subjectId', isEqualTo: subjectId)
            .orderBy('date', descending: true)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      return AttendanceSessionModel.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  @override
  Future<AttendanceSessionModel?> getActiveSession(String subjectId) async {
    final now = DateTime.now();
    final querySnapshot =
        await _firestore
            .collection(AppConstants.attendanceSessionsCollection)
            .where('subjectId', isEqualTo: subjectId)
            .where('date', isLessThanOrEqualTo: now)
            .orderBy('date', descending: true)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      return AttendanceSessionModel.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }
}
