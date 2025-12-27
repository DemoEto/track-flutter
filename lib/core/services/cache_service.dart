// Caching service for repository optimization
import 'package:track_app/core/utils/performance_utils.dart';
import 'package:track_app/features/auth/data/models/user_model.dart';
import 'package:track_app/features/attendance/data/models/subject_model.dart';
import 'package:track_app/features/attendance/data/models/attendance_session_model.dart';
import 'package:track_app/features/attendance/data/models/attendance_record_model.dart';
import 'package:track_app/features/homework/data/models/homework_model.dart';
import 'package:track_app/features/homework/data/models/submission_model.dart';
import 'package:track_app/features/notification/data/models/notification_model.dart';

class CacheService {
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Caches for different entity types
  final SimpleCache<UserModel> _userCache = SimpleCache<UserModel>(maxSize: 100);
  final SimpleCache<SubjectModel> _subjectCache = SimpleCache<SubjectModel>(maxSize: 50);
  final SimpleCache<AttendanceSessionModel> _sessionCache = SimpleCache<AttendanceSessionModel>(maxSize: 50);
  final SimpleCache<AttendanceRecordModel> _recordCache = SimpleCache<AttendanceRecordModel>(maxSize: 200);
  final SimpleCache<HomeworkModel> _homeworkCache = SimpleCache<HomeworkModel>(maxSize: 100);
  final SimpleCache<SubmissionModel> _submissionCache = SimpleCache<SubmissionModel>(maxSize: 200);
  final SimpleCache<NotificationModel> _notificationCache = SimpleCache<NotificationModel>(maxSize: 100);

  // User cache operations
  UserModel? getUserFromCache(String userId) => _userCache.get(userId);

  void setUserCache(String userId, UserModel user) {
    _userCache.put(userId, user, expiry: const Duration(hours: 2));
  }

  void removeUserCache(String userId) => _userCache.remove(userId);

  // Subject cache operations
  SubjectModel? getSubjectFromCache(String subjectId) => _subjectCache.get(subjectId);

  void setSubjectCache(String subjectId, SubjectModel subject) {
    _subjectCache.put(subjectId, subject, expiry: const Duration(hours: 1));
  }

  // Attendance session cache operations
  AttendanceSessionModel? getSessionFromCache(String sessionId) => _sessionCache.get(sessionId);

  void setSessionCache(String sessionId, AttendanceSessionModel session) {
    _sessionCache.put(sessionId, session, expiry: const Duration(minutes: 30));
  }

  // Attendance record cache operations
  AttendanceRecordModel? getRecordFromCache(String recordId) => _recordCache.get(recordId);

  void setRecordCache(String recordId, AttendanceRecordModel record) {
    _recordCache.put(recordId, record, expiry: const Duration(minutes: 60));
  }

  // Homework cache operations
  HomeworkModel? getHomeworkFromCache(String homeworkId) => _homeworkCache.get(homeworkId);

  void setHomeworkCache(String homeworkId, HomeworkModel homework) {
    _homeworkCache.put(homeworkId, homework, expiry: const Duration(hours: 1));
  }

  // Submission cache operations
  SubmissionModel? getSubmissionFromCache(String submissionId) => _submissionCache.get(submissionId);

  void setSubmissionCache(String submissionId, SubmissionModel submission) {
    _submissionCache.put(submissionId, submission, expiry: const Duration(minutes: 30));
  }

  // Notification cache operations
  NotificationModel? getNotificationFromCache(String notificationId) => _notificationCache.get(notificationId);

  void setNotificationCache(String notificationId, NotificationModel notification) {
    _notificationCache.put(notificationId, notification, expiry: const Duration(minutes: 15));
  }

  // Clear specific caches
  void clearUserCache() => _userCache.clear();
  void clearSubjectCache() => _subjectCache.clear();
  void clearSessionCache() => _sessionCache.clear();
  void clearRecordCache() => _recordCache.clear();
  void clearHomeworkCache() => _homeworkCache.clear();
  void clearSubmissionCache() => _submissionCache.clear();
  void clearNotificationCache() => _notificationCache.clear();

  // Clear all caches
  void clearAllCaches() {
    _userCache.clear();
    _subjectCache.clear();
    _sessionCache.clear();
    _recordCache.clear();
    _homeworkCache.clear();
    _submissionCache.clear();
    _notificationCache.clear();
  }

  // Get cache statistics
  Map<String, dynamic> getCacheStats() {
    return {
      'userCacheSize': _getCacheSize(_userCache),
      'subjectCacheSize': _getCacheSize(_subjectCache),
      'sessionCacheSize': _getCacheSize(_sessionCache),
      'recordCacheSize': _getCacheSize(_recordCache),
      'homeworkCacheSize': _getCacheSize(_homeworkCache),
      'submissionCacheSize': _getCacheSize(_submissionCache),
      'notificationCacheSize': _getCacheSize(_notificationCache),
    };
  }

  int _getCacheSize<T>(SimpleCache<T> cache) {
    // This is a simplified count - in a real implementation you'd need to iterate
    // For now, we'll return -1 to indicate this needs implementation
    return -1;
  }
}

// Singleton instance getter
CacheService get cacheService => CacheService._instance;
