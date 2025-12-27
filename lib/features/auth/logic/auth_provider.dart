// Auth provider for state management
import 'package:flutter/foundation.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  UserModel? _currentUser;

  UserModel? get currentUser => _currentUser;

  bool get isAuthenticated => _currentUser != null;

  String? get userRole => _currentUser?.role.value;

  AuthProvider() {
    // Listen to authentication changes
    locator.authRepository.userChanges
        .listen((user) {
          debugPrint('AuthProvider: user from stream = ${user?.toString() ?? 'null'}');
          _currentUser = user;
          notifyListeners();

          // Set up FCM token refresh listener when user is authenticated
          if (_currentUser != null) {
            _setupFcmTokenRefreshListener();
          }
        })
        .onError((error) {
          // Handle error
          debugPrint('Auth error: $error');
        });
  }

  Future<void> signIn(String email, String password) async {
    try {
      await locator.authRepository.signInWithEmailAndPassword(email, password);
      // Request notification permissions and update FCM token
      await _initializeNotifications();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signUp(String email, String password, String name, String role) async {
    try {
      await locator.authRepository.signUpWithEmailAndPassword(email, password, name, role);
      // Request notification permissions and update FCM token
      await _initializeNotifications();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await locator.authRepository.signOut();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUserProfile(UserModel user) async {
    try {
      await locator.authRepository.updateUserProfile(user);
      await locator.userRepository.updateUser(user);
      _currentUser = user;
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }

  Future<UserModel?> getCurrentUser() async {
    return await locator.authRepository.getCurrentUser();
  }

  bool hasRole(String role) {
    return _currentUser?.role.value == role;
  }

  bool hasAnyRole(List<String> roles) {
    return _currentUser != null && roles.contains(_currentUser!.role.value);
  }

  // Initialize notification permissions and update FCM token
  Future<void> _initializeNotifications() async {
    try {
      // Request notification permissions
      await locator.notificationService.requestNotificationPermission();

      // Get current user to update their FCM token
      final currentUser = await locator.authRepository.getCurrentUser();
      if (currentUser != null) {
        // Update FCM token in user profile
        await locator.notificationService.updateFcmTokenInUser(currentUser.id);
      }
    } catch (e) {
      debugPrint('Error initializing notifications: $e');
    }
  }

  // Set up FCM token refresh listener to update token when it changes
  void _setupFcmTokenRefreshListener() {
    locator.notificationService
        .onTokenRefresh()
        .listen((token) async {
          if (_currentUser != null && token.isNotEmpty) {
            try {
              await locator.notificationService.updateFcmTokenInUser(_currentUser!.id);
              debugPrint('FCM token updated in user profile: $token');
            } catch (e) {
              debugPrint('Error updating FCM token: $e');
            }
          }
        })
        .onError((error) {
          debugPrint('Error listening to FCM token refresh: $error');
        });
  }
}
