// Subject enrollment model to connect subjects and students
import 'package:cloud_firestore/cloud_firestore.dart';

class SubjectEnrollmentModel {
  final String id;
  final String subjectId;
  final String studentId;
  final DateTime enrolledAt;
  final DateTime? unenrolledAt;

  SubjectEnrollmentModel({required this.id, required this.subjectId, required this.studentId, required this.enrolledAt, this.unenrolledAt});

  // Convert Firestore document to SubjectEnrollmentModel
  factory SubjectEnrollmentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Subject enrollment data is null');
    }

    return SubjectEnrollmentModel(
      id: doc.id,
      subjectId: data['subjectId'] ?? '',
      studentId: data['studentId'] ?? '',
      enrolledAt: (data['enrolledAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unenrolledAt: (data['unenrolledAt'] as Timestamp?)?.toDate(),
    );
  }

  // Convert SubjectEnrollmentModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {'subjectId': subjectId, 'studentId': studentId, 'enrolledAt': enrolledAt, if (unenrolledAt != null) 'unenrolledAt': unenrolledAt};
  }

  SubjectEnrollmentModel copyWith({String? id, String? subjectId, String? studentId, DateTime? enrolledAt, DateTime? unenrolledAt}) {
    return SubjectEnrollmentModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      studentId: studentId ?? this.studentId,
      enrolledAt: enrolledAt ?? this.enrolledAt,
      unenrolledAt: unenrolledAt ?? this.unenrolledAt,
    );
  }
}
