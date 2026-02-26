import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../share/services/image_upload_service.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/app_button.dart';
import '../../share/widgets/app_card.dart';
import '../../share/widgets/app_scaffold.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final ImageUploadService _uploadService = ImageUploadService();

  final List<_ScanItem> _uploads = [
    _ScanItem(name: 'Oak_leaf.png', status: 'Completed', time: '2m ago'),
    _ScanItem(name: 'Pine_branch.jpg', status: 'Processing', time: '8m ago'),
    _ScanItem(name: 'Maple_spot.jpeg', status: 'Queued', time: '15m ago'),
  ];

  XFile? _selectedImage;
  String? _statusMessage;
  _UploadStatus _uploadStatus = _UploadStatus.idle;

  bool get _isUploading => _uploadStatus == _UploadStatus.uploading;

  Future<void> _pickFromCameraFlow() async {
    if (_isUploading) return;

    while (mounted) {
      final capturedImage = await _picker.pickImage(source: ImageSource.camera);
      if (capturedImage == null) {
        return;
      }

      final action = await _showCaptureLeafPreview(capturedImage);
      if (!mounted) return;

      if (action == _CaptureLeafAction.confirm) {
        setState(() {
          _selectedImage = capturedImage;
          _statusMessage = null;
          _uploadStatus = _UploadStatus.idle;
        });
        return;
      }

      if (action != _CaptureLeafAction.retake) {
        return;
      }
    }
  }

  Future<_CaptureLeafAction?> _showCaptureLeafPreview(XFile image) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return showModalBottomSheet<_CaptureLeafAction>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surface,
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.arrow_back),
                      ),
                      Expanded(
                        child: Text(
                          'Capture Leaf',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleLarge,
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(16, 6, 16, 16),
                    child: Column(
                      children: [
                        AspectRatio(
                          aspectRatio: 4 / 5,
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: theme.dividerColor.withOpacity(0.3),
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.file(
                                File(image.path),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'Selected Leaf Image',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Please ensure the leaf is clearly visible and in focus for the most accurate diagnosis.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: Column(
                    children: [
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: AppButton(
                              label: 'Retake',
                              variant: AppButtonVariant.outlined,
                              onPressed: () => Navigator.of(
                                context,
                              ).pop(_CaptureLeafAction.retake),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              label: 'Confirm',
                              onPressed: () => Navigator.of(
                                context,
                              ).pop(_CaptureLeafAction.confirm),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final image = await _picker.pickImage(source: source);
      if (image == null) return;

      if (!mounted) return;
      setState(() {
        _selectedImage = image;
        _statusMessage = null;
        _uploadStatus = _UploadStatus.idle;
      });
    } catch (_) {
      _setStatus(_UploadStatus.error, 'Failed to pick image.');
    }
  }

  Future<void> _uploadSelectedImage() async {
    if (_selectedImage == null || _isUploading) {
      _setStatus(_UploadStatus.error, 'Please choose an image first.');
      return;
    }

    setState(() {
      _uploadStatus = _UploadStatus.uploading;
      _statusMessage = 'Uploading...';
    });

    final result = await _uploadService.uploadImage(imageFile: _selectedImage!);

    if (!mounted) return;
    setState(() {
      _uploadStatus = result.success
          ? _UploadStatus.success
          : _UploadStatus.error;
      _statusMessage = result.message;

      if (result.success) {
        final data = result.data;
        final name =
            data?['originalFilename']?.toString() ?? _selectedImage!.name;
        final status = data?['uploadStatus']?.toString() ?? 'Pending';
        _uploads.insert(
          0,
          _ScanItem(name: name, status: status, time: 'Just now'),
        );
      }
    });
  }

  void _clearImage() {
    if (_isUploading) return;
    setState(() {
      _selectedImage = null;
      _statusMessage = null;
      _uploadStatus = _UploadStatus.idle;
    });
  }

  void _setStatus(_UploadStatus status, String message) {
    if (!mounted) return;
    setState(() {
      _uploadStatus = status;
      _statusMessage = message;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      centerContent: false,
      title: 'Scan',
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('New scan', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 6),
            Text(
              'Upload or capture to run the model.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final uploadCard = _UploadCard(
                  selectedImage: _selectedImage,
                  hasImage: _selectedImage != null,
                  isUploading: _isUploading,
                  statusMessage: _statusMessage,
                  uploadStatus: _uploadStatus,
                  onPickFromGallery: () => _pickImage(ImageSource.gallery),
                  onPickFromCamera: _pickFromCameraFlow,
                  onClearImage: _clearImage,
                  onUpload: _uploadSelectedImage,
                );

                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: uploadCard),
                      const SizedBox(width: 16),
                      Expanded(child: _HistoryCard(uploads: _uploads)),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    uploadCard,
                    const SizedBox(height: 16),
                    _HistoryCard(uploads: _uploads),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

enum _UploadStatus { idle, uploading, success, error }

enum _CaptureLeafAction { retake, confirm }

class _UploadCard extends StatelessWidget {
  const _UploadCard({
    required this.selectedImage,
    required this.hasImage,
    required this.isUploading,
    required this.statusMessage,
    required this.uploadStatus,
    required this.onPickFromGallery,
    required this.onPickFromCamera,
    required this.onClearImage,
    required this.onUpload,
  });

  final XFile? selectedImage;
  final bool hasImage;
  final bool isUploading;
  final String? statusMessage;
  final _UploadStatus uploadStatus;
  final VoidCallback onPickFromGallery;
  final VoidCallback onPickFromCamera;
  final VoidCallback onClearImage;
  final VoidCallback onUpload;

  Color _statusColor(BuildContext context) {
    switch (uploadStatus) {
      case _UploadStatus.success:
        return Colors.green;
      case _UploadStatus.error:
        return Colors.red;
      case _UploadStatus.uploading:
        return Theme.of(context).colorScheme.primary;
      case _UploadStatus.idle:
        return Theme.of(context).textTheme.bodyMedium?.color ?? Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    final closeBackground = hasImage ? Colors.red : Colors.grey.shade300;
    final closeIconColor = hasImage ? Colors.white : Colors.black;
    final arrowBackground = hasImage ? Colors.blue : Colors.grey.shade300;
    final arrowIconColor = hasImage ? Colors.white : Colors.black;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Upload image', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          Stack(
            children: [
              Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: Theme.of(context).dividerColor.withOpacity(0.3),
                  ),
                  color: Theme.of(context).colorScheme.surface,
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasImage)
                        Image.file(File(selectedImage!.path), fit: BoxFit.cover)
                      else
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_upload_outlined,
                                size: 36,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Drop image here or browse',
                                style: Theme.of(context).textTheme.bodyLarge,
                              ),
                              Text(
                                'PNG, JPG up to 10MB',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      if (isUploading)
                        Container(
                          color: Colors.black.withOpacity(0.08),
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(strokeWidth: 3),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: hasImage && !isUploading ? onClearImage : null,
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: closeBackground,
                    ),
                    child: Center(
                      child: Icon(Icons.close, color: closeIconColor, size: 20),
                    ),
                  ),
                ),
              ),
              Positioned(
                bottom: 12,
                right: 12,
                child: GestureDetector(
                  onTap: hasImage && !isUploading ? onUpload : null,
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: arrowBackground,
                      border: Border.all(color: arrowBackground, width: 1),
                    ),
                    child: Icon(
                      Icons.arrow_forward,
                      color: arrowIconColor,
                      size: 24,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: AppButton(
                  label: 'Upload files',
                  icon: Icons.folder_open,
                  onPressed: isUploading ? null : onPickFromGallery,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: AppButton(
                  label: 'Use camera',
                  variant: AppButtonVariant.outlined,
                  icon: Icons.photo_camera_outlined,
                  onPressed: isUploading ? null : onPickFromCamera,
                ),
              ),
            ],
          ),
          if (statusMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              statusMessage!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: _statusColor(context)),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'Tip: ensure leaves are in focus and well-lit.',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  const _HistoryCard({required this.uploads});
  final List<_ScanItem> uploads;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Recent scans', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          ...uploads.map((item) => _ScanTile(item: item)),
          const SizedBox(height: 12),
          AppButton(
            label: 'View full history',
            variant: AppButtonVariant.ghost,
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

class _ScanItem {
  const _ScanItem({
    required this.name,
    required this.status,
    required this.time,
  });
  final String name;
  final String status;
  final String time;
}

class _ScanTile extends StatelessWidget {
  const _ScanTile({required this.item});
  final _ScanItem item;

  Color _statusColor() {
    switch (item.status.toLowerCase()) {
      case 'completed':
        return AppColors.accent;
      case 'processing':
        return Colors.amber;
      default:
        return Colors.blueGrey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.image_outlined, color: _statusColor()),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.name, style: theme.textTheme.titleMedium),
                Text(item.status, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          Text(item.time, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
