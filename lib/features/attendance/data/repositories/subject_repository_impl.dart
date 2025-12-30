
// Firebase implementation of SubjectRepository
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';
import 'package:track_app/features/attendance/data/repositories/subject_repository.dart';
import 'package:track_app/core/constants.dart';

import 'package:track_app/features/subject/data/models/subject_with_students_model.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';
import 'package:track_app/core/services/service_locator.dart';
class FirebaseSubjectRepository implements SubjectRepository {
  final FirebaseFirestore _firestore;

  FirebaseSubjectRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createSubject(SubjectModel subject) async {
    await _firestore.collection(AppConstants.subjectsCollection).doc(subject.id).set(subject.toFirestore());
  }

  @override
  Future<SubjectModel?> getSubject(String subjectId) async {
    final subjectDoc = await _firestore.collection(AppConstants.subjectsCollection).doc(subjectId).get();
    if (subjectDoc.exists) {
      return SubjectModel.fromFirestore(subjectDoc);
    }
    return null;
  }

  @override
  Future<void> updateSubject(SubjectModel subject) async {
    await _firestore
        .collection(AppConstants.subjectsCollection)
        .doc(subject.id)
        .update(
          subject.toFirestore()
            ..remove('id')
            ..remove('createdAt'),
        );
  }

  @override
  Future<void> deleteSubject(String subjectId) async {
    await _firestore.collection(AppConstants.subjectsCollection).doc(subjectId).delete();
  }

  @override
  Stream<SubjectModel?> subjectChanges(String subjectId) {
    return _firestore
        .collection(AppConstants.subjectsCollection)
        .doc(subjectId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? SubjectModel.fromFirestore(snapshot) : null);
  }

  @override
  Stream<List<SubjectModel>> allSubjectsStream() {
    return _firestore
        .collection(AppConstants.subjectsCollection)
        .orderBy('createdAt', descending: true) // Most recent first
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SubjectModel.fromFirestore(doc)).toList());
  }

  @override
  Future<List<SubjectModel>> getSubjectsByTeacher(String teacherId) async {
    final querySnapshot = await _firestore.collection(AppConstants.subjectsCollection).where('teacherId', isEqualTo: teacherId).get();

    return querySnapshot.docs.map((doc) => SubjectModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<SubjectModel>> getAllSubjects() async {
    final querySnapshot = await _firestore.collection(AppConstants.subjectsCollection).get();

    return querySnapshot.docs.map((doc) => SubjectModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> enrollStudent(String subjectId, String studentId) async {
    final enrollmentId = '$subjectId-$studentId'; // Unique ID for the enrollment
    await _firestore.collection(AppConstants.subjectEnrollmentsCollection).doc(enrollmentId).set({
      'subjectId': subjectId,
      'studentId': studentId,
      'enrolledAt': DateTime.now(),
    });
  }

  @override
  Future<void> unenrollStudent(String subjectId, String studentId) async {
    final enrollmentId = '$subjectId-$studentId';
    await _firestore.collection(AppConstants.subjectEnrollmentsCollection).doc(enrollmentId).update({'unenrolledAt': DateTime.now()});
    // Note: We don't delete the document to keep historical data
  }

  @override
  Future<List<String>> getStudentIdsForSubject(String subjectId) async {
    final querySnapshot = await _firestore.collection(AppConstants.subjectEnrollmentsCollection).where('subjectId', isEqualTo: subjectId).get();

    // Filter out unenrolled students by checking that unenrolledAt is not set
    final activeEnrollments =
        querySnapshot.docs.where((doc) {
          final data = doc.data();
          final unenrolledAt = data['unenrolledAt'];
          // Return true if the unenrolledAt field doesn't exist or is null
          return unenrolledAt == null;
        }).toList();

    return activeEnrollments.map((doc) => (doc.data()['studentId'] as String)).toList();
  }

  @override
  Future<List<String>> getSubjectIdsForStudent(String studentId) async {
    final querySnapshot =
        await _firestore
            .collection(AppConstants.subjectEnrollmentsCollection)
            .where('studentId', isEqualTo: studentId)
            .where('unenrolledAt', isNull: true) // Only active enrollments
            .get();

    return querySnapshot.docs.map((doc) => (doc.data()['subjectId'] as String)).toList();
  }

  @override
  Future<List<SubjectModel>> getSubjectsByStudent(String studentId) async {
    final subjectIds = await getSubjectIdsForStudent(studentId);
    final subjects = <SubjectModel>[];

    for (final subjectId in subjectIds) {
      final subject = await getSubject(subjectId);
      if (subject != null) {
        subjects.add(subject);
      }
    }

    return subjects;
  }

  @override
  Future<bool> isStudentEnrolled(String subjectId, String studentId) async {
    final enrollmentId = '$subjectId-$studentId';
    final doc = await _firestore.collection(AppConstants.subjectEnrollmentsCollection).doc(enrollmentId).get();

    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return false;

    // Check if the enrollment is active (not unenrolled)
    final unenrolledAt = data['unenrolledAt'] as Timestamp?;
    return unenrolledAt == null;
  }

  
@override
Future<List<SubjectWithStudentsModel>> getSubjectsWithStudentsByTeacher(
  String teacherId,
) async {
  // 1️⃣ ดึงวิชาของครู
  final subjects = await getSubjectsByTeacher(teacherId);

  final List<SubjectWithStudentsModel> result = [];

  for (final subject in subjects) {
    // 2️⃣ ดึง studentIds ของแต่ละวิชา
    final studentIds = await getStudentIdsForSubject(subject.id);

    // 3️⃣ ดึง UserModel ของนักเรียน
    final List<UserModel> students = [];

    for (final studentId in studentIds) {
      final student = await locator.userRepository.getUser(studentId);
      if (student != null) {
        students.add(student);
      }
    }

    // 4️⃣ รวมเป็น SubjectWithStudentsModel
    result.add(
      SubjectWithStudentsModel(
        subject: subject,
        students: students,
      ),
    );
  }

  return result;
}
}
