// Subject provider for state management
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';
import 'package:track_app/core/enums.dart';

class SubjectProvider extends ChangeNotifier {
  List<SubjectModel> _subjects = [];
  List<UserModel> _teachers = [];

  List<SubjectModel> get subjects => _subjects;
  List<UserModel> get teachers => _teachers;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadSubjects() async {
    _isLoading = true;
    notifyListeners();

    try {
      _subjects = await locator.subjectRepository.getAllSubjects();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTeachers() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Load users with teacher role from the user repository
      final allUsers = await locator.userRepository.getAllUsers();
      _teachers = allUsers.where((user) => user.role == UserRole.teacher).toList();

      notifyListeners();
    } catch (e) {
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
      _subjects.add(newSubject);
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

      final index = _subjects.indexWhere((s) => s.id == subject.id);
      if (index != -1) {
        _subjects[index] = subject;
      }

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> deleteSubject(String subjectId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await locator.subjectRepository.deleteSubject(subjectId);
      _subjects.removeWhere((s) => s.id == subjectId);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSubjectsByTeacher(String teacherId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _subjects = await locator.subjectRepository.getSubjectsByTeacher(teacherId);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }
}
