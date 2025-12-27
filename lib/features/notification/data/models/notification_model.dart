// Notification model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_app/core/enums.dart';

class NotificationModel {
  final String id;
  final String userId;
  final NotificationType type;
  final String message;
  final String? relatedId;
  final bool isRead;
  final DateTime timestamp;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.message,
    this.relatedId,
    required this.isRead,
    required this.timestamp,
  });

  // Convert Firestore document to NotificationModel
  factory NotificationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Notification data is null');
    }

    return NotificationModel(
      id: doc.id,
      userId: data['userId'] ?? '',
      type: NotificationType.fromString(data['type'] ?? 'general'),
      message: data['message'] ?? '',
      relatedId: data['relatedId'],
      isRead: data['isRead'] ?? false,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert NotificationModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'type': type.value,
      'message': message,
      if (relatedId != null) 'relatedId': relatedId,
      'isRead': isRead,
      'timestamp': timestamp,
    };
  }

  NotificationModel copyWith({
    String? id,
    String? userId,
    NotificationType? type,
    String? message,
    String? relatedId,
    bool? isRead,
    DateTime? timestamp,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      message: message ?? this.message,
      relatedId: relatedId ?? this.relatedId,
      isRead: isRead ?? this.isRead,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
