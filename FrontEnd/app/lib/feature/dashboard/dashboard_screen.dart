import 'package:flutter/material.dart';

import '../../routes/app_router.dart';
import '../../share/constants/app_brand.dart';
import '../../share/theme/app_colors.dart';
import '../../share/theme/app_layout.dart';
import '../../share/services/history_service.dart';
import '../../share/services/prediction_service.dart';
import '../../share/services/storage_service.dart';
import '../../share/utils/disease_mapper.dart';
import '../../share/widgets/user_bottom_nav_bar.dart';
import '../prediction/prediction_screen.dart';
import '../trees/user_tree_models.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final HistoryService _historyService = HistoryService();
  final PredictionService _predictionService = PredictionService();

  String? _username;
  List<CommonThreatItem> _commonThreats = [];
  List<_RecentScanRowVm> _recentRows = [];
  List<_UrgentPlantRowVm> _urgentRows = [];
  _TreeOverviewVm? _treeOverview;
  bool _insightsLoading = true;
  bool _insightsReady = false;
  String? _insightsError;

  @override
  void initState() {
    super.initState();
    _loadUsername();
    _loadInsights(silentRefresh: false);
  }

  Future<void> _loadUsername() async {
    final u = await StorageService.getUsername();
    if (mounted) setState(() => _username = u);
  }

  bool get _dashboardFullyEmpty {
    if (!_insightsReady) return false;
    if (_insightsError != null) return false;
    final o = _treeOverview;
    final noPlantData = o == null || o.isEmpty;
    return noPlantData && _urgentRows.isEmpty && _recentRows.isEmpty;
  }

  Future<void> _loadInsights({required bool silentRefresh}) async {
    if (!silentRefresh) {
      setState(() {
        _insightsLoading = true;
        _insightsError = null;
      });
    }

    final awaited = await Future.wait([
      _historyService.getHistory(),
      _predictionService.fetchCommonThreats(take: 5),
    ]);
    if (!mounted) return;

    final response = awaited[0] as HistoryListResponse;
    final threats = awaited[1] as List<CommonThreatItem>;

    final hadCachedInsights = _recentRows.isNotEmpty ||
        _urgentRows.isNotEmpty ||
        (_treeOverview != null && !_treeOverview!.isEmpty);
    final now = DateTime.now();
    if (response.success) {
      final sorted = [...response.data]
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
      final trees = UserTreeSummary.fromHistory(sorted);
      final urgentSummaries = trees
          .where(
            (t) => t.health == TreeHealthLevel.high && t.hasConcern,
          )
          .take(5)
          .toList();

      setState(() {
        _recentRows = sorted
            .take(5)
            .map(
              (e) => _RecentScanRowVm(
                item: e,
                timeLabel: _dashboardRelativeTime(e.createdAt, now),
                healthy: DiseaseMapper.isHealthy(e.diseaseName),
              ),
            )
            .toList();
        _urgentRows = urgentSummaries
            .map((s) => _UrgentPlantRowVm.fromSummary(s, now))
            .toList();
        _treeOverview = _TreeOverviewVm.fromSummaries(trees, now);
        _commonThreats = threats;
        _insightsLoading = false;
        _insightsReady = true;
        _insightsError = null;
      });
    } else {
      setState(() {
        if (!silentRefresh) {
          _recentRows = [];
          _urgentRows = [];
          _treeOverview = null;
        }
        _commonThreats = threats;
        _insightsLoading = false;
        _insightsReady = true;
        _insightsError = response.message;
      });
      if (silentRefresh && hadCachedInsights && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _openPrediction(HistoryItem item) {
    Navigator.pushNamed(
      context,
      AppRouter.prediction,
      arguments: PredictionResult.fromHistoryItem(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _ArgivisionAppBar(
        username: _username,
        onOpenProfile: () => Navigator.pushNamed(context, AppRouter.profile),
        onOpenNotifications: () =>
            Navigator.pushNamed(context, AppRouter.notifications),
      ),
      bottomNavigationBar: const UserBottomNavBar(),
      body: RefreshIndicator(
        color: AppColors.brandAccentReadable(context),
        onRefresh: () => _loadInsights(silentRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppLayout.screenPaddingH,
            AppLayout.screenPaddingV,
            AppLayout.screenPaddingH,
            28,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            _OwnerScanHero(
              onScan: () => Navigator.pushNamed(context, AppRouter.scan),
            ),
            const SizedBox(height: 16),
            if (_insightsLoading && !_insightsReady)
              _InsightsPanel(
                blockingLoader: true,
                loading: true,
                errorMessage: _insightsError,
                recentRows: _recentRows,
                urgentRows: _urgentRows,
                onSeeAll: () => Navigator.pushNamed(context, AppRouter.history),
                onOpenItem: _openPrediction,
                onSeeTrees: () => Navigator.pushNamed(context, AppRouter.trees),
                onOpenTree: (summary) => Navigator.pushNamed(
                  context,
                  AppRouter.treeDetail,
                  arguments: summary,
                ),
              )
            else if (_dashboardFullyEmpty)
              _CompactDashboardEmpty(
                onScan: () => Navigator.pushNamed(context, AppRouter.scan),
                onTrees: () => Navigator.pushNamed(context, AppRouter.trees),
              )
            else ...[
              if (!_insightsLoading || _insightsReady) ...[
                _TreeIllnessOverviewCard(
                  overview: _treeOverview,
                  onViewAllTrees: () =>
                      Navigator.pushNamed(context, AppRouter.trees),
                  onOpenTree: (summary) => Navigator.pushNamed(
                    context,
                    AppRouter.treeDetail,
                    arguments: summary,
                  ),
                ),
                const SizedBox(height: 16),
              ],
              _InsightsPanel(
                blockingLoader: false,
                loading: _insightsLoading,
                errorMessage: _insightsError,
                recentRows: _recentRows,
                urgentRows: _urgentRows,
                onSeeAll: () => Navigator.pushNamed(context, AppRouter.history),
                onOpenItem: _openPrediction,
                onSeeTrees: () => Navigator.pushNamed(context, AppRouter.trees),
                onOpenTree: (summary) => Navigator.pushNamed(
                  context,
                  AppRouter.treeDetail,
                  arguments: summary,
                ),
              ),
            ],
            const SizedBox(height: 28),
            Text(
              'HƯỚNG DẪN QUÉT',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 12),
            const _ScanTipsCard(),
            const SizedBox(height: 28),
            Text(
              'CÁC MỐI ĐE DỌA PHỔ BIẾN',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w800,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textPrimaryDark
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Phát hiện sớm các triệu chứng—quét lá nếu thấy điều gì bất thường.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.textSecondaryDark
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 12),
            _PopularDiseasesCard(
              items: _commonThreats,
              insightsReady: _insightsReady,
              onSeeAll: () => Navigator.pushNamed(context, AppRouter.trees),
              onDiseaseTap: () => Navigator.pushNamed(context, AppRouter.scan),
            ),
          ],
        ),
        ),
      ),
    );
  }
}

String _dashboardRelativeTime(DateTime dt, DateTime now) {
  final diff = now.difference(dt);
  if (diff.inSeconds < 60) return 'Vừa xong';
  if (diff.inMinutes < 60) return '${diff.inMinutes} phút trước';
  if (diff.inHours < 24) return '${diff.inHours} giờ trước';
  if (diff.inDays < 7) return '${diff.inDays} ngày trước';
  return '${dt.day}/${dt.month}/${dt.year}';
}

String _formatCommonThreatSubtitle(CommonThreatItem it) {
  final sci = it.scientificName?.trim();
  final n = it.reportCount;
  final rep =
      n >= 1000 ? '${(n / 1000).toStringAsFixed(1)}k báo cáo' : '$n báo cáo';
  if (sci != null && sci.isNotEmpty) return '$sci • $rep';
  return rep;
}

int _predictionConcernScore(HistoryItem p) {
  if (DiseaseMapper.isHealthy(p.diseaseName)) return 0;
  final sev = (p.illnessSeverity ?? '').toLowerCase();
  if (sev.contains('cao') ||
      sev.contains('high') ||
      sev.contains('nặng') ||
      sev.contains('severe')) {
    return 3;
  }
  if (sev.contains('trung') ||
      sev.contains('medium') ||
      sev.contains('moderate')) {
    return 2;
  }
  switch (p.diseaseName) {
    case 'Leaf Blast':
    case 'Bacterial Leaf Blight':
      return 3;
    default:
      return 1;
  }
}

(String label, Color color, double progress01) _healthLevelPresentation(
  TreeHealthLevel level,
) {
  switch (level) {
    case TreeHealthLevel.healthy:
      return ('Khỏe mạnh', const Color(0xFF16A34A), 1.0);
    case TreeHealthLevel.low:
      return ('Cảnh báo thấp', const Color(0xFFCA8A04), 0.7);
    case TreeHealthLevel.medium:
      return ('Cần theo dõi', const Color(0xFFEA580C), 0.45);
    case TreeHealthLevel.high:
      return ('Khẩn cấp', const Color(0xFFDC2626), 0.18);
  }
}

(String label, Color color) _trendFromPredictions(UserTreeSummary s) {
  final p = s.predictions;
  if (p.length < 2) {
    return ('—', const Color(0xFF9CA3AF));
  }
  final newest = _predictionConcernScore(p.first);
  final oldest = _predictionConcernScore(p.last);
  if (newest < oldest) {
    return ('Đang cải thiện', const Color(0xFF16A34A));
  }
  if (newest > oldest) {
    return ('Đang tệ đi', const Color(0xFFDC2626));
  }
  return ('Ổn định', const Color(0xFF6B7280));
}

class _TreeOverviewVm {
  const _TreeOverviewVm({
    required this.totalPlants,
    required this.totalScans,
    required this.healthyCount,
    required this.lowCount,
    required this.mediumCount,
    required this.highCount,
    required this.rows,
  });

  final int totalPlants;
  final int totalScans;
  final int healthyCount;
  final int lowCount;
  final int mediumCount;
  final int highCount;
  final List<_TreeProgressRowVm> rows;

  bool get isEmpty => totalPlants == 0;

  factory _TreeOverviewVm.fromSummaries(
    List<UserTreeSummary> trees,
    DateTime now,
  ) {
    if (trees.isEmpty) {
      return const _TreeOverviewVm(
        totalPlants: 0,
        totalScans: 0,
        healthyCount: 0,
        lowCount: 0,
        mediumCount: 0,
        highCount: 0,
        rows: [],
      );
    }
    var h = 0;
    var l = 0;
    var m = 0;
    var hi = 0;
    var scans = 0;
    for (final t in trees) {
      scans += t.scanCount;
      switch (t.health) {
        case TreeHealthLevel.healthy:
          h++;
          break;
        case TreeHealthLevel.low:
          l++;
          break;
        case TreeHealthLevel.medium:
          m++;
          break;
        case TreeHealthLevel.high:
          hi++;
          break;
      }
    }
    final topRows = trees
        .take(5)
        .map((s) => _TreeProgressRowVm.fromSummary(s, now))
        .toList();
    return _TreeOverviewVm(
      totalPlants: trees.length,
      totalScans: scans,
      healthyCount: h,
      lowCount: l,
      mediumCount: m,
      highCount: hi,
      rows: topRows,
    );
  }
}

class _TreeProgressRowVm {
  const _TreeProgressRowVm({
    required this.summary,
    required this.statusLabel,
    required this.statusColor,
    required this.progress01,
    required this.trendLabel,
    required this.trendColor,
    required this.lastScanLabel,
    required this.scanCount,
  });

  final UserTreeSummary summary;
  final String statusLabel;
  final Color statusColor;
  final double progress01;
  final String trendLabel;
  final Color trendColor;
  final String lastScanLabel;
  final int scanCount;

  factory _TreeProgressRowVm.fromSummary(UserTreeSummary s, DateTime now) {
    final pres = _healthLevelPresentation(s.health);
    final trend = _trendFromPredictions(s);
    return _TreeProgressRowVm(
      summary: s,
      statusLabel: pres.$1,
      statusColor: pres.$2,
      progress01: pres.$3,
      trendLabel: trend.$1,
      trendColor: trend.$2,
      lastScanLabel: _dashboardRelativeTime(s.latestScan, now),
      scanCount: s.scanCount,
    );
  }
}

class _CompactDashboardEmpty extends StatelessWidget {
  const _CompactDashboardEmpty({
    required this.onScan,
    required this.onTrees,
  });

  final VoidCallback onScan;
  final VoidCallback onTrees;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.black.withValues(alpha: 0.06),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.dashboard_outlined,
                color: AppColors.brandAccentReadable(context),
                size: 22,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Sức khỏe & Hoạt động',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Quét lá để xem tình trạng cây, cảnh báo khẩn cấp và lịch sử của bạn — tất cả ở một nơi.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: cs.onSurfaceVariant,
                  height: 1.35,
                ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ElevatedButton(
                onPressed: onScan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brandAccent,
                  foregroundColor: AppColors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  elevation: 0,
                ),
                child: const Text('Mở máy quét'),
              ),
              TextButton(
                onPressed: onTrees,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.brandAccentReadable(context),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
                child: const Text('Cây của tôi'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TreeIllnessOverviewCard extends StatelessWidget {
  const _TreeIllnessOverviewCard({
    required this.overview,
    required this.onViewAllTrees,
    required this.onOpenTree,
  });

  final _TreeOverviewVm? overview;
  final VoidCallback onViewAllTrees;
  final void Function(UserTreeSummary summary) onOpenTree;

  static const _barRadius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final o = overview;
    if (o == null || o.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF2A2A2A)
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.softGreenContainer,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.forest_outlined,
                color: AppColors.brandAccent,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tổng quan cây trồng',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Sức khỏe từng cây sẽ hiển thị sau khi bạn quét và liên kết cây.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.25,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final total = o.totalPlants;
    final variants = <({int n, Color c, String short})>[
      (n: o.healthyCount, c: const Color(0xFF22C55E), short: 'OK'),
      (n: o.lowCount, c: const Color(0xFFEAB308), short: 'Thấp'),
      (n: o.mediumCount, c: const Color(0xFFF97316), short: 'Vừa'),
      (n: o.highCount, c: const Color(0xFFEF4444), short: 'Cao'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.black.withValues(alpha: 0.06),
        ),
        boxShadow: Theme.of(context).brightness == Brightness.dark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(
                Icons.insights_outlined,
                size: 22,
                color: AppColors.brandAccentReadable(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TỔNG QUAN SỨC KHỎE CÂY',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        letterSpacing: 1.0,
                        fontWeight: FontWeight.w800,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ),
              TextButton(
                onPressed: onViewAllTrees,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  foregroundColor: AppColors.brandAccentReadable(context),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                child: const Text('Tất cả cây'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$total cây · ${o.totalScans} lần quét trong lịch sử',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: _barRadius,
            child: SizedBox(
              height: 10,
              child: Row(
                children: [
                  for (final v in variants)
                    if (v.n > 0)
                      Expanded(
                        flex: v.n,
                        child: ColoredBox(color: v.c),
                      ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 4,
            children: [
              for (final v in variants)
                if (v.n > 0)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: v.c,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${v.short}: ${v.n}',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
            ],
          ),
          const Divider(height: 22),
          Text(
            'Trạng thái & Tiến độ (Hoạt động mới nhất)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 10),
          for (var i = 0; i < o.rows.length; i++) ...[
            if (i > 0) const SizedBox(height: 12),
            _TreeProgressRowTile(
              row: o.rows[i],
              onTap: () => onOpenTree(o.rows[i].summary),
            ),
          ],
        ],
      ),
    );
  }
}

class _TreeProgressRowTile extends StatelessWidget {
  const _TreeProgressRowTile({
    required this.row,
    required this.onTap,
  });

  final _TreeProgressRowVm row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      row.summary.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: row.trendColor.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      row.trendLabel,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: row.trendColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${row.statusLabel} · ${row.scanCount} lần quét · ${row.lastScanLabel}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: row.progress01,
                  minHeight: 6,
                  backgroundColor: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF2A2A2A)
                      : Colors.grey.shade200,
                  color: row.statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Mức độ rủi ro bệnh tật (thanh = trạng thái tương đối của cây này)',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      fontSize: 9,
                      color: Colors.grey.shade500,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecentScanRowVm {
  const _RecentScanRowVm({
    required this.item,
    required this.timeLabel,
    required this.healthy,
  });

  final HistoryItem item;
  final String timeLabel;
  final bool healthy;
}

class _UrgentPlantRowVm {
  const _UrgentPlantRowVm({
    required this.summary,
    required this.diseaseLabel,
    required this.timeLabel,
  });

  final UserTreeSummary summary;
  final String diseaseLabel;
  final String timeLabel;

  factory _UrgentPlantRowVm.fromSummary(
    UserTreeSummary summary,
    DateTime now,
  ) {
    final latest =
        summary.predictions.isNotEmpty ? summary.predictions.first : null;
    final disease = latest?.diseaseName.trim().isNotEmpty == true
        ? latest!.diseaseName
        : 'Disease detected';
    final time = latest != null
        ? _dashboardRelativeTime(latest.createdAt, now)
        : '';
    return _UrgentPlantRowVm(
      summary: summary,
      diseaseLabel: disease,
      timeLabel: time,
    );
  }
}

class _InsightsPanel extends StatelessWidget {
  const _InsightsPanel({
    required this.blockingLoader,
    required this.loading,
    required this.errorMessage,
    required this.recentRows,
    required this.urgentRows,
    required this.onSeeAll,
    required this.onOpenItem,
    required this.onSeeTrees,
    required this.onOpenTree,
  });

  final bool blockingLoader;
  final bool loading;
  final String? errorMessage;
  final List<_RecentScanRowVm> recentRows;
  final List<_UrgentPlantRowVm> urgentRows;
  final VoidCallback onSeeAll;
  final void Function(HistoryItem item) onOpenItem;
  final VoidCallback onSeeTrees;
  final void Function(UserTreeSummary summary) onOpenTree;

  static ButtonStyle _linkButtonStyle(BuildContext context) =>
      TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        foregroundColor: AppColors.brandAccentReadable(context),
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (blockingLoader) {
      return SizedBox(
        height: 140,
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: AppColors.brandAccentReadable(context),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(
              Icons.warning_amber_rounded,
              size: 18,
              color: AppColors.urgentTint,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'CẦN CHÚ Ý KHẨN CẤP',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w800,
                      color: AppColors.urgentTint,
                    ),
              ),
            ),
            if (!loading && urgentRows.isNotEmpty)
              TextButton(
                onPressed: onSeeTrees,
                style: _linkButtonStyle(context),
                child: const Text('Cây trồng'),
              ),
          ],
        ),
        if (urgentRows.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            'Kết quả quét có mức độ nghiêm trọng cao.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  height: 1.3,
                ),
          ),
          const SizedBox(height: 10),
        ] else
          const SizedBox(height: 8),
        if (urgentRows.isEmpty)
          const _UrgentAllClearCard()
        else
          Column(
            children: [
              for (var i = 0; i < urgentRows.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _UrgentPlantTile(
                  key: ValueKey<String>(
                    'urgent-${urgentRows[i].summary.treeId ?? i}-${urgentRows[i].summary.displayName}',
                  ),
                  row: urgentRows[i],
                  onTap: () => onOpenTree(urgentRows[i].summary),
                ),
              ],
            ],
          ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: Text(
                'QUÉT GẦN ĐÂY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
              ),
            ),
            if (!loading && recentRows.isNotEmpty)
              TextButton(
                onPressed: onSeeAll,
                style: _linkButtonStyle(context),
                child: const Text('Xem tất cả'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (errorMessage != null && recentRows.isEmpty)
          _InsightErrorBanner(message: errorMessage!)
        else if (recentRows.isEmpty)
          _RecentScansEmpty(onOpenHistory: onSeeAll)
        else
          SizedBox(
            height: 122,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              cacheExtent: 280,
              itemCount: recentRows.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final row = recentRows[index];
                return _RecentScanTile(
                  key: ValueKey<int>(row.item.predictionId),
                  item: row.item,
                  healthy: row.healthy,
                  timeLabel: row.timeLabel,
                  onTap: () => onOpenItem(row.item),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _RecentScanTile extends StatelessWidget {
  const _RecentScanTile({
    super.key,
    required this.item,
    required this.healthy,
    required this.timeLabel,
    required this.onTap,
  });

  final HistoryItem item;
  final bool healthy;
  final String timeLabel;
  final VoidCallback onTap;

  static String? _treeLine(HistoryItem item) {
    final n = item.treeName?.trim();
    if (n != null && n.isNotEmpty) return n;
    if (item.treeId != null) return 'Plant #${item.treeId}';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final raw = item.diseaseName.trim().isEmpty ? 'Unknown' : item.diseaseName;
    final label = DiseaseMapper.toDisplayName(raw);
    final treeLine = _treeLine(item);
    final confPct = (item.confidence * 100).clamp(0.0, 100.0);

    return Material(
      color: theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 248,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF2A2A2A)
                  : Colors.black.withValues(alpha: 0.06),
            ),
          ),
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 72,
                  height: 72,
                  child: item.imageUrl.isEmpty
                      ? ColoredBox(
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : Colors.grey.shade200,
                          child: Icon(Icons.image_outlined,
                              color: Colors.grey.shade500),
                        )
                      : Image.network(
                          item.imageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 160,
                          cacheHeight: 160,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: isDark
                                ? const Color(0xFF2A2A2A)
                                : Colors.grey.shade200,
                            child: Icon(Icons.broken_image_outlined,
                                color: Colors.grey.shade500),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      label,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: titleColor,
                        height: 1.2,
                      ),
                    ),
                    if (treeLine != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        treeLine,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                        ),
                      ),
                    ],
                    const SizedBox(height: 3),
                    Text(
                      '$timeLabel · ${confPct.toStringAsFixed(0)}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: secondary,
                        fontSize: 11,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      healthy ? 'Khỏe mạnh' : 'Xem xét',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: healthy
                            ? AppColors.brandAccentReadable(context)
                            : const Color(0xFFCA8A04),
                      ),
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
}

class _RecentScansEmpty extends StatelessWidget {
  const _RecentScansEmpty({required this.onOpenHistory});

  final VoidCallback onOpenHistory;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.history,
            size: 20,
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondaryLight,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Chưa có bản quét nào',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimaryLight,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sử dụng thẻ quét ở trên, sau đó kéo để làm mới.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondaryLight,
                        height: 1.3,
                      ),
                ),
                TextButton(
                  onPressed: onOpenHistory,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    foregroundColor: AppColors.brandAccentReadable(context),
                  ),
                  child: const Text('Mở lịch sử đầy đủ'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _UrgentPlantTile extends StatelessWidget {
  const _UrgentPlantTile({
    super.key,
    required this.row,
    required this.onTap,
  });

  final _UrgentPlantRowVm row;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final summary = row.summary;
    return Material(
      color: AppColors.urgentSurface,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColors.urgentTint.withValues(alpha: 0.35),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 52,
                  height: 52,
                  child: summary.heroImageUrl.isEmpty
                      ? ColoredBox(
                          color: Colors.orange.shade100,
                          child: Icon(Icons.park, color: Colors.orange.shade800),
                        )
                      : Image.network(
                          summary.heroImageUrl,
                          fit: BoxFit.cover,
                          cacheWidth: 120,
                          cacheHeight: 120,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: Colors.orange.shade100,
                            child: Icon(Icons.park, color: Colors.orange.shade800),
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
                      summary.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      row.diseaseLabel.isEmpty ? 'Phát hiện bệnh' : row.diseaseLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                    if (row.timeLabel.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        row.timeLabel,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppColors.urgentTint,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFEA580C).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'CAO',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF9A3412),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: Colors.grey.shade500),
            ],
          ),
        ),
      ),
    );
  }
}

