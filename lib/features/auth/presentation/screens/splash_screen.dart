import 'package:flutter/material.dart';
import 'package:track_app/core/constants.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/core/navigation/app_routes.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Initialize animation controller
    _animationController = AnimationController(duration: const Duration(milliseconds: 1500), vsync: this);

    // Create animations
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeIn));

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(CurvedAnimation(parent: _animationController, curve: Curves.elasticOut));

    // Start the animation
    _animationController.forward();

    _navigateToNextScreen();
  }

  Future<void> _navigateToNextScreen() async {
    // Add a small delay to show the splash screen
    await Future.delayed(const Duration(seconds: 3));

    // Request notification permissions early in the app lifecycle
    try {
      await locator.notificationService.requestNotificationPermission();
    } catch (e) {
      debugPrint('Error requesting notification permission: $e');
    }

    // Check if user is authenticated
    final authRepository = locator.authRepository;
    final currentUser = await authRepository.getCurrentUser();

    String nextLocation = AppRoutes.login; // Default to login

    if (currentUser != null) {
      // User is authenticated, redirect to appropriate dashboard
      // Also update FCM token for existing user
      try {
        await locator.notificationService.updateFcmTokenInUser(currentUser.id);
      } catch (e) {
        debugPrint('Error updating FCM token: $e');
      }

      switch (currentUser.role.value) {
        case 'teacher':
          nextLocation = AppRoutes.teacherDashboard;
          break;
        case 'student':
          nextLocation = AppRoutes.studentDashboard;
          break;
        case 'parent':
          nextLocation = AppRoutes.parentDashboard;
          break;

        default:
          nextLocation = AppRoutes.home;
      }
    }

    if (mounted) {
      Navigator.of(context).pushReplacementNamed(nextLocation);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).primaryColor,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Icon(Icons.school, size: 80, color: Theme.of(context).primaryColor),
                ),
                const SizedBox(height: 30),
                Text(AppConstants.appName, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 20),
                AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return Opacity(
                      opacity: _animationController.value > 0.7 ? 1.0 : 0.0,
                      child: Container(
                        width: 30,
                        height: 30,
                        padding: const EdgeInsets.all(2),
                        child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Colors.white), strokeWidth: 3),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
