// Homework list screen for students
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:track_app/features/homework/presentation/screens/student/student_homework_detail_screen.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/homework/data/models/homework_model.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';

class StudentHomeworkScreen extends StatefulWidget {
  const StudentHomeworkScreen({Key? key}) : super(key: key);

  @override
  State<StudentHomeworkScreen> createState() => _StudentHomeworkScreenState();
}

class _StudentHomeworkScreenState extends State<StudentHomeworkScreen> {
  List<HomeworkModel> _homework = [];
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    final authProvider = context.read<AuthProvider>();
    final studentId = authProvider.currentUser?.id;

    if (studentId == null) return;

    try {
      // Load homework assigned to the student
      _homework = await locator.homeworkRepository.getHomeworkByStudent(studentId);

      // Load subjects for display
      final subjectIds = _homework.map((hw) => hw.subjectId).toSet().toList();
      for (final subjectId in subjectIds) {
        final subject = await locator.subjectRepository.getSubject(subjectId);
        if (subject != null) {
          _subjects.add(subject);
        }
      }

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading homework: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _getSubjectName(String subjectId) {
    final subject = _subjects.firstWhere(
      (s) => s.id == subjectId,
      orElse: () => SubjectModel(id: subjectId, name: 'Unknown Subject', teacherId: '', createdAt: DateTime.now(), updatedAt: DateTime.now()),
    );
    return subject.name;
  }

  Color _getDueDateColor(DateTime dueDate) {
    final now = DateTime.now();
    final difference = dueDate.difference(now).inDays;

    if (difference < 0) {
      return Colors.red; // Overdue
    } else if (difference <= 1) {
      return Colors.orange; // Due soon
    } else {
      return Colors.green; // Not due yet
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Homework'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _homework.isEmpty
              ? const Center(child: Text('No homework assigned', style: TextStyle(fontSize: 16)))
              : RefreshIndicator(
                onRefresh: _loadHomework,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _homework.length,
                  itemBuilder: (context, index) {
                    final homework = _homework[index];
                    final isOverdue = homework.dueDate.isBefore(DateTime.now());

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16.0),
                        title: Text(
                          homework.title,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            decoration: isOverdue ? TextDecoration.lineThrough : null,
                            color: isOverdue ? Colors.grey : null,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(_getSubjectName(homework.subjectId), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(Icons.calendar_today, size: 14, color: _getDueDateColor(homework.dueDate)),
                                const SizedBox(width: 4),
                                Text(
                                  'Due: ${DateFormat('MMM dd, yyyy').format(homework.dueDate)}',
                                  style: TextStyle(color: _getDueDateColor(homework.dueDate), fontSize: 12),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              homework.description.length > 100 ? '${homework.description.substring(0, 100)}...' : homework.description,
                              style: TextStyle(color: isOverdue ? Colors.grey : null, fontSize: 12),
                            ),
                          ],
                        ),
                        trailing: Icon(isOverdue ? Icons.timelapse : Icons.assignment, color: _getDueDateColor(homework.dueDate)),
                        onTap: () {
                          // Navigate to homework detail screen where students can view or submit
                          Navigator.push(context, MaterialPageRoute(builder: (context) => StudentHomeworkDetailScreen(homeworkId: homework.id)));
                        },
                      ),
                    );
                  },
                ),
              ),
    );
  }
}
