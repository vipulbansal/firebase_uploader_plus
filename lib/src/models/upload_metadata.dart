import 'package:cloud_firestore/cloud_firestore.dart';

class UploadMetadata {
  final String id;
  final String fileName;
  final String downloadUrl;
  final String uploadedBy;
  final DateTime timestamp;
  final String fileType;
  final int fileSizeBytes;
  final String storagePath;
  final bool isDeleted;
  final Map<String, dynamic>? customMetadata;

  UploadMetadata({
    required this.id,
    required this.fileName,
    required this.downloadUrl,
    required this.uploadedBy,
    required this.timestamp,
    required this.fileType,
    required this.fileSizeBytes,
    required this.storagePath,
    this.isDeleted = false,
    this.customMetadata,
  });

  factory UploadMetadata.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UploadMetadata(
      id: doc.id,
      fileName: data['fileName'] ?? '',
      downloadUrl: data['downloadUrl'] ?? '',
      uploadedBy: data['uploadedBy'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      fileType: data['fileType'] ?? '',
      fileSizeBytes: data['fileSizeBytes'] ?? 0,
      storagePath: data['storagePath'] ?? '',
      isDeleted: data['isDeleted'] ?? false,
      customMetadata: data['customMetadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fileName': fileName,
      'downloadUrl': downloadUrl,
      'uploadedBy': uploadedBy,
      'timestamp': Timestamp.fromDate(timestamp),
      'fileType': fileType,
      'fileSizeBytes': fileSizeBytes,
      'storagePath': storagePath,
      'isDeleted': isDeleted,
      if (customMetadata != null) 'customMetadata': customMetadata,
    };
  }

  String get formattedFileSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  String get fileExtension {
    return fileName.split('.').last.toLowerCase();
  }

  bool get isImage {
    const imageExtensions = ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp'];
    return imageExtensions.contains(fileExtension);
  }

  bool get isPdf {
    return fileExtension == 'pdf';
  }

  bool get isVideo {
    const videoExtensions = ['mp4', 'mov', 'avi', 'mkv', 'webm'];
    return videoExtensions.contains(fileExtension);
  }

  bool get isDocument {
    const docExtensions = ['doc', 'docx', 'txt', 'rtf'];
    return docExtensions.contains(fileExtension);
  }

  UploadMetadata copyWith({
    String? id,
    String? fileName,
    String? downloadUrl,
    String? uploadedBy,
    DateTime? timestamp,
    String? fileType,
    int? fileSizeBytes,
    String? storagePath,
    bool? isDeleted,
    Map<String, dynamic>? customMetadata,
  }) {
    return UploadMetadata(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      downloadUrl: downloadUrl ?? this.downloadUrl,
      uploadedBy: uploadedBy ?? this.uploadedBy,
      timestamp: timestamp ?? this.timestamp,
      fileType: fileType ?? this.fileType,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      storagePath: storagePath ?? this.storagePath,
      isDeleted: isDeleted ?? this.isDeleted,
      customMetadata: customMetadata ?? this.customMetadata,
    );
  }

  @override
  String toString() {
    return 'UploadMetadata(id: $id, fileName: $fileName, fileType: $fileType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UploadMetadata && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}