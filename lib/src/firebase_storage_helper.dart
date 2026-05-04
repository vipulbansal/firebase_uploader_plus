import 'dart:async';
import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'models/upload_metadata.dart';
import 'utils/path_builder.dart';

class FirebaseStorageHelper {
  static final FirebaseStorage _storage = FirebaseStorage.instance;

  /// Upload file to Firebase Storage with progress tracking
  static Future<UploadMetadata> uploadFile({
    required File file,
    required String storagePath,
    Function(double)? onProgress,
    Map<String, String>? customMetadata,
  }) async {
    try {
      final fileName = path.basename(file.path);
      final sanitizedFileName = PathBuilder.sanitizeFileName(fileName);
      final fullPath = PathBuilder.buildStoragePath(
        basePath: storagePath,
        fileName: sanitizedFileName,
      );

      final ref = _storage.ref().child(fullPath);

      // Set metadata
      final metadata = SettableMetadata(
        contentType: _getContentType(fileName),
        customMetadata: customMetadata ?? {},
      );

      final uploadTask = ref.putFile(file, metadata);

      final progressSub = uploadTask.snapshotEvents.listen((
        TaskSnapshot snapshot,
      ) {
        final total = snapshot.totalBytes;
        final progress = total > 0 ? snapshot.bytesTransferred / total : 0.0;
        onProgress?.call(progress);
      });

      TaskSnapshot snapshot;
      try {
        snapshot = await uploadTask;
      } finally {
        await progressSub.cancel();
      }
      final downloadUrl = await snapshot.ref.getDownloadURL();
      final fileStats = await file.stat();

      return UploadMetadata(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        fileName: fileName,
        downloadUrl: downloadUrl,
        uploadedBy: '', // Will be set by the calling service
        timestamp: DateTime.now(),
        fileType: PathBuilder.getFileType(fileName),
        fileSizeBytes: fileStats.size,
        storagePath: fullPath,
        customMetadata: customMetadata,
      );
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  /// Delete file from Firebase Storage
  static Future<void> deleteFile(String storagePath) async {
    try {
      await _storage.ref().child(storagePath).delete();
    } catch (e) {
      throw Exception('Failed to delete file: $e');
    }
  }

  /// Get file metadata from Firebase Storage
  static Future<FullMetadata> getFileMetadata(String storagePath) async {
    try {
      return await _storage.ref().child(storagePath).getMetadata();
    } catch (e) {
      throw Exception('Failed to get file metadata: $e');
    }
  }

  /// Update file metadata in Firebase Storage
  static Future<void> updateFileMetadata(
    String storagePath,
    Map<String, String> customMetadata,
  ) async {
    try {
      final metadata = SettableMetadata(customMetadata: customMetadata);
      await _storage.ref().child(storagePath).updateMetadata(metadata);
    } catch (e) {
      throw Exception('Failed to update file metadata: $e');
    }
  }

  /// Get download URL for a file
  static Future<String> getDownloadUrl(String storagePath) async {
    try {
      return await _storage.ref().child(storagePath).getDownloadURL();
    } catch (e) {
      throw Exception('Failed to get download URL: $e');
    }
  }

  /// List files in a storage path
  static Future<List<Reference>> listFiles(String storagePath) async {
    try {
      final result = await _storage.ref().child(storagePath).listAll();
      return result.items;
    } catch (e) {
      throw Exception('Failed to list files: $e');
    }
  }

  /// Check if file exists in storage
  static Future<bool> fileExists(String storagePath) async {
    try {
      await _storage.ref().child(storagePath).getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Uploads files in order; stops and rethrows on the first failure.
  static Future<List<UploadMetadata>> uploadMultipleFiles({
    required List<File> files,
    required String storagePath,
    Function(int completed, int total)? onBatchProgress,
    Function(String fileName, double progress)? onFileProgress,
    Map<String, String>? customMetadata,
  }) async {
    final results = <UploadMetadata>[];
    int completed = 0;

    for (final file in files) {
      try {
        final result = await uploadFile(
          file: file,
          storagePath: storagePath,
          onProgress: (progress) {
            onFileProgress?.call(path.basename(file.path), progress);
          },
          customMetadata: customMetadata,
        );

        results.add(result);
        completed++;
        onBatchProgress?.call(completed, files.length);
      } catch (e) {
        completed++;
        onBatchProgress?.call(completed, files.length);
        rethrow;
      }
    }

    return results;
  }

  /// Resume upload (for large files)
  static UploadTask resumableUpload({
    required File file,
    required String storagePath,
    Map<String, String>? customMetadata,
  }) {
    final fileName = path.basename(file.path);
    final sanitizedFileName = PathBuilder.sanitizeFileName(fileName);
    final fullPath = PathBuilder.buildStoragePath(
      basePath: storagePath,
      fileName: sanitizedFileName,
    );

    final ref = _storage.ref().child(fullPath);
    final metadata = SettableMetadata(
      contentType: _getContentType(fileName),
      customMetadata: customMetadata ?? {},
    );

    return ref.putFile(file, metadata);
  }

  /// Get content type based on file extension
  static String _getContentType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.txt':
        return 'text/plain';
      case '.mp4':
        return 'video/mp4';
      case '.mov':
        return 'video/quicktime';
      case '.avi':
        return 'video/x-msvideo';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.zip':
        return 'application/zip';
      case '.json':
        return 'application/json';
      case '.xml':
        return 'application/xml';
      default:
        return 'application/octet-stream';
    }
  }
}
