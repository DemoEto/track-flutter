// Core app constants

class AppConstants {
  // App name and version
  static const String appName = 'Track App';

  // API endpoints if needed
  static const String apiBaseUrl = '';

  // Shared preferences keys
  static const String userRoleKey = 'user_role';
  static const String userIdKey = 'user_id';
  static const String userTokenKey = 'user_token';

  // Firebase collection names
  static const String usersCollection = 'users';
  static const String subjectsCollection = 'subjects';
  static const String subjectEnrollmentsCollection = 'subject_enrollments';
  static const String attendanceSessionsCollection = 'attendance_sessions';
  static const String attendanceRecordsCollection = 'attendance_records';
  static const String homeworksCollection = 'homeworks';
  static const String submissionsCollection = 'submissions';
  static const String notificationsCollection = 'notifications';

  // User roles

  static const String roleTeacher = 'teacher';
  static const String roleStudent = 'student';
  static const String roleParent = 'parent';
  static const String roleDriver = 'driver';

  // Notification types
  static const String notificationAttendance = 'attendance';
  static const String notificationHomework = 'homework';
  static const String notificationBus = 'bus';
  static const String notificationGeneral = 'general';
}

// Error messages
class ErrorMessages {
  static const String networkError = 'Network error occurred';
  static const String authError = 'Authentication error occurred';
  static const String dataError = 'Data error occurred';
  static const String unknownError = 'An unknown error occurred';
}
