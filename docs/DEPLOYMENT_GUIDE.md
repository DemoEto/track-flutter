# Deployment Guide for Track App

## Overview
This guide provides instructions for deploying the Track App to different environments (development, staging, production) using Firebase services.

## Prerequisites

### Development Environment
- Flutter SDK (latest stable version)
- Dart SDK (latest stable version)
- Firebase CLI tools
- Git
- Access to Firebase project

### Firebase Project Setup
1. Create a Firebase project at https://console.firebase.google.com
2. Enable the following services:
   - Firebase Authentication
   - Cloud Firestore
   - Firebase Storage
   - Firebase Cloud Messaging
   - Firebase Analytics
   - Firebase Crashlytics
   - Firebase Performance Monitoring

## Environment Configuration

### Development
```bash
# Clone the repository
git clone <repository-url>
cd track_app

# Install dependencies
flutter pub get

# Configure Firebase (platform-specific instructions below)
# iOS: flutterfire configure --platforms=ios
# Android: flutterfire configure --platforms=android
```

### Staging & Production
1. Create separate Firebase projects for staging and production
2. Use different `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) files for each environment
3. Configure environment variables for each deployment

## Platform-Specific Deployment

### Android

#### 1. Preparing for Release
```bash
# Generate an upload key (only for first time)
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload

# Add to ~/.gradle/gradle.properties
MYAPP_UPLOAD_STORE_FILE=~/upload-keystore.jks
MYAPP_UPLOAD_KEY_ALIAS=upload
MYAPP_UPLOAD_STORE_PASSWORD=<password>
MYAPP_UPLOAD_KEY_PASSWORD=<password>
```

#### 2. Building the APK
```bash
flutter build apk --release
```

#### 3. Building the App Bundle (recommended for Play Store)
```bash
flutter build appbundle --release
```

#### 4. Publishing to Google Play Store
1. Upload the generated `.aab` file to Google Play Console
2. Complete the store listing with screenshots and descriptions
3. Submit for review

### iOS

#### 1. Preparing for Release
1. Configure your development team in Xcode:
   - Open `ios/Runner.xcworkspace` in Xcode
   - Select the `Runner` project
   - Go to the `Signing & Capabilities` tab
   - Check "Automatically manage signing"
   - Select your development team

#### 2. Building the IPA
```bash
flutter build ios --release
```

#### 3. Publishing to App Store
1. Open Xcode and archive the project (Product > Archive)
2. Upload to App Store Connect
3. Complete the app listing
4. Submit for review

## Firebase Configuration

### Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users: users can only access their own data, admins can manage all
    // Parents can read their children's data
    match /users/{userId} {
      allow read, update: if request.auth != null && (request.auth.uid == userId || isParentOf(userId));
      allow create: if request.auth != null;
      allow delete: if request.auth != null && request.auth.token.role == 'admin';
    }
    
    // Subjects: teachers can manage their subjects, students can read assigned subjects
    match /subjects/{subjectId} {
      allow read: if request.auth != null;
      allow create, update, delete: if request.auth != null && request.auth.token.role == 'teacher';
    }
    
    // Attendance sessions: teachers can create/manage, students can read for their subjects
    // Parents can read for their children
    match /attendance_sessions/{sessionId} {
      allow read, create, update, delete: if request.auth != null && request.auth.token.role == 'teacher';
    }
    
    // Attendance records: teachers can view their subjects, students can view their own
    // Parents can view their children's records
    match /attendance_records/{recordId} {
      allow read, create, update: if request.auth != null;
    }
    
    // Homework: teachers can manage for their subjects, students can read assigned homework
    // Parents can read their children's homework
    match /homeworks/{homeworkId} {
      allow read: if request.auth != null && (request.auth.token.role == 'teacher' || request.auth.token.role == 'student' || isParentOf(resource.data.assignedTo));
      allow create, update, delete: if request.auth != null && request.auth.token.role == 'teacher';
    }
    
    // Submissions: students can submit their own work, teachers can review
    // Parents can read their children's submissions
    match /submissions/{submissionId} {
      allow read: if request.auth != null && (request.auth.token.role == 'teacher' 
        || request.auth.uid == resource.data.studentId 
        || isParentOf(resource.data.studentId));
      allow create: if request.auth != null && request.auth.token.role == 'student';
      allow update: if request.auth != null && request.auth.token.role == 'teacher';
      allow delete: if request.auth != null && request.auth.uid == resource.data.studentId;
    }
    
    // Notifications: users can only access their own notifications
    // Parents can access notifications for their children
    match /notifications/{notificationId} {
      allow read, update, delete: if request.auth != null && (request.auth.uid == resource.data.userId || isParentOf(resource.data.userId));
      allow create: if request.auth != null;
    }
    
    // Rides: drivers can update status for their trips, parents can view children's trips, admins have full access
    match /rides/{rideId} {
      allow read: if request.auth != null && (request.auth.token.role == 'driver' || request.auth.token.role == 'admin' || hasAccessToRide(resource.data.passengerIds));
      allow create, update, delete: if request.auth != null && request.auth.token.role == 'admin';
    }
  }
  
  // Helper functions
  function isParentOf(studentId) {
    return request.auth.token.role == 'parent' && 
      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.childUserIds != null &&
      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.childUserIds.hasAny([studentId]);
  }
  
  function hasAccessToRide(passengerIds) {
    return request.auth.token.role == 'parent' && 
      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.childUserIds != null &&
      // Check if any of the parent's children are in the ride
      get(/databases/$(database)/documents/users/$(request.auth.uid)).data.childUserIds.intersects(passengerIds);
  }
}
```

