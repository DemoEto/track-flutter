// Driver dashboard screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/driver/models/bus_ride_model.dart';

import 'package:track_app/core/navigation/app_routes.dart';
import 'package:track_app/features/auth/presentation/widgets/dashboard_drawer.dart';

class DriverDashboardScreen extends StatefulWidget {
  const DriverDashboardScreen({super.key});

  @override
  State<DriverDashboardScreen> createState() => _DriverDashboardScreenState();
}

class _DriverDashboardScreenState extends State<DriverDashboardScreen> with RouteAware {
  List<BusRideModel> _busRides = [];
  bool _isLoading = true;
  String? _loadedDriverId;
  RouteObserver<PageRoute>? _routeObserver;
  int _activeRidesCount = 0;
  int _completedRidesCount = 0;

  @override
  void initState() {
    super.initState();
    // Data is now loaded in didChangeDependencies and didPopNext.
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Subscribe to the route observer to detect when we navigate back to this screen.
    // This requires a RouteObserver to be provided in the widget tree (usually in main.dart).
    _routeObserver = Provider.of<RouteObserver<PageRoute>>(context, listen: false);
    _routeObserver?.subscribe(this, ModalRoute.of(context)! as PageRoute);

    final driverId = context.watch<AuthProvider>().currentUser?.id;

    // Initial data load when the widget is first built.
    if (driverId != null && driverId != _loadedDriverId) {
      _loadedDriverId = driverId;
      _loadDashboardData();
    }
  }

  @override
  void dispose() {
    _routeObserver?.unsubscribe(this);
    super.dispose();
  }

  /// Called when the top route has been popped off, and this screen is now visible.
  @override
  void didPopNext() {
    debugPrint('Returning to Driver Dashboard, reloading data...');
    _loadDashboardData();
  }

  /// Called when the current route has been pushed.
  @override
  void didPush() {}

  /// Called when the current route has been popped off.
  @override
  void didPop() {}

  /// Called when a new route has been pushed, and the current route is no longer visible.
  @override
  void didPushNext() {}

  Future<void> _loadDashboardData() async {
    // Set loading state, unless it's the very first load (where isLoading is already true)
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
    }

    try {
      final driverId = context.read<AuthProvider>().currentUser?.id;
      if (driverId != null) {
        debugPrint('Loading dashboard data for driver: $driverId');
        _busRides = await locator.driverRepository.getBusRidesByDriver(driverId);
        debugPrint('Loaded ${_busRides.length} bus rides for driver');
        await _calculateStats();
      }
    } catch (e) {
      debugPrint('Error loading driver dashboard data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _calculateStats() async {
    int activeCount = 0;
    int completedCount = 0;

    for (final ride in _busRides) {
      if (ride.status != BusRideStatus.completed) {
        activeCount++;
      } else {
        completedCount++;
      }
    }

    setState(() {
      _activeRidesCount = activeCount;
      _completedRidesCount = completedCount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final userRole = context.watch<AuthProvider>().userRole;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false,
        leading: Builder(builder: (context) => IconButton(icon: const Icon(Icons.menu), onPressed: () => Scaffold.of(context).openDrawer())),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.notifications);
            },
          ),
        ],
      ),
      drawer: DashboardDrawer(title: 'Driver Dashboard', userRole: userRole),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : RefreshIndicator(
                onRefresh: _loadDashboardData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          return Text(
                            'Welcome back, ${authProvider.currentUser?.name ?? "Driver"}!',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildStatsCard(),
                      const SizedBox(height: 16),
                      _buildRecentRides(),
                    ],
                  ),
                ),
              ),
    );
  }

  Widget _buildStatsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [_buildStatItem(_activeRidesCount, 'Active Rides', Colors.blue), _buildStatItem(_completedRidesCount, 'Completed', Colors.green)],
        ),
      ),
    );
  }

  Widget _buildStatItem(int count, String label, Color color) {
    return Column(
      children: [
        Text(count.toString(), style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
      ],
    );
  }

  Widget _buildRecentRides() {
    if (_busRides.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Recent Rides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: Colors.grey[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('No rides found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'You haven\'t created any bus rides yet.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    // Sort rides by date (most recent first)
    final sortedRides = [..._busRides];
    sortedRides.sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Recent Rides', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ...sortedRides
            .take(5)
            .map(
              (ride) => Card(
                child: ListTile(
                  title: Text(ride.routeName),
                  subtitle: Text('Status: ${ride.status.value} | Students: ${ride.studentIds.length}'),
                  trailing: Icon(
                    ride.status == BusRideStatus.pending
                        ? Icons.access_time
                        : ride.status == BusRideStatus.started
                        ? Icons.directions_bus
                        : ride.status == BusRideStatus.inTransit
                        ? Icons.map
                        : Icons.check_circle,
                    color:
                        ride.status == BusRideStatus.pending
                            ? Colors.orange
                            : ride.status == BusRideStatus.started
                            ? Colors.blue
                            : ride.status == BusRideStatus.inTransit
                            ? Colors.blue[800]
                            : Colors.green,
                  ),
                  // Removed onTap to prevent navigation to detail screen
                ),
              ),
            ),
      ],
    );
  }
}
