import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../routes/app_router.dart';
import '../../share/services/history_service.dart';
import '../../share/services/image_upload_service.dart';
import '../../share/services/prediction_service.dart';
import '../../share/services/storage_service.dart';
import '../../share/utils/disease_mapper.dart';
import '../../share/theme/app_colors.dart';
import '../../share/theme/app_layout.dart';
import '../../share/widgets/app_button.dart';
import '../../share/widgets/app_scaffold.dart';
import '../prediction/prediction_screen.dart';

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
  final HistoryService _historyService = HistoryService();

  List<PredictionModelOption> _predictionModels = [];
  int? _selectedModelId;
  bool _modelsLoading = true;
  String? _modelsError;

  static const int _kRecentScanLimit = 3;

  List<HistoryItem> _recentHistory = [];
  bool _historyLoading = true;
  String? _historyError;

  XFile? _selectedImage;
  String? _statusMessage;
  _UploadStatus _uploadStatus = _UploadStatus.idle;

  bool get _isUploading => _uploadStatus == _UploadStatus.uploading;

  @override
  void initState() {
    super.initState();
    _loadPredictionModels();
    _loadRecentHistory();
  }

  Future<void> _loadRecentHistory({bool silent = false}) async {
    if (!silent && mounted) {
      setState(() {
        _historyLoading = true;
        _historyError = null;
      });
    }
    final res = await _historyService.getHistory();
    if (!mounted) return;
    final sorted = [...res.data]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    setState(() {
      _recentHistory = sorted.take(_kRecentScanLimit).toList();
      _historyLoading = false;
      if (res.success) {
        _historyError = null;
      } else {
        final msg = res.message;
        _historyError = msg.contains('login') || msg.contains('Unauthorized')
            ? 'Sign in to see your recent scans.'
            : msg;
      }
    });
  }

  Future<void> _loadPredictionModels() async {
    setState(() {
      _modelsLoading = true;
      _modelsError = null;
    });
    final token = await StorageService.getAccessToken();
    final result = await _predictionService.fetchAvailableModels();
    final list = result.models;
    if (!mounted) return;
    int? pick;
    if (list.isNotEmpty) {
      PredictionModelOption? def;
      for (final m in list) {
        if (m.isDefault) {
          def = m;
          break;
        }
      }
      pick = (def ?? list.first).modelVersionId;
    }
    final loggedIn = token != null && token.isNotEmpty;
    setState(() {
      _predictionModels = list;
      _modelsLoading = false;
      _selectedModelId = pick;
      if (list.isNotEmpty) {
        _modelsError = null;
      } else if (!loggedIn) {
        _modelsError = null;
      } else if (result.errorMessage != null &&
          result.errorMessage!.isNotEmpty) {
        _modelsError = result.errorMessage;
      } else {
        _modelsError =
            'No AI models available. An admin must upload and activate a model.';
      }
    });
  }

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
                  padding: const EdgeInsets.fromLTRB(
                    AppLayout.screenPaddingH,
                    AppLayout.screenPaddingV,
                    AppLayout.screenPaddingH,
                    4,
                  ),
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
        _loadRecentHistory(silent: true);
      }
    });
  }

  Future<void> _predictImage() async {
    if (_selectedImage == null || _isUploading) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an image first.')),
      );
      return;
    }

    if (_predictionModels.isNotEmpty && _selectedModelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select an AI model.')),
      );
      return;
    }

    setState(() {
      _uploadStatus = _UploadStatus.uploading;
      _statusMessage = 'Analyzing image...';
    });

    try {
      final response = await _predictionService.predict(
        _selectedImage!.path,
        modelVersionId: _selectedModelId,
      );

      if (!mounted) return;

      if (response.success && response.data != null) {
        final predictionResult = PredictionResult.fromApiResponse(
          response.data!,
        );

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
          await _loadRecentHistory(silent: true);
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
      actions: [
        IconButton(
          tooltip: 'Scan history',
          onPressed: () =>
              Navigator.pushNamed(context, AppRouter.history),
          icon: const Icon(Icons.history_rounded),
        ),
      ],
      backgroundColor: bg,
      contentPadding: const EdgeInsets.fromLTRB(
        AppLayout.screenPaddingH,
        AppLayout.screenPaddingV,
        AppLayout.screenPaddingH,
        28,
      ),
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
            predictionModels: _predictionModels,
            selectedModelId: _selectedModelId,
            onModelChanged: (id) => setState(() => _selectedModelId = id),
            modelsLoading: _modelsLoading,
            modelsError: _modelsError,
            onRetryLoadModels: _loadPredictionModels,
          );
          const tips = _ScanPageTipsCard();
          final recent = _RecentActivityCard(
            items: _recentHistory,
            loading: _historyLoading,
            errorMessage: _historyError,
            onOpenItem: (item) {
              Navigator.pushNamed(
                context,
                AppRouter.prediction,
                arguments: PredictionResult.fromHistoryItem(item),
              );
            },
          );

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
    required this.predictionModels,
    required this.selectedModelId,
    required this.onModelChanged,
    required this.modelsLoading,
    this.modelsError,
    this.onRetryLoadModels,
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
  final List<PredictionModelOption> predictionModels;
  final int? selectedModelId;
  final ValueChanged<int?> onModelChanged;
  final bool modelsLoading;
  final String? modelsError;
  final VoidCallback? onRetryLoadModels;

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
    final cardBg = isLight ? _kDarkCard : AppColors.surfaceDark;
    final innerSurface =
        isLight ? const Color(0xFFF0F4F1) : AppColors.darkControlFill;
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
              color: AppColors.onPrimary.withValues(alpha: 0.06),
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
                Text(
                  'Analyze a sample',
                  style: TextStyle(
                    color: AppColors.onPrimary,
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
                                : AppColors.surfaceLight.withValues(alpha: 0.65),
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
                              color:
                                  hasImage ? AppColors.onPrimary : Colors.black45,
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
                if (modelsLoading)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: _kBrandGreen,
                        ),
                      ),
                    ),
                  )
                else ...[
                  if (modelsError != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                            modelsError!,
                            style: TextStyle(
                              color: Colors.orange.shade200,
                              fontSize: 12,
                              height: 1.35,
                            ),
                          ),
                          if (onRetryLoadModels != null) ...[
                            const SizedBox(height: 6),
                            TextButton(
                              onPressed: onRetryLoadModels,
                              child: const Text('Retry'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  if (predictionModels.isNotEmpty)
                    DropdownButtonFormField<int>(
                      value: selectedModelId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: null,
                        floatingLabelBehavior: FloatingLabelBehavior.always,
                        labelStyle: TextStyle(
                          color: muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                        filled: true,
                        fillColor: innerSurface,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: _kBrandGreen.withValues(alpha: 0.45),
                            width: 1.25,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: _kBrandGreen.withValues(alpha: 0.5),
                            width: 1.25,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: _kBrandGreen,
                            width: 2,
                          ),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        contentPadding: const EdgeInsets.fromLTRB(
                          16,
                          14,
                          12,
                          14,
                        ),
                      ),
                      dropdownColor: innerSurface,
                      iconEnabledColor: _kBrandGreen,
                      style: const TextStyle(
                        color: Color(0xFF1B2D20),
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        height: 1.25,
                      ),
                      items: predictionModels
                          .map(
                            (m) => DropdownMenuItem<int>(
                              value: m.modelVersionId,
                              child: Text(
                                m.label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: isUploading
                          ? null
                          : (v) => onModelChanged(v),
                    ),
                  if (predictionModels.isNotEmpty)
                    const SizedBox(height: 12),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: hasImage && !isUploading && !modelsLoading
                        ? (onPredict ?? onUpload)
                        : null,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 22),
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
                          AppColors.surfaceLight.withValues(alpha: 0.12),
                      disabledForegroundColor:
                          AppColors.surfaceLight.withValues(alpha: 0.35),
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
        foregroundColor: AppColors.onPrimary,
        side: BorderSide(
          color: AppColors.onPrimary.withValues(alpha: 0.38),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

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
                ? AppColors.surfaceLight
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

String _scanRelativeTime(DateTime dt, DateTime now) {
  final diff = now.difference(dt);
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
}

class _RecentActivityCard extends StatelessWidget {
  const _RecentActivityCard({
    required this.items,
    required this.loading,
    this.errorMessage,
    required this.onOpenItem,
  });

  final List<HistoryItem> items;
  final bool loading;
  final String? errorMessage;
  final void Function(HistoryItem item) onOpenItem;

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'SCAN HISTORY',
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
                ? AppColors.surfaceLight
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
                    'Recent scans',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: _kBrandGreen,
                      ),
                    ),
                  ),
                )
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    errorMessage ??
                        'No scans yet. Run an analysis above to see it here.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                  ),
                )
              else
                for (final item in items)
                  _ScanHistoryTile(
                    item: item,
                    timeLabel: _scanRelativeTime(item.createdAt, now),
                    onTap: () => onOpenItem(item),
                  ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton.tonal(
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.history),
                  style: FilledButton.styleFrom(
                    foregroundColor: _kBrandGreen,
                    backgroundColor: _kBrandGreen.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'View all scan history',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ScanHistoryTile extends StatelessWidget {
  const _ScanHistoryTile({
    required this.item,
    required this.timeLabel,
    required this.onTap,
  });

  final HistoryItem item;
  final String timeLabel;
  final VoidCallback onTap;

  Color _accent(bool healthy) {
    if (healthy) return _kBrandGreen;
    return const Color(0xFFD4A017);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final soft = theme.dividerColor.withValues(alpha: 0.2);
    final healthy = DiseaseMapper.isHealthy(item.diseaseName);
    final accent = _accent(healthy);
    final title = DiseaseMapper.toDisplayName(
      item.diseaseName.trim().isEmpty ? 'Leaf scan' : item.diseaseName,
    );
    final statusLabel = healthy ? 'Healthy' : 'Review';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: theme.colorScheme.surface.withValues(alpha: 0.65),
              border: Border.all(color: soft),
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: SizedBox(
                    width: 40,
                    height: 40,
                    child: item.imageUrl.isEmpty
                        ? ColoredBox(
                            color: accent.withValues(alpha: 0.12),
                            child:
                                Icon(Icons.image_outlined, color: accent, size: 22),
                          )
                        : Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            cacheWidth: 96,
                            cacheHeight: 96,
                            filterQuality: FilterQuality.low,
                            errorBuilder: (_, __, ___) => ColoredBox(
                              color: accent.withValues(alpha: 0.12),
                              child: Icon(Icons.image_outlined,
                                  color: accent, size: 22),
                            ),
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        statusLabel,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: healthy
                              ? _kBrandGreen
                              : const Color(0xFFCA8A04),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  timeLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
