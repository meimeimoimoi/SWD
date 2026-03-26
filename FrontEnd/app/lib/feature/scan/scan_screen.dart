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
            ? 'Đăng nhập để xem các bản quét gần đây.'
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
            'Không có mô hình AI nào khả dụng. Quản trị viên cần tải lên và kích hoạt mô hình.';
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
                          'Chụp ảnh lá',
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
                          'Ảnh lá đã chọn',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Đảm bảo lá được lấy nét và đủ ánh sáng để có kết quả phân tích tốt nhất.',
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
                              label: 'Chụp lại',
                              variant: AppButtonVariant.outlined,
                              onPressed: () => Navigator.of(
                                context,
                              ).pop(_CaptureLeafAction.retake),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: AppButton(
                              label: 'Xác nhận',
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
      _setStatus(_UploadStatus.error, 'Không thể chọn ảnh. Vui lòng thử lại.');
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
        'Không thể mở tệp. Vui lòng thử lại.',
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
                    'Tải lên từ thiết bị',
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
                  title: const Text('Thư viện ảnh'),
                  subtitle: const Text('Chọn từ bộ sưu tập'),
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
                  title: const Text('Tệp'),
                  subtitle: const Text('Duyệt các tệp ảnh'),
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
      _statusMessage = 'Đang tải ảnh lên...';
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
        const SnackBar(content: Text('Vui lòng chọn ảnh trước.')),
      );
      return;
    }

    if (_predictionModels.isNotEmpty && _selectedModelId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng chọn mô hình AI.')),
      );
      return;
    }

    setState(() {
      _uploadStatus = _UploadStatus.uploading;
      _statusMessage = 'Đang phân tích ảnh...';
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
        ? AppColors.scanBackgroundLight
        : Theme.of(context).colorScheme.surface;

    return AppScaffold(
      centerContent: false,
      showUserBottomNav: true,
      selectedNavIndex: 1,
      title: 'Quét lá',
      actions: [
        IconButton(
          tooltip: 'Lịch sử quét',
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
        return AppColors.brandAccentOnDark;
      case _UploadStatus.error:
        return const Color(0xFFFFB4A8);
      case _UploadStatus.uploading:
        return AppColors.brandAccentOnDark;
      case _UploadStatus.idle:
        return const Color(0xFFB8C4BF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final isLight = theme.brightness == Brightness.light;
    final innerSurface =
        isLight ? const Color(0xFFF0F4F1) : AppColors.darkControlFill;
    final muted = Colors.grey.shade400;
    final onInnerPrimary = cs.onSurface;
    final onInnerSecondary = cs.onSurfaceVariant;
    final accentReadable = AppColors.brandAccentReadable(context);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isLight
              ? [
                  const Color(0xFF3A4038),
                  AppColors.forestCardDark,
                  const Color(0xFF232821),
                ]
              : [
                  const Color(0xFF1C1C1C),
                  AppColors.surfaceDark,
                  const Color(0xFF0A0A0A),
                ],
        ),
        boxShadow: AppLayout.heroCardShadows(context),
        border: Border.all(
          color: (isLight ? AppColors.brandAccentOnDark : AppColors.accent)
              .withValues(alpha: isLight ? 0.14 : 0.12),
        ),
      ),
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
                        color: AppColors.brandAccent.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'QUÉT LÁ',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: AppColors.brandAccentOnDark,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Phân tích mẫu',
                  style: TextStyle(
                    color: AppColors.onPrimary,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Thêm ảnh lá rõ nét, sau đó nhấn gửi để chạy mô hình.',
                  style: TextStyle(color: muted, fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 18),
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isLight ? 0.14 : 0.5,
                            ),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Material(
                        color: innerSurface,
                        borderRadius: BorderRadius.circular(16),
                        child: InkWell(
                          onTap: !isUploading && !hasImage
                              ? onUploadFromDevice
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isLight
                                  ? Colors.black.withValues(alpha: 0.07)
                                  : Colors.white.withValues(alpha: 0.08),
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
                                            color: accentReadable,
                                          ),
                                          const SizedBox(height: 10),
                                          Text(
                                            'Nhấn để chọn từ thiết bị',
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.titleSmall
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: onInnerPrimary,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Hoặc sử dụng Chụp / Tải lên bên dưới',
                                            textAlign: TextAlign.center,
                                            style: theme.textTheme.bodySmall
                                                ?.copyWith(
                                              color: onInnerSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                if (isUploading)
                                  Container(
                                    color: Colors.black.withValues(alpha: 0.08),
                                    child: Center(
                                      child: SizedBox(
                                        width: 32,
                                        height: 32,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 3,
                                          color: accentReadable,
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
                        label: 'Chụp ảnh',
                        onPressed: isUploading ? null : onCapture,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _WorkbenchOutlineButton(
                        icon: Icons.upload_file_outlined,
                        label: 'Tải lên',
                        onPressed: isUploading ? null : onUploadFromDevice,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (modelsLoading)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Center(
                      child: SizedBox(
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: accentReadable,
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
                              child: const Text('Thử lại'),
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
                            color: AppColors.brandAccent.withValues(alpha: 0.45),
                            width: 1.25,
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: AppColors.brandAccent.withValues(alpha: 0.5),
                            width: 1.25,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.brandAccent,
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
                      iconEnabledColor: accentReadable,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: onInnerPrimary,
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
                      'Gửi đi',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandAccentOnDark,
                      foregroundColor: AppColors.onBrandFixedDark,
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.4),
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
                          ? 'Sẵn sàng — nhấn Gửi để phân tích.'
                          : 'Chọn hoặc chụp ảnh lá để bắt đầu.'),
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
        minimumSize: const Size(0, 52),
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
    'Chụp đầy khung hình với một chiếc lá; tránh bóng râm gay gắt tại điểm bạn quan tâm.',
    'Ánh sáng ban ngày tự nhiên là tốt nhất—tránh bóng đèn vàng trong nhà nếu có thể.',
    'Giữ chắc tay; ảnh bị nhòe sẽ khiến mô hình khó đọc hơn.',
  ];

  @override
  Widget build(BuildContext context) {
    final line = Theme.of(context).dividerColor.withValues(alpha: 0.12);
    final accent = AppColors.brandAccentReadable(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'HƯỚNG DẪN QUÉT',
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
            boxShadow: AppLayout.cardShadows(context),
          ),
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.tips_and_updates_outlined,
                    size: 22,
                    color: accent,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Mẹo chụp ảnh',
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
                            color: accent,
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
  if (diff.inSeconds < 60) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
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
    final accent = AppColors.brandAccentReadable(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'LỊCH SỬ QUÉT',
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
            boxShadow: AppLayout.cardShadows(context),
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
                    color: accent,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Các bản quét gần đây',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              if (loading)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: accent,
                      ),
                    ),
                  ),
                )
              else if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    errorMessage ??
                        'Chưa có bản quét nào. Thực hiện phân tích ở trên để xem tại đây.',
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
                    foregroundColor: accent,
                    backgroundColor: accent.withValues(alpha: 0.12),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history_rounded, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Xem tất cả lịch sử quét',
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

  Color _accent(BuildContext context, bool healthy) {
    if (healthy) return AppColors.brandAccentReadable(context);
    return const Color(0xFFD4A017);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final soft = theme.dividerColor.withValues(alpha: 0.2);
    final healthy = DiseaseMapper.isHealthy(item.diseaseName);
    final accent = _accent(context, healthy);
    final title = DiseaseMapper.toDisplayName(
      item.diseaseName.trim().isEmpty ? 'Quét lá' : item.diseaseName,
    );
    final statusLabel = healthy ? 'Khỏe mạnh' : 'Xem xét';

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
                              ? AppColors.brandAccentReadable(context)
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
