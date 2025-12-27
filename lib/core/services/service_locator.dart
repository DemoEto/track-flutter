// Service locator/di setup
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:track_app/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:track_app/features/auth/data/repositories/user_repository_impl.dart';
import 'package:track_app/features/attendance/data/repositories/subject_repository_impl.dart';

import 'package:track_app/features/attendance/data/repositories/attendance_session_repository_impl.dart';
import 'package:track_app/features/attendance/data/repositories/attendance_record_repository_impl.dart';
import 'package:track_app/features/homework/data/repositories/homework_repository_impl.dart';
import 'package:track_app/features/homework/data/repositories/submission_repository_impl.dart';
import 'package:track_app/features/notification/data/repositories/notification_repository_impl.dart';
import 'package:track_app/features/driver/data/repositories/driver_repository.dart';

import 'package:track_app/features/notification/services/notification_service.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  factory ServiceLocator() => _instance;
  ServiceLocator._internal();

  FirebaseAuth? _firebaseAuth;
  FirebaseFirestore? _firestore;

  // Repositories
  late final FirebaseAuthService authRepository;
  late final FirebaseUserRepository userRepository;
  late final FirebaseSubjectRepository subjectRepository;
  late final FirebaseAttendanceSessionRepository attendanceSessionRepository;
  late final FirebaseAttendanceRecordRepository attendanceRecordRepository;
  late final FirebaseHomeworkRepository homeworkRepository;
  late final FirebaseSubmissionRepository submissionRepository;
  late final FirebaseNotificationRepository notificationRepository;
  late final FirebaseDriverRepository driverRepository;

  // Services
  late final NotificationService notificationService;

  void init() {
    _firebaseAuth = FirebaseAuth.instance;
    _firestore = FirebaseFirestore.instance;

    authRepository = FirebaseAuthService(firebaseAuth: _firebaseAuth, firestore: _firestore);
    userRepository = FirebaseUserRepository(firestore: _firestore);
    subjectRepository = FirebaseSubjectRepository(firestore: _firestore);
    attendanceSessionRepository = FirebaseAttendanceSessionRepository(firestore: _firestore);
    attendanceRecordRepository = FirebaseAttendanceRecordRepository(firestore: _firestore);
    homeworkRepository = FirebaseHomeworkRepository(firestore: _firestore);
    submissionRepository = FirebaseSubmissionRepository(firestore: _firestore);
    notificationRepository = FirebaseNotificationRepository(firestore: _firestore);
    driverRepository = FirebaseDriverRepository(firestore: _firestore);
    notificationService = NotificationService();
  }
}

// Singleton instance getter
ServiceLocator get locator => ServiceLocator._instance;
