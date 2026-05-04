# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2026-05-04

### Changed
- Require Dart `>=3.11.0` and Flutter `>=3.41.7`.
- Pub.dev `description` tightened; dropped unused direct `mime` dependency (still available transitively where needed).
- MIT `LICENSE` copyright line updated.
- `PathBuilder.getFileType` now returns `pdf` for `.pdf` files (aligned with list UI and Firestore `fileType`).
- `FirestoreService.streamUploads`: when `filterByUser` is `null`, queries are no longer implicitly scoped to the signed-in user (matches `FirebaseUploader` `filterByCurrentUser: false`).

### Added
- `PathBuilder.buildDateOrganizedPath`.
- `UploadMetadata.fromMap` for tests and non-Firestore construction.

### Fixed
- `connectivity_plus` v6: `checkConnectivity()` returns a `List<ConnectivityResult>`; offline detection updated accordingly.
- Upload progress listener is cancelled after the upload task completes; avoid divide-by-zero when `totalBytes` is 0.
- `UploadMetadata.fromFirestore` validates map-shaped document data.
- Example app declares `firebase_core`, `firebase_auth`, and `firebase_uploader_plus` as runtime dependencies.

## [1.0.0] - 2024-01-15

### Added
- Initial release of firebase_uploader_plus
- Complete Firebase Storage integration with automatic file uploads
- Firestore metadata management with real-time streams
- Smart auto-pathing with user-based organization
- File type validation and size limits
- Camera capture and gallery selection support
- Real-time upload progress tracking
- Soft delete functionality for files
- Customizable UI components (headers, file tiles, empty states)
- Batch upload support for multiple files
- Search and filtering capabilities
- Upload statistics and analytics
- Offline connectivity handling
- Cross-platform support (Android, iOS, Web, Desktop)

### Features
- **FirebaseUploader Widget**: Main widget for file upload and management
- **FirebaseStorageHelper**: Service for Firebase Storage operations
- **FirestoreService**: Service for metadata management and real-time streams
- **UploadMetadata Model**: Comprehensive file metadata model
- **PathBuilder Utility**: Smart path generation and file organization
- **Authentication Integration**: Automatic user-based file filtering
- **Progress Tracking**: Real-time upload progress with callbacks
- **File Validation**: Extension and size validation
- **Custom UI Support**: Flexible widget customization options

### Documentation
- Comprehensive README with usage examples
- API reference documentation
- Example application demonstrating all features
- Setup guides for Firebase configuration
- Security best practices and performance tips

### Dependencies
- firebase_core: ^2.24.2
- firebase_storage: ^11.6.0
- cloud_firestore: ^4.13.6
- firebase_auth: ^4.15.3
- file_picker: ^6.1.1
- image_picker: ^1.0.4
- path: ^1.8.3
- mime: ^1.0.4
- connectivity_plus: ^5.0.2
- cached_network_image: ^3.3.0