import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:track_app/firebase_options.dart';
import 'app.dart';
import 'core/services/service_locator.dart';
import 'features/notification/services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  ServiceLocator().init(); // Initialize the service locator

  // Initialize and setup notification services
  final notificationService = NotificationService();
  await notificationService.initializeLocalNotifications();
  await notificationService.setupBackgroundMessaging();

  runApp(const TrackApp());
}
