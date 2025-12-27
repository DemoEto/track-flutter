// Homework model
import 'package:cloud_firestore/cloud_firestore.dart';

class HomeworkModel {
  final String id;
  final String subjectId;
  final String title;
  final String description;
  final List<String> assignedTo;
  final DateTime dueDate;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? fileUrl; // URL to the attached file (PDF, image, etc.)
  final String? fileName; // Name of the attached file

  HomeworkModel({
    required this.id,
    required this.subjectId,
    required this.title,
    required this.description,
    required this.assignedTo,
    required this.dueDate,
    required this.createdAt,
    required this.updatedAt,
    this.fileUrl,
    this.fileName,
  });

  // Convert Firestore document to HomeworkModel
  factory HomeworkModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Homework data is null');
    }

    return HomeworkModel(
      id: doc.id,
      subjectId: data['subjectId'] ?? '',
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      assignedTo: (data['assignedTo'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      dueDate: (data['dueDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fileUrl: data['fileUrl'],
      fileName: data['fileName'],
    );
  }

  // Convert HomeworkModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'subjectId': subjectId,
      'title': title,
      'description': description,
      'assignedTo': assignedTo,
      'dueDate': dueDate,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
      if (fileUrl != null) 'fileUrl': fileUrl,
      if (fileName != null) 'fileName': fileName,
    };
  }

  HomeworkModel copyWith({
    String? id,
    String? subjectId,
    String? title,
    String? description,
    List<String>? assignedTo,
    DateTime? dueDate,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? fileUrl,
    String? fileName,
  }) {
    return HomeworkModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      description: description ?? this.description,
      assignedTo: assignedTo ?? this.assignedTo,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      fileUrl: fileUrl ?? this.fileUrl,
      fileName: fileName ?? this.fileName,
    );
  }
}
