import 'package:flutter/foundation.dart';
import 'package:track_app/core/services/service_locator.dart';
import '../models/bus_ride_model.dart';
import '../services/driver_service.dart';

class DriverProvider with ChangeNotifier {
  final DriverService _driverService = DriverService();
  final _driverRepository = locator.driverRepository;

  List<BusRideModel> _busRides = [];
  List<BusRideModel> get busRides => _busRides;

  BusRideModel? _currentRide;
  BusRideModel? get currentRide => _currentRide;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String _error = '';
  String get error => _error;

  // Load all bus rides for the current driver
  Future<void> loadBusRides(String driverId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _busRides = await _driverRepository.getBusRidesByDriver(driverId);
      _error = '';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load active bus rides
  Future<void> loadActiveBusRides() async {
    _isLoading = true;
    notifyListeners();

    try {
      _busRides = await _driverRepository.getActiveBusRides();
      _error = '';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load a specific bus ride
  Future<void> loadBusRide(String rideId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _currentRide = await _driverRepository.getBusRide(rideId);
      _error = '';
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start a new bus ride
  Future<bool> startBusRide({
    required String driverId,
    required String driverName,
    required String routeName,
    required List<String> studentIds,
    String? startLocation,
    String? endLocation,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final ride = await _driverService.createBusRide(
        driverId: driverId,
        driverName: driverName,
        routeName: routeName,
        studentIds: studentIds,
        startLocation: startLocation,
        endLocation: endLocation,
      );

      // Add to local list
      _busRides.insert(0, ride);
      _currentRide = ride;

      _error = '';
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Start journey (update status to started and notify)
  Future<bool> startJourney(String rideId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _driverService.startJourney(rideId);

      // Update local ride status
      final rideIndex = _busRides.indexWhere((ride) => ride.id == rideId);
      if (rideIndex != -1) {
        _busRides[rideIndex] = _busRides[rideIndex].copyWith(status: BusRideStatus.started);
      }

      if (_currentRide?.id == rideId) {
        _currentRide = _currentRide!.copyWith(status: BusRideStatus.started);
      }

      _error = '';
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Mark student as picked up
  Future<bool> pickUpStudent(String rideId, String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _driverService.pickUpStudent(rideId, studentId);

      // Update local ride status
      final rideIndex = _busRides.indexWhere((ride) => ride.id == rideId);
      if (rideIndex != -1) {
        final ride = _busRides[rideIndex];
        final updatedStatuses = Map<String, StudentRideStatus>.from(ride.studentStatuses);
        updatedStatuses[studentId] = StudentRideStatus.pickedUp;

        _busRides[rideIndex] = ride.copyWith(studentStatuses: updatedStatuses);
      }

      if (_currentRide?.id == rideId) {
        final updatedStatuses = Map<String, StudentRideStatus>.from(_currentRide!.studentStatuses);
        updatedStatuses[studentId] = StudentRideStatus.pickedUp;
        _currentRide = _currentRide!.copyWith(studentStatuses: updatedStatuses);
      }

      _error = '';
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Complete the journey
  Future<bool> completeJourney(String rideId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _driverService.completeJourney(rideId);

      // Update local ride status and end time
      final rideIndex = _busRides.indexWhere((ride) => ride.id == rideId);
      if (rideIndex != -1) {
        _busRides[rideIndex] = _busRides[rideIndex].copyWith(status: BusRideStatus.completed, endTime: DateTime.now());
      }

      if (_currentRide?.id == rideId) {
        _currentRide = _currentRide!.copyWith(status: BusRideStatus.completed, endTime: DateTime.now());
      }

      _error = '';
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update selected ride
  void setSelectedRide(BusRideModel? ride) {
    _currentRide = ride;
    notifyListeners();
  }

  // Clear error
  void clearError() {
    _error = '';
    notifyListeners();
  }

  // Add student to current ride
  Future<bool> addStudentToRide(String rideId, String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _driverService.addStudentToRide(rideId, studentId);

      // Update local ride data
      final rideIndex = _busRides.indexWhere((ride) => ride.id == rideId);
      if (rideIndex != -1) {
        final ride = _busRides[rideIndex];
        final updatedStudentIds = List<String>.from(ride.studentIds)..add(studentId);
        final updatedStatuses = Map<String, StudentRideStatus>.from(ride.studentStatuses)..[studentId] = StudentRideStatus.pending;

        _busRides[rideIndex] = ride.copyWith(studentIds: updatedStudentIds, studentStatuses: updatedStatuses);
      }

      if (_currentRide?.id == rideId) {
        final updatedStudentIds = List<String>.from(_currentRide!.studentIds)..add(studentId);
        final updatedStatuses = Map<String, StudentRideStatus>.from(_currentRide!.studentStatuses)..[studentId] = StudentRideStatus.pending;

        _currentRide = _currentRide!.copyWith(studentIds: updatedStudentIds, studentStatuses: updatedStatuses);
      }

      _error = '';
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Remove student from current ride
  Future<bool> removeStudentFromRide(String rideId, String studentId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _driverService.removeStudentFromRide(rideId, studentId);

      // Update local ride data
      final rideIndex = _busRides.indexWhere((ride) => ride.id == rideId);
      if (rideIndex != -1) {
        final ride = _busRides[rideIndex];
        final updatedStudentIds = List<String>.from(ride.studentIds)..remove(studentId);
        final updatedStatuses = Map<String, StudentRideStatus>.from(ride.studentStatuses)..remove(studentId);

        _busRides[rideIndex] = ride.copyWith(studentIds: updatedStudentIds, studentStatuses: updatedStatuses);
      }

      if (_currentRide?.id == rideId) {
        final updatedStudentIds = List<String>.from(_currentRide!.studentIds)..remove(studentId);
        final updatedStatuses = Map<String, StudentRideStatus>.from(_currentRide!.studentStatuses)..remove(studentId);

        _currentRide = _currentRide!.copyWith(studentIds: updatedStudentIds, studentStatuses: updatedStatuses);
      }

      _error = '';
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
