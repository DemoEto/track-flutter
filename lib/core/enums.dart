// App enums

// User roles
enum UserRole {
  teacher('teacher'),
  student('student'),
  parent('parent'),
  driver('driver');

  const UserRole(this.value);
  final String value;

  static UserRole fromString(String value) {
    switch (value) {
      case 'teacher':
        return UserRole.teacher;
      case 'student':
        return UserRole.student;
      case 'parent':
        return UserRole.parent;
      case 'driver':
        return UserRole.driver;
      default:
        throw ArgumentError('Invalid role: $value');
    }
  }
}

// Attendance status
enum AttendanceStatus {
  present('present'),
  absent('absent'),
  late('late');

  const AttendanceStatus(this.value);
  final String value;

  static AttendanceStatus fromString(String value) {
    switch (value) {
      case 'present':
        return AttendanceStatus.present;
      case 'absent':
        return AttendanceStatus.absent;
      case 'late':
        return AttendanceStatus.late;
      default:
        throw ArgumentError('Invalid attendance status: $value');
    }
  }
}

// Homework status
enum HomeworkStatus {
  assigned('assigned'),
  submitted('submitted'),
  checked('checked'),
  overdue('overdue');

  const HomeworkStatus(this.value);
  final String value;

  static HomeworkStatus fromString(String value) {
    switch (value) {
      case 'assigned':
        return HomeworkStatus.assigned;
      case 'submitted':
        return HomeworkStatus.submitted;
      case 'checked':
        return HomeworkStatus.checked;
      case 'overdue':
        return HomeworkStatus.overdue;
      default:
        throw ArgumentError('Invalid homework status: $value');
    }
  }
}

// Notification types
enum NotificationType {
  attendance('attendance'),
  homework('homework'),
  general('general'),
  bus('bus');

  const NotificationType(this.value);
  final String value;

  static NotificationType fromString(String value) {
    switch (value) {
      case 'attendance':
        return NotificationType.attendance;
      case 'homework':
        return NotificationType.homework;
      case 'general':
        return NotificationType.general;
      case 'bus':
        return NotificationType.bus;
      default:
        throw ArgumentError('Invalid notification type: $value');
    }
  }
}
