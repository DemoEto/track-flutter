import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';

import '../attendance_result_page.dart';

class StudentSummerizeScreen extends StatefulWidget {
  const StudentSummerizeScreen({super.key});

  @override
  State<StudentSummerizeScreen> createState() => _StudentSummerizeScreenState();
}

class _StudentSummerizeScreenState extends State<StudentSummerizeScreen> {
  final PageController _pageController = PageController();
  final _formKey = GlobalKey<FormState>();

  List<SubjectModel> _subjects = [];
  SubjectModel? _selectedSubject;

  DateTime? _startDate;
  DateTime? _endDate;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  //-- Load Subjects by Students
  Future<void> _loadSubjects() async {
    final studentId = context.read<AuthProvider>().currentUser?.id;
    if (studentId == null) {
      setState(() => _isLoading = false);
      return;
    }
    // print('ID : ${studentId}');

    try {
      final result = await locator.subjectRepository.getSubjectsByStudent(studentId);
      // print('result subject: ${result}');

      if (mounted) {
        setState(() {
          _subjects = result;
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

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
        // ถ้า endDate น้อยกว่า startDate → ทำการ reset endDate
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Student Summary'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                children: [_buildFormPage(), _buildResultPage()],
              ),
    );
  }

  Widget _buildFormPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildLabel('Select Subject'),
            const SizedBox(height: 8),
            DropdownButtonFormField<SubjectModel>(
              decoration: const InputDecoration(border: OutlineInputBorder()),
              hint: const Text('Select subject'),
              value: _selectedSubject,
              items: _subjects
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                setState(() => _selectedSubject = value);
              },
              validator: (value) =>
                  value == null ? 'Please select subject' : null,
            ),
            const SizedBox(height: 24),
            _buildLabel('Select Date Range'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickStartDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_startDate == null ? 'Start Date' : DateFormat('dd/MM/yyyy').format(_startDate!)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: _pickEndDate,
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: Text(_endDate == null ? 'End Date' : DateFormat('dd/MM/yyyy').format(_endDate!)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
              onPressed: () {
                if (!_formKey.currentState!.validate()) return;
                if (_startDate == null || _endDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('กรุณาเลือกช่วงเวลาให้ครบถ้วน')));
                  return;
                }
                _pageController.animateToPage(1, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
              },
              child: const Text('Confirm', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold));
  }

  Widget _buildResultPage() {
    final studentId = context.read<AuthProvider>().currentUser?.id;

    if (_selectedSubject == null ||
        _startDate == null ||
        _endDate == null ||
        studentId == null) {
      return const Center(
        child: Text('กรุณาเลือกข้อมูลให้ครบถ้วน'),
      );
    }

    return AttendanceResultPage(
      subjectId: _selectedSubject!.id,
      studentId: studentId,
      startDate: _startDate!,
      endDate: _endDate!,
    );
  }

}
