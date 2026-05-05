import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import 'models/upload_metadata.dart';
import 'firebase_storage_helper.dart';
import 'firestore_service.dart';
import 'utils/path_builder.dart';

class FirebaseUploader extends StatefulWidget {
  final List<String> allowedExtensions;
  final String firestorePath;
  final String firebaseStoragePath;
  final bool enablePreview;
  final bool enableCamera;
  final bool enableMultipleFiles;
  final bool filterByCurrentUser;
  final int? maxFileSize;
  final Function(UploadMetadata)? onUploadComplete;
  final Function(String)? onUploadError;
  final Function(double)? onUploadProgress;
  final Widget Function(BuildContext, UploadMetadata)? fileTileBuilder;
  final Widget Function(BuildContext)? headerBuilder;
  final Widget Function(BuildContext)? emptyStateBuilder;
  final Map<String, String>? customMetadata;

  const FirebaseUploader({
    super.key,
    this.allowedExtensions = const [],
    required this.firestorePath,
    required this.firebaseStoragePath,
    this.enablePreview = true,
    this.enableCamera = true,
    this.enableMultipleFiles = false,
    this.filterByCurrentUser = true,
    this.maxFileSize,
    this.onUploadComplete,
    this.onUploadError,
    this.onUploadProgress,
    this.fileTileBuilder,
    this.headerBuilder,
    this.emptyStateBuilder,
    this.customMetadata,
  });

  @override
  State<FirebaseUploader> createState() => _FirebaseUploaderState();
}

