// Attendance session model
import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceSessionModel {
  final String id;
  final String subjectId;
  final DateTime date;
  final String qrCode;
  final DateTime createdAt;

  AttendanceSessionModel({required this.id, required this.subjectId, required this.date, required this.qrCode, required this.createdAt});

  // Convert Firestore document to AttendanceSessionModel
  factory AttendanceSessionModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Attendance session data is null');
    }

    return AttendanceSessionModel(
      id: doc.id,
      subjectId: data['subjectId'] ?? '',
      date: (data['date'] as Timestamp?)?.toDate() ?? DateTime.now(),
      qrCode: data['qrCode'] ?? '',
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert AttendanceSessionModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {'subjectId': subjectId, 'date': date, 'qrCode': qrCode, 'createdAt': createdAt};
  }

  AttendanceSessionModel copyWith({String? id, String? subjectId, DateTime? date, String? qrCode, DateTime? createdAt}) {
    return AttendanceSessionModel(
      id: id ?? this.id,
      subjectId: subjectId ?? this.subjectId,
      date: date ?? this.date,
      qrCode: qrCode ?? this.qrCode,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
