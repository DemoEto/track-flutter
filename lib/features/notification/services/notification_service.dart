// Notification service
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'dart:typed_data';
import 'package:track_app/core/services/service_locator.dart';
import 'package:track_app/core/enums.dart';
import 'package:track_app/features/notification/data/models/notification_model.dart';

// Background message handler function (must be top level function)
Future<void> backgroundMessageHandler(RemoteMessage message) async {
  // Handle background messages
  // Log background message handling: ${message.messageId}

  // Show local notification for background messages
  await NotificationService().showLocalNotification(
    title: message.notification?.title ?? 'New Notification',
    body: message.notification?.body ?? 'You have a new notification',
    payload: message.data.toString(),
  );
}

class NotificationService {
  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin = FlutterLocalNotificationsPlugin();

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  // Request permission for notifications
  Future<void> requestNotificationPermission() async {
    await _firebaseMessaging.requestPermission(alert: true, badge: true, sound: true);
  }

  // Get the FCM token
  Future<String?> getFcmToken() async {
    return await _firebaseMessaging.getToken();
  }

  // Update the FCM token in the user's profile
  Future<void> updateFcmTokenInUser(String userId) async {
    final token = await getFcmToken();
    if (token != null) {
      await locator.userRepository.updateFcmToken(userId, token);
    }
  }

  // Subscribe to FCM token refresh
  Stream<String> onTokenRefresh() {
    return _firebaseMessaging.onTokenRefresh;
  }

  // Handle incoming messages when app is in foreground
  static Stream<RemoteMessage> get onMessage => FirebaseMessaging.onMessage;

  // Handle messages when app is opened from terminated state
  Future<RemoteMessage?> getInitialMessage() async {
    return await _firebaseMessaging.getInitialMessage();
  }

  // Send notification to a specific user
  Future<void> sendNotificationToUser({required String userId, required String title, required String body, Map<String, String>? data}) async {
    // In a real implementation, you would call your backend API
    // to send the notification via FCM
    debugPrint('Notification sent to $userId: $title - $body');
  }

  // Create a local notification record
  Future<void> createNotification({required String userId, required NotificationType type, required String message, String? relatedId}) async {
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
  }

  // Mark notification as read
  Future<void> markAsRead(String notificationId) async {
    await locator.notificationRepository.markAsRead(notificationId);
  }

  // Mark all notifications as read for a user
  Future<void> markAllAsRead(String userId) async {
    await locator.notificationRepository.markAllAsRead(userId);
  }

  // Get unread count for a user
  Future<int> getUnreadCount(String userId) async {
    return await locator.notificationRepository.getUnreadCount(userId);
  }

  // Initialize local notifications
  Future<void> initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid = AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Handle when notification is tapped
        debugPrint('Notification tapped: ${details.payload}');
      },
    );
  }

  // Show a local notification
  Future<void> showLocalNotification({required String title, required String body, String? payload}) async {
    AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
      'track_app_channel_id',
      'Track App Notifications',
      channelDescription: 'Notifications for the Track App',
      importance: Importance.high,
      priority: Priority.high,
      ticker: 'ticker',
      playSound: true,
      enableVibration: true,
      vibrationPattern: Int64List.fromList([0, 100, 50, 100]),
    );

    const DarwinNotificationDetails iosNotificationDetails = DarwinNotificationDetails(presentAlert: true, presentBadge: true, presentSound: true);

    NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails, iOS: iosNotificationDetails);

    await _localNotificationsPlugin.show(0, title, body, notificationDetails, payload: payload);
  }

  // Set up background message handling
  Future<void> setupBackgroundMessaging() async {
    // Set the background messaging handler
    FirebaseMessaging.onBackgroundMessage(backgroundMessageHandler);

    // Also handle messages when the app is in the foreground
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Handling a foreground message: ${message.messageId}');

      // Show local notification for foreground messages
      showLocalNotification(
        title: message.notification?.title ?? 'New Notification',
        body: message.notification?.body ?? 'You have a new notification',
        payload: message.data.toString(),
      );
    });
  }
}
