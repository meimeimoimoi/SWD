import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import '../../share/services/history_service.dart';
import '../../share/widgets/app_scaffold.dart';
import '../../share/theme/app_colors.dart';
import '../../share/utils/disease_mapper.dart';
import '../prediction/prediction_screen.dart';

enum _Severity { low, medium, high }

_Severity _severityOf(String diseaseName) {
  if (DiseaseMapper.isHealthy(diseaseName)) return _Severity.low;
  switch (diseaseName) {
    case 'Leaf Blast':
    case 'Bacterial Leaf Blight':
      return _Severity.high;
    default:
      return _Severity.medium;
  }
}

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final _service = HistoryService();
  List<HistoryItem> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final response = await _service.getHistory();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (response.success) {
        // Newest first
        _items = response.data
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        _error = null;
      } else {
        _error = response.message;
      }
    });
  }

  // ── date helpers ──────────────────────────────────────────────────────────

  String _dateGroupKey(DateTime dt) {
    // Use date part only as a stable key for grouping
    return '${dt.year}-${dt.month}-${dt.day}';
  }

  String _dateGroupLabel(DateTime dt) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final d = DateTime(dt.year, dt.month, dt.day);
    final formatted =
        '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    if (d == today) return 'Hôm nay - $formatted';
    if (d == yesterday) return 'Hôm qua - $formatted';
    return formatted;
  }

  String _timeOf(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  // ── grouping ──────────────────────────────────────────────────────────────

  List<MapEntry<String, List<HistoryItem>>> _grouped() {
    final map = <String, List<HistoryItem>>{};
    for (final item in _items) {
      final key = _dateGroupKey(item.createdAt);
      map.putIfAbsent(key, () => []).add(item);
    }
    return map.entries.toList();
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AppScaffold(
      title: 'Lịch sử quét',
      actions: [
        IconButton(
          onPressed: _loadHistory,
          icon: Icon(
            Icons.refresh,
            color: isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
        ),
      ],
      centerContent: false,
      showUserBottomNav: true,
      selectedNavIndex: 2,
      child: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.accent),
                  )
                : _error != null
                ? _buildErrorState(isDark)
                : _items.isEmpty
                ? _buildEmptyState(isDark)
                : _buildList(isDark),
          ),
        ],
      ),
    );
  }

  // ── header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.darkBackground.withOpacity(0.95)
            : AppColors.lightBackground.withOpacity(0.95),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.borderDark : AppColors.borderLight,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Lịch sử quét',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark
                  ? AppColors.textPrimaryDark
                  : AppColors.textPrimaryLight,
            ),
          ),
          Material(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            child: InkWell(
              onTap: _loadHistory,
              borderRadius: BorderRadius.circular(20),
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(
                  Icons.refresh,
                  size: 20,
                  color: isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── list ──────────────────────────────────────────────────────────────────

  Widget _buildList(bool isDark) {
    final groups = _grouped();
    return RefreshIndicator(
      onRefresh: _loadHistory,
      color: AppColors.accent,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          for (final entry in groups) ...[
            _buildDateLabel(
              _dateGroupLabel(
                _items
                    .firstWhere((i) => _dateGroupKey(i.createdAt) == entry.key)
                    .createdAt,
              ),
              isDark,
            ),
            const SizedBox(height: 8),
            ...entry.value.map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildCard(item, isDark),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildDateLabel(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.8,
          color: isDark
              ? AppColors.textSecondaryDark.withOpacity(0.7)
              : AppColors.textSecondaryLight,
        ),
      ),
    );
  }

  // ── card ──────────────────────────────────────────────────────────────────

  Widget _buildCard(HistoryItem item, bool isDark) {
    final severity = _severityOf(item.diseaseName);
    final vietName = DiseaseMapper.toVietnamese(item.diseaseName);

    return Material(
      color: isDark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _openDetail(item),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : AppColors.borderLight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Thumbnail
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 80,
                  height: 80,
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, progress) {
                            if (progress == null) return child;
                            return Container(
                              color: isDark
                                  ? const Color(0xFF1F2937)
                                  : const Color(0xFFE5E7EB),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.accent.withOpacity(0.6),
                                ),
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) =>
                              _placeholderThumb(isDark),
                        )
                      : _placeholderThumb(isDark),
                ),
              ),
              const SizedBox(width: 14),
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                vietName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimaryLight,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    size: 12,
                                    color: isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondaryLight,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    _timeOf(item.createdAt),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondaryLight,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        _buildConfidenceRing(item.confidence),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _buildSeverityBadge(severity, isDark),
                        const SizedBox(width: 8),
                        Text(
                          'Mức độ nghiêm trọng',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark
                                ? AppColors.textSecondaryDark.withOpacity(0.6)
                                : AppColors.textSecondaryLight.withOpacity(0.6),
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
      ),
    );
  }

  Widget _placeholderThumb(bool isDark) {
    return Container(
      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFE5E7EB),
      child: Icon(
        Icons.grass,
        size: 36,
        color: isDark ? Colors.white24 : Colors.black12,
      ),
    );
  }

  Widget _buildConfidenceRing(double confidence) {
    final pct = confidence * 100;
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: confidence.clamp(0.0, 1.0),
            strokeWidth: 2.5,
            color: AppColors.accent,
            backgroundColor: AppColors.accent.withOpacity(0.15),
          ),
          Text(
            '${pct.toStringAsFixed(0)}%',
            style: const TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.bold,
              color: AppColors.accent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSeverityBadge(_Severity severity, bool isDark) {
    final Color bg;
    final Color fg;
    final String label;

    switch (severity) {
      case _Severity.low:
        bg = isDark
            ? AppColors.accent.withOpacity(0.2)
            : AppColors.accent.withOpacity(0.13);
        fg = isDark ? AppColors.accent : AppColors.primary;
        label = 'Thấp';
      case _Severity.medium:
        bg = isDark
            ? AppColors.warning.withOpacity(0.2)
            : AppColors.warning.withOpacity(0.15);
        fg = isDark ? AppColors.warning : const Color(0xFFB45309);
        label = 'Trung bình';
      case _Severity.high:
        bg = isDark
            ? const Color(0xFFEF4444).withOpacity(0.2)
            : const Color(0xFFEF4444).withOpacity(0.12);
        fg = isDark ? const Color(0xFFF87171) : const Color(0xFFB91C1C);
        label = 'Cao';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
          color: fg,
        ),
      ),
    );
  }

  // ── empty / error states ──────────────────────────────────────────────────

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.history,
            size: 72,
            color: isDark
                ? AppColors.textSecondaryDark.withOpacity(0.3)
                : AppColors.textSecondaryLight.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Chưa có lịch sử quét',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark
                  ? AppColors.textSecondaryDark
                  : AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Hãy quét lá cây để bắt đầu.',
            style: TextStyle(
              fontSize: 14,
              color: isDark
                  ? AppColors.textSecondaryDark.withOpacity(0.6)
                  : AppColors.textSecondaryLight.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.wifi_off_rounded,
              size: 56,
              color: isDark
                  ? AppColors.textSecondaryDark.withOpacity(0.5)
                  : AppColors.textSecondaryLight.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'Không thể tải dữ liệu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadHistory,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Thử lại'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── navigation ────────────────────────────────────────────────────────────

  void _openDetail(HistoryItem item) {
    final result = PredictionResult(
      diseaseName: item.diseaseName,
      vietnameseName: DiseaseMapper.toVietnamese(item.diseaseName),
      scientificName: DiseaseMapper.getScientificName(item.diseaseName),
      imageUrl: item.imageUrl,
      confidence: item.confidence,
      description: 'Chưa có dữ liệu mô tả.',
      cause: 'Chưa có thông tin.',
      symptoms: 'Chưa có thông tin triệu chứng.',
      impact: DiseaseMapper.getImpact(item.diseaseName),
      treatments: [],
      medicines: [],
      isHealthy: DiseaseMapper.isHealthy(item.diseaseName),
      predictionId: item.predictionId,
    );
    Navigator.of(context).pushNamed(AppRouter.prediction, arguments: result);
  }
}
