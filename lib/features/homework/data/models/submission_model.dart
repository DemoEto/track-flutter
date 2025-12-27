// Submission model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_app/core/enums.dart';

class SubmissionModel {
  final String id;
  final String homeworkId;
  final String studentId;
  final List<String>? fileUrls; // List of URLs to submitted files (PDF, images, etc.)
  final List<String>? fileNames; // List of names of submitted files
  final DateTime submitTime;
  final HomeworkStatus status;
  final String? feedback;

  SubmissionModel({
    required this.id,
    required this.homeworkId,
    required this.studentId,
    this.fileUrls,
    this.fileNames,
    required this.submitTime,
    required this.status,
    this.feedback,
  });

  // Convert Firestore document to SubmissionModel
  factory SubmissionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Submission data is null');
    }

    return SubmissionModel(
      id: doc.id,
      homeworkId: data['homeworkId'] ?? '',
      studentId: data['studentId'] ?? '',
      fileUrls: data['fileUrls']?.cast<String>() ?? (data['fileUrl'] != null ? [data['fileUrl']] : null), // Maintain backward compatibility
      fileNames: data['fileNames']?.cast<String>() ?? (data['fileName'] != null ? [data['fileName']] : null), // Maintain backward compatibility
      submitTime: (data['submitTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: HomeworkStatus.fromString(data['status'] ?? 'submitted'),
      feedback: data['feedback'],
    );
  }

  // Convert SubmissionModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'homeworkId': homeworkId,
      'studentId': studentId,
      if (fileUrls != null) 'fileUrls': fileUrls,
      if (fileNames != null) 'fileNames': fileNames,
      'submitTime': submitTime,
      'status': status.value,
      if (feedback != null) 'feedback': feedback,
    };
  }

  SubmissionModel copyWith({
    String? id,
    String? homeworkId,
    String? studentId,
    List<String>? fileUrls,
    List<String>? fileNames,
    DateTime? submitTime,
    HomeworkStatus? status,
    String? feedback,
  }) {
    return SubmissionModel(
      id: id ?? this.id,
      homeworkId: homeworkId ?? this.homeworkId,
      studentId: studentId ?? this.studentId,
      fileUrls: fileUrls ?? this.fileUrls,
      fileNames: fileNames ?? this.fileNames,
      submitTime: submitTime ?? this.submitTime,
      status: status ?? this.status,
      feedback: feedback ?? this.feedback,
    );
  }
}
