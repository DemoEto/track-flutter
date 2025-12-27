// Widget for managing parent's children
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';

class ParentChildrenEditScreen extends StatefulWidget {
  const ParentChildrenEditScreen({super.key});

  @override
  State<ParentChildrenEditScreen> createState() => _ParentChildrenEditScreenState();
}

class _ParentChildrenEditScreenState extends State<ParentChildrenEditScreen> {
  List<UserModel> _allStudents = [];
  List<UserModel> _currentChildren = [];
  bool _isLoading = true;
  List<String> _selectedStudentIds = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final parentId = context.read<AuthProvider>().currentUser?.id;
      if (parentId != null) {
        // Load all students
        _allStudents = await locator.userRepository.getUsersByRole('student');

        // Load current children for this parent
        _currentChildren = await locator.userRepository.getChildrenForParent(parentId);

        // Remove children from all students to avoid duplicates
        _allStudents.removeWhere((student) => _currentChildren.any((child) => child.id == student.id));
      }
    } catch (e) {
      debugPrint('Error loading data: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _addChild() async {
    if (_selectedStudentIds.isEmpty) {
      _showMessage('Please select at least one student to add');
      return;
    }

    try {
      final parentId = context.read<AuthProvider>().currentUser?.id;
      if (parentId != null) {
        // Add all selected students
        for (String studentId in _selectedStudentIds) {
          await locator.userRepository.linkParentToChild(parentId, studentId);
        }

        _showMessage('Students added successfully');
        setState(() {
          // Move the selected students from allStudents to currentChildren
          for (String studentId in _selectedStudentIds) {
            final newChild = _allStudents.firstWhere((s) => s.id == studentId);
            _allStudents.removeWhere((s) => s.id == studentId);
            _currentChildren.add(newChild);
          }
          _selectedStudentIds.clear();
        });
      }
    } catch (e) {
      _showMessage('Error adding students: $e');
    }
  }

  Future<void> _removeChild(String childId) async {
    try {
      final parentId = context.read<AuthProvider>().currentUser?.id;
      if (parentId != null) {
        await locator.userRepository.unlinkParentFromChild(parentId, childId);
        _showMessage('Student removed successfully');
        setState(() {
          // Move the student from currentChildren to allStudents
          final removedChild = _currentChildren.firstWhere((s) => s.id == childId);
          _currentChildren.removeWhere((s) => s.id == childId);
          _allStudents.add(removedChild);
        });
      }
    } catch (e) {
      _showMessage('Error removing student: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showAddStudentDialog() async {
    List<String> selectedIds = [..._selectedStudentIds];

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Select Students to Add'),
            content: SizedBox(
              width: double.maxFinite,
              child:
                  _allStudents.isEmpty
                      ? const Text('No students available to add')
                      : StatefulBuilder(
                        builder: (BuildContext context, StateSetter setState) {
                          return ListView.builder(
                            shrinkWrap: true,
                            itemCount: _allStudents.length,
                            itemBuilder: (context, index) {
                              final student = _allStudents[index];
                              return CheckboxListTile(
                                title: Text(student.name),
                                subtitle: Text(student.email),
                                value: selectedIds.contains(student.id),
                                onChanged: (bool? value) {
                                  setState(() {
                                    if (value == true) {
                                      selectedIds.add(student.id);
                                    } else {
                                      selectedIds.remove(student.id);
                                    }
                                  });
                                },
                              );
                            },
                          );
                        },
                      ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedStudentIds = selectedIds;
                  });
                  Navigator.of(context).pop();
                  if (_selectedStudentIds.isNotEmpty) {
                    _addChild(); // Automatically add selected students when Done is pressed
                  }
                },
                child: const Text('Done'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Manage Children'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Your Children', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // List of current children
                    if (_currentChildren.isNotEmpty)
                      Expanded(
                        child: ListView.builder(
                          itemCount: _currentChildren.length,
                          itemBuilder: (context, index) {
                            final child = _currentChildren[index];
                            return Card(
                              child: ListTile(
                                title: Text(child.name),
                                subtitle: Text(child.email),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle, color: Colors.red),
                                  onPressed: () => _removeChild(child.id),
                                ),
                              ),
                            );
                          },
                        ),
                      )
                    else
                      const Expanded(child: Center(child: Text('No children added yet', style: TextStyle(color: Colors.grey)))),
                  ],
                ),
              ),
      floatingActionButton: FloatingActionButton(onPressed: _showAddStudentDialog, tooltip: 'Add Children', child: const Icon(Icons.add)),
    );
  }
}
