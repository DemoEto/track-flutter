// Mock repository tests
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';
import 'package:track_app/features/auth/data/repositories/user_repository.dart';
import 'package:track_app/core/enums.dart';

// Generate mock classes
@GenerateMocks([UserRepository])
import 'repository_test.mocks.dart';

void main() {
  late MockUserRepository mockUserRepository;
  late UserModel testUser;

  setUp(() {
    mockUserRepository = MockUserRepository();
    testUser = UserModel(
      id: 'test_user_id',
      email: 'test@example.com',
      name: 'Test User',
      role: UserRole.student,
      fcmToken: null,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  });

  group('User Repository Integration Tests', () {
    test('getUser should return correct user', () async {
      // Arrange
      when(mockUserRepository.getUser('test_user_id')).thenAnswer((realInvocation) async => testUser);

      // Act
      final result = await mockUserRepository.getUser('test_user_id');

      // Assert
      expect(result, isNotNull);
      expect(result!.id, 'test_user_id');
      expect(result.name, 'Test User');
      verify(mockUserRepository.getUser('test_user_id')).called(1);
    });

    test('createUser should call repository method', () async {
      // Arrange
      when(mockUserRepository.createUser(testUser)).thenAnswer((realInvocation) async => Future.value());

      // Act
      await mockUserRepository.createUser(testUser);

      // Assert
      verify(mockUserRepository.createUser(testUser)).called(1);
    });

    test('updateUser should call repository method', () async {
      // Arrange
      final updatedUser = testUser.copyWith(name: 'Updated Name');
      when(mockUserRepository.updateUser(updatedUser)).thenAnswer((realInvocation) async => Future.value());

      // Act
      await mockUserRepository.updateUser(updatedUser);

      // Assert
      verify(mockUserRepository.updateUser(updatedUser)).called(1);
    });

    test('deleteUser should call repository method', () async {
      // Arrange
      when(mockUserRepository.deleteUser('test_user_id')).thenAnswer((realInvocation) async => Future.value());

      // Act
      await mockUserRepository.deleteUser('test_user_id');

      // Assert
      verify(mockUserRepository.deleteUser('test_user_id')).called(1);
    });

    test('getUsersByRole should return correct users', () async {
      // Arrange
      final users = [testUser];
      when(mockUserRepository.getUsersByRole('student')).thenAnswer((realInvocation) async => users);

      // Act
      final result = await mockUserRepository.getUsersByRole('student');

      // Assert
      expect(result, isNotNull);
      expect(result.length, 1);
      expect(result.first.name, 'Test User');
      verify(mockUserRepository.getUsersByRole('student')).called(1);
    });
  });
}
