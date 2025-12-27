import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_app/features/driver/models/bus_ride_model.dart';

abstract class DriverRepository {
  Future<BusRideModel> createBusRide(BusRideModel busRide);
  Future<BusRideModel> getBusRide(String rideId);
  Future<List<BusRideModel>> getBusRidesByDriver(String driverId);
  Future<List<BusRideModel>> getActiveBusRides();
  Future<void> updateBusRideStatus(String rideId, BusRideStatus status);
  Future<void> updateStudentRideStatus(String rideId, String studentId, StudentRideStatus status);
  Future<void> updateBusRideLocation(String rideId, String location);
  Future<void> updateBusRideEndTime(String rideId, DateTime endTime);
  Future<void> addStudentToRide(String rideId, String studentId);
  Future<void> removeStudentFromRide(String rideId, String studentId);
  Stream<BusRideModel> getBusRideStream(String rideId);
}

class FirebaseDriverRepository implements DriverRepository {
  final FirebaseFirestore _firestore;

  FirebaseDriverRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<BusRideModel> createBusRide(BusRideModel busRide) async {
    final doc = _firestore.collection('rides').doc();
    await doc.set(busRide.copyWith(id: doc.id).toFirestore());
    return busRide.copyWith(id: doc.id);
  }

  @override
  Future<BusRideModel> getBusRide(String rideId) async {
    final doc = await _firestore.collection('rides').doc(rideId).get();
    if (!doc.exists) {
      throw Exception('Bus ride not found');
    }
    return BusRideModel.fromFirestore(doc);
  }

  @override
  Future<List<BusRideModel>> getBusRidesByDriver(String driverId) async {
    final querySnapshot = await _firestore.collection('rides').where('driverId', isEqualTo: driverId).orderBy('createdAt', descending: true).get();

    return querySnapshot.docs.map((doc) => BusRideModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<BusRideModel>> getActiveBusRides() async {
    final querySnapshot =
        await _firestore.collection('rides').where('status', isNotEqualTo: 'completed').orderBy('createdAt', descending: true).get();

    return querySnapshot.docs.map((doc) => BusRideModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> updateBusRideStatus(String rideId, BusRideStatus status) async {
    await _firestore.collection('rides').doc(rideId).update({'status': status.value, 'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> updateStudentRideStatus(String rideId, String studentId, StudentRideStatus status) async {
    await _firestore.collection('rides').doc(rideId).update({'studentStatuses.$studentId': status.value, 'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> updateBusRideLocation(String rideId, String location) async {
    await _firestore.collection('rides').doc(rideId).update({'currentLocation': location, 'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> updateBusRideEndTime(String rideId, DateTime endTime) async {
    await _firestore.collection('rides').doc(rideId).update({'endTime': endTime, 'updatedAt': FieldValue.serverTimestamp()});
  }

  // Add a student to a bus ride
  Future<void> addStudentToRide(String rideId, String studentId) async {
    await _firestore.collection('rides').doc(rideId).update({
      'studentIds': FieldValue.arrayUnion([studentId]),
      'studentStatuses.$studentId': StudentRideStatus.pending.value,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Remove a student from a bus ride
  Future<void> removeStudentFromRide(String rideId, String studentId) async {
    await _firestore.collection('rides').doc(rideId).update({
      'studentIds': FieldValue.arrayRemove([studentId]),
      'studentStatuses.$studentId': FieldValue.delete(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Stream<BusRideModel> getBusRideStream(String rideId) {
    return _firestore.collection('rides').doc(rideId).snapshots().map((doc) => BusRideModel.fromFirestore(doc));
  }
}
