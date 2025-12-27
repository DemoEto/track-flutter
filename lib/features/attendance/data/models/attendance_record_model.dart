// Attendance record model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_app/core/enums.dart';

class AttendanceRecordModel {
  final String id;
  final String sessionId;
  final String studentId;
  final DateTime scanTime;
  final AttendanceStatus status;
  final DateTime createdAt;

  AttendanceRecordModel({
    required this.id,
    required this.sessionId,
    required this.studentId,
    required this.scanTime,
    required this.status,
    required this.createdAt,
  });

  // Convert Firestore document to AttendanceRecordModel
  factory AttendanceRecordModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Attendance record data is null');
    }

    return AttendanceRecordModel(
      id: doc.id,
      sessionId: data['sessionId'] ?? '',
      studentId: data['studentId'] ?? '',
      scanTime: (data['scanTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: AttendanceStatus.fromString(data['status'] ?? 'present'),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert AttendanceRecordModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {'sessionId': sessionId, 'studentId': studentId, 'scanTime': scanTime, 'status': status.value, 'createdAt': createdAt};
  }

  AttendanceRecordModel copyWith({
    String? id,
    String? sessionId,
    String? studentId,
    DateTime? scanTime,
    AttendanceStatus? status,
    DateTime? createdAt,
  }) {
    return AttendanceRecordModel(
      id: id ?? this.id,
      sessionId: sessionId ?? this.sessionId,
      studentId: studentId ?? this.studentId,
      scanTime: scanTime ?? this.scanTime,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