### Firebase Authentication Configuration
1. Enable Email/Password sign-in method
2. Configure email templates for password reset
3. Set up email verification flows

### Firebase Cloud Messaging
1. Upload your APNs certificate for iOS
2. Configure notification settings in Firebase Console

## Continuous Integration/Deployment (CI/CD)

### GitHub Actions Example
Create `.github/workflows/deploy.yml`:

```yaml
name: Deploy to Firebase

on:
  push:
    branches: [ main, staging ]
  pull_request:
    branches: [ main ]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - run: flutter test
      - run: flutter analyze
      - run: flutter build apk --debug

  deploy:
    needs: test
    runs-on: ubuntu-latest
    if: github.ref == 'refs/heads/main'
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.x'
      - run: flutter pub get
      - name: Build Android App Bundle
        run: flutter build appbundle --release
      - name: Build iOS
        run: flutter build ios --release --no-codesign
      - name: Deploy to Firebase App Distribution
        uses: wzieba/Firebase-Distribution-Github-Action@v1
        with:
          appId: ${{secrets.FIREBASE_APP_ID}}
          authToken: ${{secrets.FIREBASE_TOKEN}}
          groups: testers
          file: build/app/outputs/bundle/release/app-release.aab
```

## Analytics and Monitoring

### Firebase Analytics Setup
The app automatically tracks these events:
- User registration/login
- Screen views
- Key feature usage
- Errors and exceptions

### Crashlytics Configuration
- Automatic crash reporting is enabled
- Custom logs can be added using `FirebaseCrashlytics.instance.log()`
- Non-fatal exceptions can be reported with `FirebaseCrashlytics.instance.recordError()`

### Performance Monitoring
- App startup time
- Screen rendering performance
- Network request performance
- Custom trace monitoring for key operations

## Environment Variables

### Flutter Configuration
Use the following patterns for environment configuration:

```dart
class Environment {
  static String get firebaseProjectId {
    const String? projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
    return projectId ?? 'default-project-id';
  }
  
  static bool get isDebugMode {
    return const bool.fromEnvironment('DEBUG', defaultValue: false);
  }
}
```

### Build Variants
```bash
# Development build
flutter run --dart-define=ENV=development

# Staging build
flutter run --dart-define=ENV=staging

# Production build
flutter build apk --dart-define=ENV=production
```

## Maintenance and Updates

### Regular Maintenance Tasks
1. Monitor Firebase usage quotas
2. Review and update security rules regularly
3. Update dependencies monthly
4. Monitor crash reports and analytics
5. Review user feedback and app store ratings

### Updating the App
1. Create a new branch for updates
2. Make changes and test thoroughly
3. Update version numbers in `pubspec.yaml`
4. Run all tests (`flutter test`)
5. Create release builds
6. Deploy to app stores
7. Monitor for issues after release

## Rollback Procedures

### In Case of Critical Issues
1. Identify the issue and confirm its source
2. If necessary, roll back to a previous stable version
3. Inform users about the issue and resolution timeline
4. Fix the issue in a new update
5. Deploy the fix with thorough testing

## Security Considerations

### Data Protection
- All sensitive data is encrypted in transit
- User authentication tokens are securely stored
- Regular security audits of code and dependencies

### Best Practices
- Never hardcode API keys or secrets in the code
- Use Firebase security rules to protect data
- Regularly update dependencies to patch security vulnerabilities
- Implement proper error handling to avoid information disclosure

## Troubleshooting Common Deployment Issues

### Firebase Configuration Issues
- Ensure `google-services.json` is in the correct location for Android
- Verify `GoogleService-Info.plist` is properly configured for iOS
- Confirm Firebase CLI is authenticated with the correct project

### Build Issues
- Clean and rebuild if experiencing build errors: `flutter clean && flutter pub get`
- Ensure all dependencies are compatible with target SDK versions
- Check for platform-specific build requirements

### Performance Issues
- Monitor app size and optimize assets
- Implement lazy loading for heavy features
- Use Flutter's performance tools to identify bottlenecks

This deployment guide provides comprehensive instructions for deploying the Track App across different environments while maintaining security, performance, and user experience standards.