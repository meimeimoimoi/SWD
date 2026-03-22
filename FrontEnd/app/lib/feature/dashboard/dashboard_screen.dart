import 'package:flutter/material.dart';

import '../../routes/app_router.dart';
import '../../share/constants/app_brand.dart';
import '../../share/services/history_service.dart';
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
  static const Color _primary = Color(0xFF2D7B31);
  static const Color _bg = Color(0xFFF6F8F6);
  static const Color _darkCard = Color(0xFF2D322B);
  static const Color _primaryFixed = Color(0xFFA4F69C);
  static const Color _secondaryContainer = Color(0xFFC9ECC1);
  static const Color _urgentTint = Color(0xFFB45309);
  static const Color _urgentBg = Color(0xFFFFF7ED);

  final HistoryService _historyService = HistoryService();

  String? _username;
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

  Future<void> _loadInsights({required bool silentRefresh}) async {
    if (!silentRefresh) {
      setState(() {
        _insightsLoading = true;
        _insightsError = null;
      });
    }

    final response = await _historyService.getHistory();
    if (!mounted) return;

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
      backgroundColor: _bg,
      appBar: _ArgivisionAppBar(
        username: _username,
        onOpenProfile: () => Navigator.pushNamed(context, AppRouter.profile),
        onOpenNotifications: () =>
            Navigator.pushNamed(context, AppRouter.notifications),
      ),
      bottomNavigationBar: const UserBottomNavBar(),
      body: RefreshIndicator(
        color: _primary,
        onRefresh: () => _loadInsights(silentRefresh: true),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
            _OwnerScanHero(
              onScan: () => Navigator.pushNamed(context, AppRouter.scan),
            ),
            const SizedBox(height: 20),
            if (!_insightsLoading || _insightsReady)
              _TreeIllnessOverviewCard(
                overview: _treeOverview,
                onViewAllTrees: () =>
                    Navigator.pushNamed(context, AppRouter.trees),
                onOpenTree: (summary) => Navigator.pushNamed(
                  context,
                  AppRouter.treeDetail,
                  arguments: summary,
                ),
                onStartScan: () => Navigator.pushNamed(context, AppRouter.scan),
              ),
            if (!_insightsLoading || _insightsReady)
              const SizedBox(height: 20),
            _InsightsPanel(
              blockingLoader: _insightsLoading && !_insightsReady,
              loading: _insightsLoading,
              errorMessage: _insightsError,
              recentRows: _recentRows,
              urgentRows: _urgentRows,
              onSeeAll: () => Navigator.pushNamed(context, AppRouter.history),
              onOpenItem: _openPrediction,
              onStartScan: () => Navigator.pushNamed(context, AppRouter.scan),
              onSeeTrees: () => Navigator.pushNamed(context, AppRouter.trees),
              onOpenTree: (summary) => Navigator.pushNamed(
                context,
                AppRouter.treeDetail,
                arguments: summary,
              ),
            ),
            const SizedBox(height: 28),
            Text(
              'GET A CLEAR SCAN',
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
              'COMMON THREATS',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    letterSpacing: 1.2,
                    fontWeight: FontWeight.w700,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Spot symptoms early—scan a leaf if something looks off.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    height: 1.35,
                  ),
            ),
            const SizedBox(height: 12),
            _PopularDiseasesCard(
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
  if (diff.inSeconds < 60) return 'Just now';
  if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
  if (diff.inHours < 24) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${dt.day}/${dt.month}/${dt.year}';
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
      return ('Healthy', const Color(0xFF16A34A), 1.0);
    case TreeHealthLevel.low:
      return ('Low concern', const Color(0xFFCA8A04), 0.7);
    case TreeHealthLevel.medium:
      return ('Needs watch', const Color(0xFFEA580C), 0.45);
    case TreeHealthLevel.high:
      return ('Urgent', const Color(0xFFDC2626), 0.18);
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
    return ('Improving', const Color(0xFF16A34A));
  }
  if (newest > oldest) {
    return ('Worsening', const Color(0xFFDC2626));
  }
  return ('Stable', const Color(0xFF6B7280));
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

class _TreeIllnessOverviewCard extends StatelessWidget {
  const _TreeIllnessOverviewCard({
    required this.overview,
    required this.onViewAllTrees,
    required this.onOpenTree,
    required this.onStartScan,
  });

  final _TreeOverviewVm? overview;
  final VoidCallback onViewAllTrees;
  final void Function(UserTreeSummary summary) onOpenTree;
  final VoidCallback onStartScan;

  static const _barRadius = BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    final o = overview;
    if (o == null || o.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _DashboardScreenState._secondaryContainer,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.forest_outlined,
                color: _DashboardScreenState._primary,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Plant overview',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Scans grouped by plant will show illness status and progress here.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                  ),
                ],
              ),
            ),
            TextButton(onPressed: onStartScan, child: const Text('Scan')),
          ],
        ),
      );
    }

    final total = o.totalPlants;
    final variants = <({int n, Color c, String short})>[
      (n: o.healthyCount, c: const Color(0xFF22C55E), short: 'OK'),
      (n: o.lowCount, c: const Color(0xFFEAB308), short: 'Low'),
      (n: o.mediumCount, c: const Color(0xFFF97316), short: 'Med'),
      (n: o.highCount, c: const Color(0xFFEF4444), short: 'Hi'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
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
                color: _DashboardScreenState._primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PLANT HEALTH OVERVIEW',
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
                  foregroundColor: _DashboardScreenState._primary,
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                child: const Text('All trees'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '$total ${total == 1 ? 'plant' : 'plants'} · ${o.totalScans} scans in history',
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
            'Status & progress (latest activity)',
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
      color: _DashboardScreenState._bg,
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
                '${row.statusLabel} · ${row.scanCount} ${row.scanCount == 1 ? 'scan' : 'scans'} · ${row.lastScanLabel}',
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
                  backgroundColor: Colors.grey.shade200,
                  color: row.statusColor,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Illness risk level (bar = relative status for this plant)',
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
    required this.onStartScan,
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
  final VoidCallback onStartScan;
  final VoidCallback onSeeTrees;
  final void Function(UserTreeSummary summary) onOpenTree;

  static ButtonStyle _linkButtonStyle(BuildContext context) =>
      TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        foregroundColor: _DashboardScreenState._primary,
        textStyle: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      );

  @override
  Widget build(BuildContext context) {
    if (blockingLoader) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: _DashboardScreenState._primary,
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
              color: _DashboardScreenState._urgentTint,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                'NEEDS URGENT ATTENTION',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.0,
                      fontWeight: FontWeight.w800,
                      color: _DashboardScreenState._urgentTint,
                    ),
              ),
            ),
            if (!loading && urgentRows.isNotEmpty)
              TextButton(
                onPressed: onSeeTrees,
                style: _linkButtonStyle(context),
                child: const Text('Trees'),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Plants with high-severity findings from your scan history.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                height: 1.35,
              ),
        ),
        const SizedBox(height: 12),
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
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: Text(
                'RECENT SCANS',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
            if (!loading && recentRows.isNotEmpty)
              TextButton(
                onPressed: onSeeAll,
                style: _linkButtonStyle(context),
                child: const Text('See all'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (errorMessage != null && recentRows.isEmpty)
          _InsightErrorBanner(message: errorMessage!)
        else if (recentRows.isEmpty)
          _RecentScansEmpty(onStartScan: onStartScan)
        else
          SizedBox(
            height: 104,
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

  @override
  Widget build(BuildContext context) {
    final label = item.diseaseName.trim().isEmpty ? 'Unknown' : item.diseaseName;
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          width: 236,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
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
                          color: Colors.grey.shade200,
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
                            color: Colors.grey.shade200,
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
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      timeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                            fontSize: 11,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      healthy ? 'Healthy' : 'Review',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: healthy
                            ? _DashboardScreenState._primary
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
  const _RecentScansEmpty({required this.onStartScan});

  final VoidCallback onStartScan;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _DashboardScreenState._secondaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.history,
              color: _DashboardScreenState._primary,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'No scans yet',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your latest leaf checks will show up here.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onStartScan,
            child: const Text('Scan'),
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
      color: _DashboardScreenState._urgentBg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: _DashboardScreenState._urgentTint.withValues(alpha: 0.35),
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
                      row.diseaseLabel,
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
                              color: _DashboardScreenState._urgentTint,
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
                  'HIGH',
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
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: _DashboardScreenState._primary,
            size: 28,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No plants are flagged as high severity right now. Keep scanning if you spot new symptoms.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    height: 1.4,
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
      backgroundColor: Colors.white.withValues(alpha: 0.92),
      surfaceTintColor: _DashboardScreenState._primary.withValues(alpha: 0.08),
      title: Row(
        children: [
          const Icon(Icons.eco, color: _DashboardScreenState._primary, size: 26),
          const SizedBox(width: 10),
          Text(
            AppBrand.homeHeader,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: _DashboardScreenState._primary,
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
        Padding(
          padding: const EdgeInsets.only(right: 12, left: 4),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onOpenProfile,
              borderRadius: BorderRadius.circular(20),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: _DashboardScreenState._secondaryContainer,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: _DashboardScreenState._primary,
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
    return Material(
      color: _DashboardScreenState._darkCard,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      elevation: 0,
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
                          color: _DashboardScreenState._primary
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'LEAF SCAN',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: _DashboardScreenState._primaryFixed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Scan for disease',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Upload or take a clear photo—we’ll analyze it in seconds.',
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
                      'Start scan',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: _DashboardScreenState._primaryFixed,
                      foregroundColor: const Color(0xFF1A3D16),
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
    'Fill the frame with one leaf; avoid harsh shadow on the spot you care about.',
    'Natural daylight works best—avoid yellow indoor bulbs if you can.',
    'Hold steady; blurry photos are harder for the model to read.',
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
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
                color: _DashboardScreenState._primary,
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
                        color: _DashboardScreenState._primary,
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
    required this.onSeeAll,
    required this.onDiseaseTap,
  });

  final VoidCallback onSeeAll;
  final VoidCallback onDiseaseTap;

  static const _items = <_DiseaseItem>[
    _DiseaseItem(
      title: 'Rice blast',
      subtitle: 'Magnaporthe oryzae • 1.2k reports',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuC6y89Z5i1M2Thl6LhQpTycTJTGYMvtg2HCf3H-MD0Vr4Mcpamjib5aWHNZYgQIA4J6zwq2s1Y_9zCUUsajgQSo2l3MjyDH-4oSMZi8361_NzaRhe2DUn4cNJU_fWKsh2cnOSMpcDaz5hF6BMbjh_X5d88pTy7Pq6zTROjJYVJsCS6I1AAPrrnzAEgLwih8ZaLPeV7fPlX77cP8APGyJeO-KRD6rF-gVVNvOvXlT9r7aqD0iI1_NzrLkE33HmJpO_7bTjNYgynnbMJn',
    ),
    _DiseaseItem(
      title: 'Corn rust',
      subtitle: 'Puccinia sorghi • 850 reports',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuArjtI0eX8p6lyO6zKqs_VP26c7cX52dATKkacXOpmwFXL592VGOy_l-isz4LWqf4u27s2Wp4ULwPdmb2gyAGdHxOEbLxl_rILW1LYMHAEW_oEromrkGB8z1hMeuWZ-jZkizptFLEeSRJiAPLyTvbwPQhkf9vY0yLFMi4MWKO5sKHskpQYNv3wn8dqP3I9GHy-zqZ34841dXcm6oAg3qzxNLGdpcXqsCDWcyag_jSP33y_SrAfEJsgmTooJ8tDgYZGSlel2pvJOTka5',
    ),
    _DiseaseItem(
      title: 'Citrus greening',
      subtitle: 'Candidatus Liberibacter • 420 reports',
      imageUrl:
          'https://lh3.googleusercontent.com/aida-public/AB6AXuAhft4NNrNQaJPDHb764AzrJj1rRVUnUiUCH86EGeaqZNxVyKNfZGF0K7_F_Zc2b9eSZ6FzTGJrooHXO4SFcmALzPsv3DC09tlFbrJFIzxBIUglTacGd5bJuG3mxFprJ0mqwws7w587HkhvMdBL185SimgFnNkaw40eWOkhluxwNtp2RODdZAYet88BWp4t1pI-44iBBuFRwXI3CT_-KlovOY0W2f281E0_AiNptjWFuV71yAlEfuV0y4GqHx-IFUBj10eoVk2rdiJP',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            if (i > 0) Divider(height: 1, color: Colors.grey.shade100),
            _DiseaseTile(item: _items[i], onTap: onDiseaseTap),
          ],
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: _DashboardScreenState._bg,
            child: TextButton(
              onPressed: onSeeAll,
              child: const Text(
                'Open my trees',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: _DashboardScreenState._primary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DiseaseItem {
  const _DiseaseItem({
    required this.title,
    required this.subtitle,
    required this.imageUrl,
  });
  final String title;
  final String subtitle;
  final String imageUrl;
}

class _DiseaseTile extends StatelessWidget {
  const _DiseaseTile({required this.item, required this.onTap});

  final _DiseaseItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Image.network(
                    item.imageUrl,
                    fit: BoxFit.cover,
                    cacheWidth: 112,
                    cacheHeight: 112,
                    filterQuality: FilterQuality.low,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey.shade200,
                      child: const Icon(Icons.spa, color: Colors.grey),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      item.subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
