// Teacher attendance create screen for teachers to create attendance sessions
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/features/attendance/presentation/screens/teacher/teacher_attendance_detail_screen.dart';
import 'package:uuid/uuid.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';
import 'package:track_app/features/attendance/data/models/attendance_session_model.dart';
import 'package:qr_flutter/qr_flutter.dart';

class TeacherAttendanceCreateScreen extends StatefulWidget {
  const TeacherAttendanceCreateScreen({super.key});

  @override
  State<TeacherAttendanceCreateScreen> createState() => _TeacherAttendanceCreateScreenState();
}

class _TeacherAttendanceCreateScreenState extends State<TeacherAttendanceCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dateController = TextEditingController();
  final _timeController = TextEditingController();
  String? _selectedSubjectId;
  DateTime? _selectedDateTime;

  List<SubjectModel> _subjects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    final authProvider = context.read<AuthProvider>();
    final teacherId = authProvider.currentUser?.id;

    if (teacherId != null) {
      try {
        final subjects = await locator.subjectRepository.getSubjectsByTeacher(teacherId);

        if (mounted) {
          setState(() {
            _subjects = subjects;
            _isLoading = false;
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading subjects: $e'), backgroundColor: Colors.red));
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

  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2101));
    if (picked != null) {
      _selectedDateTime = picked;
      _dateController.text = picked.toLocal().toString().split(' ')[0];
      _selectTime();
    }
  }

  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(context: context, initialTime: TimeOfDay.now());
    if (picked != null && _selectedDateTime != null) {
      final selectedTime = DateTime(_selectedDateTime!.year, _selectedDateTime!.month, _selectedDateTime!.day, picked.hour, picked.minute);
      _selectedDateTime = selectedTime;
      _timeController.text = '${picked.hour}:${picked.minute.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _createSession() async {
    if (_formKey.currentState!.validate() && _selectedSubjectId != null && _selectedDateTime != null) {
      try {
        // Check if the selected subject has any enrolled students
        final studentIds = await locator.subjectRepository.getStudentIdsForSubject(_selectedSubjectId!);
        if (studentIds.isEmpty) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Cannot create attendance session: No students enrolled in this subject'), backgroundColor: Colors.red),
            );
          }
          return;
        }

        // Generate a unique QR code (in a real app, this would be based on session details)
        final qrCode = 'ATT-${DateTime.now().millisecondsSinceEpoch}-${const Uuid().v4()}';

        final session = AttendanceSessionModel(
          id: const Uuid().v4(),
          subjectId: _selectedSubjectId!,
          date: _selectedDateTime!,
          qrCode: qrCode,
          createdAt: DateTime.now(),
        );

        await locator.attendanceSessionRepository.createSession(session);

        if (mounted) {
          // Show a dialog with the QR code instead of immediately navigating back
          _showQRCodeDialog(session);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating session: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _showQRCodeDialog(AttendanceSessionModel session) {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent dismissal by tapping outside
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Attendance Session Created'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Show this QR code to students to scan'),
                const SizedBox(height: 16),
                Expanded(child: QrImageView(data: session.qrCode, version: QrVersions.auto, size: 200.0, gapless: false)),
                const SizedBox(height: 16),
                Text('QR Code: ${session.qrCode}', style: const TextStyle(fontSize: 12), textAlign: TextAlign.center),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Go back to previous screen
                Navigator.push(context, MaterialPageRoute(builder: (context) => TeacherAttendanceDetailScreen(session: session)));
              },
              child: const Text('DONE'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Attendance Session'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      bottomNavigationBar:
          _isLoading
              ? null
              : Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _createSession,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  child: const Text('Create Session', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Create New Attendance Session', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 24),
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
                                : (value) {
                                  setState(() {
                                    _selectedSubjectId = value;
                                  });
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
                      const SizedBox(height: 24),
                      const Text('Select Date and Time', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextFormField(
                              controller: _dateController,
                              decoration: const InputDecoration(labelText: 'Date', border: OutlineInputBorder()),
                              readOnly: true,
                              onTap: _selectDate,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a date';
                                }
                                return null;
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: TextFormField(
                              controller: _timeController,
                              decoration: const InputDecoration(labelText: 'Time', border: OutlineInputBorder()),
                              readOnly: true,
                              onTap: _selectTime,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Please select a time';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  @override
  void dispose() {
    _dateController.dispose();
    _timeController.dispose();
    super.dispose();
  }
}
