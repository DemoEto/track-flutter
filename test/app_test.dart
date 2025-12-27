// Unit tests for the application
import 'package:flutter_test/flutter_test.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';
import 'package:track_app/core/enums.dart';
import 'package:track_app/features/attendance/data/models/attendance_record_model.dart';
import 'package:track_app/features/homework/data/models/homework_model.dart';

void main() {
  group('User Model Tests', () {
    test('UserModel should be created correctly', () {
      final user = UserModel(
        id: 'test_id',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.student,
        fcmToken: 'test_token',
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 2),
      );

      expect(user.id, 'test_id');
      expect(user.email, 'test@example.com');
      expect(user.name, 'Test User');
      expect(user.role, UserRole.student);
      expect(user.fcmToken, 'test_token');
      expect(user.createdAt, DateTime(2023, 1, 1));
      expect(user.updatedAt, DateTime(2023, 1, 2));
    });

    test('UserModel copyWith should work correctly', () {
      final originalUser = UserModel(
        id: 'test_id',
        email: 'test@example.com',
        name: 'Test User',
        role: UserRole.student,
        fcmToken: null,
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 1),
      );

      final updatedUser = originalUser.copyWith(name: 'Updated Name', role: UserRole.teacher);

      expect(updatedUser.name, 'Updated Name');
      expect(updatedUser.role, UserRole.teacher);
      expect(updatedUser.email, 'test@example.com'); // Should remain unchanged
    });
  });

  group('Attendance Record Model Tests', () {
    test('AttendanceRecordModel should be created correctly', () {
      final record = AttendanceRecordModel(
        id: 'record_id',
        sessionId: 'session_id',
        studentId: 'student_id',
        scanTime: DateTime(2023, 1, 1, 9, 0),
        status: AttendanceStatus.present,
        createdAt: DateTime(2023, 1, 1, 10, 0),
      );

      expect(record.id, 'record_id');
      expect(record.sessionId, 'session_id');
      expect(record.studentId, 'student_id');
      expect(record.scanTime, DateTime(2023, 1, 1, 9, 0));
      expect(record.status, AttendanceStatus.present);
      expect(record.createdAt, DateTime(2023, 1, 1, 10, 0));
    });
  });

  group('Homework Model Tests', () {
    test('HomeworkModel should be created correctly', () {
      final homework = HomeworkModel(
        id: 'homework_id',
        subjectId: 'subject_id',
        title: 'Test Homework',
        description: 'Test Description',
        assignedTo: ['student1', 'student2'],
        dueDate: DateTime(2023, 12, 31),
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 1),
      );

      expect(homework.id, 'homework_id');
      expect(homework.subjectId, 'subject_id');
      expect(homework.title, 'Test Homework');
      expect(homework.description, 'Test Description');
      expect(homework.assignedTo, ['student1', 'student2']);
      expect(homework.dueDate, DateTime(2023, 12, 31));
      expect(homework.createdAt, DateTime(2023, 1, 1));
      expect(homework.updatedAt, DateTime(2023, 1, 1));
    });

    test('HomeworkModel copyWith should work correctly', () {
      final originalHomework = HomeworkModel(
        id: 'homework_id',
        subjectId: 'subject_id',
        title: 'Original Title',
        description: 'Original Description',
        assignedTo: ['student1'],
        dueDate: DateTime(2023, 12, 31),
        createdAt: DateTime(2023, 1, 1),
        updatedAt: DateTime(2023, 1, 1),
      );

      final updatedHomework = originalHomework.copyWith(title: 'Updated Title', description: 'Updated Description');

      expect(updatedHomework.title, 'Updated Title');
      expect(updatedHomework.description, 'Updated Description');
      expect(updatedHomework.subjectId, 'subject_id'); // Should remain unchanged
    });
  });

  group('Role Enum Tests', () {
    test('UserRole enum conversion should work', () {
      expect(UserRole.fromString('student'), UserRole.student);
      expect(UserRole.fromString('teacher'), UserRole.teacher);

      expect(() => UserRole.fromString('invalid'), throwsArgumentError);
    });

    test('AttendanceStatus enum conversion should work', () {
      expect(AttendanceStatus.fromString('present'), AttendanceStatus.present);
      expect(AttendanceStatus.fromString('absent'), AttendanceStatus.absent);
      expect(AttendanceStatus.fromString('late'), AttendanceStatus.late);

      expect(() => AttendanceStatus.fromString('invalid'), throwsArgumentError);
    });
  });
}
