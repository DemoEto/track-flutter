// Notification repository interface
import 'package:track_app/features/notification/data/models/notification_model.dart';

abstract class NotificationRepository {
  Future<void> createNotification(NotificationModel notification);
  Future<NotificationModel?> getNotification(String notificationId);
  Future<void> updateNotification(NotificationModel notification);
  Future<void> deleteNotification(String notificationId);
  Stream<NotificationModel?> notificationChanges(String notificationId);
  Stream<List<NotificationModel>> getNotificationsByUserStream(String userId);
  Future<List<NotificationModel>> getNotificationsByUser(String userId);
  Future<List<NotificationModel>> getNotificationsByType(String userId, String type);
  Future<List<NotificationModel>> getUnreadNotifications(String userId);
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead(String userId);
  Future<int> getUnreadCount(String userId);
}
