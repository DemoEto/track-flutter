// Firebase implementation of AuthRepository
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';
import 'package:track_app/features/auth/data/repositories/auth_repository.dart';
import 'package:track_app/core/constants.dart';
import 'package:track_app/core/enums.dart';

class FirebaseAuthService implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;

  FirebaseAuthService({firebase_auth.FirebaseAuth? firebaseAuth, FirebaseFirestore? firestore})
    : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Stream<UserModel?> get userChanges => _firebaseAuth.authStateChanges().asyncMap((firebaseUser) async {
    if (firebaseUser != null) {
      final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }
    }
    return null;
  });

  @override
  Future<UserModel?> getCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser != null) {
      final userDoc = await _firestore.collection(AppConstants.usersCollection).doc(firebaseUser.uid).get();
      if (userDoc.exists) {
        return UserModel.fromFirestore(userDoc);
      }
    }
    return null;
  }

  @override
  Future<void> signInWithEmailAndPassword(String email, String password) async {
    try {
      await _firebaseAuth.signInWithEmailAndPassword(email: email.trim(), password: password.trim());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signUpWithEmailAndPassword(String email, String password, String name, String role) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);

      // Create user document in Firestore
      final user = UserModel(
        id: credential.user!.uid,
        email: email,
        name: name,
        role: UserRole.fromString(role),
        fcmToken: null,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await _firestore.collection(AppConstants.usersCollection).doc(credential.user!.uid).set(user.toFirestore());
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> updateUserProfile(UserModel user) async {
    await _firestore.collection(AppConstants.usersCollection).doc(user.id).update(user.toFirestore()..remove('id'));
  }
}
