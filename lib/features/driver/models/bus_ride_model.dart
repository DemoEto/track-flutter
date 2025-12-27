import 'package:cloud_firestore/cloud_firestore.dart';

// Status of the bus ride journey
enum BusRideStatus {
  pending('pending'),
  started('started'),
  inTransit('in-transit'),
  completed('completed');

  const BusRideStatus(this.value);
  final String value;

  static BusRideStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return BusRideStatus.pending;
      case 'started':
        return BusRideStatus.started;
      case 'in-transit':
        return BusRideStatus.inTransit;
      case 'completed':
        return BusRideStatus.completed;
      default:
        throw ArgumentError('Invalid bus ride status: $value');
    }
  }
}

// Status of individual students in the bus ride
enum StudentRideStatus {
  pending('pending'), // Student has not been picked up yet
  pickedUp('picked-up'), // Student has been picked up
  droppedOff('dropped-off'); // Student has been dropped off

  const StudentRideStatus(this.value);
  final String value;

  static StudentRideStatus fromString(String value) {
    switch (value) {
      case 'pending':
        return StudentRideStatus.pending;
      case 'picked-up':
        return StudentRideStatus.pickedUp;
      case 'dropped-off':
        return StudentRideStatus.droppedOff;
      default:
        throw ArgumentError('Invalid student ride status: $value');
    }
  }
}

class BusRideModel {
  final String id;
  final String driverId;
  final String driverName;
  final String routeName;
  final List<String> studentIds; // IDs of students in this ride
  final Map<String, StudentRideStatus> studentStatuses; // Current status of each student
  final DateTime startTime;
  final DateTime? endTime;
  final BusRideStatus status;
  final String? startLocation;
  final String? endLocation;
  final DateTime createdAt;
  final DateTime updatedAt;

  BusRideModel({
    required this.id,
    required this.driverId,
    required this.driverName,
    required this.routeName,
    required this.studentIds,
    required this.studentStatuses,
    required this.startTime,
    this.endTime,
    required this.status,
    this.startLocation,
    this.endLocation,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convert Firestore document to BusRideModel
  factory BusRideModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) {
      throw Exception('Bus ride data is null');
    }

    // Parse student statuses map
    Map<String, StudentRideStatus> studentStatuses = {};
    final statusesData = data['studentStatuses'] as Map<String, dynamic>?;
    if (statusesData != null) {
      studentStatuses = statusesData.map((key, value) => MapEntry(key, StudentRideStatus.fromString(value as String)));
    }

    return BusRideModel(
      id: doc.id,
      driverId: data['driverId'] ?? '',
      driverName: data['driverName'] ?? '',
      routeName: data['routeName'] ?? '',
      studentIds: (data['studentIds'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      studentStatuses: studentStatuses,
      startTime: (data['startTime'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endTime: (data['endTime'] as Timestamp?)?.toDate(),
      status: BusRideStatus.fromString(data['status'] ?? 'pending'),
      startLocation: data['startLocation'],
      endLocation: data['endLocation'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Convert BusRideModel to Firestore map
  Map<String, dynamic> toFirestore() {
    return {
      'driverId': driverId,
      'driverName': driverName,
      'routeName': routeName,
      'studentIds': studentIds,
      'studentStatuses': studentStatuses.map((key, value) => MapEntry(key, value.value)),
      'startTime': startTime,
      if (endTime != null) 'endTime': endTime,
      'status': status.value,
      if (startLocation != null) 'startLocation': startLocation,
      if (endLocation != null) 'endLocation': endLocation,
      'createdAt': createdAt,
      'updatedAt': updatedAt,
    };
  }

  BusRideModel copyWith({
    String? id,
    String? driverId,
    String? driverName,
    String? routeName,
    List<String>? studentIds,
    Map<String, StudentRideStatus>? studentStatuses,
    DateTime? startTime,
    DateTime? endTime,
    BusRideStatus? status,
    String? startLocation,
    String? endLocation,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    // Create a new studentStatuses map with updated studentIds if provided
    Map<String, StudentRideStatus> newStudentStatuses = {...(studentStatuses ?? this.studentStatuses)};

    if (studentIds != null) {
      // Add any new students with pending status
      for (String studentId in studentIds) {
        if (!newStudentStatuses.containsKey(studentId)) {
          newStudentStatuses[studentId] = StudentRideStatus.pending;
        }
      }

      // Remove statuses for students not in the new list
      newStudentStatuses.removeWhere((key, value) => !studentIds.contains(key));
    }

    return BusRideModel(
      id: id ?? this.id,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      routeName: routeName ?? this.routeName,
      studentIds: studentIds ?? this.studentIds,
      studentStatuses: newStudentStatuses,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      startLocation: startLocation ?? this.startLocation,
      endLocation: endLocation ?? this.endLocation,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
