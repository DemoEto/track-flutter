// User model
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_app/core/enums.dart';

class UserModel {
  final String id;
  final String email;
  final String name;
  final UserRole role;
  final String? fcmToken;
  final List<String>? childUserIds; // For parent role - list of student IDs

  final DateTime createdAt;
  final DateTime updatedAt;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    this.fcmToken,
    this.childUserIds,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Firestore document to UserModel
  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('User data is null');
    }

    return UserModel(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: UserRole.fromString(data['role'] ?? 'student'),
      fcmToken: data['fcmToken'],
      childUserIds: (data['childUserIds'] as List<dynamic>?)?.map((e) => e.toString()).toList(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert UserModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.value,
      if (fcmToken != null) 'fcmToken': fcmToken,
      if (childUserIds != null) 'childUserIds': childUserIds,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  UserModel copyWith({
    String? id,
    String? email,
    String? name,
    UserRole? role,
    String? fcmToken,
    List<String>? childUserIds,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      fcmToken: fcmToken ?? this.fcmToken,
      childUserIds: childUserIds ?? this.childUserIds,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
