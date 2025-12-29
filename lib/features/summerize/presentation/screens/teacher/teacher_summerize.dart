import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';
import 'package:track_app/features/subject/data/models/subject_with_students_model.dart';

import 'attendance_result_page.dart';

class TeacherSummerizeScreen extends StatefulWidget {
  const TeacherSummerizeScreen({super.key});

  @override
  State<TeacherSummerizeScreen> createState() => _TeacherSummerizeScreenState();
}

class _TeacherSummerizeScreenState extends State<TeacherSummerizeScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  List<SubjectWithStudentsModel> _subjectsWithStudents = [];
  SubjectWithStudentsModel? _selectedSubject;
  UserModel? _selectedStudent;

  // DateTimeRange? _selectedRange;
  DateTime? _startDate;
  DateTime? _endDate;
  //---

  bool _isLoading = true;

  //-- Load Subjects and Students
  Future<void> _loadSubjects() async {
    final teacherId = context.read<AuthProvider>().currentUser?.id;
    if (teacherId == null) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final result = await locator.subjectRepository.getSubjectsWithStudentsByTeacher(teacherId);

      if (mounted) {
        setState(() {
          _subjectsWithStudents = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red));
    }
  }

  //-- Load subjects
  // Future<void> _loadSubjects() async {
  //   final authProvider = context.read<AuthProvider>();
  //   final teacherId = authProvider.currentUser?.id;
  //   if (teacherId != null) {
  //     try {
  //       final subjects = await locator.subjectRepository.getSubjectsByTeacher(teacherId);
  //       if (mounted) {
  //         setState(() {
  //           _subjects = subjects;
  //           _isLoading = false;
  //         });
  //       }
  //     } catch (e) {
  //       if (mounted) {
  //         setState(() {
  //           _isLoading = false;
  //         });
  //         ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading subjects: $e'), backgroundColor: Colors.red));
  //       }
  //     }
  //   } else {
  //     if (mounted) {
  //       setState(() {
  //         _isLoading = false;
  //       });
  //       ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No user found'), backgroundColor: Colors.red));
  //     }
  //   }
  // }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime.now(),
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _startDate = picked;

        // ถ้า endDate น้อยกว่า startDate → reset
        if (_endDate != null && _endDate!.isBefore(picked)) {
          _endDate = null;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    if (_startDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือก Start Date ก่อน')));
      return;
    }

    final picked = await showDatePicker(context: context, initialDate: _endDate ?? _startDate!, firstDate: _startDate!, lastDate: DateTime.now());

    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    // _dateController.dispose();
    // _timeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Teacher Summerize'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildFormPage(),
                  _buildResultPage(),
                  // AttendanceResultPage(
                  //   subjectId: _selectedSubject!.subject.id,
                  //   studentId: _selectedStudent!.id,
                  //   startDate: _selectedRange!.start,
                  //   endDate: _selectedRange!.end,
                  // ),
                ],
              ),
    );
  }

  Widget _buildFormPage() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text('Select Subject', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),

            DropdownButtonFormField<SubjectWithStudentsModel>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              hint: const Text('Select subject'),
              value: _selectedSubject,
              items: _subjectsWithStudents.map((item) => DropdownMenuItem(value: item, child: Text(item.subject.name))).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedSubject = value;
                  _selectedStudent = null; // reset นักเรียน
                });
              },
              validator: (value) => value == null ? 'Please select subject' : null,
            ),

            // DropdownButtonFormField<String>(
            //   decoration: const InputDecoration(border: OutlineInputBorder()),
            //   hint: _subjects.isEmpty ? const Text('No subjects available') : const Text('Select a subject'),
            //   value: _selectedSubjectId,
            //   items:
            //       _subjects.isEmpty
            //           ? null
            //           : _subjects.map((subject) => DropdownMenuItem(value: subject.id, child: Text(subject.name))).toList(),
            //   onChanged:
            //       _subjects.isEmpty
            //           ? null
            //           : (value) {
            //             setState(() {
            //               _selectedSubjectId = value;
            //             });
            //           },
            //   validator: (value) {
            //     if (_subjects.isEmpty) {
            //       return 'No subjects available';
            //     }
            //     if (value == null || value.isEmpty) {
            //       return 'Please select a subject';
            //     }
            //     return null;
            //   },
            // ),
            const SizedBox(height: 24),
            const Text('Select Student', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),

            DropdownButtonFormField<UserModel>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              hint: const Text('Select student'),
              value: _selectedStudent,
              items:
                  (_selectedSubject?.students ?? [])
                      .map((student) => DropdownMenuItem(value: student, child: Text(student.name ?? student.email)))
                      .toList(),
              onChanged:
                  _selectedSubject == null
                      ? null
                      : (value) {
                        setState(() => _selectedStudent = value);
                      },
              validator: (value) {
                if (_selectedSubject == null) {
                  return 'Please select subject first';
                }
                if (_selectedSubject!.students.isEmpty) {
                  return 'No student enroll this subject';
                }
                if (value == null) {
                  return 'Please select student';
                }
                return null;
              },
            ),

            // DropdownButtonFormField<String>(
            //   decoration: const InputDecoration(border: OutlineInputBorder()),
            //   hint: _subjects.isEmpty ? const Text('No student enroll this subject') : const Text('Select student'),
            //   value: _selectedSubjectId,
            //   items:
            //       _subjects.isEmpty
            //           ? null
            //           : _subjects.map((subject) => DropdownMenuItem(value: subject.id, child: Text(subject.name))).toList(),
            //   onChanged:
            //       _subjects.isEmpty
            //           ? null
            //           : (value) {
            //             setState(() {
            //               _selectedSubjectId = value;
            //             });
            //           },
            //   validator: (value) {
            //     if (_subjects.isEmpty) {
            //       return 'No subjects available';
            //     }
            //     if (value == null || value.isEmpty) {
            //       return 'Please select a subject';
            //     }
            //     return null;
            //   },
            // ),
            const SizedBox(height: 24),
            const Text('Select date', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickStartDate,
                    child: Text(_startDate == null ? 'Start Date' : DateFormat('dd/MM/yyyy').format(_startDate!)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickEndDate,
                    child: Text(_endDate == null ? 'End Date' : DateFormat('dd/MM/yyyy').format(_endDate!)),
                  ),
                ),
              ],
            ),
const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;

                if (_startDate == null || _endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือก Start Date และ End Date')));
                  return;
                }

                _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              },
              child: const Text('Confirm'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultPage() {
  if (_selectedSubject == null ||
      _selectedStudent == null ||
      _startDate == null ||
      _endDate == null) {
    return const Center(child: Text('กรุณาเลือกข้อมูลให้ครบถ้วน'));
  }

  return AttendanceResultPage(
    subjectId: _selectedSubject!.subject.id,
    studentId: _selectedStudent!.id,
    startDate: _startDate!,
    endDate: _endDate!,
  );
}
}
