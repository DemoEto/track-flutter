// Firebase implementation of UserRepository
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';
import 'package:track_app/features/auth/data/repositories/user_repository.dart';
import 'package:track_app/core/constants.dart';

class FirebaseUserRepository implements UserRepository {
  final FirebaseFirestore _firestore;

  FirebaseUserRepository({FirebaseFirestore? firestore}) : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<void> createUser(UserModel user) async {
    await _firestore.collection(AppConstants.usersCollection).doc(user.id).set(user.toFirestore());
  }

  @override
  Future<UserModel?> getUser(String userId) async {
    final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(userId).get();
    if (userDoc.exists) {
      return UserModel.fromFirestore(userDoc);
    }
    return null;
  }

  @override
  Future<void> updateUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .update(
          user.toFirestore()
            ..remove('id')
            ..remove('createdAt'),
        );
  }

  @override
  Future<void> deleteUser(String userId) async {
    await _firestore.collection(AppConstants.usersCollection).doc(userId).delete();
  }

  @override
  Stream<UserModel?> userChanges(String userId) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(userId)
        .snapshots()
        .map((snapshot) => snapshot.exists ? UserModel.fromFirestore(snapshot) : null);
  }

  @override
  Stream<List<UserModel>> allUsersStream() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .orderBy('createdAt', descending: true) // Most recent first
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  @override
  Stream<List<UserModel>> getStudentsStream() {
    return _firestore
        .collection(AppConstants.usersCollection)
        .where('role', isEqualTo: 'student')
        .orderBy('name')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList());
  }

  @override
  Future<List<UserModel>> getUsersByRole(String role) async {
    final querySnapshot = await _firestore.collection(AppConstants.usersCollection).where('role', isEqualTo: role).get();

    return querySnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  @override
  Future<List<UserModel>> getAllUsers() async {
    final querySnapshot = await _firestore.collection(AppConstants.usersCollection).get();
    return querySnapshot.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }

  @override
  Future<void> updateFcmToken(String userId, String fcmToken) async {
    await _firestore.collection(AppConstants.usersCollection).doc(userId).update({'fcmToken': fcmToken, 'updatedAt': FieldValue.serverTimestamp()});
  }

  @override
  Future<void> linkParentToChild(String? parentId, String? childId) async {
    if (parentId == null || childId == null) {
      throw ArgumentError('Parent ID and Child ID cannot be null');
    }

    // Add child ID to parent's childUserIds array
    await _firestore.collection(AppConstants.usersCollection).doc(parentId).update({
      'childUserIds': FieldValue.arrayUnion([childId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<void> unlinkParentFromChild(String? parentId, String? childId) async {
    if (parentId == null || childId == null) {
      throw ArgumentError('Parent ID and Child ID cannot be null');
    }

    // Remove child ID from parent's childUserIds array
    await _firestore.collection(AppConstants.usersCollection).doc(parentId).update({
      'childUserIds': FieldValue.arrayRemove([childId]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Future<List<UserModel>> getChildrenForParent(String parentId) async {
    final parentDoc = await _firestore.collection(AppConstants.usersCollection).doc(parentId).get();
    if (!parentDoc.exists) {
      return [];
    }

    final parentData = parentDoc.data();
    final childUserIds = (parentData?['childUserIds'] as List<dynamic>?)?.map((e) => e.toString()).toList();

    if (childUserIds == null || childUserIds.isEmpty) {
      return [];
    }

    // Get all child users
    final childDocs = await _firestore.collection(AppConstants.usersCollection).where(FieldPath.documentId, whereIn: childUserIds).get();

    return childDocs.docs.map((doc) => UserModel.fromFirestore(doc)).toList();
  }
}
