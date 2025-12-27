// Subject repository interface with enrollment functionality
import 'package:track_app/features/attendance/data/models/subject_model.dart';
import 'package:track_app/features/subject/data/models/subject_enrollment_model.dart';

abstract class SubjectRepositoryExtended {
  // Existing methods
  Future<void> createSubject(SubjectModel subject);
  Future<SubjectModel?> getSubject(String subjectId);
  Future<void> updateSubject(SubjectModel subject);
  Future<void> deleteSubject(String subjectId);
  Stream<SubjectModel?> subjectChanges(String subjectId);
  Stream<List<SubjectModel>> allSubjectsStream();
  Future<List<SubjectModel>> getAllSubjects();
  Future<List<SubjectModel>> getSubjectsByTeacher(String teacherId);

  // Enrollment methods
  Future<void> enrollStudent(String subjectId, String studentId);
  Future<void> unenrollStudent(String subjectId, String studentId);
  Future<List<String>> getStudentIdsForSubject(String subjectId);
  Future<List<String>> getSubjectIdsForStudent(String studentId);
  Future<List<SubjectModel>> getSubjectsByStudent(String studentId);
  Future<bool> isStudentEnrolled(String subjectId, String studentId);
}
