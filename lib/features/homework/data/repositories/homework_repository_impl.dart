// Firebase implementation of HomeworkRepository
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_app/features/homework/data/models/homework_model.dart';
import 'package:track_app/features/homework/data/repositories/homework_repository.dart';
import 'package:track_app/core/constants.dart';

class FirebaseHomeworkRepository implements HomeworkRepository {
  final FirebaseFirestore _firestore;

  FirebaseHomeworkRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createHomework(HomeworkModel homework) async {
    await _firestore.collection(AppConstants.homeworksCollection).doc(homework.id).set(homework.toFirestore());
  }

  @override
  Future<HomeworkModel?> getHomework(String homeworkId) async {
    final homeworkDoc = await _firestore.collection(AppConstants.homeworksCollection).doc(homeworkId).get();
    if (homeworkDoc.exists) {
      return HomeworkModel.fromFirestore(homeworkDoc);
    }
    return null;
  }

  @override
  Future<void> updateHomework(HomeworkModel homework) async {
    await _firestore
        .collection(AppConstants.homeworksCollection)
        .doc(homework.id)
        .update(
          homework.toFirestore()
            ..remove('id')
            ..remove('createdAt'),
        );
  }

  @override
  Future<void> deleteHomework(String homeworkId) async {
    await _firestore.collection(AppConstants.homeworksCollection).doc(homeworkId).delete();
  }

  @override
  Stream<HomeworkModel?> homeworkChanges(String homeworkId) {
    return _firestore
        .collection(AppConstants.homeworksCollection)
        .doc(homeworkId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? HomeworkModel.fromFirestore(snapshot) : null);
  }

  @override
  Stream<List<HomeworkModel>> homeworkBySubject(String subjectId) {
    return _firestore
        .collection(AppConstants.homeworksCollection)
        .where('subjectId', isEqualTo: subjectId)
        .orderBy('createdAt', descending: true) // Most recent first
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => HomeworkModel.fromFirestore(doc)).toList());
  }

  @override
  Stream<List<HomeworkModel>> getHomeworkByStudentStream(String studentId) {
    return _firestore
        .collection(AppConstants.homeworksCollection)
        .where('assignedTo', arrayContains: studentId)
        .orderBy('createdAt', descending: true) // Most recent first
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => HomeworkModel.fromFirestore(doc)).toList());
  }

  @override
  Future<List<HomeworkModel>> getHomeworkBySubject(String subjectId) async {
    final querySnapshot = await _firestore.collection(AppConstants.homeworksCollection).where('subjectId', isEqualTo: subjectId).get();

    return querySnapshot.docs.map((doc) => HomeworkModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<HomeworkModel>> getHomeworkByTeacher(String teacherId) async {
    // This would require checking which subjects the teacher teaches
    // For now, we'll get homework for all subjects taught by the teacher
    final subjects = await _firestore.collection(AppConstants.subjectsCollection).where('teacherId', isEqualTo: teacherId).get();

    if (subjects.docs.isEmpty) return [];

    final subjectIds = subjects.docs.map((doc) => doc.id).toList();
    final querySnapshot = await _firestore.collection(AppConstants.homeworksCollection).where('subjectId', whereIn: subjectIds).get();

    return querySnapshot.docs.map((doc) => HomeworkModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<HomeworkModel>> getHomeworkByStudent(String studentId) async {
    // Get homework assigned to this specific student
    final querySnapshot = await _firestore.collection(AppConstants.homeworksCollection).where('assignedTo', arrayContains: studentId).get();

    return querySnapshot.docs.map((doc) => HomeworkModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<HomeworkModel>> getHomeworkDueForStudent(String studentId) async {
    final now = DateTime.now();
    final querySnapshot =
        await _firestore
            .collection(AppConstants.homeworksCollection)
            .where('assignedTo', arrayContains: studentId)
            .where('dueDate', isGreaterThanOrEqualTo: now)
            .get();

    return querySnapshot.docs.map((doc) => HomeworkModel.fromFirestore(doc)).toList();
  }
}
