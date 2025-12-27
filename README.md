# Track App - Online Learning System

A comprehensive Flutter application for online learning with Firebase backend, supporting multiple user roles including students, teachers, parents, admins, and drivers.

## Features

### User Roles
- **Student**: Attendance tracking, homework management, notifications
- **Teacher**: Create attendance sessions, assign homework, track student performance
- **Parent**: Monitor child attendance, homework, and bus status
- **Admin**: User management, system configuration, analytics
- **Driver**: Passenger management, trip status updates

### Core Functionality
- **Authentication**: Firebase Authentication with role-based access
- **Attendance System**: QR code generation and scanning for attendance
- **Homework Management**: Assignment creation, submission, and grading
- **Notifications**: Real-time notifications with Firebase Cloud Messaging
- **Bus Tracking**: Real-time bus tracking for parents and drivers
- **Responsive UI**: Works on mobile, tablet, and desktop

## Technology Stack

- **Frontend**: Flutter (Dart)
- **Backend**: Firebase
  - Firestore Database
  - Firebase Authentication
  - Firebase Cloud Messaging
  - Firebase Storage
- **State Management**: Provider
- **Navigation**: Go Router
- **QR Code**: qr_flutter, qr_code_scanner
- **Testing**: Flutter Test, Mockito

## Project Structure

```
lib/
├── core/                 # Shared components
│   ├── constants/        # App constants
│   ├── enums/            # App enums
│   ├── services/         # Core services
│   ├── theme/            # Theme configuration
│   ├── utils/            # Utility functions
│   └── widgets/          # Shared widgets
└── features/             # Feature modules
    ├── auth/             # Authentication
    ├── attendance/       # Attendance system
    ├── homework/         # Homework system
    ├── notification/     # Notification system
    ├── admin/            # Admin features
    ├── driver/            # Bus tracking
    └── parent/           # Parent features
```

## Getting Started

### Prerequisites
- Flutter SDK (latest stable)
- Firebase project with required services enabled
- Android Studio or VS Code

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd track_app
```

2. Install dependencies:
```bash
flutter pub get
```

3. Configure Firebase:
```bash
# Follow the instructions at https://firebase.google.com/docs/flutter/setup
flutterfire configure
```

4. Run the application:
```bash
flutter run
```

## Testing

Run all tests:
```bash
flutter test
```

Run specific test file:
```bash
flutter test test/app_test.dart
```

## Documentation

- **Technical Documentation**: [TECHNICAL_DOCUMENTATION.md](TECHNICAL_DOCUMENTATION.md)
- **User Guide**: [USER_GUIDE.md](USER_GUIDE.md)
- **Deployment Guide**: [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md)
- **Implementation Plan**: [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md)
- **Original Requirements**: [TODO.md](TODO.md)

## Architecture

This app follows a feature-first architecture with clean separation of concerns:

- **Presentation Layer**: UI components and screens
- **Logic Layer**: State management (Provider)
- **Data Layer**: Models and repositories
- **Core**: Shared utilities, themes, and services

## Deployment

For deployment instructions, see [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md).

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests if applicable
5. Submit a pull request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

For support, contact the development team or refer to the documentation files included with this project.