# firebase_uploader_plus example

This example demonstrates auth + uploads with `firebase_uploader_plus`.

## Firebase setup

Use one of these approaches before running:

1. Add `android/app/google-services.json` (and platform equivalents as needed), or
2. Pass Firebase config from CLI:

```bash
flutter run \
  --dart-define=FIREBASE_ANDROID_APP_ID=... \
  --dart-define=FIREBASE_PROJECT_ID=... \
  --dart-define=FIREBASE_MESSAGING_SENDER_ID=... \
  --dart-define=FIREBASE_ANDROID_API_KEY=... \
  --dart-define=FIREBASE_STORAGE_BUCKET=...
```

`FIREBASE_STORAGE_BUCKET` is optional.
