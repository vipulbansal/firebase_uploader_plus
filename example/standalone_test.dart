/// Standalone PathBuilder Testing Utility
/// Run this to test PathBuilder functionality without Firebase setup
/// Usage: dart run example/standalone_test.dart

import '../lib/src/utils/path_builder.dart';

void main() {
  print('=== Firebase Uploader Plus - PathBuilder Test ===\n');
  
  // Test file sanitization
  print('1. File Sanitization Tests:');
  testFileSanitization();
  
  print('\n2. File Type Detection Tests:');
  testFileTypeDetection();
  
  print('\n3. Extension Validation Tests:');
  testExtensionValidation();
  
  print('\n4. MIME Type Tests:');
  testMimeTypes();
  
  print('\n5. Path Building Tests (without Firebase):');
  testPathBuilding();
  
  print('\n6. Storage Path Parsing Tests:');
  testPathParsing();
  
  print('\n=== All PathBuilder Tests Complete ===');
}

void testFileSanitization() {
  final testCases = [
    'normal_file.pdf',
    'file with spaces.doc',
    'unsafe<>chars.txt',
    'path/with/slashes.jpg',
    'file"with"quotes.png',
    'very_long_filename_that_exceeds_normal_limits_and_should_be_truncated_automatically_by_the_sanitization_function_to_prevent_filesystem_issues_and_ensure_compatibility_across_different_platforms_and_storage_systems.pdf',
  ];
  
  for (final fileName in testCases) {
    final sanitized = PathBuilder.sanitizeFileName(fileName);
    print('  "$fileName" → "$sanitized"');
  }
}

void testFileTypeDetection() {
  final testFiles = [
    'document.pdf',
    'report.docx',
    'photo.jpg',
    'video.mp4',
    'song.mp3',
    'data.txt',
    'archive.zip',
    'unknown.xyz',
  ];
  
  for (final file in testFiles) {
    final type = PathBuilder.getFileType(file);
    print('  $file → Type: $type');
  }
}

void testExtensionValidation() {
  final allowedExtensions = ['pdf', 'doc', 'docx', 'jpg', 'png'];
  final testFiles = [
    'report.pdf',
    'document.docx',
    'image.jpg',
    'presentation.pptx',
    'video.mp4',
    'archive.zip',
  ];
  
  print('  Allowed extensions: ${allowedExtensions.join(', ')}');
  for (final file in testFiles) {
    final isAllowed = PathBuilder.isAllowedExtension(file, allowedExtensions);
    print('  $file → ${isAllowed ? "✓ Allowed" : "✗ Blocked"}');
  }
}

void testMimeTypes() {
  final testFiles = [
    'document.pdf',
    'image.jpg',
    'image.png',
    'video.mp4',
    'audio.mp3',
    'text.txt',
    'archive.zip',
    'unknown.xyz',
  ];
  
  for (final file in testFiles) {
    final mimeType = PathBuilder.getMimeType(file);
    print('  $file → $mimeType');
  }
}

void testPathBuilding() {
  print('  Note: These tests simulate path building without actual Firebase Auth');
  
  // Test basic storage path building
  final basicPath = PathBuilder.buildStoragePath(
    basePath: 'uploads/documents',
    fileName: 'my_report.pdf',
    userId: 'test_user_123',
    includeTimestamp: false,
  );
  print('  Basic path: $basicPath');
  
  // Test hierarchical path building
  final hierarchicalPath = PathBuilder.buildHierarchicalPath(
    basePath: 'uploads',
    fileName: 'presentation.pptx',
    category: 'Business Documents',
    userId: 'user_456',
    includeDate: true,
    includeTimestamp: false,
  );
  print('  Hierarchical path: $hierarchicalPath');
  
  // Test collection path building
  final collectionPath = PathBuilder.buildCollectionPath(
    basePath: 'user/documents',
    collectionPrefix: 'metadata',
  );
  print('  Collection path: $collectionPath');
  
  // Test document ID generation
  final docId = PathBuilder.generateDocumentId(
    userId: 'user_789',
    fileName: 'important_file.pdf',
  );
  print('  Document ID: $docId');
}

void testPathParsing() {
  final testPaths = [
    'uploads/user123/document.pdf',
    'uploads/documents/2024/06/user456/report_1234567890.docx',
    'images/user789/photo.jpg',
    'simple_file.txt',
  ];
  
  for (final path in testPaths) {
    final parsed = PathBuilder.parseStoragePath(path);
    print('  Path: $path');
    print('    Base: ${parsed['basePath']}');
    print('    User: ${parsed['userId']}');
    print('    File: ${parsed['fileName']}');
    print('    Category: ${parsed['category']}');
    print('');
  }
}