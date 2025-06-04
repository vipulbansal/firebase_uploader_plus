import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_uploader_plus/firebase_uploader_plus.dart';
import 'package:firebase_uploader_plus/src/utils/path_builder.dart';
import 'package:firebase_uploader_plus/src/models/upload_metadata.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('PathBuilder Tests', () {
    test('buildStoragePath creates correct path structure', () {
      final path = PathBuilder.buildStoragePath(
        basePath: 'uploads/test',
        fileName: 'test_file.pdf',
        userId: 'user123',
        includeTimestamp: false,
      );
      
      expect(path, equals('uploads/test/user123/test_file.pdf'));
    });

    test('buildStoragePath includes timestamp when enabled', () {
      final path = PathBuilder.buildStoragePath(
        basePath: 'uploads/test',
        fileName: 'test_file.pdf',
        userId: 'user123',
        includeTimestamp: true,
      );
      
      expect(path, contains('uploads/test/user123/'));
      expect(path, contains('_test_file.pdf'));
    });

    test('sanitizeFileName removes special characters', () {
      final sanitized = PathBuilder.sanitizeFileName('Test File (1).pdf');
      expect(sanitized, equals('test_file_1.pdf'));
    });

    test('getFileType returns correct type for extensions', () {
      expect(PathBuilder.getFileType('image.jpg'), equals('image'));
      expect(PathBuilder.getFileType('document.pdf'), equals('pdf'));
      expect(PathBuilder.getFileType('video.mp4'), equals('video'));
      expect(PathBuilder.getFileType('unknown.xyz'), equals('unknown'));
    });

    test('isAllowedExtension validates correctly', () {
      const allowedExtensions = ['jpg', 'png', 'pdf'];
      
      expect(PathBuilder.isAllowedExtension('file.jpg', allowedExtensions), isTrue);
      expect(PathBuilder.isAllowedExtension('file.PDF', allowedExtensions), isTrue);
      expect(PathBuilder.isAllowedExtension('file.txt', allowedExtensions), isFalse);
    });

    test('buildDateOrganizedPath creates date structure', () {
      final date = DateTime(2024, 1, 15);
      final path = PathBuilder.buildDateOrganizedPath(
        basePath: 'uploads',
        date: date,
      );
      
      expect(path, equals('uploads/2024/01/15'));
    });
  });

  group('UploadMetadata Tests', () {
    test('fromFirestore creates correct model', () {
      final docData = {
        'fileName': 'test.pdf',
        'downloadUrl': 'https://example.com/test.pdf',
        'uploadedBy': 'user123',
        'timestamp': Timestamp.fromDate(DateTime(2024, 1, 15)),
        'fileType': 'pdf',
        'fileSizeBytes': 1024,
        'storagePath': 'uploads/test.pdf',
        'isDeleted': false,
      };

      final doc = MockDocumentSnapshot(id: 'doc123', data: docData);
      final metadata = UploadMetadata.fromFirestore(doc);

      expect(metadata.id, equals('doc123'));
      expect(metadata.fileName, equals('test.pdf'));
      expect(metadata.fileType, equals('pdf'));
      expect(metadata.fileSizeBytes, equals(1024));
      expect(metadata.isDeleted, isFalse);
    });

    test('toFirestore creates correct map', () {
      final metadata = UploadMetadata(
        id: 'test123',
        fileName: 'test.pdf',
        downloadUrl: 'https://example.com/test.pdf',
        uploadedBy: 'user123',
        timestamp: DateTime(2024, 1, 15),
        fileType: 'pdf',
        fileSizeBytes: 1024,
        storagePath: 'uploads/test.pdf',
        isDeleted: false,
      );

      final map = metadata.toFirestore();

      expect(map['fileName'], equals('test.pdf'));
      expect(map['fileType'], equals('pdf'));
      expect(map['fileSizeBytes'], equals(1024));
      expect(map['isDeleted'], isFalse);
      expect(map['timestamp'], isA<Timestamp>());
    });

    test('formattedFileSize returns correct format', () {
      final metadata1 = UploadMetadata(
        id: 'test',
        fileName: 'test.pdf',
        downloadUrl: 'url',
        uploadedBy: 'user',
        timestamp: DateTime.now(),
        fileType: 'pdf',
        fileSizeBytes: 512,
        storagePath: 'path',
      );

      final metadata2 = UploadMetadata(
        id: 'test',
        fileName: 'test.pdf',
        downloadUrl: 'url',
        uploadedBy: 'user',
        timestamp: DateTime.now(),
        fileType: 'pdf',
        fileSizeBytes: 1536,
        storagePath: 'path',
      );

      final metadata3 = UploadMetadata(
        id: 'test',
        fileName: 'test.pdf',
        downloadUrl: 'url',
        uploadedBy: 'user',
        timestamp: DateTime.now(),
        fileType: 'pdf',
        fileSizeBytes: 2097152,
        storagePath: 'path',
      );

      expect(metadata1.formattedFileSize, equals('512 B'));
      expect(metadata2.formattedFileSize, equals('1.5 KB'));
      expect(metadata3.formattedFileSize, equals('2.0 MB'));
    });

    test('file type getters work correctly', () {
      final imageMetadata = UploadMetadata(
        id: 'test',
        fileName: 'image.jpg',
        downloadUrl: 'url',
        uploadedBy: 'user',
        timestamp: DateTime.now(),
        fileType: 'image',
        fileSizeBytes: 1024,
        storagePath: 'path',
      );

      final pdfMetadata = UploadMetadata(
        id: 'test',
        fileName: 'document.pdf',
        downloadUrl: 'url',
        uploadedBy: 'user',
        timestamp: DateTime.now(),
        fileType: 'pdf',
        fileSizeBytes: 1024,
        storagePath: 'path',
      );

      expect(imageMetadata.isImage, isTrue);
      expect(imageMetadata.isPdf, isFalse);
      expect(pdfMetadata.isImage, isFalse);
      expect(pdfMetadata.isPdf, isTrue);
    });

    test('copyWith creates modified copy', () {
      final original = UploadMetadata(
        id: 'test',
        fileName: 'test.pdf',
        downloadUrl: 'url',
        uploadedBy: 'user',
        timestamp: DateTime.now(),
        fileType: 'pdf',
        fileSizeBytes: 1024,
        storagePath: 'path',
      );

      final copy = original.copyWith(fileName: 'new_name.pdf', fileSizeBytes: 2048);

      expect(copy.fileName, equals('new_name.pdf'));
      expect(copy.fileSizeBytes, equals(2048));
      expect(copy.id, equals(original.id)); // unchanged
      expect(copy.uploadedBy, equals(original.uploadedBy)); // unchanged
    });
  });
}

// Mock class for testing
class MockDocumentSnapshot implements DocumentSnapshot {
  @override
  final String id;
  final Map<String, dynamic> _data;

  MockDocumentSnapshot({required this.id, required Map<String, dynamic> data})
      : _data = data;

  @override
  Map<String, dynamic>? data() => _data;

  @override
  bool get exists => true;

  // Implement other required methods with basic implementations
  @override
  DocumentReference get reference => throw UnimplementedError();

  @override
  SnapshotMetadata get metadata => throw UnimplementedError();

  @override
  dynamic operator [](Object field) => _data[field];

  @override
  dynamic get(Object field) => _data[field];
}