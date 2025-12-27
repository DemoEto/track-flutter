// Firebase implementation of SubmissionRepository
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_app/features/homework/data/models/submission_model.dart';
import 'package:track_app/features/homework/data/repositories/submission_repository.dart';
import 'package:track_app/core/constants.dart';

class FirebaseSubmissionRepository implements SubmissionRepository {
  final FirebaseFirestore _firestore;

  FirebaseSubmissionRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createSubmission(SubmissionModel submission) async {
    await _firestore.collection(AppConstants.submissionsCollection).doc(submission.id).set(submission.toFirestore());
  }

  @override
  Future<SubmissionModel?> getSubmission(String submissionId) async {
    final submissionDoc = await _firestore.collection(AppConstants.submissionsCollection).doc(submissionId).get();
    if (submissionDoc.exists) {
      return SubmissionModel.fromFirestore(submissionDoc);
    }
    return null;
  }

  @override
  Future<void> updateSubmission(SubmissionModel submission) async {
    await _firestore.collection(AppConstants.submissionsCollection).doc(submission.id).update(submission.toFirestore()..remove('id'));
  }

  @override
  Future<void> deleteSubmission(String submissionId) async {
    await _firestore.collection(AppConstants.submissionsCollection).doc(submissionId).delete();
  }

  @override
  Stream<SubmissionModel?> submissionChanges(String submissionId) {
    return _firestore
        .collection(AppConstants.submissionsCollection)
        .doc(submissionId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? SubmissionModel.fromFirestore(snapshot) : null);
  }

  @override
  Stream<List<SubmissionModel>> submissionsByHomework(String homeworkId) {
    return _firestore
        .collection(AppConstants.submissionsCollection)
        .where('homeworkId', isEqualTo: homeworkId)
        .orderBy('submitTime', descending: true) // Most recent first
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => SubmissionModel.fromFirestore(doc)).toList());
  }

  @override
  Future<List<SubmissionModel>> getSubmissionsByHomework(String homeworkId) async {
    final querySnapshot = await _firestore.collection(AppConstants.submissionsCollection).where('homeworkId', isEqualTo: homeworkId).get();

    return querySnapshot.docs.map((doc) => SubmissionModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<SubmissionModel>> getSubmissionsByStudent(String studentId) async {
    final querySnapshot = await _firestore.collection(AppConstants.submissionsCollection).where('studentId', isEqualTo: studentId).get();

    return querySnapshot.docs.map((doc) => SubmissionModel.fromFirestore(doc)).toList();
  }

  @override
  Future<SubmissionModel?> getSubmissionByHomeworkAndStudent(String homeworkId, String studentId) async {
    final querySnapshot =
        await _firestore
            .collection(AppConstants.submissionsCollection)
            .where('homeworkId', isEqualTo: homeworkId)
            .where('studentId', isEqualTo: studentId)
            .limit(1)
            .get();

    if (querySnapshot.docs.isNotEmpty) {
      return SubmissionModel.fromFirestore(querySnapshot.docs.first);
    }
    return null;
  }

  @override
  Future<List<SubmissionModel>> getSubmissionsByTeacher(String teacherId) async {
    // Get subjects taught by the teacher
    final subjects = await _firestore.collection(AppConstants.subjectsCollection).where('teacherId', isEqualTo: teacherId).get();

    if (subjects.docs.isEmpty) return [];

    final subjectIds = subjects.docs.map((doc) => doc.id).toList();

    // Get homework for those subjects
    final homeworks = await _firestore.collection(AppConstants.homeworksCollection).where('subjectId', whereIn: subjectIds).get();

    if (homeworks.docs.isEmpty) return [];

    final homeworkIds = homeworks.docs.map((doc) => doc.id).toList();

    // Get submissions for those homeworks
    final querySnapshot = await _firestore.collection(AppConstants.submissionsCollection).where('homeworkId', whereIn: homeworkIds).get();

    return querySnapshot.docs.map((doc) => SubmissionModel.fromFirestore(doc)).toList();
  }
}
