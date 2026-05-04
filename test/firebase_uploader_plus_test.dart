import 'package:flutter_test/flutter_test.dart';
import 'package:firebase_uploader_plus/firebase_uploader_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

void main() {
  group('PathBuilder Tests', () {
    test('buildStoragePath creates correct path structure', () {
      final built = PathBuilder.buildStoragePath(
        basePath: 'uploads/test',
        fileName: 'test_file.pdf',
        userId: 'user123',
        includeTimestamp: false,
      );

      expect(built, equals('uploads/test/user123/test_file.pdf'));
    });

    test('buildStoragePath includes timestamp when enabled', () {
      final built = PathBuilder.buildStoragePath(
        basePath: 'uploads/test',
        fileName: 'test_file.pdf',
        userId: 'user123',
        includeTimestamp: true,
      );

      expect(built, contains('uploads/test/user123/'));
      expect(built, matches(RegExp(r'test_file_\d+\.pdf')));
    });

    test('sanitizeFileName replaces reserved characters', () {
      expect(
        PathBuilder.sanitizeFileName('bad:name<>file?.pdf'),
        equals('bad_name__file_.pdf'),
      );
    });

    test('getFileType returns correct type for extensions', () {
      expect(PathBuilder.getFileType('image.jpg'), equals('image'));
      expect(PathBuilder.getFileType('document.pdf'), equals('pdf'));
      expect(PathBuilder.getFileType('video.mp4'), equals('video'));
      expect(PathBuilder.getFileType('unknown.xyz'), equals('other'));
    });

    test('isAllowedExtension validates correctly', () {
      const allowedExtensions = ['jpg', 'png', 'pdf'];

      expect(
        PathBuilder.isAllowedExtension('file.jpg', allowedExtensions),
        isTrue,
      );
      expect(
        PathBuilder.isAllowedExtension('file.PDF', allowedExtensions),
        isTrue,
      );
      expect(
        PathBuilder.isAllowedExtension('file.txt', allowedExtensions),
        isFalse,
      );
    });

    test('buildDateOrganizedPath creates date structure', () {
      final date = DateTime(2024, 1, 15);
      final built = PathBuilder.buildDateOrganizedPath(
        basePath: 'uploads',
        date: date,
      );

      expect(built, equals('uploads/2024/01/15'));
    });
  });

  group('UploadMetadata Tests', () {
    test('fromMap creates correct model', () {
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

      final metadata = UploadMetadata.fromMap('doc123', docData);

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

      final copy = original.copyWith(
        fileName: 'new_name.pdf',
        fileSizeBytes: 2048,
      );

      expect(copy.fileName, equals('new_name.pdf'));
      expect(copy.fileSizeBytes, equals(2048));
      expect(copy.id, equals(original.id));
      expect(copy.uploadedBy, equals(original.uploadedBy));
    });
  });
}
