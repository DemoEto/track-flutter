// Firebase implementation of NotificationRepository
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_app/features/notification/data/models/notification_model.dart';
import 'package:track_app/features/notification/data/repositories/notification_repository.dart';
import 'package:track_app/core/constants.dart';

class FirebaseNotificationRepository implements NotificationRepository {
  final FirebaseFirestore _firestore;

  FirebaseNotificationRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createNotification(NotificationModel notification) async {
    await _firestore.collection(AppConstants.notificationsCollection).doc(notification.id).set(notification.toFirestore());
  }

  @override
  Future<NotificationModel?> getNotification(String notificationId) async {
    final notificationDoc = await _firestore.collection(AppConstants.notificationsCollection).doc(notificationId).get();
    if (notificationDoc.exists) {
      return NotificationModel.fromFirestore(notificationDoc);
    }
    return null;
  }

  @override
  Future<void> updateNotification(NotificationModel notification) async {
    await _firestore.collection(AppConstants.notificationsCollection).doc(notification.id).update(notification.toFirestore()..remove('id'));
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _firestore.collection(AppConstants.notificationsCollection).doc(notificationId).delete();
  }

  @override
  Stream<NotificationModel?> notificationChanges(String notificationId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .doc(notificationId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? NotificationModel.fromFirestore(snapshot) : null);
  }

  @override
  Stream<List<NotificationModel>> getNotificationsByUserStream(String userId) {
    return _firestore
        .collection(AppConstants.notificationsCollection)
        .where('userId', isEqualTo: userId)
        .orderBy('timestamp', descending: true) // Most recent first
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList());
  }

  @override
  Future<List<NotificationModel>> getNotificationsByUser(String userId) async {
    final querySnapshot =
        await _firestore
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: userId)
            .orderBy('timestamp', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<NotificationModel>> getNotificationsByType(String userId, String type) async {
    final querySnapshot =
        await _firestore
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: userId)
            .where('type', isEqualTo: type)
            .orderBy('timestamp', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<NotificationModel>> getUnreadNotifications(String userId) async {
    final querySnapshot =
        await _firestore
            .collection(AppConstants.notificationsCollection)
            .where('userId', isEqualTo: userId)
            .where('isRead', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .get();

    return querySnapshot.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _firestore.collection(AppConstants.notificationsCollection).doc(notificationId).update({'isRead': true});
  }

  @override
  Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();

    final querySnapshot =
        await _firestore.collection(AppConstants.notificationsCollection).where('userId', isEqualTo: userId).where('isRead', isEqualTo: false).get();

    for (final doc in querySnapshot.docs) {
      batch.update(doc.reference, {'isRead': true});
    }

    await batch.commit();
  }

  @override
  Future<int> getUnreadCount(String userId) async {
    final querySnapshot =
        await _firestore.collection(AppConstants.notificationsCollection).where('userId', isEqualTo: userId).where('isRead', isEqualTo: false).get();

    return querySnapshot.size;
  }
}
