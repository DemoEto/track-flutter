// Subject provider with enrollment functionality for state management
import 'package:flutter/foundation.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';
import 'package:track_app/features/subject/data/models/subject_with_students_model.dart';
import 'package:track_app/core/enums.dart';

class SubjectEnrollmentProvider extends ChangeNotifier {
  List<SubjectWithStudentsModel> _subjects = [];
  List<UserModel> _allStudents = [];
  bool _isLoading = false;

  List<SubjectWithStudentsModel> get subjects => _subjects;
  List<UserModel> get allStudents => _allStudents;
  bool get isLoading => _isLoading;

  Future<void> loadAllStudents() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load all users with student role
      final allUsers = await locator.userRepository.getAllUsers();
      _allStudents = allUsers.where((user) => user.role == UserRole.student).toList();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSubjectsForTeacher(String teacherId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Get all subjects taught by this teacher
      final subjectModels = await locator.subjectRepository.getSubjectsByTeacher(teacherId);
      debugPrint('Found ${subjectModels.length} subjects for teacher $teacherId');

      // Convert to SubjectWithStudentsModel with enrolled students
      _subjects = [];
      for (final subject in subjectModels) {
        final enrolledStudentIds = await locator.subjectRepository.getStudentIdsForSubject(subject.id);
        debugPrint('Found ${enrolledStudentIds.length} enrolled student IDs for subject ${subject.name} (${subject.id})');

        final enrolledStudents = <UserModel>[];

        for (final studentId in enrolledStudentIds) {
          final student = await locator.userRepository.getUser(studentId);
          if (student != null) {
            enrolledStudents.add(student);
          } else {
            debugPrint('Could not find user for student ID: $studentId');
          }
        }

        debugPrint('Loaded ${enrolledStudents.length} enrolled students for subject ${subject.name}');
        _subjects.add(SubjectWithStudentsModel(subject: subject, students: enrolledStudents));
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error in loadSubjectsForTeacher: $e');
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createSubject(SubjectModel subject) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newSubject = SubjectModel(
        id: const Uuid().v4(),
        name: subject.name,
        teacherId: subject.teacherId,
        description: subject.description,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await locator.subjectRepository.createSubject(newSubject);

      // Add to local list
      _subjects.add(SubjectWithStudentsModel(subject: newSubject, students: []));

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateSubject(SubjectModel subject) async {
    _isLoading = true;
    notifyListeners();

    try {
      await locator.subjectRepository.updateSubject(subject);

      // Find and update the subject in the local list
      final index = _subjects.indexWhere((s) => s.subject.id == subject.id);
      if (index != -1) {
        _subjects[index] = SubjectWithStudentsModel(
          subject: subject,
          students: _subjects[index].students, // Keep the same student list
        );
      }

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    // notifyListeners() already called above
  }

  Future<void> deleteSubject(String subjectId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await locator.subjectRepository.deleteSubject(subjectId);

      // Remove from local list
      _subjects.removeWhere((s) => s.subject.id == subjectId);

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    // notifyListeners() already called above
  }

  Future<void> enrollStudent(String subjectId, String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await locator.subjectRepository.enrollStudent(subjectId, studentId);

      // Reload the subjects to ensure data consistency
      await _refreshSubjectWithStudents(subjectId);
      // notifyListeners() is called in _refreshSubjectWithStudents
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    // notifyListeners() is called in _refreshSubjectWithStudents
  }

  Future<void> unenrollStudent(String subjectId, String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await locator.subjectRepository.unenrollStudent(subjectId, studentId);

      // Reload the subjects to ensure data consistency
      await _refreshSubjectWithStudents(subjectId);
      // notifyListeners() is called in _refreshSubjectWithStudents
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    // notifyListeners() is called in _refreshSubjectWithStudents
  }

  /// Refresh the specific subject with its students to ensure data consistency
  Future<void> _refreshSubjectWithStudents(String subjectId) async {
    try {
      // Get the existing subject
      final subjectIndex = _subjects.indexWhere((s) => s.subject.id == subjectId);
      if (subjectIndex != -1) {
        final existingSubject = _subjects[subjectIndex].subject;

        // Get updated list of enrolled students
        final enrolledStudentIds = await locator.subjectRepository.getStudentIdsForSubject(subjectId);
        debugPrint('Refreshing subject $subjectId: found ${enrolledStudentIds.length} enrolled student IDs');

        final enrolledStudents = <UserModel>[];

        for (final studentId in enrolledStudentIds) {
          final student = await locator.userRepository.getUser(studentId);
          if (student != null) {
            enrolledStudents.add(student);
          } else {
            debugPrint('Could not find user for student ID: $studentId during refresh');
          }
        }

        debugPrint('Refreshing subject $subjectId: loaded ${enrolledStudents.length} enrolled students');

        // Update the subject with students in the list
        _subjects[subjectIndex] = SubjectWithStudentsModel(subject: existingSubject, students: enrolledStudents);

        notifyListeners(); // Make sure UI updates after refresh
      }
    } catch (e) {
      debugPrint('Error refreshing subject with students: $e');
    }
  }

  SubjectWithStudentsModel? getSubjectById(String subjectId) {
    try {
      return _subjects.firstWhere((s) => s.subject.id == subjectId);
    } catch (e) {
      return null;
    }
  }

  List<UserModel> getUnenrolledStudents(String subjectId) {
    final subject = getSubjectById(subjectId);
    if (subject == null) return [];

    final enrolledStudentIds = subject.students.map((s) => s.id).toSet();
    return _allStudents.where((student) => !enrolledStudentIds.contains(student.id)).toList();
  }
}
