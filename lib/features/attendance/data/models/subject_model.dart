// Subject model
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectModel {
  final String id;
  final String name;
  final String teacherId;
  final String? description;
  final DateTime createdAt;
  final DateTime updatedAt;

  SubjectModel({required this.id, required this.name, required this.teacherId, this.description, required this.createdAt, required this.updatedAt});

  // Convert Firestore document to SubjectModel
  factory SubjectModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Subject data is null');
    }

    return SubjectModel(
      id: doc.id,
      name: data['name'] ?? '',
      teacherId: data['teacherId'] ?? '',
      description: data['description'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert SubjectModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'teacherId': teacherId,
      if (description != null) 'description': description,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  SubjectModel copyWith({String? id, String? name, String? teacherId, String? description, DateTime? createdAt, DateTime? updatedAt}) {
    return SubjectModel(
      id: id ?? this.id,
      name: name ?? this.name,
      teacherId: teacherId ?? this.teacherId,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