class _UrgentAllClearCard extends StatelessWidget {
  const _UrgentAllClearCard();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.check_circle_outline,
            color: AppColors.brandAccentReadable(context),
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Hiện không có cây nào ở mức độ nghiêm trọng cao.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.3,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightErrorBanner extends StatelessWidget {
  const _InsightErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade100),
      ),
      child: Text(
        message,
        style: TextStyle(
          fontSize: 12,
          color: Colors.red.shade900,
          height: 1.35,
        ),
      ),
    );
  }
}

class _ArgivisionAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _ArgivisionAppBar({
    this.username,
    this.onOpenProfile,
    this.onOpenNotifications,
  });

  final String? username;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenNotifications;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    final trimmed = username?.trim() ?? '';
    final initials = trimmed.isEmpty
        ? 'U'
        : trimmed.substring(0, 1).toUpperCase();

    return AppBar(
      automaticallyImplyLeading: false,
      elevation: 0,
      scrolledUnderElevation: 0.5,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? Theme.of(context).scaffoldBackgroundColor.withValues(alpha: 0.92)
          : AppColors.scrimLight(0.92),
      surfaceTintColor: AppColors.brandAccent.withValues(alpha: 0.08),
      title: Row(
        children: [
          Icon(
            Icons.eco,
            color: AppColors.brandAccentReadable(context),
            size: 26,
          ),
          const SizedBox(width: 10),
          Text(
            AppBrand.homeHeader,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandAccentReadable(context),
                  letterSpacing: -0.2,
                ),
          ),
        ],
      ),
      actions: [
        IconButton(
          onPressed: onOpenNotifications,
          icon: Icon(
            Icons.notifications_outlined,
            color: Colors.grey.shade600,
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pushNamed(context, AppRouter.cart),
          icon: Icon(
            Icons.shopping_cart_outlined,
            color: Colors.grey.shade600,
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenProfile,
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: AppColors.softGreenContainer,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: AppColors.brandAccent,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _OwnerScanHero extends StatelessWidget {
  const _OwnerScanHero({required this.onScan});

  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  const Color(0xFF2A2F28),
                  AppColors.forestCardDark,
                  const Color(0xFF1A1D18),
                ]
              : [
                  const Color(0xFF3A4038),
                  AppColors.forestCardDark,
                  const Color(0xFF232821),
                ],
        ),
        boxShadow: AppLayout.heroCardShadows(context),
        border: Border.all(
          color: AppColors.brandAccentOnDark.withValues(alpha: 0.16),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onScan,
        child: Stack(
          children: [
            Positioned(
              right: -24,
              bottom: -24,
              child: Icon(
                Icons.document_scanner_outlined,
                size: 140,
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
                          color: AppColors.brandAccent
                              .withValues(alpha: 0.35),
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
                  const Text(
                    'Quét sâu bệnh',
                    style: TextStyle(
                      color: AppColors.onPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Tải lên hoặc chụp ảnh rõ nét—chúng tôi sẽ phân tích trong vài giây.',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  FilledButton.icon(
                    onPressed: onScan,
                    icon: const Icon(Icons.photo_camera_outlined, size: 22),
                    label: const Text(
                      'Bắt đầu quét',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandAccentOnDark,
                      foregroundColor: const Color(0xFF1A3D16),
                      elevation: 4,
                      shadowColor: Colors.black.withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScanTipsCard extends StatelessWidget {
  const _ScanTipsCard();

  static const _tips = <String>[
    'Chụp đầy khung hình với một chiếc lá; tránh bóng râm gay gắt tại điểm bạn quan tâm.',
    'Ánh sáng ban ngày tự nhiên là tốt nhất—tránh bóng đèn vàng trong nhà nếu có thể.',
    'Giữ chắc tay; ảnh bị nhòe sẽ khiến mô hình khó đọc hơn.',
  ];

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.brandAccentReadable(context);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF2A2A2A)
              : Colors.black.withValues(alpha: 0.06),
        ),
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
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PopularDiseasesCard extends StatelessWidget {
  const _PopularDiseasesCard({
    required this.items,
    required this.insightsReady,
    required this.onSeeAll,
    required this.onDiseaseTap,
  });

  final List<CommonThreatItem> items;
  final bool insightsReady;
  final VoidCallback onSeeAll;
  final VoidCallback onDiseaseTap;

  @override
  Widget build(BuildContext context) {
    if (!insightsReady) {
      return Container(
        height: 120,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.forestCardBorder
                : Colors.black.withValues(alpha: 0.06),
          ),
        ),
        child: SizedBox(
          width: 28,
          height: 28,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: AppColors.brandAccentReadable(context),
          ),
        ),
      );
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor =
        isDark ? AppColors.forestCardDark : Theme.of(context).colorScheme.surface;
    final dividerColor = isDark ? AppColors.forestCardBorder : Colors.grey.shade200;
    final borderColor =
        isDark ? AppColors.forestCardBorder : Colors.black.withValues(alpha: 0.06);

    if (items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          'Chưa có dữ liệu quét. Khi các kết quả tích lũy, các bệnh phổ biến nhất sẽ xuất hiện ở đây.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: isDark
            ? const []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Divider(height: 1, thickness: 1, color: dividerColor),
            _CommonThreatTile(
              item: items[i],
              onTap: onDiseaseTap,
              panelColor: cardColor,
              isDark: isDark,
            ),
          ],
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 4, 8, 10),
            child: Center(
              child: TextButton(
                onPressed: onSeeAll,
                child: Text(
                  'Mở cây của tôi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: AppColors.brandAccentReadable(context),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommonThreatTile extends StatelessWidget {
  const _CommonThreatTile({
    required this.item,
    required this.onTap,
    required this.panelColor,
    required this.isDark,
  });

  final CommonThreatItem item;
  final VoidCallback onTap;
  final Color panelColor;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final titleColor = isDark
        ? AppColors.textPrimaryDark
        : Theme.of(context).colorScheme.onSurface;
    final subColor = isDark
        ? AppColors.textSecondaryDark
        : Theme.of(context).colorScheme.onSurfaceVariant;
    final chevronColor =
        isDark ? AppColors.textSecondaryDark : Colors.grey.shade500;

    final raw = item.imageUrl?.trim() ?? '';
    final resolved =
        raw.isEmpty ? '' : HistoryItem.resolveImageUrl(raw);

    return Material(
      color: panelColor,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.brandAccent.withValues(alpha: 0.12),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: resolved.isEmpty
                      ? ColoredBox(
                          color: isDark
                              ? const Color(0xFF1A1D18)
                              : Colors.grey.shade200,
                          child: Icon(Icons.eco_outlined,
                              color: Colors.grey.shade500),
                        )
                      : Image.network(
                          resolved,
                          fit: BoxFit.cover,
                          cacheWidth: 112,
                          cacheHeight: 112,
                          filterQuality: FilterQuality.low,
                          errorBuilder: (_, __, ___) => ColoredBox(
                            color: isDark
                                ? const Color(0xFF1A1D18)
                                : Colors.grey.shade200,
                            child: Icon(Icons.eco_outlined,
                                color: Colors.grey.shade500),
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
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                            fontSize: 15,
                          ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _formatCommonThreatSubtitle(item),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: subColor,
                            height: 1.25,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 22, color: chevronColor),
            ],
          ),
        ),
      ),
    );
  }
}
