import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/core/enums.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/driver/logic/driver_provider.dart';
import 'package:track_app/features/driver/models/bus_ride_model.dart';

class DriverBusRideDetailScreen extends StatefulWidget {
  final String rideId;

  const DriverBusRideDetailScreen({super.key, required this.rideId});

  @override
  State<DriverBusRideDetailScreen> createState() => _DriverBusRideDetailScreenState();
}

class _DriverBusRideDetailScreenState extends State<DriverBusRideDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DriverProvider>().loadBusRide(widget.rideId);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ride Details'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          Builder(
            builder: (context) {
              final provider = Provider.of<DriverProvider>(context);
              final ride = provider.currentRide;
              final authProvider = Provider.of<AuthProvider>(context, listen: false);
              final currentUserId = authProvider.currentUser?.id;

              // Only show manage students button if the current user is the driver of this ride
              if (ride?.driverId != currentUserId) {
                return Container();
              }

              return IconButton(
                icon: const Icon(Icons.people_alt),
                tooltip: 'Add/Remove Students',
                onPressed: () => _showAddStudentDialog(ride!, provider),
              );
            },
          ),
        ],
      ),
      body: Consumer<DriverProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.error.isNotEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${provider.error}'),
                  ElevatedButton(
                    onPressed: () {
                      provider.loadBusRide(widget.rideId);
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          final ride = provider.currentRide;
          if (ride == null) {
            return const Center(child: Text('Ride not found'));
          }

          return Column(
            children: [
              // Student list with tabs (reduced spacing)
              Expanded(
                flex: 2,
                child: DefaultTabController(
                  length: 2,
                  child: Column(
                    children: [
                      Material(
                        // ใส่ Material เพื่อกำจัด background ส่วนเกิน
                        color: Colors.transparent,
                        child: TabBar(
                          tabs: [
                            Tab(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.access_time, size: 20, color: Theme.of(context).colorScheme.secondary), // กำหนดขนาด icon
                                  const SizedBox(height: 2),
                                  const Text('Pending', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                            Tab(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.check_circle, size: 20, color: Theme.of(context).colorScheme.primary),
                                  const SizedBox(height: 2),
                                  const Text('Picked Up', style: TextStyle(fontSize: 10)),
                                ],
                              ),
                            ),
                          ],
                          indicatorColor: Colors.green,
                          labelColor: Colors.green,
                          unselectedLabelColor: Colors.grey,
                          labelPadding: EdgeInsets.symmetric(vertical: 4), // ลด padding ของ tab
                        ),
                      ),
                      // เอา SizedBox ออก หรือเหลือน้อยมาก
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildStudentListByStatus(ride, StudentRideStatus.pending, provider),
                            _buildStudentListByStatus(ride, StudentRideStatus.pickedUp, provider),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
      bottomNavigationBar: Consumer<DriverProvider>(
        builder: (context, provider, child) {
          final ride = provider.currentRide;
          if (ride == null) return Container();

          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          final currentUserId = authProvider.currentUser?.id;

          // Only show action buttons if the current user is the driver of this ride
          if (ride.driverId != currentUserId) {
            return Container();
          }

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (ride.status == BusRideStatus.pending)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () async {
                          final success = await provider.startJourney(ride.id);
                          if (success) {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(const SnackBar(content: Text('Notification sent to parents successfully'), backgroundColor: Colors.green));
                          } else {
                            ScaffoldMessenger.of(
                              context,
                            ).showSnackBar(SnackBar(content: Text('Error: ${provider.error}'), backgroundColor: Colors.red));
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(vertical: 16.0),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                        ),
                        child: const Text('Start Journey', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      ),
                    ),
                  ),
                if (ride.status == BusRideStatus.started || ride.status == BusRideStatus.inTransit)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () async {
                        final success = await provider.completeJourney(ride.id);
                        if (success) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(const SnackBar(content: Text('Notification sent to parents that arrived'), backgroundColor: Colors.green));
                        } else {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text('Error: ${provider.error}'), backgroundColor: Colors.red));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        foregroundColor: Theme.of(context).colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
                      ),
                      child: const Text('Complete Journey', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _getStatusIcon(StudentRideStatus status) {
    switch (status) {
      case StudentRideStatus.pending:
        return Icon(Icons.access_time, color: Theme.of(context).colorScheme.secondary);
      case StudentRideStatus.pickedUp:
        return Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary);
      case StudentRideStatus.droppedOff:
        return Icon(Icons.check_circle, color: Theme.of(context).colorScheme.tertiary);
    }
  }

  void _confirmPickUp(String studentId, DriverProvider provider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Pickup'),
            content: const Text('Are you sure this student has been picked up?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await provider.pickUpStudent(widget.rideId, studentId);
                  if (success) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Student status updated successfully'), backgroundColor: Colors.green));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${provider.error}'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
    );
  }

  void _showAddStudentDialog(BusRideModel ride, DriverProvider provider) async {
    // Get all students
    List<UserModel> allStudents = [];

    try {
      final allUsers = await locator.userRepository.getAllUsers();
      allStudents = allUsers.where((user) => user.role == UserRole.student).toList();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading students: ${e.toString()}'), backgroundColor: Colors.red));
      return;
    }

    // Create a Set to track selected student IDs (initially contains all current ride students)
    Set<String> selectedStudentIds = ride.studentIds.toSet();

    await showDialog(
      context: context,
      builder: (context) {
        // Create a local copy to track changes in the dialog
        Set<String> localSelectedIds = Set.from(selectedStudentIds);

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Manage Students'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  children: [
                    Text('Select students to add or remove from this ride', style: TextStyle(color: Colors.grey[600])),
                    const SizedBox(height: 16),
                    Expanded(
                      child: ListView.builder(
                        itemCount: allStudents.length,
                        itemBuilder: (context, index) {
                          UserModel student = allStudents[index];
                          bool isSelected = localSelectedIds.contains(student.id);

                          return CheckboxListTile(
                            title: Text(student.name),
                            subtitle: Text(student.email),
                            value: isSelected,
                            onChanged: (bool? value) {
                              setDialogState(() {
                                if (value == true) {
                                  localSelectedIds.add(student.id);
                                } else {
                                  localSelectedIds.remove(student.id);
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                TextButton(
                  onPressed: () async {
                    // Determine which students to add and which to remove
                    List<String> studentsToAdd = [];
                    List<String> studentsToRemove = [];

                    // Find students to add (selected but not in original ride)
                    for (String studentId in localSelectedIds) {
                      if (!selectedStudentIds.contains(studentId)) {
                        studentsToAdd.add(studentId);
                      }
                    }

                    // Find students to remove (in original ride but not selected)
                    for (String studentId in selectedStudentIds) {
                      if (!localSelectedIds.contains(studentId)) {
                        studentsToRemove.add(studentId);
                      }
                    }

                    // Process additions
                    bool success = true;
                    for (String studentId in studentsToAdd) {
                      final addSuccess = await provider.addStudentToRide(widget.rideId, studentId);
                      if (!addSuccess) {
                        success = false;
                        break;
                      }
                    }

                    // Process removals
                    if (success) {
                      for (String studentId in studentsToRemove) {
                        final removeSuccess = await provider.removeStudentFromRide(widget.rideId, studentId);
                        if (!removeSuccess) {
                          success = false;
                          break;
                        }
                      }
                    }

                    Navigator.pop(context); // Close dialog

                    if (success) {
                      if (studentsToAdd.isNotEmpty && studentsToRemove.isNotEmpty) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Students added and removed successfully'), backgroundColor: Colors.green));
                      } else if (studentsToAdd.isNotEmpty) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Students added successfully'), backgroundColor: Colors.green));
                      } else if (studentsToRemove.isNotEmpty) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(const SnackBar(content: Text('Students removed successfully'), backgroundColor: Colors.green));
                      }
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${provider.error}'), backgroundColor: Colors.red));
                    }
                  },
                  child: const Text('Save Changes'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildStudentListByStatus(BusRideModel ride, StudentRideStatus status, DriverProvider provider) {
    // Filter students by the selected status
    List<String> studentsWithStatus =
        ride.studentIds.where((studentId) {
          final studentStatus = ride.studentStatuses[studentId] ?? StudentRideStatus.pending;
          return studentStatus == status;
        }).toList();

    if (studentsWithStatus.isEmpty) {
      return Center(child: Text('No students with ${status.value} status', style: TextStyle(color: Colors.grey[600], fontSize: 16)));
    }

    return FutureBuilder<List<UserModel>>(
      future: locator.userRepository.getAllUsers().then((users) => users.where((user) => user.role == UserRole.student).toList()),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          List<UserModel> allStudents = snapshot.data!;
          Map<String, UserModel> studentMap = {};
          for (UserModel student in allStudents) {
            studentMap[student.id] = student;
          }

          List<UserModel> studentsToShow = [];
          for (String studentId in studentsWithStatus) {
            if (studentMap.containsKey(studentId)) {
              studentsToShow.add(studentMap[studentId]!);
            }
          }

          if (studentsToShow.isEmpty) {
            return Center(child: Text('No students with ${status.value} status', style: TextStyle(color: Colors.grey[600], fontSize: 16)));
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const AlwaysScrollableScrollPhysics(),
            itemCount: studentsToShow.length,
            itemBuilder: (context, index) {
              final student = studentsToShow[index];
              final studentStatus = ride.studentStatuses[student.id] ?? StudentRideStatus.pending;

              return Card(
                child: Dismissible(
                  key: Key(student.id),
                  direction: DismissDirection.endToStart,
                  onDismissed: (direction) {
                    // Remove student from ride
                    _confirmRemoveStudent(student.id, provider);
                  },
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16.0),
                    child: const Icon(Icons.delete, color: Colors.white),
                  ),
                  child: ListTile(
                    title: Text(student.name),
                    subtitle: Text(student.email),
                    trailing: _getStatusIcon(studentStatus),
                    // Only show pickup button if ride has started and student hasn't been picked up yet
                    onTap:
                        ride.status != BusRideStatus.pending && studentStatus == StudentRideStatus.pending
                            ? () => _confirmPickUp(student.id, provider)
                            : null,
                  ),
                ),
              );
            },
          );
        } else {
          return const Center(child: CircularProgressIndicator());
        }
      },
    );
  }

  void _confirmRemoveStudent(String studentId, DriverProvider provider) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Confirm Remove Student'),
            content: const Text('Are you sure you want to remove this student from the ride?'),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);
                  final success = await provider.removeStudentFromRide(widget.rideId, studentId);
                  if (success) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Student removed successfully'), backgroundColor: Colors.green));
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${provider.error}'), backgroundColor: Colors.red));
                  }
                },
                child: const Text('Remove'),
              ),
            ],
          ),
    );
  }
}
