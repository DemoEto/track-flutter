// Teacher subject management screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/subject/logic/subject_enrollment_provider.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';

class TeacherSubjectManagementScreen extends StatefulWidget {
  const TeacherSubjectManagementScreen({Key? key}) : super(key: key);

  @override
  State<TeacherSubjectManagementScreen> createState() => _TeacherSubjectManagementScreenState();
}

class _TeacherSubjectManagementScreenState extends State<TeacherSubjectManagementScreen> {
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final subjectEnrollmentProvider = context.read<SubjectEnrollmentProvider>();

    if (authProvider.currentUser != null) {
      await subjectEnrollmentProvider.loadSubjectsForTeacher(authProvider.currentUser!.id);
      await subjectEnrollmentProvider.loadAllStudents();
    }
  }

  Future<void> _createNewSubject() async {
    final authProvider = context.read<AuthProvider>();
    final subjectEnrollmentProvider = context.read<SubjectEnrollmentProvider>();

    final TextEditingController nameController = TextEditingController();
    final TextEditingController descriptionController = TextEditingController();

    await showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Create New Subject'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Subject Name', border: OutlineInputBorder())),
                const SizedBox(height: 10),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder()),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty && authProvider.currentUser != null) {
                    try {
                      await subjectEnrollmentProvider.createSubject(
                        SubjectModel(
                          id: '',
                          name: nameController.text,
                          teacherId: authProvider.currentUser!.id,
                          description: descriptionController.text,
                          createdAt: DateTime.now(),
                          updatedAt: DateTime.now(),
                        ),
                      );
                      if (mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Subject created successfully'), backgroundColor: Colors.green));
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error creating subject: $e'), backgroundColor: Colors.red));
                      }
                    }
                  }
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  void _showManageStudentsDialog(SubjectModel subject) {
    Set<String> selectedStudents = {};

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter dialogSetState) {
            return Consumer<SubjectEnrollmentProvider>(
              builder: (context, provider, child) {
                if (provider.isLoading) {
                  return const AlertDialog(title: Text('Manage Students'), content: Center(child: CircularProgressIndicator()));
                }

                final enrolledStudents = provider.getSubjectById(subject.id)?.students ?? [];
                final unenrolledStudents = provider.getUnenrolledStudents(subject.id);

                return AlertDialog(
                  title: Text('Manage Students - ${subject.name}'),
                  content: SizedBox(
                    width: double.maxFinite,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Expanded(
                          child: ListView(
                            shrinkWrap: true,
                            children: [
                              const Text('Enrolled Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              if (enrolledStudents.isEmpty)
                                const Text('No students enrolled yet', style: TextStyle(color: Colors.grey))
                              else
                                ...enrolledStudents.map(
                                  (student) => ListTile(
                                    contentPadding: const EdgeInsets.all(8.0),
                                    leading: const Icon(Icons.account_circle),
                                    title: Text(student.name),
                                    subtitle: Text(student.email),
                                    trailing: IconButton(
                                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                                      onPressed: () async {
                                        try {
                                          await provider.unenrollStudent(subject.id, student.id);
                                          if (mounted) {
                                            ScaffoldMessenger.of(context).showSnackBar(
                                              const SnackBar(content: Text('Student unenrolled successfully'), backgroundColor: Colors.green),
                                            );
                                          }
                                        } catch (e) {
                                          if (mounted) {
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(SnackBar(content: Text('Error unenrolling student: $e'), backgroundColor: Colors.red));
                                          }
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              const SizedBox(height: 16),
                              const Text('Available Students', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed:
                                    unenrolledStudents.isEmpty
                                        ? null
                                        : () {
                                          dialogSetState(() {
                                            for (UserModel student in unenrolledStudents) {
                                              selectedStudents.add(student.id);
                                            }
                                          });
                                        },
                                child: const Text('Select All'),
                              ),
                              const SizedBox(height: 12),
                              if (unenrolledStudents.isEmpty)
                                const Text('No students available to enroll', style: TextStyle(color: Colors.grey))
                              else
                                ...unenrolledStudents.map(
                                  (student) => CheckboxListTile(
                                    title: Text(student.name),
                                    subtitle: Text(student.email),
                                    value: selectedStudents.contains(student.id),
                                    onChanged: (bool? value) {
                                      dialogSetState(() {
                                        if (value == true) {
                                          selectedStudents.add(student.id);
                                        } else {
                                          selectedStudents.remove(student.id);
                                        }
                                      });
                                    },
                                    controlAffinity: ListTileControlAffinity.leading,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
                    ElevatedButton(
                      onPressed:
                          selectedStudents.isEmpty
                              ? null
                              : () async {
                                for (String studentId in selectedStudents) {
                                  try {
                                    await provider.enrollStudent(subject.id, studentId);
                                  } catch (e) {
                                    if (dialogContext.mounted) {
                                      ScaffoldMessenger.of(
                                        dialogContext,
                                      ).showSnackBar(SnackBar(content: Text('Error enrolling student: $e'), backgroundColor: Colors.red));
                                      return;
                                    }
                                  }
                                }

                                if (dialogContext.mounted) {
                                  Navigator.of(dialogContext).pop();
                                  ScaffoldMessenger.of(
                                    dialogContext,
                                  ).showSnackBar(const SnackBar(content: Text('Students enrolled successfully'), backgroundColor: Colors.green));
                                }
                              },
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      child: Text('Add ${selectedStudents.length} Student(s)'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ScaffoldMessenger(
      key: _scaffoldMessengerKey,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Subject Management'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          actions: [IconButton(onPressed: _createNewSubject, icon: const Icon(Icons.add))],
        ),
        body: Consumer<SubjectEnrollmentProvider>(
          builder: (context, provider, child) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.subjects.isEmpty) {
              return const Center(child: Text('No subjects found. Create a new subject to get started.'));
            }

            return RefreshIndicator(
              onRefresh: () async {
                await _loadData();
                if (mounted) {
                  // Use the global key to ensure access to ScaffoldMessenger even after widget rebuild
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      _scaffoldMessengerKey.currentState?.showSnackBar(
                        const SnackBar(content: Text('Refresh completed'), backgroundColor: Colors.green),
                      );
                    }
                  });
                }
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16.0),
                itemCount: provider.subjects.length,
                itemBuilder: (context, index) {
                  final subjectWithStudents = provider.subjects[index];
                  final subject = subjectWithStudents.subject;
                  final students = subjectWithStudents.students;

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: ExpansionTile(
                      title: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(subject.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                if (subject.description != null && subject.description!.isNotEmpty)
                                  Text(subject.description!, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                              ],
                            ),
                          ),
                        ],
                      ),
                      subtitle: Text('${students.length} enrolled student${students.length != 1 ? 's' : ''}'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (students.isEmpty)
                                const Text('No students enrolled yet', style: TextStyle(color: Colors.grey))
                              else
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Enrolled Students:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    const SizedBox(height: 8),
                                    ...students.map(
                                      (student) => ListTile(
                                        contentPadding: EdgeInsets.zero,
                                        leading: const Icon(Icons.person),
                                        title: Text(student.name),
                                        subtitle: Text(student.email),
                                        trailing: IconButton(
                                          icon: const Icon(Icons.remove_circle, color: Colors.red),
                                          onPressed: () async {
                                            try {
                                              await provider.unenrollStudent(subject.id, student.id);
                                              if (mounted) {
                                                // Use the global key to ensure access to ScaffoldMessenger even after widget rebuild
                                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                                  if (mounted) {
                                                    _scaffoldMessengerKey.currentState?.showSnackBar(
                                                      const SnackBar(content: Text('Student unenrolled successfully'), backgroundColor: Colors.green),
                                                    );
                                                  }
                                                });
                                              }
                                            } catch (e) {
                                              if (mounted) {
                                                WidgetsBinding.instance.addPostFrameCallback((_) {
                                                  if (mounted) {
                                                    _scaffoldMessengerKey.currentState?.showSnackBar(
                                                      SnackBar(content: Text('Error unenrolling student: $e'), backgroundColor: Colors.red),
                                                    );
                                                  }
                                                });
                                              }
                                            }
                                          },
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: () => _showManageStudentsDialog(subject),
                                style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
                                child: const Text('Manage Students'),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
