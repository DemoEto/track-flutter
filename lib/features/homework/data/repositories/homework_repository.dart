// Homework repository interface
import 'package:track_app/features/homework/data/models/homework_model.dart';

abstract class HomeworkRepository {
  Future<void> createHomework(HomeworkModel homework);
  Future<HomeworkModel?> getHomework(String homeworkId);
  Future<void> updateHomework(HomeworkModel homework);
  Future<void> deleteHomework(String homeworkId);
  Stream<HomeworkModel?> homeworkChanges(String homeworkId);
  Stream<List<HomeworkModel>> homeworkBySubject(String subjectId);
  Stream<List<HomeworkModel>> getHomeworkByStudentStream(String studentId);
  Future<List<HomeworkModel>> getHomeworkBySubject(String subjectId);
  Future<List<HomeworkModel>> getHomeworkByTeacher(String teacherId);
  Future<List<HomeworkModel>> getHomeworkByStudent(String studentId);
  Future<List<HomeworkModel>> getHomeworkDueForStudent(String studentId);
}
