// Homework assignment screen for teachers
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/homework/data/models/homework_model.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';

import 'package:track_app/core/enums.dart';
import 'package:track_app/core/services/storage_service.dart';

class TeacherHomeworkCreateScreen extends StatefulWidget {
  const TeacherHomeworkCreateScreen({super.key});

  @override
  State<TeacherHomeworkCreateScreen> createState() => _TeacherHomeworkCreateScreenState();
}

class _TeacherHomeworkCreateScreenState extends State<TeacherHomeworkCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _dueDateController = TextEditingController();
  DateTime? _selectedDueDate;

  String? _selectedSubjectId;
  // Removed _selectedStudentIds as homework will be assigned to all enrolled students

  List<SubjectModel> _subjects = [];
  List<UserModel> _studentsInSelectedSubject = [];
  bool _isLoading = true;
  bool _isLoadingStudents = false;

  // File upload variables
  File? _selectedFile;
  String? _fileName;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final authProvider = context.read<AuthProvider>();
    final teacherId = authProvider.currentUser?.id;

    if (teacherId != null) {
      try {
        // Load teacher's subjects
        _subjects = await locator.subjectRepository.getSubjectsByTeacher(teacherId);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading data: $e'), backgroundColor: Colors.red));
        }
      }
    } else {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user found'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _loadStudentsForSubject(String subjectId) async {
    try {
      // No need to set loading state here since it's set in the onChanged handler
      // Load students enrolled in the selected subject
      final studentIds = await locator.subjectRepository.getStudentIdsForSubject(subjectId);
      final enrolledStudents = <UserModel>[];

      for (final studentId in studentIds) {
        final student = await locator.userRepository.getUser(studentId);
        if (student != null) {
          enrolledStudents.add(student);
        }
      }

      if (mounted) {
        setState(() {
          _studentsInSelectedSubject = enrolledStudents;
          _isLoadingStudents = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingStudents = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading students for subject: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _selectDueDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime(2101),
    );
    if (picked != null) {
      _selectedDueDate = picked;
      _dueDateController.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  Future<void> _selectFile() async {
    final ImagePicker picker = ImagePicker();

    // Ask user whether to pick an image or document using bottom sheet
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const ListTile(leading: Icon(Icons.insert_drive_file), title: Text('Select File Type')),
                ListTile(
                  leading: Icon(Icons.image),
                  title: Text('Image'),
                  onTap: () {
                    Navigator.of(context).pop(1); // Image
                  },
                ),
                ListTile(
                  leading: Icon(Icons.picture_as_pdf),
                  title: Text('Document (PDF, etc.)'),
                  onTap: () {
                    Navigator.of(context).pop(2); // Document
                  },
                ),
                const Divider(),
                ListTile(
                  leading: Icon(Icons.cancel),
                  title: Text('Cancel'),
                  onTap: () {
                    Navigator.of(context).pop(0); // Cancel
                  },
                ),
              ],
            ),
          ),
        );
      },
    );

    XFile? pickedFile;

    if (result == 1 || result == 2) {
      // Both image and document use gallery
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    }

    if (pickedFile != null) {
      setState(() {
        _selectedFile = File(pickedFile!.path);
        _fileName = pickedFile.name;
      });
    }
  }

  Future<String?> _uploadFile() async {
    if (_selectedFile == null) return null;

    try {
      setState(() {
        _isUploading = true;
      });

      final storageService = StorageService();
      final fileUrl = await storageService.uploadFile(_selectedFile!, 'homework_attachments', fileName: _fileName);

      return fileUrl;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading file: $e'), backgroundColor: Colors.red));
      }
      return null;
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _createHomework() async {
    if (_formKey.currentState!.validate() &&
        _selectedSubjectId != null &&
        _selectedDueDate != null &&
        _studentsInSelectedSubject.isNotEmpty &&
        !_isLoadingStudents) {
      try {
        String? fileUrl;
        if (_selectedFile != null) {
          fileUrl = await _uploadFile();
          if (fileUrl == null) {
            // Upload failed, return early
            return;
          }
        }

        // Get student IDs for the assignedTo list
        final studentIds = _studentsInSelectedSubject.map((student) => student.id).toList();

        final homework = HomeworkModel(
          id: const Uuid().v4(),
          subjectId: _selectedSubjectId!,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          assignedTo: studentIds,
          dueDate: _selectedDueDate!,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          fileUrl: fileUrl,
          fileName: _fileName,
        );

        await locator.homeworkRepository.createHomework(homework);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Homework created successfully'), backgroundColor: Colors.green));
          Navigator.pop(context); // Go back to previous screen
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating homework: $e'), backgroundColor: Colors.red));
        }
      }
    } else if (_isLoadingStudents) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please wait while students are being loaded'), backgroundColor: Colors.orange));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please fill all required fields and select a subject with enrolled students'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Assignment'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: SingleChildScrollView(
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Create New Homework', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _titleController,
                          decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder()),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a title';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(labelText: 'Description', border: OutlineInputBorder(), alignLabelWithHint: true),
                          maxLines: 3,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter a description';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Select Subject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          decoration: const InputDecoration(border: OutlineInputBorder()),
                          hint: _subjects.isEmpty ? const Text('No subjects available') : const Text('Select a subject'),
                          value: _selectedSubjectId,
                          items:
                              _subjects.isEmpty
                                  ? null
                                  : _subjects.map((subject) => DropdownMenuItem(value: subject.id, child: Text(subject.name))).toList(),
                          onChanged:
                              _subjects.isEmpty
                                  ? null
                                  : (value) async {
                                    // Make this async to handle async call properly
                                    setState(() {
                                      _selectedSubjectId = value;
                                      _studentsInSelectedSubject = []; // Clear the previous students list
                                      _isLoadingStudents = true; // Set loading state immediately
                                    });

                                    if (value != null) {
                                      await _loadStudentsForSubject(value); // Wait for loading to complete
                                    }
                                  },
                          validator: (value) {
                            if (_subjects.isEmpty) {
                              return 'No subjects available';
                            }
                            if (value == null || value.isEmpty) {
                              return 'Please select a subject';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Students in Subject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                          child:
                              _isLoadingStudents
                                  ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                        SizedBox(width: 8),
                                        Text('Loading students...'),
                                      ],
                                    ),
                                  )
                                  : _studentsInSelectedSubject.isEmpty
                                  ? const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.warning, color: Colors.orange),
                                        SizedBox(width: 8),
                                        Text('No students enrolled in this subject'),
                                      ],
                                    ),
                                  )
                                  : Container(
                                    height: 150, // Fixed height for the list
                                    padding: const EdgeInsets.all(4),
                                    child: Scrollbar(
                                      child: ListView.builder(
                                        itemCount: _studentsInSelectedSubject.length,
                                        itemBuilder: (context, index) {
                                          final student = _studentsInSelectedSubject[index];
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 2.0),
                                            child: Card(
                                              child: Padding(
                                                padding: const EdgeInsets.all(8.0),
                                                child: Row(
                                                  children: [
                                                    const Icon(Icons.person, size: 16),
                                                    const SizedBox(width: 8),
                                                    Expanded(child: Text(student.name, style: const TextStyle(fontSize: 14))),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _dueDateController,
                          decoration: const InputDecoration(labelText: 'Due Date', border: OutlineInputBorder()),
                          readOnly: true,
                          onTap: _selectDueDate,
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a due date';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        const Text('Attach File (Optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(border: Border.all(color: Colors.grey), borderRadius: BorderRadius.circular(4)),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  _selectedFile != null ? _fileName ?? 'Unknown file' : 'No file selected',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Row(
                                children: [
                                  if (_isUploading)
                                    const Padding(
                                      padding: EdgeInsets.only(right: 8.0),
                                      child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                                    ),
                                  IconButton(icon: const Icon(Icons.attach_file), onPressed: _selectFile),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        width: double.infinity,
        child: ElevatedButton(
          onPressed: _createHomework,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
          ),
          child: const Text('Create Homework', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _dueDateController.dispose();
    super.dispose();
  }
}
