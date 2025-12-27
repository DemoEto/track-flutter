// Notification provider for state management
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';
import 'package:track_app/features/notification/data/models/notification_model.dart';
import 'package:track_app/core/enums.dart';

class NotificationProvider extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  List<UserModel> _users = [];

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  List<UserModel> get users => _users;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  Future<void> loadNotifications(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _notifications = await locator.notificationRepository.getNotificationsByUser(userId);
      _unreadCount = await locator.notificationRepository.getUnreadCount(userId);
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAsRead(String notificationId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await locator.notificationRepository.markAsRead(notificationId);

      // Update local list
      final index = _notifications.indexWhere((n) => n.id == notificationId);
      if (index != -1) {
        _notifications[index] = _notifications[index].copyWith(isRead: true);
        _unreadCount = await locator.notificationRepository.getUnreadCount(_notifications[index].userId);
      }

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> markAllAsRead(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      await locator.notificationRepository.markAllAsRead(userId);

      // Update local list
      for (int i = 0; i < _notifications.length; i++) {
        if (!_notifications[i].isRead) {
          _notifications[i] = _notifications[i].copyWith(isRead: true);
        }
      }
      _unreadCount = 0;

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> createNotification({required String userId, required NotificationType type, required String message, String? relatedId}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final notification = NotificationModel(
        id: const Uuid().v4(),
        userId: userId,
        type: type,
        message: message,
        relatedId: relatedId,
        isRead: false,
        timestamp: DateTime.now(),
      );

      await locator.notificationRepository.createNotification(notification);
      _notifications.insert(0, notification); // Add to the beginning
      _unreadCount++;

      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }

  // Listen to notification changes for a specific user
  void listenToNotifications(String userId) {
    locator.notificationRepository.getNotificationsByUserStream(userId).listen((newNotifications) {
      _notifications = newNotifications;
      _unreadCount = newNotifications.where((notification) => !notification.isRead).length;
      notifyListeners();
    });
  }

  // Load all users for notification purposes
  Future<void> loadUsers() async {
    _isLoading = true;
    notifyListeners();

    try {
      _users = await locator.userRepository.getAllUsers();
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }

    _isLoading = false;
    notifyListeners();
  }
}
