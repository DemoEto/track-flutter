import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/driver/models/bus_ride_model.dart';
import 'package:track_app/core/enums.dart';
import 'driver_bus_ride_detail_screen.dart';
import 'driver_bus_ride_create_screen.dart';

class DriverBusRideScreen extends StatefulWidget {
  const DriverBusRideScreen({super.key});

  @override
  State<DriverBusRideScreen> createState() => _DriverBusRideScreenState();
}

class _DriverBusRideScreenState extends State<DriverBusRideScreen> {
  List<BusRideModel> _busRides = [];
  bool _isLoading = true;
  String? _loadedDriverId;

  @override
  void initState() {
    super.initState();
    _loadBusRides();
  }

  Future<void> _loadBusRides() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final driverId = context.read<AuthProvider>().currentUser?.id;
      if (driverId != null) {
        _busRides = await locator.driverRepository.getBusRidesByDriver(driverId);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading rides: ${e.toString()}'), backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Bus Rides'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadBusRides)],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(onRefresh: _loadBusRides, child: _busRides.isEmpty ? const _EmptyStateWidget() : _buildRideList()),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const DriverBusRideCreateScreen())).then((_) {
            // Refresh the list after returning from create screen
            _loadBusRides();
          });
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRideList() {
    // Sort rides by date (most recent first)
    final sortedRides = [..._busRides];
    sortedRides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: sortedRides.length,
      itemBuilder: (context, index) {
        final ride = sortedRides[index];
        return Card(
          child: ListTile(
            title: Text(ride.routeName),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Status: ${ride.status.value}'),
                Text('Students: ${ride.studentIds.length}'),
                if (ride.createdAt != null)
                  Text('Created: ${_formatDate(ride.createdAt!)}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            trailing: Icon(_getStatusIcon(ride.status), color: _getStatusColor(ride.status)),
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => DriverBusRideDetailScreen(rideId: ride.id)));
            },
          ),
        );
      },
    );
  }

  IconData _getStatusIcon(BusRideStatus status) {
    switch (status) {
      case BusRideStatus.pending:
        return Icons.access_time;
      case BusRideStatus.started:
        return Icons.directions_bus;
      case BusRideStatus.inTransit:
        return Icons.map;
      case BusRideStatus.completed:
        return Icons.check_circle;
    }
  }

  Color _getStatusColor(BusRideStatus status) {
    switch (status) {
      case BusRideStatus.pending:
        return Colors.orange;
      case BusRideStatus.started:
        return Colors.blue;
      case BusRideStatus.inTransit:
        return Colors.blue[800]!;
      case BusRideStatus.completed:
        return Colors.green;
    }
  }

  String _formatDate(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

class _EmptyStateWidget extends StatelessWidget {
  const _EmptyStateWidget();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(Icons.directions_bus, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          const Text('No bus rides yet', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Create your first bus ride to get started', textAlign: TextAlign.center, style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }
}
