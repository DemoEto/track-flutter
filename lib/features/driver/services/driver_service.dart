import 'package:track_app/core/enums.dart';
import 'package:uuid/uuid.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/notification/services/notification_service.dart';
import '../models/bus_ride_model.dart';

class DriverService {
  final notificationService = NotificationService();

  // Create a new bus ride
  Future<BusRideModel> createBusRide({
    required String driverId,
    required String driverName,
    required String routeName,
    required List<String> studentIds,
    String? startLocation,
    String? endLocation,
  }) async {
    final rideId = const Uuid().v4();
    final now = DateTime.now();

    final busRide = BusRideModel(
      id: rideId,
      driverId: driverId,
      driverName: driverName,
      routeName: routeName,
      studentIds: studentIds,
      studentStatuses: {for (String id in studentIds) id: StudentRideStatus.pending},
      startTime: now,
      endTime: null,
      status: BusRideStatus.pending,
      startLocation: startLocation,
      endLocation: endLocation,
      createdAt: now,
      updatedAt: now,
    );

    final repo = locator.driverRepository;
    return await repo.createBusRide(busRide);
  }

  // Start a bus journey
  Future<void> startJourney(String rideId) async {
    final repo = locator.driverRepository;

    // Update ride status to started
    await repo.updateBusRideStatus(rideId, BusRideStatus.started);

    // Note: Student and parent notifications for bus status changes are now handled by Firebase Functions
    // when the bus ride status is updated in the Firestore database
  }

  // Update student status when picked up
  Future<void> pickUpStudent(String rideId, String studentId) async {
    final repo = locator.driverRepository;

    // Update student status to picked up
    await repo.updateStudentRideStatus(rideId, studentId, StudentRideStatus.pickedUp);

    // Note: Student and parent notifications for pickup events are now handled by Firebase Functions
    // when the student ride status is updated in the Firestore database
  }

  // Complete the journey
  Future<void> completeJourney(String rideId) async {
    final repo = locator.driverRepository;

    // Update ride status to completed and set end time
    await repo.updateBusRideStatus(rideId, BusRideStatus.completed);
    await repo.updateBusRideEndTime(rideId, DateTime.now());

    // Note: Student and parent notifications for journey completion are now handled by Firebase Functions
    // when the bus ride status is updated in the Firestore database
  }

  // Add a student to a bus ride
  Future<void> addStudentToRide(String rideId, String studentId) async {
    final repo = locator.driverRepository;

    // Add student to ride
    await repo.addStudentToRide(rideId, studentId);

    // Note: Student and parent notifications for being added to bus rides are now handled by Firebase Functions
    // when the studentIds array is updated in the Firestore database
  }

  // Remove a student from a bus ride
  Future<void> removeStudentFromRide(String rideId, String studentId) async {
    final repo = locator.driverRepository;

    // Remove student from ride
    await repo.removeStudentFromRide(rideId, studentId);

    // Note: Student and parent notifications for being removed from bus rides are now handled by Firebase Functions
    // when the studentIds array is updated in the Firestore database
  }
}
