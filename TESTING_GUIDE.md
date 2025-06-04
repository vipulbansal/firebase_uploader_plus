# Firebase Uploader Plus - Testing Guide

## Prerequisites

To test this package, you need to set up Firebase for your Flutter project. The package will NOT work without proper Firebase configuration.

## Firebase Setup Steps

### 1. Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Enable Authentication and Cloud Firestore
4. Enable Firebase Storage

### 2. Configure Flutter Project

#### For Android:
1. Add your Android app in Firebase Console
2. Download `google-services.json`
3. Place it in `android/app/` directory
4. Add to `android/build.gradle`:
```gradle
buildscript {
    dependencies {
        classpath 'com.google.gms:google-services:4.3.15'
    }
}
```

5. Add to `android/app/build.gradle`:
```gradle
apply plugin: 'com.google.gms.google-services'
```

#### For Web:
1. Add your Web app in Firebase Console
2. Copy the Firebase configuration
3. Create `web/firebase-config.js`:
```javascript
import { initializeApp } from "https://www.gstatic.com/firebasejs/9.22.0/firebase-app.js";

const firebaseConfig = {
  // Your config here
  apiKey: "your-api-key",
  authDomain: "your-project.firebaseapp.com",
  projectId: "your-project-id",
  storageBucket: "your-project.appspot.com",
  messagingSenderId: "123456789",
  appId: "your-app-id"
};

initializeApp(firebaseConfig);
```

4. Include in `web/index.html`:
```html
<script type="module" src="firebase-config.js"></script>
```

### 3. Add Dependencies

Add to your `pubspec.yaml`:
```yaml
dependencies:
  flutter:
    sdk: flutter
  firebase_core: ^2.15.1
  firebase_auth: ^4.7.3
  firebase_storage: ^11.2.6
  cloud_firestore: ^4.9.1
  firebase_uploader_plus:
    path: ../firebase_uploader_plus  # or from pub.dev once published
```

### 4. Initialize Firebase

In your `main.dart`:
```dart
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

## Running the Example

### Quick Test (Recommended)
1. Follow Firebase setup steps above
2. Run the example app:
```bash
cd example
flutter run
```

### What the Example App Does:
- **Authentication**: Sign in anonymously or with email
- **File Upload**: Upload any files to Firebase Storage
- **Metadata Storage**: Automatically saves file info to Firestore
- **Three Tabs**: All files, Images only, Documents only
- **Real-time Updates**: Shows uploaded files immediately

## Firebase Rules Setup

### Storage Rules (`storage.rules`):
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

### Firestore Rules (`firestore.rules`):
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

## Testing Without Firebase (Unit Tests Only)

For unit testing the PathBuilder utility without Firebase:

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_uploader_plus/firebase_uploader_plus.dart';

void main() {
  group('PathBuilder Tests', () {
    test('sanitizeFileName removes unsafe characters', () {
      expect(
        PathBuilder.sanitizeFileName('test<>file.pdf'),
        equals('test__file.pdf'),
      );
    });

    test('getFileType returns correct type', () {
      expect(PathBuilder.getFileType('document.pdf'), equals('document'));
      expect(PathBuilder.getFileType('image.jpg'), equals('image'));
      expect(PathBuilder.getFileType('video.mp4'), equals('video'));
    });

    test('isAllowedExtension works correctly', () {
      expect(
        PathBuilder.isAllowedExtension('test.pdf', ['pdf', 'doc']),
        isTrue,
      );
      expect(
        PathBuilder.isAllowedExtension('test.txt', ['pdf', 'doc']),
        isFalse,
      );
    });

    test('getMimeType returns correct MIME type', () {
      expect(PathBuilder.getMimeType('test.pdf'), equals('application/pdf'));
      expect(PathBuilder.getMimeType('image.jpg'), equals('image/jpeg'));
    });
  });
}
```

## Common Issues

### 1. "Firebase not initialized"
- Ensure `await Firebase.initializeApp()` is called before `runApp()`

### 2. "Permission denied" errors
- Check Firebase Authentication rules
- Ensure user is signed in before uploading

### 3. "No such document" errors
- The package creates documents automatically
- Check Firestore rules allow write access

### 4. Web platform issues
- Ensure CORS is configured for your domain in Firebase Storage
- Check browser console for detailed errors

## Testing Checklist

- [ ] Firebase project created and configured
- [ ] Authentication enabled (Anonymous + Email/Password)
- [ ] Cloud Firestore enabled with proper rules
- [ ] Firebase Storage enabled with proper rules
- [ ] Platform-specific configuration files added
- [ ] Dependencies added to pubspec.yaml
- [ ] Firebase initialized in main.dart
- [ ] Example app runs without errors
- [ ] Can sign in (anonymously or with email)
- [ ] Can upload files successfully
- [ ] Files appear in Firebase Storage
- [ ] Metadata appears in Firestore
- [ ] Real-time updates work in the app

## Need Help?

The package requires active Firebase services to function. If you encounter issues:

1. Check Firebase Console for error logs
2. Verify your Firebase configuration
3. Ensure all Firebase services are enabled
4. Check network connectivity
5. Verify Firebase rules allow your operations

For production use, implement proper security rules and authentication flows.