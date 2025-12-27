// Homework screen for teachers to manage assignments
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/homework/data/models/homework_model.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';
import 'package:track_app/features/homework/presentation/screens/teacher/teacher_homework_create_screen.dart';
import 'package:track_app/features/homework/presentation/screens/teacher/teacher_homework_detail_screen.dart';

class TeacherHomeworkScreen extends StatefulWidget {
  const TeacherHomeworkScreen({Key? key}) : super(key: key);

  @override
  State<TeacherHomeworkScreen> createState() => _TeacherHomeworkScreenState();
}

class _TeacherHomeworkScreenState extends State<TeacherHomeworkScreen> {
  List<HomeworkModel> _homework = [];
  List<HomeworkModel> _filteredHomework = [];
  List<SubjectModel> _subjects = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadHomework();
  }

  Future<void> _loadHomework() async {
    final authProvider = context.read<AuthProvider>();
    final teacherId = authProvider.currentUser?.id;

    if (teacherId == null) return;

    try {
      // Load homework created by the teacher
      _homework = await locator.homeworkRepository.getHomeworkByTeacher(teacherId);

      // Load subjects taught by the teacher
      _subjects = await locator.subjectRepository.getSubjectsByTeacher(teacherId);

      setState(() {
        _isLoading = false;
        _filteredHomework = _homework;
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

  Color _getStatusColor(DateTime dueDate) {
    final now = DateTime.now();

    if (dueDate.isBefore(now)) {
      return Colors.red; // Past due
    } else if (dueDate.isBefore(now.add(const Duration(days: 2)))) {
      return Colors.orange; // Due soon
    } else {
      return Colors.green; // Not due yet
    }
  }

  List<HomeworkModel> _getFilteredHomework() {
    if (_searchQuery.isEmpty) return _filteredHomework;

    return _filteredHomework.where((homework) {
      return homework.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          homework.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          _getSubjectName(homework.subjectId).toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredHomework = _getFilteredHomework();

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assignments'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const TeacherHomeworkCreateScreen())).then((value) {
                _loadHomework(); // Always refresh after creating homework
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              decoration: const InputDecoration(hintText: 'Search assignments...', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
          if (_isLoading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else
            Expanded(
              child: RefreshIndicator(
                onRefresh: _loadHomework,
                child:
                    filteredHomework.isEmpty
                        ? const Center(child: Text('No assignments created', style: TextStyle(fontSize: 16)))
                        : ListView.builder(
                          padding: const EdgeInsets.all(8.0),
                          itemCount: filteredHomework.length,
                          itemBuilder: (context, index) {
                            final homework = filteredHomework[index];
                            final isOverdue = homework.dueDate.isBefore(DateTime.now());

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 4.0),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16.0),
                                title: Text(homework.title, style: TextStyle(fontWeight: FontWeight.bold, color: isOverdue ? Colors.grey : null)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(_getSubjectName(homework.subjectId), style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Icon(Icons.calendar_today, size: 14, color: _getStatusColor(homework.dueDate)),
                                        const SizedBox(width: 4),
                                        Text(
                                          'Due: ${DateFormat('MMM dd, yyyy').format(homework.dueDate)}',
                                          style: TextStyle(color: _getStatusColor(homework.dueDate), fontSize: 12),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text('${homework.assignedTo.length} students assigned', style: const TextStyle(color: Colors.blue, fontSize: 11)),
                                    const SizedBox(height: 4),
                                    Text(
                                      homework.description.length > 100 ? '${homework.description.substring(0, 100)}...' : homework.description,
                                      style: TextStyle(color: isOverdue ? Colors.grey : null, fontSize: 12),
                                    ),
                                  ],
                                ),
                                trailing: Icon(isOverdue ? Icons.timelapse : Icons.assignment, color: _getStatusColor(homework.dueDate)),
                                onTap: () {
                                  // Navigate to homework details or submission review
                                  Navigator.push(context, MaterialPageRoute(builder: (context) => TeacherHomeworkDetailScreen(homework: homework)));
                                },
                              ),
                            );
                          },
                        ),
              ),
            ),
        ],
      ),
    );
  }
}
