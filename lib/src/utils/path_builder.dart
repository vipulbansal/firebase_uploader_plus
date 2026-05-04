import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as path;

/// Utility class for building smart auto-paths for Firebase Storage
class PathBuilder {
  /// Builds a smart auto-path for Firebase Storage
  /// Pattern: {basePath}/{uid}/{timestamp}_{filename}
  static String buildStoragePath({
    required String basePath,
    required String fileName,
    String? userId,
    bool includeTimestamp = true,
  }) {
    final cleanBasePath = basePath.replaceAll(RegExp(r'^/+|/+$'), '');
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    String finalFileName = fileName;
    if (includeTimestamp) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(fileName);
      final nameWithoutExt = path.basenameWithoutExtension(fileName);
      finalFileName = '${nameWithoutExt}_$timestamp$extension';
    }

    return '$cleanBasePath/$uid/$finalFileName';
  }

  /// Date-only path segments: `{basePath}/{year}/{month}/{day}`.
  static String buildDateOrganizedPath({
    required String basePath,
    required DateTime date,
  }) {
    final cleanBasePath = basePath.replaceAll(RegExp(r'^/+|/+$'), '');
    final y = date.year.toString();
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$cleanBasePath/$y/$m/$d';
  }

  /// Builds a collection path for Firestore metadata storage
  /// Pattern: {collectionName}_{basePath}
  static String buildCollectionPath({
    required String basePath,
    String collectionPrefix = 'uploads',
  }) {
    final cleanBasePath = basePath.replaceAll(RegExp(r'[^a-zA-Z0-9_]'), '_');
    return '${collectionPrefix}_$cleanBasePath';
  }

  /// Sanitizes a filename for safe storage
  static String sanitizeFileName(String fileName) {
    // Remove or replace unsafe characters
    String sanitized = fileName.replaceAll(RegExp(r'[<>:"/\\|?*]'), '_');

    // Limit length to prevent issues
    if (sanitized.length > 255) {
      final extension = path.extension(sanitized);
      final nameWithoutExt = path.basenameWithoutExtension(sanitized);
      final maxNameLength = 255 - extension.length;
      sanitized = '${nameWithoutExt.substring(0, maxNameLength)}$extension';
    }

    return sanitized;
  }

  /// Generates a unique document ID for Firestore
  static String generateDocumentId({String? userId, String? fileName}) {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';
    final shortUid = uid.length > 8 ? uid.substring(0, 8) : uid;

    if (fileName != null) {
      final nameWithoutExt = path.basenameWithoutExtension(fileName);
      final shortName = nameWithoutExt.length > 20
          ? nameWithoutExt.substring(0, 20)
          : nameWithoutExt;
      return '${shortUid}_${shortName}_$timestamp';
    }

    return '${shortUid}_$timestamp';
  }

  /// Creates a hierarchical path structure for organized storage
  /// Pattern: {basePath}/{category}/{year}/{month}/{uid}/{filename}
  static String buildHierarchicalPath({
    required String basePath,
    required String fileName,
    String? category,
    String? userId,
    bool includeTimestamp = true,
    bool includeDate = false,
  }) {
    final cleanBasePath = basePath.replaceAll(RegExp(r'^/+|/+$'), '');
    final uid = userId ?? FirebaseAuth.instance.currentUser?.uid ?? 'anonymous';

    List<String> pathSegments = [cleanBasePath];

    if (category != null && category.isNotEmpty) {
      pathSegments.add(category.toLowerCase().replaceAll(' ', '_'));
    }

    if (includeDate) {
      final now = DateTime.now();
      pathSegments.addAll([
        now.year.toString(),
        now.month.toString().padLeft(2, '0'),
      ]);
    }

    pathSegments.add(uid);

    String finalFileName = sanitizeFileName(fileName);
    if (includeTimestamp) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final extension = path.extension(finalFileName);
      final nameWithoutExt = path.basenameWithoutExtension(finalFileName);
      finalFileName = '${nameWithoutExt}_$timestamp$extension';
    }

    pathSegments.add(finalFileName);

    return pathSegments.join('/');
  }

  /// Extracts metadata from a storage path
  static Map<String, String?> parseStoragePath(String storagePath) {
    final segments = storagePath.split('/');

    return {
      'basePath': segments.isNotEmpty ? segments[0] : null,
      'userId': segments.length > 1 ? segments[1] : null,
      'fileName': segments.isNotEmpty ? segments.last : null,
      'category': segments.length > 2 ? segments[1] : null,
      'fullPath': storagePath,
    };
  }

  /// Check if a file extension is allowed
  static bool isAllowedExtension(
    String fileName,
    List<String> allowedExtensions,
  ) {
    if (allowedExtensions.isEmpty) return true;

    final extension = path.extension(fileName).toLowerCase();
    return allowedExtensions.any(
      (ext) =>
          extension ==
          (ext.startsWith('.') ? ext.toLowerCase() : '.${ext.toLowerCase()}'),
    );
  }

  /// Get file type category based on extension
  static String getFileType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    switch (extension) {
      case '.pdf':
        return 'pdf';
      case '.doc':
      case '.docx':
        return 'document';
      case '.jpg':
      case '.jpeg':
      case '.png':
      case '.gif':
      case '.webp':
        return 'image';
      case '.mp4':
      case '.avi':
      case '.mov':
      case '.wmv':
        return 'video';
      case '.mp3':
      case '.wav':
      case '.aac':
      case '.flac':
        return 'audio';
      case '.txt':
      case '.md':
      case '.rtf':
        return 'text';
      case '.zip':
      case '.rar':
      case '.7z':
        return 'archive';
      default:
        return 'other';
    }
  }

  /// Get MIME type for a file
  static String getMimeType(String fileName) {
    final extension = path.extension(fileName).toLowerCase();

    switch (extension) {
      case '.pdf':
        return 'application/pdf';
      case '.doc':
        return 'application/msword';
      case '.docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.webp':
        return 'image/webp';
      case '.mp4':
        return 'video/mp4';
      case '.avi':
        return 'video/x-msvideo';
      case '.mov':
        return 'video/quicktime';
      case '.mp3':
        return 'audio/mpeg';
      case '.wav':
        return 'audio/wav';
      case '.txt':
        return 'text/plain';
      case '.md':
        return 'text/markdown';
      case '.zip':
        return 'application/zip';
      default:
        return 'application/octet-stream';
    }
  }
}
