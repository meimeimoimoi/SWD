import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../routes/app_router.dart';
import '../../share/services/image_upload_service.dart';
import '../../share/services/prediction_service.dart';
import '../../share/widgets/app_button.dart';
import '../../share/widgets/app_scaffold.dart';
import '../prediction/prediction_screen.dart';

/// Matches [DashboardScreen] owner hub palette.
const Color _kBrandGreen = Color(0xFF2D7B31);
const Color _kPageBgLight = Color(0xFFF6F8F6);
const Color _kDarkCard = Color(0xFF2D322B);
const Color _kPrimaryFixed = Color(0xFFA4F69C);
const Color _kOnPrimaryFixed = Color(0xFF1A3D16);

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final ImagePicker _picker = ImagePicker();
  final ImageUploadService _uploadService = ImageUploadService();
  final PredictionService _predictionService = PredictionService();

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
                          'Capture leaf',
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
                                color: theme.dividerColor
                                    .withValues(alpha: 0.3),
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
                          'Selected leaf image',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Make sure the leaf is in focus and well lit for the best analysis.',
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
      _setStatus(_UploadStatus.error, 'Could not pick image. Please try again.');
    }
  }

  Future<void> _pickFromFiles() async {
    if (_isUploading) return;
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowCompression: true,
        withData: false,
      );
      if (result == null || result.files.isEmpty) return;
      final f = result.files.single;
      final path = f.path;
      if (path == null || path.isEmpty) return;
      if (!mounted) return;
      setState(() {
        _selectedImage = XFile(path);
        _statusMessage = null;
        _uploadStatus = _UploadStatus.idle;
      });
    } catch (_) {
      _setStatus(
        _UploadStatus.error,
        'Could not open file. Please try again.',
      );
    }
  }

  /// Gallery or file picker (used by Upload button / empty-state tap).
  void _showUploadFromDeviceSheet() {
    if (_isUploading) return;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: cs.surface,
      showDragHandle: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Text(
                    'Upload from device',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.secondaryContainer,
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: cs.onSecondaryContainer,
                    ),
                  ),
                  title: const Text('Photo library'),
                  subtitle: const Text('Pick from gallery'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Future<void>.microtask(
                      () => _pickImage(ImageSource.gallery),
                    );
                  },
                ),
                ListTile(
                  leading: CircleAvatar(
                    backgroundColor: cs.tertiaryContainer,
                    child: Icon(
                      Icons.folder_open,
                      color: cs.onTertiaryContainer,
                    ),
                  ),
                  title: const Text('Files'),
                  subtitle: const Text('Browse image files'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Future<void>.microtask(_pickFromFiles);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _uploadSelectedImage() async {
    if (_selectedImage == null || _isUploading) {
      _setStatus(_UploadStatus.error, 'Please select an image first.');
      return;
    }

    setState(() {
      _uploadStatus = _UploadStatus.uploading;
      _statusMessage = 'Uploading image...';
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

  /// Predict disease from selected image and navigate to prediction screen
  Future<void> _predictImage() async {
    if (_selectedImage == null || _isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }

    setState(() {
      _uploadStatus = _UploadStatus.uploading;
      _statusMessage = 'Analyzing image...';
    });

    try {
      final response = await _predictionService.predict(_selectedImage!.path);

      if (!mounted) return;

      if (response.success && response.data != null) {
        // Convert API response to PredictionResult
        final predictionResult = PredictionResult.fromApiResponse(
          response.data!,
        );

        // Navigate to prediction screen with the result
        await Navigator.pushNamed(
          context,
          AppRouter.prediction,
          arguments: predictionResult,
        );
        if (mounted) {
          setState(() {
            _uploadStatus = _UploadStatus.idle;
            _statusMessage = null;
          });
        }
      } else {
        if (!mounted) return;
        setState(() {
          _uploadStatus = _UploadStatus.error;
          _statusMessage = response.message;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(response.message)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _uploadStatus = _UploadStatus.error;
        _statusMessage = 'Error: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
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
    final bg = Theme.of(context).brightness == Brightness.light
        ? _kPageBgLight
        : Theme.of(context).colorScheme.surface;

    return AppScaffold(
      centerContent: false,
      showUserBottomNav: true,
      selectedNavIndex: 1,
      title: 'Scan',
      backgroundColor: bg,
      contentPadding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth > 900;
          final workbench = _ScanWorkbenchCard(
            selectedImage: _selectedImage,
            hasImage: _selectedImage != null,
            isUploading: _isUploading,
            statusMessage: _statusMessage,
            uploadStatus: _uploadStatus,
            onCapture: _pickFromCameraFlow,
            onUploadFromDevice: _showUploadFromDeviceSheet,
            onClearImage: _clearImage,
            onUpload: _uploadSelectedImage,
            onPredict: _predictImage,
          );
          const tips = _ScanPageTipsCard();
          final recent = _RecentActivityCard(uploads: _uploads);

          if (isWide) {
            return SingleChildScrollView(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        workbench,
                        const SizedBox(height: 20),
                        tips,
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: recent),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                workbench,
                const SizedBox(height: 20),
                tips,
                const SizedBox(height: 20),
                recent,
              ],
            ),
          );
        },
      ),
    );
  }
}

enum _UploadStatus { idle, uploading, success, error }

enum _CaptureLeafAction { retake, confirm }

class _ScanWorkbenchCard extends StatelessWidget {
  const _ScanWorkbenchCard({
    required this.selectedImage,
    required this.hasImage,
    required this.isUploading,
    required this.statusMessage,
    required this.uploadStatus,
    required this.onCapture,
    required this.onUploadFromDevice,
    required this.onClearImage,
    required this.onUpload,
    this.onPredict,
  });

  final XFile? selectedImage;
  final bool hasImage;
  final bool isUploading;
  final String? statusMessage;
  final _UploadStatus uploadStatus;
  final VoidCallback onCapture;
  final VoidCallback onUploadFromDevice;
  final VoidCallback onClearImage;
  final VoidCallback onUpload;
  final VoidCallback? onPredict;

  Color _statusColor() {
    switch (uploadStatus) {
      case _UploadStatus.success:
        return _kPrimaryFixed;
      case _UploadStatus.error:
        return const Color(0xFFFFB4A8);
      case _UploadStatus.uploading:
        return _kPrimaryFixed;
      case _UploadStatus.idle:
        return const Color(0xFFB8C4BF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    final cardBg = isLight ? _kDarkCard : const Color(0xFF2C3430);
    final innerSurface =
        isLight ? const Color(0xFFF0F4F1) : const Color(0xFF1E2521);
    final muted = Colors.grey.shade400;

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -28,
            bottom: -28,
            child: Icon(
              Icons.document_scanner_outlined,
              size: 150,
              color: Colors.white.withValues(alpha: 0.06),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 22),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: _kBrandGreen.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'LEAF SCAN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: _kPrimaryFixed,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Analyze a sample',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Add a clear leaf photo, then submit to run the model.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 18),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Material(
                      color: innerSurface,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        onTap: !isUploading && !hasImage ? onUploadFromDevice : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                if (hasImage)
                                  Image.file(
                                    File(selectedImage!.path),
                                    fit: BoxFit.cover,
                                  )
                                else
                                  Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.add_photo_alternate_outlined,
                                            size: 44,
                                            color: _kBrandGreen,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Tap to choose from device',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .titleSmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                  color: const Color(0xFF1B2D20),
                                                ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Or use Capture / Upload below',
                                            textAlign: TextAlign.center,
                                            style: Theme.of(context)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  color: const Color(0xFF5C6B62),
                                                ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (isUploading)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    child: const Center(
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: _kBrandGreen,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
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
                            color: hasImage
                                ? const Color(0xFFC94C4C)
                                : Colors.white.withValues(alpha: 0.65),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Icon(
                              Icons.close,
                              color: hasImage ? Colors.white : Colors.black45,
                              size: 20,
                            ),
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
                      child: _WorkbenchOutlineButton(
                        icon: Icons.photo_camera_outlined,
                        label: 'Capture',
                        onPressed: isUploading ? null : onCapture,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WorkbenchOutlineButton(
                        icon: Icons.upload_file_outlined,
                        label: 'Upload',
                        onPressed: isUploading ? null : onUploadFromDevice,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: hasImage && !isUploading
                        ? (onPredict ?? onUpload)
                        : null,
                    icon: const Icon(Icons.biotech_outlined, size: 22),
                    label: const Text(
                      'Submit',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _kPrimaryFixed,
                      foregroundColor: _kOnPrimaryFixed,
                      disabledBackgroundColor:
                          Colors.white.withValues(alpha: 0.12),
                      disabledForegroundColor:
                          Colors.white.withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  statusMessage ??
                      (hasImage
                          ? 'Ready when you are — tap Submit to analyze.'
                          : 'Choose or capture a leaf image to begin.'),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: statusMessage != null
                            ? _statusColor()
                            : muted,
                        height: 1.45,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkbenchOutlineButton extends StatelessWidget {
  const _WorkbenchOutlineButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      label: Text(
        label,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        foregroundColor: Colors.white,
        side: BorderSide(color: Colors.white.withValues(alpha: 0.38)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// Same tips as dashboard [dashboard_screen.dart] `_ScanTipsCard`.
class _ScanPageTipsCard extends StatelessWidget {
  const _ScanPageTipsCard();

  static const _tips = <String>[
    'Fill the frame with one leaf; avoid harsh shadow on the spot you care about.',
    'Natural daylight works best—avoid yellow indoor bulbs if you can.',
    'Hold steady; blurry photos are harder for the model to read.',
  ];

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'GET A CLEAR SCAN',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: line),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.tips_and_updates_outlined,
                    size: 22,
                    color: _kBrandGreen,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Photo tips',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              for (var i = 0; i < _tips.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${i + 1}.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: _kBrandGreen,
                          ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _tips[i],
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              height: 1.45,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({required this.uploads});

  final List<_ScanItem> uploads;

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'RECENT ACTIVITY',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.light
                ? Colors.white
                : Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: line),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(
                  alpha: Theme.of(context).brightness == Brightness.light
                      ? 0.06
                      : 0.2,
                ),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 22,
                    color: _kBrandGreen,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Queue snapshot',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              ...uploads.map((item) => _ScanTile(item: item)),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.history),
                  style: TextButton.styleFrom(
                    foregroundColor: _kBrandGreen,
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  child: const Text('View full history'),
                ),
              ),
            ],
          ),
        ),
      ],
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

  Color _statusAccent() {
    switch (item.status.toLowerCase()) {
      case 'completed':
        return _kBrandGreen;
      case 'processing':
        return const Color(0xFFD4A017);
      default:
        return const Color(0xFF64748B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final soft = theme.dividerColor.withValues(alpha: 0.2);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface.withValues(alpha: 0.65),
        border: Border.all(color: soft),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _statusAccent().withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.image_outlined, color: _statusAccent(), size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.status,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Text(
            item.time,
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
