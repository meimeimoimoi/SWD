import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../../share/services/dashboard_service.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/admin_app_bar_actions.dart';
import '../../share/widgets/admin_bottom_nav.dart';
import '../../share/widgets/admin_pop_scope.dart';
import '../../share/widgets/app_card.dart';
import '../../routes/app_router.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchAdminDashboard();
    });
  }

  static Map<String, dynamic>? _pickActiveModel(List<Map<String, dynamic>> models) {
    if (models.isEmpty) return null;
    for (final m in models) {
      if (m['isActive'] == true) return m;
    }
    for (final m in models) {
      if (m['isDefault'] == true) return m;
    }
    return models.first;
  }

  static String _scanTrendSubtitle(Map<String, dynamic>? predStats, int todayPredictions) {
    final trend = predStats?['dailyTrend'];
    if (trend is! List || trend.length < 4) {
      return '$todayPredictions hôm nay';
    }
    int sum(List<Map<String, dynamic>> slice) {
      var t = 0;
      for (final e in slice) {
        final c = e['count'];
        t += c is int ? c : (c is num ? c.toInt() : int.tryParse('$c') ?? 0);
      }
      return t;
    }

    final maps = trend.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    final half = maps.length ~/ 2;
    final recent = sum(maps.sublist(half));
    final older = sum(maps.sublist(0, half));
    if (older == 0) {
      return recent > 0 ? '+$recent tuần này' : '$todayPredictions hôm nay';
    }
    final pct = ((recent - older) / older * 100).round();
    final sign = pct >= 0 ? '+' : '';
    return '$sign$pct% so với tuần trước · $todayPredictions hôm nay';
  }

  static _ActivityUi _mapLogToActivity(ActivityLogItem log) {
    final action = log.action;
    final entity = log.entityName;
    final title = (log.description != null && log.description!.trim().isNotEmpty)
        ? log.description!.trim()
        : '$action · $entity';

    _ActivityBadgeKind kind;
    if (entity.toLowerCase().contains('prediction') ||
        action.toLowerCase().contains('prediction')) {
      kind = _ActivityBadgeKind.detected;
    } else if (action == 'Login' ||
        action == 'UpdateProfile' ||
        action.toLowerCase().contains('profile')) {
      kind = _ActivityBadgeKind.normal;
    } else {
      kind = _ActivityBadgeKind.warning;
    }

    return _ActivityUi(title: title, kind: kind);
  }

  Future<void> _openAllActivity(BuildContext context) async {
    final logs = await DashboardService().getAdminActivityLogs(count: 100);
    if (!context.mounted) return;
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return Scaffold(
            appBar: AppBar(title: const Text('Toàn bộ hoạt động')),
            body: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (_, i) {
                final log = logs[i];
                final ui = _mapLogToActivity(log);
                final when = _relativeTime(log.createdAt);
                final uid = log.userId;
                final sub = uid != null
                    ? 'Mã người dùng: #$uid • $when'
                    : 'Hệ thống • $when';
                return ListTile(
                  tileColor: theme.cardColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  title: Text(ui.title, maxLines: 2, overflow: TextOverflow.ellipsis),
                  subtitle: Text(sub),
                );
              },
            ),
          );
        },
      ),
    );
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
    final pageBg =
        isDark ? AppColors.darkBackground : AppColors.lightBackground;
    final appBarBackground =
        isDark ? Colors.transparent : AppColors.surfaceLight;
    final appBarShadow = isDark ? Colors.transparent : Colors.black12;
    final nf = NumberFormat.decimalPattern();

    final provider = context.watch<DashboardProvider>();
    final stats = provider.adminStats;
    final pred = provider.adminPredictionStats;
    final models = provider.adminModelAccuracy;
    final logs = provider.adminLogs;
    final activeModel = _pickActiveModel(models);

    final totalUsers = stats?.totalUsers ?? 0;
    final activeUsers = stats?.activeUsers ?? 0;
    final totalScans = stats?.totalPredictions ?? 0;
    final todayScans = stats?.todayPredictions ?? 0;

    double avgConf = 0;
    if (activeModel != null) {
      final ac = activeModel['averageConfidence'];
      if (ac is num) avgConf = ac.toDouble();
    } else if (pred != null) {
      final ac = pred['averageConfidence'];
      if (ac is num) avgConf = ac.toDouble();
    }
    final accuracyPct = (avgConf * 100).clamp(0.0, 100.0);

    final modelSubtitle = activeModel != null
        ? '${activeModel['modelName'] ?? 'Model'} v${activeModel['version'] ?? ''}'
            .trim()
        : 'Không có mô hình hoạt động';

    final warnings = provider.criticalFeedbackCount;

    return AdminPopScope(
      child: Scaffold(
        backgroundColor: pageBg,
        appBar: AppBar(
          backgroundColor: appBarBackground,
          surfaceTintColor: Colors.transparent,
          elevation: isDark ? 0 : 1,
          shadowColor: appBarShadow,
          title: Text(
            'Bảng điều khiển',
            style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
          ),
          actions: adminSecondaryAppBarActions(context),
        ),
        body: provider.isLoading && stats == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: () => provider.fetchAdminDashboard(),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                      children: [
                        Text(
                          'Tổng quan',
                          style: theme.textTheme.labelLarge?.copyWith(
                            color: textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.count(
                          crossAxisCount: 2,
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          mainAxisSpacing: 12,
                          crossAxisSpacing: 12,
                          childAspectRatio: 1.15,
                          children: [
                            _MetricCard(
                              title: 'Tổng người dùng',
                              value: nf.format(totalUsers),
                              subtitle: '$activeUsers tài khoản hoạt động',
                              subtitleColor: AppColors.primary,
                              icon: Icons.groups_outlined,
                              iconBackground: AppColors.primary.withValues(alpha: 0.12),
                            ),
                            _MetricCard(
                              title: 'Tổng lượt quét',
                              value: nf.format(totalScans),
                              subtitle:
                                  _scanTrendSubtitle(pred, todayScans),
                              subtitleColor: AppColors.primary,
                              icon: Icons.photo_camera_outlined,
                              iconBackground: AppColors.primary.withValues(alpha: 0.12),
                            ),
                            _MetricCard(
                              title: 'Độ chính xác',
                              value: '${accuracyPct.toStringAsFixed(1)}%',
                              subtitle: modelSubtitle,
                              subtitleColor: AppColors.primary,
                              icon: Icons.verified_outlined,
                              iconBackground: AppColors.primary.withValues(alpha: 0.12),
                            ),
                            _MetricCard(
                              title: 'Cảnh báo',
                              value: warnings.toString().padLeft(2, '0'),
                              subtitle: warnings > 0
                                  ? 'Cần xử lý ngay'
                                  : 'Không có phản hồi khẩn cấp',
                              subtitleColor: warnings > 0
                                  ? Colors.red.shade400
                                  : textSecondary,
                              icon: Icons.warning_amber_rounded,
                              iconBackground: warnings > 0
                                  ? Colors.red.withValues(alpha: 0.12)
                                  : AppColors.primary.withValues(alpha: 0.12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Hoạt động gần đây',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: textPrimary,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: () => _openAllActivity(context),
                              child: const Text('Xem tất cả'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        AppCard(
                          padding: const EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 4,
                          ),
                          child: logs.isEmpty
                              ? Padding(
                                  padding: const EdgeInsets.all(20),
                                  child: Text(
                                    'Chưa có hoạt động nào',
                                    style: TextStyle(color: textSecondary),
                                  ),
                                )
                              : Column(
                                  children: [
                                    for (var i = 0;
                                        i < logs.length && i < 6;
                                        i++)
                                      _ActivityRow(
                                        log: logs[i],
                                        ui: _mapLogToActivity(logs[i]),
                                        textPrimary: textPrimary,
                                        textSecondary: textSecondary,
                                      ),
                                  ],
                                ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.pushNamed(
                              context,
                              AppRouter.adminFeedback,
                            ),
                            icon: const Icon(Icons.rate_review_outlined),
                            label: const Text('Mở phản hồi'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
        bottomNavigationBar:
            const AdminBottomNav(selected: AdminShellTab.dashboard),
      ),
    );
  }
}

enum _ActivityBadgeKind { detected, normal, warning }

class _ActivityUi {
  const _ActivityUi({required this.title, required this.kind});

  final String title;
  final _ActivityBadgeKind kind;
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.subtitleColor,
    required this.icon,
    required this.iconBackground,
  });

  final String title;
  final String value;
  final String subtitle;
  final Color subtitleColor;
  final IconData icon;
  final Color iconBackground;

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

    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBackground,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 20, color: AppColors.primary),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: theme.textTheme.headlineSmall?.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.labelSmall?.copyWith(
              color: subtitleColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.log,
    required this.ui,
    required this.textPrimary,
    required this.textSecondary,
  });

  final ActivityLogItem log;
  final _ActivityUi ui;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final (Color bg, Color fg, String badgeLabel) = switch (ui.kind) {
      _ActivityBadgeKind.detected => (
          const Color(0xFFFFF4E5),
          const Color(0xFFB45309),
          'Đã phát hiện',
        ),
      _ActivityBadgeKind.normal => (
          AppColors.primary.withValues(alpha: 0.1),
          AppColors.primary,
          'Bình thường',
        ),
      _ActivityBadgeKind.warning => (
          Colors.red.withValues(alpha: 0.08),
          Colors.red.shade700,
          'Cảnh báo',
        ),
    };

    final isDark = theme.brightness == Brightness.dark;

    final when = _relativeTime(log.createdAt);
    final uid = log.userId;
    final sub = uid != null
        ? 'Mã người dùng: #$uid • $when'
        : 'Hệ thống • $when';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkControlFill : bg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              ui.kind == _ActivityBadgeKind.normal
                  ? Icons.check_circle_outline
                  : ui.kind == _ActivityBadgeKind.detected
                      ? Icons.eco_outlined
                      : Icons.local_florist_outlined,
              color: fg,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ui.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: isDark ? fg.withValues(alpha: 0.15) : bg,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              badgeLabel,
              style: theme.textTheme.labelSmall?.copyWith(
                color: fg,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime dt) {
  final diff = DateTime.now().difference(dt);
  if (diff.inDays >= 1) return '${diff.inDays} ngày trước';
  if (diff.inHours >= 1) return '${diff.inHours} giờ trước';
  if (diff.inMinutes >= 1) return '${diff.inMinutes} phút trước';
  return 'Vừa xong';
}
