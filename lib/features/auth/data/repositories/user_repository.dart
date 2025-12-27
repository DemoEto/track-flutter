// User repository interface
import 'package:track_app/features/auth/data/models/user_model.dart';

abstract class UserRepository {
  Future<void> createUser(UserModel user);
  Future<UserModel?> getUser(String userId);
  Future<void> updateUser(UserModel user);
  Future<void> deleteUser(String userId);
  Stream<UserModel?> userChanges(String userId);
  Stream<List<UserModel>> allUsersStream();
  Stream<List<UserModel>> getStudentsStream();
  Future<List<UserModel>> getAllUsers();
  Future<List<UserModel>> getUsersByRole(String role);

  Future<void> updateFcmToken(String userId, String fcmToken);

  // Parent-child relationship methods
  Future<void> linkParentToChild(String? parentId, String? childId);
  Future<void> unlinkParentFromChild(String? parentId, String? childId);
  Future<List<UserModel>> getChildrenForParent(String parentId);
}
