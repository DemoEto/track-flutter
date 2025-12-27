// Auth repository interface
import 'package:track_app/features/auth/data/models/user_model.dart';

abstract class AuthRepository {
  Stream<UserModel?> get userChanges;
  Future<void> signInWithEmailAndPassword(String email, String password);
  Future<void> signUpWithEmailAndPassword(String email, String password, String name, String role);
  Future<void> signOut();
  Future<UserModel?> getCurrentUser();
  Future<void> updateUserProfile(UserModel user);
}
