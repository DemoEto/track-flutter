// Submission repository interface
import 'package:track_app/features/homework/data/models/submission_model.dart';

abstract class SubmissionRepository {
  Future<void> createSubmission(SubmissionModel submission);
  Future<SubmissionModel?> getSubmission(String submissionId);
  Future<void> updateSubmission(SubmissionModel submission);
  Future<void> deleteSubmission(String submissionId);
  Stream<SubmissionModel?> submissionChanges(String submissionId);
  Stream<List<SubmissionModel>> submissionsByHomework(String homeworkId);
  Future<List<SubmissionModel>> getSubmissionsByHomework(String homeworkId);
  Future<List<SubmissionModel>> getSubmissionsByStudent(String studentId);
  Future<List<SubmissionModel>> getSubmissionsByTeacher(String teacherId);
  Future<SubmissionModel?> getSubmissionByHomeworkAndStudent(String homeworkId, String studentId);
}
