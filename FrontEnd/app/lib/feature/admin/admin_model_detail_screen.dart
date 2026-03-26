import 'package:flutter/material.dart';

import '../../share/models/model_version_detail.dart';
import '../../share/services/dashboard_service.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/app_card.dart';

class AdminModelDetailScreen extends StatefulWidget {
  const AdminModelDetailScreen({super.key, required this.modelVersionId});

  final int modelVersionId;

  @override
  State<AdminModelDetailScreen> createState() => _AdminModelDetailScreenState();
}

class _AdminModelDetailScreenState extends State<AdminModelDetailScreen> {
  final DashboardService _api = DashboardService();
  ModelVersionDetail? _detail;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final d = await _api.getAdminModelDetail(widget.modelVersionId);
    if (!mounted) return;
    setState(() {
      _detail = d;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Chi tiết mô hình',
          style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
        ),
        actions: [
          IconButton(
            tooltip: 'Làm mới',
            onPressed: _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: _detail == null
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(24),
                        children: [
                          AppCard(
                            padding: const EdgeInsets.all(20),
                            child: Text(
                              'Chi tiết mô hình không khả dụng. Kéo để làm mới hoặc sử dụng nút trên thanh công cụ.',
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: textSecondary,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ListView(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                        children: [
                          _buildOverview(
                            theme,
                            _detail!,
                            textPrimary,
                            textSecondary,
                          ),
                          const SizedBox(height: 16),
                          _buildUsage(
                            theme,
                            _detail!,
                            textPrimary,
                            textSecondary,
                          ),
                          const SizedBox(height: 16),
                          _buildFile(
                            theme,
                            _detail!,
                            textPrimary,
                            textSecondary,
                          ),
                          const SizedBox(height: 16),
                          _buildOnnx(
                            theme,
                            _detail!,
                            textPrimary,
                            textSecondary,
                          ),
                          const SizedBox(height: 16),
                          _buildRuntime(
                            theme,
                            _detail!,
                            textPrimary,
                            textSecondary,
                          ),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _buildOverview(
    ThemeData theme,
    ModelVersionDetail d,
    Color textPrimary,
    Color textSecondary,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.psychology_outlined, color: AppColors.primary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      d.modelName,
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Phiên bản ${d.version} · ID ${d.modelVersionId}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (d.isActive == true)
                Chip(
                  label: const Text('Hoạt động'),
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.play_circle_outline, size: 18),
                ),
              if (d.isDefault == true)
                Chip(
                  label: const Text('Mặc định'),
                  visualDensity: VisualDensity.compact,
                  avatar: const Icon(Icons.star_outline, size: 18),
                ),
              if (d.isActive != true)
                Chip(
                  label: const Text('Không hoạt động'),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          if (d.modelType != null && d.modelType!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _kv(theme, 'Loại', d.modelType!, textPrimary, textSecondary),
          ],
          if (d.description != null && d.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              d.description!,
              style: theme.textTheme.bodyMedium?.copyWith(color: textSecondary),
            ),
          ],
          if (d.createdAt != null)
            _kv(
              theme,
              'Đã đăng ký',
              d.createdAt!.toUtc().toIso8601String(),
              textPrimary,
              textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _buildUsage(
    ThemeData theme,
    ModelVersionDetail d,
    Color textPrimary,
    Color textSecondary,
  ) {
    final confPct = (d.averageConfidence * 100).clamp(0.0, 100.0);
    final ratePct = d.positiveRatingRate.clamp(0.0, 100.0);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sử dụng & chất lượng',
            style: theme.textTheme.titleMedium?.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          _kv(theme, 'Tổng lượt dự đoán', '${d.totalPredictions}', textPrimary,
              textSecondary),
          _kv(theme, 'Hôm nay', '${d.predictionsToday}', textPrimary,
              textSecondary),
          _kv(theme, '7 ngày qua', '${d.predictionsLast7Days}', textPrimary,
              textSecondary),
          const SizedBox(height: 8),
          Text(
            'Độ tin cậy trung bình',
            style: theme.textTheme.labelLarge?.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: confPct / 100,
              minHeight: 10,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${confPct.toStringAsFixed(1)}%',
            style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            'Đánh giá tích cực (${d.totalRatings} tổng cộng)',
            style: theme.textTheme.labelLarge?.copyWith(color: textPrimary),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: d.totalRatings > 0 ? ratePct / 100 : null,
              minHeight: 10,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            d.totalRatings > 0
                ? '${ratePct.toStringAsFixed(1)}% · ${d.positiveRatings} tích cực'
                : 'Chưa có đánh giá',
            style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
          if (d.topPredictedClasses.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Các lớp dự đoán hàng đầu',
              style: theme.textTheme.labelLarge?.copyWith(color: textPrimary),
            ),
            const SizedBox(height: 8),
            ...d.topPredictedClasses.map(
              (c) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        c.className,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '${c.count}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildFile(
    ThemeData theme,
    ModelVersionDetail d,
    Color textPrimary,
    Color textSecondary,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tệp tin trên ổ đĩa',
            style: theme.textTheme.titleMedium?.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _kv(theme, 'Tồn tại', d.fileExists ? 'Có' : 'Không', textPrimary,
              textSecondary),
          if (d.relativeFilePath != null)
            _kv(theme, 'Đường dẫn tương đối', d.relativeFilePath!, textPrimary,
                textSecondary, selectable: true),
          if (d.absolutePath != null)
            _kv(theme, 'Đường dẫn đầy đủ', d.absolutePath!, textPrimary, textSecondary,
                selectable: true),
          _kv(theme, 'Kích thước', d.fileSizeHuman, textPrimary, textSecondary),
          if (d.fileLastModifiedUtc != null)
            _kv(
              theme,
              'Đã chỉnh sửa (UTC)',
              d.fileLastModifiedUtc!.toIso8601String(),
              textPrimary,
              textSecondary,
            ),
        ],
      ),
    );
  }

  Widget _buildOnnx(
    ThemeData theme,
    ModelVersionDetail d,
    Color textPrimary,
    Color textSecondary,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Siêu dữ liệu ONNX',
            style: theme.textTheme.titleMedium?.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          if (d.onnxMetadataError != null)
            Text(
              d.onnxMetadataError!,
              style: TextStyle(color: Colors.orange.shade800, fontSize: 13),
            ),
          if (d.onnxMetadataError == null) ...[
            if (d.onnxProducerName != null)
              _kv(theme, 'Nhà sản xuất', d.onnxProducerName!, textPrimary,
                  textSecondary),
            if (d.onnxGraphName != null)
              _kv(theme, 'Biểu đồ', d.onnxGraphName!, textPrimary, textSecondary),
            if (d.onnxDomain != null)
              _kv(theme, 'Miền', d.onnxDomain!, textPrimary, textSecondary),
            if (d.onnxModelVersion != null)
              _kv(theme, 'Phiên bản mô hình', '${d.onnxModelVersion}', textPrimary,
                  textSecondary),
            const SizedBox(height: 8),
            Text(
              'Đầu vào',
              style: theme.textTheme.labelLarge?.copyWith(color: textPrimary),
            ),
            const SizedBox(height: 4),
            ...d.onnxInputNames.map(
              (n) => _tensorRow(theme, n, d.onnxInputShapeDescriptions[n],
                  textPrimary, textSecondary),
            ),
            const SizedBox(height: 8),
            Text(
              'Đầu ra',
              style: theme.textTheme.labelLarge?.copyWith(color: textPrimary),
            ),
            const SizedBox(height: 4),
            ...d.onnxOutputNames.map(
              (n) => _tensorRow(theme, n, d.onnxOutputShapeDescriptions[n],
                  textPrimary, textSecondary),
            ),
            if (d.onnxClassLabelCount != null)
              _kv(
                theme,
                'Nhãn lớp',
                '${d.onnxClassLabelCount}',
                textPrimary,
                textSecondary,
              ),
            if (d.onnxClassLabelsError != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Nhãn: ${d.onnxClassLabelsError}',
                  style: TextStyle(color: Colors.orange.shade800, fontSize: 12),
                ),
              ),
            if (d.onnxClassLabelsSample.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Mẫu nhãn',
                style: theme.textTheme.labelSmall?.copyWith(color: textSecondary),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: d.onnxClassLabelsSample
                    .map(
                      (s) => Chip(
                        label: Text(s, style: const TextStyle(fontSize: 11)),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildRuntime(
    ThemeData theme,
    ModelVersionDetail d,
    Color textPrimary,
    Color textSecondary,
  ) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Môi trường thực thi',
            style: theme.textTheme.titleMedium?.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _kv(
            theme,
            'Mã mô hình đang tải',
            d.currentlyLoadedModelVersionId?.toString() ?? '—',
            textPrimary,
            textSecondary,
          ),
          _kv(
            theme,
            'Mô hình này đã được tải',
            d.isCurrentInferenceModel ? 'Có' : 'Không',
            textPrimary,
            textSecondary,
          ),
          const SizedBox(height: 6),
          Text(
            'API duy trì một phiên làm việc ONNX; nó sẽ tải lại khi mô hình mặc định/hoạt động thay đổi hoặc sau lần dự đoán đầu tiên.',
            style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _kv(
    ThemeData theme,
    String k,
    String v,
    Color textPrimary,
    Color textSecondary, {
    bool selectable = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              k,
              style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
            ),
          ),
          Expanded(
            child: selectable
                ? SelectableText(
                    v,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  )
                : Text(
                    v,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tensorRow(
    ThemeData theme,
    String name,
    String? shape,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: SelectableText(
              name,
              style: theme.textTheme.bodySmall?.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w600,
                fontFamily: 'monospace',
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              shape ?? '—',
              style: theme.textTheme.bodySmall?.copyWith(
                color: textSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
