// Notification list screen
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/features/auth/logic/auth_provider.dart';
import 'package:track_app/features/notification/data/models/notification_model.dart';
import 'package:track_app/core/enums.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({Key? key}) : super(key: key);

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId == null) return;

    try {
      _notifications = await locator.notificationRepository.getNotificationsByUser(userId);
      _unreadCount = await locator.notificationRepository.getUnreadCount(userId);

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading notifications: $e'), backgroundColor: Colors.red));
      }
    }
  }

  Future<void> _markAsRead(NotificationModel notification) async {
    if (!notification.isRead) {
      await locator.notificationRepository.markAsRead(notification.id);

      // Update the local list
      final index = _notifications.indexWhere((n) => n.id == notification.id);
      if (index != -1) {
        setState(() {
          _notifications[index] = notification.copyWith(isRead: true);
          _unreadCount--;
        });
      }
    }
  }

  Future<void> _markAllAsRead() async {
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.currentUser?.id;

    if (userId != null) {
      try {
        await locator.notificationRepository.markAllAsRead(userId);
        setState(() {
          for (int i = 0; i < _notifications.length; i++) {
            _notifications[i] = _notifications[i].copyWith(isRead: true);
          }
          _unreadCount = 0;
        });

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('All notifications marked as read'), backgroundColor: Colors.green));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error marking notifications as read: $e'), backgroundColor: Colors.red));
        }
      }
    }
  }

  String _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.attendance:
        return '📅';
      case NotificationType.homework:
        return '📝';
      case NotificationType.general:
        return '🔔';
      case NotificationType.bus:
        return '🚌';
    }
  }

  Color _getNotificationColor(NotificationType type, bool isRead) {
    if (isRead) {
      return Colors.grey;
    }

    switch (type) {
      case NotificationType.attendance:
        return Colors.blue;
      case NotificationType.homework:
        return Colors.orange;
      case NotificationType.general:
        return Colors.purple;
      case NotificationType.bus:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          if (_unreadCount > 0) TextButton(onPressed: _markAllAsRead, child: const Text('Mark All Read', style: TextStyle(color: Colors.white))),
        ],
      ),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _notifications.isEmpty
              ? const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.notifications_none, size: 64, color: Colors.grey),
                    SizedBox(height: 16),
                    Text('No notifications', style: TextStyle(fontSize: 16, color: Colors.grey)),
                  ],
                ),
              )
              : RefreshIndicator(
                onRefresh: _loadNotifications,
                child: ListView.builder(
                  padding: const EdgeInsets.all(8.0),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final notification = _notifications[index];
                    final timeAgo = _getTimeAgo(notification.timestamp);

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4.0),
                      color: notification.isRead ? Colors.grey[50] : Colors.white,
                      child: ListTile(
                        leading: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: _getNotificationColor(notification.type, notification.isRead).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Center(
                            child: Text(
                              _getNotificationIcon(notification.type),
                              style: TextStyle(color: _getNotificationColor(notification.type, notification.isRead)),
                            ),
                          ),
                        ),
                        title: Text(
                          notification.message,
                          style: TextStyle(
                            fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                            color: _getNotificationColor(notification.type, notification.isRead),
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [const SizedBox(height: 4), Text(timeAgo, style: const TextStyle(fontSize: 12, color: Colors.grey))],
                        ),
                        trailing:
                            !notification.isRead
                                ? Container(width: 10, height: 10, decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle))
                                : null,
                        onTap: () async {
                          await _markAsRead(notification);
                          // Handle notification action based on type and relatedId
                          _handleNotificationTap(notification);
                        },
                      ),
                    );
                  },
                ),
              ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  void _handleNotificationTap(NotificationModel notification) {
    // Handle different notification types
    switch (notification.type) {
      case NotificationType.attendance:
        // Navigate to attendance screen
        break;
      case NotificationType.homework:
        // Navigate to homework screen
        break;
      case NotificationType.general:
        // Handle general notification
        break;
      case NotificationType.bus:
        // Handle bus notification (could navigate to bus tracking screen)
        break;
    }
  }
}
