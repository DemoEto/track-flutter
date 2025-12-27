// Homework detail screen for teachers to review student submissions
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/homework/data/models/homework_model.dart';
import 'package:track_app/features/homework/data/models/submission_model.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';
import 'package:track_app/core/enums.dart';
import 'package:track_app/features/homework/presentation/widgets/file_viewers.dart';
import 'dart:async';
import 'package:url_launcher/url_launcher.dart';
import 'package:photo_view/photo_view.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';

class TeacherHomeworkDetailScreen extends StatefulWidget {
  final HomeworkModel? homework;

  const TeacherHomeworkDetailScreen({Key? key, this.homework}) : super(key: key);

  @override
  State<TeacherHomeworkDetailScreen> createState() => _TeacherHomeworkDetailScreenState();
}

class _TeacherHomeworkDetailScreenState extends State<TeacherHomeworkDetailScreen> {
  List<SubmissionModel> _submissions = [];
  List<UserModel> _students = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubmissions();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Reload data when returning to this screen
    _loadSubmissions();
  }

  Future<void> _loadSubmissions() async {
    final authProvider = context.read<AuthProvider>();
    final teacherId = authProvider.currentUser?.id;

    if (teacherId == null || widget.homework == null) return;

    try {
      // Load submissions for this homework
      _submissions = await locator.submissionRepository.getSubmissionsByHomework(widget.homework!.id);

      // Load student details for the submissions
      final studentIds = _submissions.map((sub) => sub.studentId).toSet().toList();
      for (final studentId in studentIds) {
        final student = await locator.userRepository.getUser(studentId);
        if (student != null) {
          _students.add(student);
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
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading submissions: $e'), backgroundColor: Colors.red));
      }
    }
  }

  String _getStudentName(String studentId) {
    final student = _students.firstWhere(
      (s) => s.id == studentId,
      orElse:
          () => UserModel(
            id: studentId,
            email: 'unknown@example.com',
            name: 'Unknown Student',
            role: UserRole.student,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
    );
    return student.name;
  }

  Color _getStatusColor(HomeworkStatus status) {
    switch (status) {
      case HomeworkStatus.submitted:
        return Colors.orange;
      case HomeworkStatus.checked:
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getStatusText(HomeworkStatus status) {
    switch (status) {
      case HomeworkStatus.submitted:
        return 'Submitted';
      case HomeworkStatus.checked:
        return 'Checked';
      default:
        return 'Unknown';
    }
  }

  Future<void> _updateSubmissionStatus(SubmissionModel submission, HomeworkStatus newStatus) async {
    try {
      final updatedSubmission = submission.copyWith(status: newStatus);
      await locator.submissionRepository.updateSubmission(updatedSubmission);

      // Update local list
      final index = _submissions.indexOf(submission);
      if (index != -1) {
        _submissions[index] = updatedSubmission;
        setState(() {});
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Submission status updated to ${_getStatusText(newStatus)}'), backgroundColor: _getStatusColor(newStatus)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating submission: $e'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Review Submissions - ${widget.homework?.title ?? 'Homework'}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _submissions.isEmpty
              ? const Center(child: Text('No submissions to review'))
              : RefreshIndicator(
                onRefresh: _loadSubmissions,
                child: ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: _submissions.length,
                  itemBuilder: (context, index) {
                    final submission = _submissions[index];
                    final studentName = _getStudentName(submission.studentId);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ExpansionTile(
                        initiallyExpanded: false,
                        title: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(studentName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                  Text(
                                    'Submitted: ${DateFormat('MMM dd, yyyy - hh:mm a').format(submission.submitTime)}',
                                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _getStatusColor(submission.status).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _getStatusColor(submission.status), width: 1),
                              ),
                              child: Text(
                                _getStatusText(submission.status),
                                style: TextStyle(color: _getStatusColor(submission.status), fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                        children: [
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (submission.fileUrls != null && submission.fileUrls!.isNotEmpty)
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text('Submitted Files:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                                      const SizedBox(height: 8),
                                      ...List.generate(submission.fileUrls!.length, (index) {
                                        final fileUrl = submission.fileUrls![index];
                                        final fileName =
                                            submission.fileNames != null && submission.fileNames!.isNotEmpty
                                                ? submission.fileNames![index]
                                                : 'File ${index + 1}';

                                        final fileExtension = _getFileExtension(fileName).toLowerCase();
                                        IconData icon = Icons.insert_drive_file;

                                        if (fileExtension.contains('pdf')) {
                                          icon = Icons.picture_as_pdf;
                                        } else if (fileExtension.contains('jpg') ||
                                            fileExtension.contains('jpeg') ||
                                            fileExtension.contains('png') ||
                                            fileExtension.contains('gif')) {
                                          icon = Icons.image;
                                        } else if (fileExtension.contains('doc') || fileExtension.contains('docx')) {
                                          icon = Icons.description;
                                        }

                                        return Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: ListTile(
                                            tileColor: Colors.grey.withOpacity(0.1),
                                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
                                            leading: Icon(icon),
                                            title: Text(fileName, style: const TextStyle(fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            onTap: () => _openFile(fileUrl, fileExtension),
                                            dense: true,
                                          ),
                                        );
                                      }),
                                    ],
                                  ),
                                const SizedBox(height: 12),
                                Row(
                                  children: [
                                    Expanded(
                                      child: DropdownButtonFormField<HomeworkStatus>(
                                        value: submission.status,
                                        decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                                        items:
                                            HomeworkStatus.values.map((status) {
                                              return DropdownMenuItem(value: status, child: Text(_getStatusText(status)));
                                            }).toList(),
                                        onChanged: (newStatus) {
                                          if (newStatus != null) {
                                            _updateSubmissionStatus(submission, newStatus);
                                          }
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    ElevatedButton(
                                      onPressed: () {
                                        _showFeedbackDialog(submission);
                                      },
                                      child: const Text('Feedback'),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
    );
  }

  void _openFile(String fileUrl, String fileExtension) async {
    // Determine file type and open accordingly
    if (fileExtension.contains('jpg') || fileExtension.contains('jpeg') || fileExtension.contains('png') || fileExtension.contains('gif')) {
      // Open image in full-screen viewer
      _openImageViewer(fileUrl);
    } else if (fileExtension.contains('pdf')) {
      // Open PDF in a dedicated PDF viewer
      _openPDFViewer(fileUrl);
    } else if (fileExtension.contains('doc') || fileExtension.contains('docx')) {
      // Open DOC/DOCX files in web view
      if (await canLaunchUrl(Uri.parse(fileUrl))) {
        await launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the file'), backgroundColor: Colors.red));
        }
      }
    } else {
      // For other file types, try to open with default handler
      if (await canLaunchUrl(Uri.parse(fileUrl))) {
        await launchUrl(Uri.parse(fileUrl), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Could not open the file'), backgroundColor: Colors.red));
        }
      }
    }
  }

  void _openImageViewer(String imageUrl) {
    showDialog(context: context, builder: (context) => PhotoViewDialog(imageUrl: imageUrl, fileName: imageUrl.split('/').last));
  }

  void _openPDFViewer(String pdfUrl) {
    showDialog(context: context, builder: (context) => PDFViewerDialog(pdfUrl: pdfUrl, fileName: pdfUrl.split('/').last));
  }

  void _showFeedbackDialog(SubmissionModel submission) {
    final TextEditingController feedbackController = TextEditingController(text: submission.feedback);

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Feedback'),
            content: TextField(
              controller: feedbackController,
              maxLines: 4,
              decoration: const InputDecoration(hintText: 'Enter feedback for the student...', border: OutlineInputBorder()),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  try {
                    // Update submission status to 'checked' when giving feedback
                    final updatedSubmission = submission.copyWith(feedback: feedbackController.text, status: HomeworkStatus.checked);
                    await locator.submissionRepository.updateSubmission(updatedSubmission);

                    // Update local list
                    final index = _submissions.indexOf(submission);
                    if (index != -1) {
                      _submissions[index] = updatedSubmission;
                      setState(() {});
                    }

                    if (mounted) {
                      Navigator.of(context).pop(); // Close dialog
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Feedback saved successfully'), backgroundColor: Colors.green));
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving feedback: $e'), backgroundColor: Colors.red));
                    }
                  }
                },
                child: const Text('Save'),
              ),
            ],
          ),
    );
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return '.${parts.last}'.toLowerCase();
    }
    return '';
  }
}
