// Student homework detail screen - shows current submission or allows new submission
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/homework/data/models/homework_model.dart';
import 'package:track_app/features/homework/data/models/submission_model.dart';
import 'package:track_app/core/enums.dart';
import 'package:track_app/core/services/storage_service.dart';
import 'package:track_app/features/homework/presentation/widgets/file_viewers.dart';

class StudentHomeworkDetailScreen extends StatefulWidget {
  final String homeworkId;

  const StudentHomeworkDetailScreen({Key? key, required this.homeworkId}) : super(key: key);

  @override
  State<StudentHomeworkDetailScreen> createState() => _StudentHomeworkDetailScreenState();
}

class _StudentHomeworkDetailScreenState extends State<StudentHomeworkDetailScreen> {
  List<File> _selectedFiles = [];
  List<String> _fileNames = [];
  bool _isSubmitting = false;
  bool _isUploading = false;
  SubmissionModel? _currentSubmission;
  HomeworkModel? _homework;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadHomeworkAndSubmission();
  }

  Future<void> _loadHomeworkAndSubmission() async {
    try {
      final authProvider = context.read<AuthProvider>();
      final studentId = authProvider.currentUser?.id;
      final homework = await _getHomework();

      if (studentId != null) {
        final submission = await locator.submissionRepository.getSubmissionByHomeworkAndStudent(widget.homeworkId, studentId);

        if (mounted) {
          setState(() {
            _homework = homework;
            _currentSubmission = submission;
            _isLoading = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _homework = homework;
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading homework details: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<HomeworkModel> _getHomework() async {
    return await locator.homeworkRepository.getHomework(widget.homeworkId) ??
        HomeworkModel(
          id: widget.homeworkId,
          subjectId: '',
          title: 'Unknown Homework',
          description: 'Homework not found',
          assignedTo: [],
          dueDate: DateTime.now(),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(appBar: AppBar(title: const Text('Homework Details')), body: const Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Homework Details'), backgroundColor: Theme.of(context).colorScheme.inversePrimary),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child:
            _homework != null
                ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_homework!.title, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text('Due: ${_homework!.dueDate.toString().split(' ')[0]}', style: const TextStyle(fontSize: 16, color: Colors.grey)),
                    const SizedBox(height: 16),
                    const Text('Description', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(_homework!.description, style: const TextStyle(fontSize: 16)),
                    const SizedBox(height: 16),
                    if (_homework!.fileUrl != null && _homework!.fileName != null) ...[
                      const Text('Teacher Attachment', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 8),
                      _buildTeacherFileCard(_homework!.fileUrl!, _homework!.fileName!),
                      const SizedBox(height: 16),
                    ],
                    const Divider(),
                    const Text('Your Submission', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),

                    // Show current submission if exists
                    if (_currentSubmission != null)
                      _buildCurrentSubmission(_currentSubmission!)
                    else
                      // Show submission form if no submission exists
                      Expanded(child: _buildSubmissionForm()),
                  ],
                )
                : const Center(child: Text('Error loading homework details')),
      ),
      bottomNavigationBar:
          _currentSubmission == null
              ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _selectFile,
                        icon: const Icon(Icons.attach_file),
                        label: const Text('Add File'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.secondary,
                          foregroundColor: Theme.of(context).colorScheme.onSecondary,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _selectedFiles.isEmpty || _isSubmitting ? null : _submitHomework,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                        child:
                            _isSubmitting
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Text('Submit Assignment', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ],
                ),
              )
              : _currentSubmission!.status == HomeworkStatus.submitted ||
                  _currentSubmission!.status ==
                      HomeworkStatus
                          .checked // Show resubmit when submitted (before teacher review) or checked (after teacher review)
              ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _resubmit,
                        icon: const Icon(Icons.edit),
                        label: const Text('Resubmit'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                      ),
                    ),
                  ],
                ),
              )
              : null,
    );
  }

  Widget _buildCurrentSubmission(SubmissionModel submission) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Submitted on:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        Text(submission.submitTime.toString().split('.')[0], style: const TextStyle(fontSize: 14, color: Colors.grey)),
        const SizedBox(height: 12),
        if (submission.fileNames != null && submission.fileUrls != null && submission.fileNames!.isNotEmpty && submission.fileUrls!.isNotEmpty) ...[
          const Text('Submitted Files:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(), // Disable scrolling for inner list
            itemCount: submission.fileNames!.length,
            itemBuilder: (context, index) {
              final fileName = submission.fileNames![index];
              final fileUrl = submission.fileUrls![index];
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

              return Card(
                child: ListTile(
                  leading: Icon(icon, size: 40, color: Colors.blue),
                  title: Text(fileName, overflow: TextOverflow.ellipsis),
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new, color: Colors.blue),
                    onPressed: () => _openFile(context, fileUrl, fileName),
                  ),
                ),
              );
            },
          ),
        ],
        if (submission.feedback != null && submission.feedback!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Feedback:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Card(
            color: Colors.grey[100],
            child: Padding(padding: const EdgeInsets.all(12.0), child: Text(submission.feedback!, style: const TextStyle(fontSize: 14))),
          ),
        ],
        const SizedBox(height: 16),
        Text(
          'Status: ${submission.status.name}',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: submission.status == HomeworkStatus.submitted ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildSubmissionForm() {
    return Column(
      children: [
        const Text('You haven\'t submitted this assignment yet.', style: TextStyle(fontSize: 16, color: Colors.grey)),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _selectedFiles.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final fileName = _fileNames[index];
              final file = _selectedFiles[index];
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

              return Card(
                child: ListTile(
                  leading: Icon(icon, size: 40, color: Colors.blue),
                  title: Text(fileName, overflow: TextOverflow.ellipsis),
                  subtitle: Text('${(file.lengthSync() / 1024).ceil()} KB', style: const TextStyle(fontSize: 12)),
                  trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeFile(index)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildTeacherFileCard(String fileUrl, String fileName) {
    final fileExtension = _getFileExtension(fileName).toLowerCase();
    IconData icon = Icons.insert_drive_file;

    if (fileExtension.contains('pdf')) {
      icon = Icons.picture_as_pdf;
    } else if (fileExtension.contains('jpg') || fileExtension.contains('jpeg') || fileExtension.contains('png') || fileExtension.contains('gif')) {
      icon = Icons.image;
    }

    return Card(
      child: InkWell(
        onTap: () => _openFile(context, fileUrl, fileName),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            children: [
              Icon(icon, size: 40, color: Colors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fileName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500), overflow: TextOverflow.ellipsis),
                    Text('Teacher attachment', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                  ],
                ),
              ),
              const Icon(Icons.open_in_new, color: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  String _getFileExtension(String fileName) {
    final parts = fileName.split('.');
    if (parts.length > 1) {
      return '.${parts.last}';
    }
    return '';
  }

  Future<void> _selectFile() async {
    final ImagePicker picker = ImagePicker();

    // Ask user whether to pick an image, take a photo, or document using bottom sheet
    final result = await showModalBottomSheet<int>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const ListTile(leading: Icon(Icons.insert_drive_file), title: Text('Select File Type')),
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Take Photo'),
                onTap: () {
                  Navigator.of(context).pop(1); // Take Photo
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.of(context).pop(2); // Image from gallery
                },
              ),
              ListTile(
                leading: const Icon(Icons.picture_as_pdf),
                title: const Text('Document (PDF, etc.)'),
                onTap: () {
                  Navigator.of(context).pop(3); // Document
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.cancel),
                title: const Text('Cancel'),
                onTap: () {
                  Navigator.of(context).pop(0); // Cancel
                },
              ),
            ],
          ),
        );
      },
    );

    XFile? pickedFile;

    if (result == 1) {
      // Take photo using camera
      pickedFile = await picker.pickImage(source: ImageSource.camera);
    } else if (result == 2) {
      // Choose image from gallery
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    } else if (result == 3) {
      // Document/Other file - using image picker for gallery access
      pickedFile = await picker.pickImage(source: ImageSource.gallery);
    }

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final fileName = pickedFile.name;
      setState(() {
        _selectedFiles.add(file);
        _fileNames.add(fileName);
      });
    }
  }

  void _removeFile(int index) {
    setState(() {
      _selectedFiles.removeAt(index);
      _fileNames.removeAt(index);
    });
  }

  Future<void> _submitHomework() async {
    final authProvider = context.read<AuthProvider>();
    final studentId = authProvider.currentUser?.id;

    if (studentId == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Student not authenticated'), backgroundColor: Colors.red));
      }
      return;
    }

    if (_selectedFiles.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Please select at least one file to submit'), backgroundColor: Colors.orange));
      }
      return;
    }

    try {
      setState(() {
        _isSubmitting = true;
      });

      // Upload all files to Firebase Storage
      final storageService = StorageService();
      final List<String> fileUrls = [];
      final List<String> fileNames = [];

      for (int i = 0; i < _selectedFiles.length; i++) {
        final file = _selectedFiles[i];
        final fileName = _fileNames[i];

        _isUploading = true;

        final fileUrl = await storageService.uploadFile(
          file,
          'homework_submissions/${DateTime.now().millisecondsSinceEpoch}_${i}_',
          fileName: fileName,
        );

        fileUrls.add(fileUrl);
        fileNames.add(fileName);
      }

      // Create submission record in Firestore
      final submission = SubmissionModel(
        id: const Uuid().v4(),
        homeworkId: widget.homeworkId,
        studentId: studentId,
        fileUrls: fileUrls,
        fileNames: fileNames,
        submitTime: DateTime.now(),
        status: HomeworkStatus.submitted,
      );

      await locator.submissionRepository.createSubmission(submission);

      // Update the current submission
      if (mounted) {
        setState(() {
          _currentSubmission = submission;
        });

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Homework submitted successfully'), backgroundColor: Colors.green));
      }
    } catch (e) {
      _isUploading = false;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error submitting homework: $e'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
          _isUploading = false;
        });
      }
    }
  }

  Future<void> _resubmit() async {
    // Reset the submission lists and allow user to submit again
    if (mounted) {
      setState(() {
        _currentSubmission = null; // Reset to show submission form
        _selectedFiles.clear();
        _fileNames.clear();
      });
    }
  }

  Future<void> _openFile(BuildContext context, String fileUrl, String fileName) async {
    final fileExtension = _getFileExtension(fileName).toLowerCase();

    if (fileExtension.contains('jpg') || fileExtension.contains('jpeg') || fileExtension.contains('png') || fileExtension.contains('gif')) {
      // Open image in full-screen viewer
      _openImageViewer(fileUrl, fileName);
    } else if (fileExtension.contains('pdf')) {
      // Open PDF in a dedicated PDF viewer
      _openPDFViewer(fileUrl, fileName);
    } else {
      // For other file types, open in a web view
      await showDialog(
        context: context,
        builder:
            (context) => AlertDialog(
              title: const Text('File Preview'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('File: $fileName'),
                  const SizedBox(height: 8),
                  Text('URL: $fileUrl'),
                  const SizedBox(height: 8),
                  const Text('Cannot preview this file type directly in the app. Please download it to view.'),
                ],
              ),
              actions: [TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK'))],
            ),
      );
    }
  }

  void _openImageViewer(String imageUrl, String fileName) {
    showDialog(context: context, builder: (context) => PhotoViewDialog(imageUrl: imageUrl, fileName: fileName));
  }

  void _openPDFViewer(String pdfUrl, String fileName) {
    showDialog(context: context, builder: (context) => PDFViewerDialog(pdfUrl: pdfUrl, fileName: fileName));
  }
}
