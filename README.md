# 🔥 firebase_uploader_plus

**All-in-One Firebase File & Metadata Uploader**

A powerful, customizable Flutter widget that handles file uploads to Firebase Storage with automatic Firestore metadata management, real-time streams, and comprehensive file management capabilities.

## ✅ Built On

- `firebase_storage` - File upload and storage
- `cloud_firestore` - Metadata management and real-time streams
- `file_picker` - File selection from device
- `image_picker` - Camera capture and gallery selection
- `firebase_core` - Firebase initialization
- `firebase_auth` - User authentication (optional)

## 💡 Features

### 🔼 Upload Features
- 📁 Upload any file type (images, PDFs, videos, documents)
- 📷 Capture or pick images via camera/gallery
- 🧠 Smart auto-pathing (`uploads/users/{uid}/{timestamp}_{filename}`)
- 📊 Real-time progress bar during upload
- 🔁 You can retry failed uploads from your own code using the callbacks
- ✅ Success and failure callbacks
- 🔒 File size and type validation
- 📦 Multiple file upload support

### 📝 Metadata Features (Firestore Integration)
- ✅ Auto-create Firestore document alongside each file:
```json
{
  "fileName": "receipt_123.pdf",
  "downloadUrl": "https://firebasestorage...",
  "uploadedBy": "user_uid",
  "timestamp": "2024-01-15T10:30:00Z",
  "fileType": "pdf",
  "fileSizeBytes": 1363148,
  "storagePath": "uploads/users/uid/1705315800000_receipt_123.pdf",
  "isDeleted": false,
  "customMetadata": {}
}
```
- 🔄 Update/delete metadata in Firestore
- 🗑️ Soft-delete functionality
- 📊 Upload statistics and analytics

### 🌊 Stream Features
- 🔁 Real-time list of uploaded files using Firestore streams
- 📥 Auto-refresh UI on new uploads or deletions
- 🗑️ Delete files from both Firebase Storage and Firestore
- 🔍 Search and filter capabilities
- 📄 Pagination support for large file lists

## 🚀 Getting Started

### Requirements

- **Dart** `>=3.11.0`
- **Flutter** `>=3.41.7`

### Installation

Add to your `pubspec.yaml`:

```yaml
dependencies:
  firebase_uploader_plus: ^1.1.0
```

### Firebase Setup

1. **Initialize Firebase** in your app:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(MyApp());
}
```

2. **Configure Firebase Storage rules**:
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

3. **Configure Firestore security rules**:
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /user_uploads/{document} {
      allow read, write: if request.auth != null 
        && resource.data.uploadedBy == request.auth.uid;
    }
  }
}
```

### Basic Usage

```dart
import 'package:firebase_uploader_plus/firebase_uploader_plus.dart';

FirebaseUploader(
  allowedExtensions: ['jpg', 'png', 'pdf'],
  firestorePath: 'user_uploads',
  firebaseStoragePath: 'uploads/users',
  enablePreview: true,
  onUploadComplete: (UploadMetadata metadata) {
    print("File uploaded: ${metadata.downloadUrl}");
  },
)
```

## 📖 Comprehensive Examples

### Image Gallery with Camera Support

```dart
FirebaseUploader(
  allowedExtensions: ['jpg', 'jpeg', 'png', 'gif'],
  firestorePath: 'photos',
  firebaseStoragePath: 'uploads/photos',
  enablePreview: true,
  enableCamera: true,
  enableMultipleFiles: true,
  maxFileSize: 5 * 1024 * 1024, // 5MB
  onUploadComplete: (metadata) {
    print('Photo uploaded: ${metadata.fileName}');
  },
  onUploadError: (error) {
    print('Upload failed: $error');
  },
)
```

### Document Management System

```dart
FirebaseUploader(
  allowedExtensions: ['pdf', 'doc', 'docx', 'txt'],
  firestorePath: 'documents',
  firebaseStoragePath: 'uploads/documents',
  enablePreview: false,
  enableCamera: false,
  maxFileSize: 25 * 1024 * 1024, // 25MB
  customMetadata: {
    'department': 'HR',
    'category': 'employee_docs',
  },
  fileTileBuilder: (context, upload) => ListTile(
    leading: Icon(Icons.description),
    title: Text(upload.fileName),
    subtitle: Text(upload.formattedFileSize),
    trailing: IconButton(
      icon: Icon(Icons.download),
      onPressed: () => downloadFile(upload.downloadUrl),
    ),
  ),
)
```

### Custom Header and Empty State

