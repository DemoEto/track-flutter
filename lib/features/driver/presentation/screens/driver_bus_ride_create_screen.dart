import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/core/enums.dart';
import 'package:track_app/features/driver/logic/driver_provider.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';

class DriverBusRideCreateScreen extends StatefulWidget {
  const DriverBusRideCreateScreen({super.key});

  @override
  State<DriverBusRideCreateScreen> createState() => _DriverBusRideCreateScreenState();
}

class _DriverBusRideCreateScreenState extends State<DriverBusRideCreateScreen> {
  List<UserModel> _allUsers = []; // This stores the original User objects
  Set<String> _selectedStudentIds = {}; // This stores only the IDs of selected students
  bool _isLoading = true; // Loading state

  @override
  void initState() {
    super.initState();
    _loadStudents();
  }

  Future<void> _loadStudents() async {
    setState(() {
      _isLoading = true; // Set loading to true when starting to load
    });

    try {
      final allUsers = await locator.userRepository.getAllUsers();
      _allUsers = allUsers.where((user) => user.role == UserRole.student).toList();

      if (mounted) {
        setState(() {
          _isLoading = false; // Set loading to false after loading
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false; // Ensure loading is false even if there's an error
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading students: ${e.toString()}'), backgroundColor: Colors.red));
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Students for Ride'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _loadStudents)],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (_allUsers.isNotEmpty)
                    Expanded(
                      child: ListView.builder(
                        itemCount: _allUsers.length,
                        itemBuilder: (context, index) {
                          var user = _allUsers[index];
                          String studentId = user.id;
                          bool isSelected = _selectedStudentIds.contains(studentId);

                          return CheckboxListTile(
                            title: Text('${user.name}'),
                            subtitle: Text(user.email),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setState(() {
                                if (value == true) {
                                  _selectedStudentIds.add(studentId);
                                } else {
                                  _selectedStudentIds.remove(studentId);
                                }
                              });
                            },
                          );
                        },
                      ),
                    )
                  else
                    const Padding(padding: EdgeInsets.only(top: 8.0), child: Text('No students available. Please refresh or create students first.')),
                ],
              ),
      bottomNavigationBar:
          _isLoading
              ? null
              : Container(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _startRide,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Theme.of(context).colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                  ),
                  child: const Text('Start Ride', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
    );
  }

  void _startRide() async {
    if (_selectedStudentIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please add at least one student'), backgroundColor: Colors.red));
      return;
    }

    // Get current driver info
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Error: User not authenticated'), backgroundColor: Colors.red));
      return;
    }

    // Show loading indicator
    final provider = context.read<DriverProvider>();
    provider.clearError();

    // Create the bus ride
    List<String> studentIds = _selectedStudentIds.toList();
    final success = await provider.startBusRide(
      driverId: currentUser.id,
      driverName: currentUser.name,
      routeName: 'New Route', // Default route name since we removed the input field
      studentIds: studentIds,
      startLocation: null, // Removed input field
      endLocation: null, // Removed input field
    );

    if (success) {
      Navigator.pop(context); // Close the form
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bus ride started successfully!'), backgroundColor: Colors.green));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${provider.error}'), backgroundColor: Colors.red));
    }
  }
}