class _FirebaseUploaderState extends State<FirebaseUploader> {
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _uploadingFileName;
  List<File> _pendingUploads = [];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.headerBuilder != null)
          widget.headerBuilder!(context)
        else
          _buildDefaultHeader(),

        if (_isUploading) _buildUploadProgress(),

        Expanded(
          child: StreamBuilder<List<UploadMetadata>>(
            stream: FirestoreService.streamUploads(
              firestorePath: widget.firestorePath,
              filterByUser: widget.filterByCurrentUser
                  ? FirebaseAuth.instance.currentUser?.uid
                  : null,
            ),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              final uploads = snapshot.data ?? [];

              if (uploads.isEmpty) {
                return widget.emptyStateBuilder?.call(context) ??
                    _buildEmptyState();
              }

              return _buildFilesList(uploads);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickFiles,
                  icon: const Icon(Icons.attach_file),
                  label: Text(
                    widget.enableMultipleFiles ? 'Pick Files' : 'Pick File',
                  ),
                ),
              ),
              if (widget.enableCamera) ...[
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: _isUploading ? null : _pickImageFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: const Text('Camera'),
                ),
              ],
            ],
          ),
          if (widget.allowedExtensions.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Allowed: ${widget.allowedExtensions.join(", ")}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              const CircularProgressIndicator(strokeWidth: 2),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Uploading: ${_uploadingFileName ?? "File"}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: _uploadProgress),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${(_uploadProgress * 100).toStringAsFixed(1)}% complete',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(child: CircularProgressIndicator());
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Error loading files',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.cloud_upload_outlined, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No files uploaded yet',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap the button above to upload your first file',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildFilesList(List<UploadMetadata> uploads) {
    return ListView.builder(
      itemCount: uploads.length,
      itemBuilder: (context, index) {
        final upload = uploads[index];
        return widget.fileTileBuilder?.call(context, upload) ??
            _buildDefaultFileTile(upload);
      },
    );
  }

  Widget _buildDefaultFileTile(UploadMetadata upload) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: _buildFileIcon(upload),
        title: Text(
          upload.fileName,
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${upload.formattedFileSize} • ${upload.fileType}'),
            Text(
              _formatDate(upload.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleFileAction(value, upload),
          itemBuilder: (context) => [
            const PopupMenuItem(
              value: 'download',
              child: ListTile(
                leading: Icon(Icons.download),
                title: Text('Download'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'share',
              child: ListTile(
                leading: Icon(Icons.share),
                title: Text('Share'),
                dense: true,
              ),
            ),
            const PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: Icon(Icons.delete, color: Colors.red),
                title: Text('Delete', style: TextStyle(color: Colors.red)),
                dense: true,
              ),
            ),
          ],
        ),
        onTap: widget.enablePreview ? () => _previewFile(upload) : null,
      ),
    );
  }

  Widget _buildFileIcon(UploadMetadata upload) {
    if (upload.isImage && widget.enablePreview) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(4),
        child: CachedNetworkImage(
          imageUrl: upload.downloadUrl,
          width: 40,
          height: 40,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            width: 40,
            height: 40,
            color: Colors.grey[300],
            child: const Icon(Icons.image, size: 20),
          ),
          errorWidget: (context, url, error) => Container(
            width: 40,
            height: 40,
            color: Colors.grey[300],
            child: const Icon(Icons.broken_image, size: 20),
          ),
        ),
      );
    }

    IconData iconData;
    Color iconColor;

    switch (upload.fileType) {
      case 'pdf':
        iconData = Icons.picture_as_pdf;
        iconColor = Colors.red;
        break;
      case 'image':
        iconData = Icons.image;
        iconColor = Colors.blue;
        break;
      case 'video':
        iconData = Icons.video_file;
        iconColor = Colors.purple;
        break;
      case 'document':
        iconData = Icons.description;
        iconColor = Colors.blue;
        break;
      case 'audio':
        iconData = Icons.audio_file;
        iconColor = Colors.orange;
        break;
      default:
        iconData = Icons.insert_drive_file;
        iconColor = Colors.grey;
    }

    return CircleAvatar(
      backgroundColor: iconColor.withValues(alpha: 0.1),
      child: Icon(iconData, color: iconColor),
    );
  }

  Future<void> _pickFiles() async {
    try {
      final result = await FilePicker.pickFiles(
        allowMultiple: widget.enableMultipleFiles,
        allowedExtensions: widget.allowedExtensions.isNotEmpty
            ? widget.allowedExtensions
            : null,
        type: widget.allowedExtensions.isNotEmpty
            ? FileType.custom
            : FileType.any,
      );

      if (result != null) {
        final files = result.files
            .where((file) => file.path != null)
            .map((file) => File(file.path!))
            .toList();

        await _uploadFiles(files);
      }
    } catch (e) {
      widget.onUploadError?.call('Failed to pick files: $e');
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (image != null) {
        await _uploadFiles([File(image.path)]);
      }
    } catch (e) {
      widget.onUploadError?.call('Failed to capture image: $e');
    }
  }

  Future<void> _uploadFiles(List<File> files) async {
    // Check connectivity
    final connectivityResult = await Connectivity().checkConnectivity();
    if (connectivityResult.contains(ConnectivityResult.none)) {
      widget.onUploadError?.call('No internet connection');
      return;
    }

    // Validate files
    for (final file in files) {
      if (!_validateFile(file)) {
        return;
      }
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _pendingUploads = files;
    });

    try {
      for (int i = 0; i < files.length; i++) {
        final file = files[i];
        setState(() {
          _uploadingFileName = PathBuilder.sanitizeFileName(
            file.path.split('/').last,
          );
        });

        // Upload to Firebase Storage
        final uploadMetadata = await FirebaseStorageHelper.uploadFile(
          file: file,
          storagePath: widget.firebaseStoragePath,
          onProgress: (progress) {
            setState(() {
              _uploadProgress = (i + progress) / files.length;
            });
            widget.onUploadProgress?.call(_uploadProgress);
          },
          customMetadata: widget.customMetadata,
        );

        // Save metadata to Firestore
        await FirestoreService.saveUploadMetadata(
          metadata: uploadMetadata,
          firestorePath: widget.firestorePath,
        );

        widget.onUploadComplete?.call(uploadMetadata);
      }
    } catch (e) {
      widget.onUploadError?.call('Upload failed: $e');
    } finally {
      setState(() {
        _isUploading = false;
        _uploadProgress = 0.0;
        _uploadingFileName = null;
        _pendingUploads.clear();
      });
    }
  }

  bool _validateFile(File file) {
    // Check file size
    if (widget.maxFileSize != null) {
      final fileSize = file.lengthSync();
      if (fileSize > widget.maxFileSize!) {
        widget.onUploadError?.call(
          'File too large. Maximum size: ${(widget.maxFileSize! / (1024 * 1024)).toStringAsFixed(1)} MB',
        );
        return false;
      }
    }

    // Check file extension
    final fileName = file.path.split('/').last;
    if (!PathBuilder.isAllowedExtension(fileName, widget.allowedExtensions)) {
      widget.onUploadError?.call(
        'File type not allowed. Allowed: ${widget.allowedExtensions.join(", ")}',
      );
      return false;
    }

    return true;
  }

  void _handleFileAction(String action, UploadMetadata upload) {
    switch (action) {
      case 'download':
        _downloadFile(upload);
        break;
      case 'share':
        _shareFile(upload);
        break;
      case 'delete':
        _deleteFile(upload);
        break;
    }
  }

  void _downloadFile(UploadMetadata upload) {
    // Open download URL in browser
    // Note: For mobile apps, you might want to implement actual file download
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Download: ${upload.fileName}'),
        action: SnackBarAction(
          label: 'Copy URL',
          onPressed: () {
            // Copy URL to clipboard
          },
        ),
      ),
    );
  }

  void _shareFile(UploadMetadata upload) {
    // Implement sharing functionality
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Share: ${upload.fileName}')));
  }

  Future<void> _deleteFile(UploadMetadata upload) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete File'),
        content: Text('Are you sure you want to delete "${upload.fileName}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        // Delete from Firebase Storage
        await FirebaseStorageHelper.deleteFile(upload.storagePath);

        // Delete metadata from Firestore
        await FirestoreService.deleteUploadMetadata(
          documentId: upload.id,
          firestorePath: widget.firestorePath,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Deleted ${upload.fileName}')));
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _previewFile(UploadMetadata upload) {
    // Show file preview dialog
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 500, maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: Text(upload.fileName),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: upload.isImage
                    ? CachedNetworkImage(
                        imageUrl: upload.downloadUrl,
                        fit: BoxFit.contain,
                        placeholder: (context, url) =>
                            const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) =>
                            const Center(child: Icon(Icons.error)),
                      )
                    : Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.description,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              upload.fileName,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${upload.formattedFileSize} • ${upload.fileType}',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 7) {
      return '${date.day}/${date.month}/${date.year}';
    } else if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }
}