```dart
FirebaseUploader(
  firestorePath: 'media_uploads',
  firebaseStoragePath: 'uploads/media',
  headerBuilder: (context) => Container(
    padding: EdgeInsets.all(16),
    child: Column(
      children: [
        Text('Media Upload Center', 
             style: Theme.of(context).textTheme.headlineSmall),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => pickFromGallery(),
                icon: Icon(Icons.photo_library),
                label: Text('Gallery'),
              ),
            ),
            SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () => capturePhoto(),
                icon: Icon(Icons.camera_alt),
                label: Text('Camera'),
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  emptyStateBuilder: (context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.cloud_upload, size: 64, color: Colors.grey),
        SizedBox(height: 16),
        Text('No files uploaded yet'),
        Text('Tap above to upload your first file'),
      ],
    ),
  ),
)
```

## 🔧 API Reference

### FirebaseUploader Parameters

| Parameter | Type | Default | Description |
|-----------|------|---------|-------------|
| `allowedExtensions` | `List<String>` | `[]` | Allowed file extensions (empty = all types) |
| `firestorePath` | `String` | **required** | Firestore collection path for metadata |
| `firebaseStoragePath` | `String` | **required** | Firebase Storage path for files |
| `enablePreview` | `bool` | `true` | Enable file preview functionality |
| `enableCamera` | `bool` | `true` | Show camera capture button |
| `enableMultipleFiles` | `bool` | `false` | Allow multiple file selection |
| `filterByCurrentUser` | `bool` | `true` | When `true`, only lists files where `uploadedBy` matches the signed-in user. When `false`, lists **all** documents in the collection (no `uploadedBy` filter); use only with paths and security rules you trust. |
| `maxFileSize` | `int?` | `null` | Maximum file size in bytes |
| `onUploadComplete` | `Function(UploadMetadata)?` | `null` | Callback on successful upload |
| `onUploadError` | `Function(String)?` | `null` | Callback on upload error |
| `onUploadProgress` | `Function(double)?` | `null` | Progress callback (0.0 to 1.0) |
| `fileTileBuilder` | `Widget Function(BuildContext, UploadMetadata)?` | `null` | Custom file tile builder |
| `headerBuilder` | `Widget Function(BuildContext)?` | `null` | Custom header builder |
| `emptyStateBuilder` | `Widget Function(BuildContext)?` | `null` | Custom empty state builder |
| `customMetadata` | `Map<String, String>?` | `null` | Additional metadata to store |

### UploadMetadata Properties

```dart
class UploadMetadata {
  final String id;                    // Firestore document ID
  final String fileName;              // Original filename
  final String downloadUrl;           // Firebase Storage download URL
  final String uploadedBy;            // User ID who uploaded
  final DateTime timestamp;           // Upload timestamp
  final String fileType;              // File type (image, pdf, document, etc.)
  final int fileSizeBytes;           // File size in bytes
  final String storagePath;          // Firebase Storage path
  final bool isDeleted;              // Soft delete flag
  final Map<String, dynamic>? customMetadata; // Additional metadata
  
  // Computed properties
  String get formattedFileSize;       // Human-readable file size
  String get fileExtension;           // File extension
  bool get isImage;                   // Is image file
  bool get isPdf;                     // Is PDF file
  bool get isVideo;                   // Is video file
  bool get isDocument;                // Is document file
}
```

## 🔐 Authentication Support

The package automatically integrates with Firebase Auth:

```dart
// Files are automatically tagged with current user ID
FirebaseAuth.instance.currentUser?.uid

// Filter files by current user (default behavior)
FirebaseUploader(
  filterByCurrentUser: true, // default
  firestorePath: 'user_uploads',
  firebaseStoragePath: 'uploads/users',
)

// Show all files (admin view)
FirebaseUploader(
  filterByCurrentUser: false,
  firestorePath: 'all_uploads',
  firebaseStoragePath: 'uploads/shared',
)
```

## 🌐 Offline Handling

The package includes built-in connectivity checking:

- Validates internet connection **before** starting an upload
- Surfaces an error via `onUploadError` when the device appears offline

It does **not** automatically retry uploads when connectivity returns; handle retries in your app if you need them.

## 🎨 Customization

### Custom File Tile

```dart
fileTileBuilder: (context, upload) => Card(
  child: ListTile(
    leading: CircleAvatar(
      backgroundImage: upload.isImage 
        ? NetworkImage(upload.downloadUrl)
        : null,
      child: upload.isImage ? null : Icon(Icons.description),
    ),
    title: Text(upload.fileName),
    subtitle: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${upload.formattedFileSize} • ${upload.fileType}'),
        Text('Uploaded ${timeAgo(upload.timestamp)}'),
      ],
    ),
    trailing: PopupMenuButton<String>(
      onSelected: (action) => handleFileAction(action, upload),
      itemBuilder: (context) => [
        PopupMenuItem(value: 'download', child: Text('Download')),
        PopupMenuItem(value: 'share', child: Text('Share')),
        PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    ),
  ),
)
```

