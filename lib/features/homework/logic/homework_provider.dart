// Homework provider for state management
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/homework/data/models/homework_model.dart';

class HomeworkProvider extends ChangeNotifier {
  List<HomeworkModel> _homeworkList = [];

  List<HomeworkModel> get homeworkList => _homeworkList;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadHomeworkForStudent(String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _homeworkList = await locator.homeworkRepository.getHomeworkByStudent(studentId);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadHomeworkForTeacher(String teacherId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _homeworkList = await locator.homeworkRepository.getHomeworkByTeacher(teacherId);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createHomework(HomeworkModel homework) async {
    _isLoading = true;
    notifyListeners();

    try {
      final newHomework = homework.copyWith(id: const Uuid().v4(), createdAt: DateTime.now(), updatedAt: DateTime.now());

      await locator.homeworkRepository.createHomework(newHomework);
      _homeworkList.add(newHomework);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateHomework(HomeworkModel homework) async {
    _isLoading = true;
    notifyListeners();

    try {
      await locator.homeworkRepository.updateHomework(homework);
      final index = _homeworkList.indexWhere((hw) => hw.id == homework.id);
      if (index != -1) {
        _homeworkList[index] = homework;
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

  Future<void> deleteHomework(String homeworkId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await locator.homeworkRepository.deleteHomework(homeworkId);
      _homeworkList.removeWhere((hw) => hw.id == homeworkId);
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
