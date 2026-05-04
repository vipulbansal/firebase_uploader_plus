import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/upload_metadata.dart';

class FirestoreService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Save upload metadata to Firestore
  static Future<String> saveUploadMetadata({
    required UploadMetadata metadata,
    required String firestorePath,
    String? customDocId,
  }) async {
    try {
      final collection = _firestore.collection(firestorePath);
      final docRef = customDocId != null
          ? collection.doc(customDocId)
          : collection.doc();

      final dataToSave = metadata.copyWith(
        id: docRef.id,
        uploadedBy: metadata.uploadedBy.isEmpty
            ? FirebaseAuth.instance.currentUser?.uid ?? 'anonymous'
            : metadata.uploadedBy,
      );

      await docRef.set(dataToSave.toFirestore());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to save metadata to Firestore: $e');
    }
  }

  /// Update upload metadata in Firestore
  static Future<void> updateUploadMetadata({
    required String documentId,
    required String firestorePath,
    required Map<String, dynamic> updates,
  }) async {
    try {
      await _firestore
          .collection(firestorePath)
          .doc(documentId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update metadata: $e');
    }
  }

  /// Soft delete a file (mark as deleted)
  static Future<void> softDeleteFile({
    required String documentId,
    required String firestorePath,
  }) async {
    try {
      await _firestore.collection(firestorePath).doc(documentId).update({
        'isDeleted': true,
        'deletedAt': Timestamp.now(),
      });
    } catch (e) {
      throw Exception('Failed to soft delete file: $e');
    }
  }

  /// Hard delete metadata from Firestore
  static Future<void> deleteUploadMetadata({
    required String documentId,
    required String firestorePath,
  }) async {
    try {
      await _firestore.collection(firestorePath).doc(documentId).delete();
    } catch (e) {
      throw Exception('Failed to delete metadata: $e');
    }
  }

  /// Get single upload metadata
  static Future<UploadMetadata?> getUploadMetadata({
    required String documentId,
    required String firestorePath,
  }) async {
    try {
      final doc = await _firestore
          .collection(firestorePath)
          .doc(documentId)
          .get();

      if (doc.exists) {
        return UploadMetadata.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get metadata: $e');
    }
  }

  /// Stream all uploads (real-time)
  static Stream<List<UploadMetadata>> streamUploads({
    required String firestorePath,
    bool includeDeleted = false,
    String? filterByUser,
    int? limit,
    String? orderBy = 'timestamp',
    bool descending = true,
  }) {
    try {
      Query query = _firestore.collection(firestorePath);

      // Filter by user only when a UID is passed (null = no user filter).
      if (filterByUser != null) {
        query = query.where('uploadedBy', isEqualTo: filterByUser);
      }

      // Filter deleted files
      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }

      // Order by specified field
      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => UploadMetadata.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to stream uploads: $e');
    }
  }

  /// Stream uploads by file type
  static Stream<List<UploadMetadata>> streamUploadsByType({
    required String firestorePath,
    required String fileType,
    bool includeDeleted = false,
    String? filterByUser,
    int? limit,
  }) {
    try {
      Query query = _firestore.collection(firestorePath);

      // Filter by file type
      query = query.where('fileType', isEqualTo: fileType);

      // Filter by user
      if (filterByUser != null) {
        query = query.where('uploadedBy', isEqualTo: filterByUser);
      }

      // Filter deleted files
      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }

      // Order by timestamp
      query = query.orderBy('timestamp', descending: true);

      // Apply limit
      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => UploadMetadata.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to stream uploads by type: $e');
    }
  }

  /// Get uploads with pagination
  static Future<List<UploadMetadata>> getUploadsPaginated({
    required String firestorePath,
    DocumentSnapshot? lastDocument,
    int limit = 20,
    bool includeDeleted = false,
    String? filterByUser,
  }) async {
    try {
      Query query = _firestore.collection(firestorePath);

      // Filter by user
      if (filterByUser != null) {
        query = query.where('uploadedBy', isEqualTo: filterByUser);
      }

      // Filter deleted files
      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }

      // Order by timestamp
      query = query.orderBy('timestamp', descending: true);

      // Start after last document for pagination
      if (lastDocument != null) {
        query = query.startAfterDocument(lastDocument);
      }

      // Apply limit
      query = query.limit(limit);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => UploadMetadata.fromFirestore(doc))
          .toList();
    } catch (e) {
      throw Exception('Failed to get paginated uploads: $e');
    }
  }

  /// Search uploads by filename
  static Stream<List<UploadMetadata>> searchUploads({
    required String firestorePath,
    required String searchTerm,
    bool includeDeleted = false,
    String? filterByUser,
  }) {
    try {
      Query query = _firestore.collection(firestorePath);

      // Filter by user
      if (filterByUser != null) {
        query = query.where('uploadedBy', isEqualTo: filterByUser);
      }

      // Filter deleted files
      if (!includeDeleted) {
        query = query.where('isDeleted', isEqualTo: false);
      }

      // Search by filename (basic text search)
      // Note: For advanced search, consider using Algolia or similar
      query = query
          .where('fileName', isGreaterThanOrEqualTo: searchTerm)
          .where('fileName', isLessThanOrEqualTo: '$searchTerm\uf8ff');

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => UploadMetadata.fromFirestore(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to search uploads: $e');
    }
  }

  /// Get upload statistics
  static Future<Map<String, dynamic>> getUploadStats({
    required String firestorePath,
    String? filterByUser,
  }) async {
    try {
      Query query = _firestore.collection(firestorePath);

      // Filter by user
      if (filterByUser != null) {
        query = query.where('uploadedBy', isEqualTo: filterByUser);
      }

      // Get all non-deleted uploads
      query = query.where('isDeleted', isEqualTo: false);

      final snapshot = await query.get();
      final uploads = snapshot.docs
          .map((doc) => UploadMetadata.fromFirestore(doc))
          .toList();

      // Calculate statistics
      int totalFiles = uploads.length;
      int totalSize = uploads.fold(
        0,
        (summ, upload) => summ + upload.fileSizeBytes,
      );

      Map<String, int> typeCount = {};
      for (final upload in uploads) {
        typeCount[upload.fileType] = (typeCount[upload.fileType] ?? 0) + 1;
      }

      return {
        'totalFiles': totalFiles,
        'totalSizeBytes': totalSize,
        'totalSizeFormatted': _formatBytes(totalSize),
        'fileTypeBreakdown': typeCount,
        'averageFileSize': totalFiles > 0 ? totalSize / totalFiles : 0,
      };
    } catch (e) {
      throw Exception('Failed to get upload statistics: $e');
    }
  }

  /// Batch operations for multiple files
  static Future<void> batchUpdateMetadata({
    required String firestorePath,
    required List<String> documentIds,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final batch = _firestore.batch();

      for (final docId in documentIds) {
        final docRef = _firestore.collection(firestorePath).doc(docId);
        batch.update(docRef, updates);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to batch update metadata: $e');
    }
  }

  /// Helper method to format bytes
  static String _formatBytes(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }
}