### Custom Upload Progress

```dart
onUploadProgress: (progress) {
  setState(() {
    uploadProgress = progress;
  });
  print('Upload progress: ${(progress * 100).toStringAsFixed(1)}%');
}
```

## 📊 Advanced Features

### Stream Management

Use the services directly for advanced operations:

```dart
// Stream files by type
StreamBuilder<List<UploadMetadata>>(
  stream: FirestoreService.streamUploadsByType(
    firestorePath: 'uploads',
    fileType: 'image',
    limit: 50,
  ),
  builder: (context, snapshot) {
    final images = snapshot.data ?? [];
    return GridView.builder(
      itemCount: images.length,
      itemBuilder: (context, index) => ImageTile(images[index]),
    );
  },
)

// Get upload statistics
final stats = await FirestoreService.getUploadStats(
  firestorePath: 'user_uploads',
  filterByUser: FirebaseAuth.instance.currentUser?.uid,
);
print('Total files: ${stats['totalFiles']}');
print('Total size: ${stats['totalSizeFormatted']}');
```

### Batch Operations

```dart
// Batch delete multiple files
await FirestoreService.batchUpdateMetadata(
  firestorePath: 'uploads',
  documentIds: selectedFileIds,
  updates: {'isDeleted': true, 'deletedAt': Timestamp.now()},
);
```

### Custom Path Building

```dart
// Custom storage path
final customPath = PathBuilder.buildStoragePath(
  basePath: 'company_files',
  fileName: 'document.pdf',
  userId: 'specific_user_id',
  includeTimestamp: true,
);
// Result: company_files/specific_user_id/1705315800000_document.pdf

// Date-organized path
final datePath = PathBuilder.buildDateOrganizedPath(
  basePath: 'daily_reports',
  date: DateTime.now(),
);
// Result: daily_reports/2024/01/15
```

## 🔧 Direct Service Usage

For advanced use cases, use the services directly:

```dart
// Upload file programmatically
final metadata = await FirebaseStorageHelper.uploadFile(
  file: selectedFile,
  storagePath: 'custom/path',
  onProgress: (progress) => print('Progress: $progress'),
  customMetadata: {'source': 'api_upload'},
);

// Save metadata to Firestore
final docId = await FirestoreService.saveUploadMetadata(
  metadata: metadata,
  firestorePath: 'api_uploads',
);

// Stream real-time updates
FirestoreService.streamUploads(
  firestorePath: 'uploads',
  filterByUser: FirebaseAuth.instance.currentUser?.uid, // omit / null = no user filter
  orderBy: 'timestamp',
  descending: true,
  limit: 20,
).listen((uploads) {
  print('${uploads.length} files available');
});
```

`filterByUser`: pass a UID to restrict to that user. Pass **`null` to load all users’ uploads** (for example an admin dashboard). This matches `FirebaseUploader(filterByCurrentUser: false)`, which passes `null` internally.

## 🔒 Security Best Practices

1. **Firebase Storage Rules**: Ensure users can only access their own files
2. **Firestore Rules**: Implement proper read/write permissions
3. **File Validation**: Always validate file types and sizes
4. **Authentication**: Require authentication for sensitive uploads
5. **Content Scanning**: Consider implementing virus/malware scanning

## 🚀 Performance Tips

1. **Image Optimization**: Compress images before upload
2. **Lazy Loading**: Use pagination for large file lists
3. **Caching**: Implement proper image caching strategies
4. **Background Upload**: Handle uploads in background for large files
5. **Connection Monitoring**: Check connectivity before operations

## 📱 Platform Support

The widget uses `dart:io` `File` for picked paths, so it is aimed at **Android, iOS, and desktop** (macOS, Windows, Linux). **Web** is not supported by the current implementation without replacing file handling (for example `XFile` / bytes APIs and conditional imports).

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For issues and questions:
- [GitHub Issues](https://github.com/vipulbansal/firebase_uploader_plus/issues)
- [Documentation](https://github.com/vipulbansal/firebase_uploader_plus#readme)
- [Examples](https://github.com/vipulbansal/firebase_uploader_plus/tree/main/example)

## 📈 Changelog

See [CHANGELOG.md](CHANGELOG.md) for detailed version history.

## 💖 Support This Package

If you find this package useful, consider supporting my work:

[![Donate](https://img.shields.io/badge/Donate-PayPal-blue.svg)](https://paypal.me/vipulbansal?country.x=IN&locale.x=en_GB)
