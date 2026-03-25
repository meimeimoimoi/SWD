import 'package:flutter/material.dart';

import '../../share/constants/api_config.dart';
import '../../share/models/server_host_status.dart';
import '../../share/services/dashboard_service.dart';
import '../../share/services/prediction_service.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/admin_app_bar_actions.dart';
import '../../share/widgets/admin_bottom_nav.dart';
import '../../share/widgets/admin_pop_scope.dart';
import '../../share/widgets/app_card.dart';

class AdminServerManagementScreen extends StatefulWidget {
  const AdminServerManagementScreen({super.key});

  @override
  State<AdminServerManagementScreen> createState() =>
      _AdminServerManagementScreenState();
}

class _AdminServerManagementScreenState
    extends State<AdminServerManagementScreen> {
  final DashboardService _api = DashboardService();
  final PredictionService _prediction = PredictionService();

  ServerHostStatusSimple? _simple;
  ServerHostStatusDetail? _detail;
  Map<String, dynamic> _healthSnapshot = {};
  bool _predictionHealthy = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);

    try {
      final results = await Future.wait([
        _api.getAdminServerStatusSimple(),
        _api.getAdminServerStatusDetail(),
        _api.getHealthChecks(),
        _prediction.isPredictionServiceHealthy(),
      ]);

      if (!mounted) return;

      setState(() {
        _simple = results[0] as ServerHostStatusSimple?;
        _detail = results[1] as ServerHostStatusDetail?;
        _healthSnapshot = results[2] as Map<String, dynamic>;
        _predictionHealthy = results[3] as bool;
        _loading = false;
      });
    } catch (_) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
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

    return AdminPopScope(
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            'Máy chủ',
            style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
          ),
          actions: [
            ...adminSecondaryAppBarActions(context),
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
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 88),
                    children: [
                      Text(
                        'Tổng quan máy chủ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Các thông số trực tiếp từ tiến trình API và thiết bị (chỉ dành cho quản trị viên).',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _OverviewCard(
                        simple: _simple ?? _detail,
                        detail: _detail,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Dịch vụ',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _ServiceStrip(
                        health: _healthSnapshot,
                        predictionOk: _predictionHealthy,
                        textPrimary: textPrimary,
                        textSecondary: textSecondary,
                      ),
                      const SizedBox(height: 20),
                      if (_detail != null) ...[
                        Text(
                          'Chi tiết thực thi',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: textPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _DetailCard(
                          detail: _detail!,
                          textPrimary: textPrimary,
                          textSecondary: textSecondary,
                        ),
                      ],
                    ],
                  ),
                ),
        ),
        bottomNavigationBar:
            const AdminBottomNav(selected: AdminShellTab.server),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({
    required this.simple,
    required this.detail,
    required this.textPrimary,
    required this.textSecondary,
  });

  final ServerHostStatusSimple? simple;
  final ServerHostStatusDetail? detail;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final s = simple;
    if (s == null) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        child: Text(
          'Không có thông số',
          style: theme.textTheme.bodyMedium?.copyWith(color: textSecondary),
        ),
      );
    }

    final memPct = s.machineMemoryUsedPercent;
    final cpu = detail?.estimatedProcessCpuPercent;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.memory, color: AppColors.primary, size: 26),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.machineName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${s.environmentName} · ${s.processorCount} CPU logic · .NET ${s.dotNetVersion}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _metricRow(
            theme,
            'Thời gian hoạt động',
            _formatUptime(s.processUptimeSeconds),
            textPrimary,
            textSecondary,
          ),
          const SizedBox(height: 12),
          if (memPct != null) ...[
            _labeledProgress(
              theme,
              label: 'Bộ nhớ thiết bị đang sử dụng',
              value: (memPct / 100).clamp(0.0, 1.0),
              caption:
                  '${memPct.toStringAsFixed(1)}% · ${_fmtMb(s.machineTotalMemoryMb)} tổng · ${_fmtMb(s.machineAvailableMemoryMb)} trống.',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
            const SizedBox(height: 12),
          ] else ...[
            Text(
              'Bộ nhớ thiết bị: không khả dụng trên máy chủ này',
              style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
            ),
            const SizedBox(height: 12),
          ],
          if (s.machineTotalMemoryMb != null && s.machineTotalMemoryMb! > 0)
            _labeledProgress(
              theme,
              label: 'Bộ nhớ tiến trình API (Working set)',
              value: _processRamFraction(s),
              caption:
                  '${s.processWorkingSetMb.toStringAsFixed(1)} MB working set · ${s.processPrivateMemoryMb.toStringAsFixed(1)} MB riêng tư',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            )
          else
            _metricRow(
              theme,
              'RAM tiến trình',
              '${s.processWorkingSetMb.toStringAsFixed(1)} MB working set · '
                  '${s.processPrivateMemoryMb.toStringAsFixed(1)} MB riêng tư',
              textPrimary,
              textSecondary,
            ),
          if (cpu != null) ...[
            const SizedBox(height: 12),
            _labeledProgress(
              theme,
              label: 'CPU tiến trình API (mẫu)',
              value: (cpu / 100).clamp(0.0, 1.0),
              caption: '${cpu.toStringAsFixed(1)}% trong khoảng ~120 ms',
              textPrimary: textPrimary,
              textSecondary: textSecondary,
            ),
          ],
        ],
      ),
    );
  }

  double _processRamFraction(ServerHostStatusSimple s) {
    final total = s.machineTotalMemoryMb;
    if (total == null || total <= 0) return 0;
    final frac = s.processWorkingSetMb / total;
    return frac.clamp(0.0, 1.0);
  }

  static String _fmtMb(double? mb) {
    if (mb == null) return '—';
    if (mb >= 1024) return '${(mb / 1024).toStringAsFixed(2)} GB';
    return '${mb.toStringAsFixed(0)} MB';
  }

  static String _formatUptime(double seconds) {
    final d = Duration(seconds: seconds.round());
    final parts = <String>[];
    if (d.inDays > 0) parts.add('${d.inDays}d');
    final h = d.inHours.remainder(24);
    if (h > 0) parts.add('${h}h');
    final m = d.inMinutes.remainder(60);
    if (m > 0 && d.inDays < 2) parts.add('${m}m');
    if (parts.isEmpty) return '${seconds.toStringAsFixed(0)}s';
    return parts.join(' ');
  }

  static Widget _metricRow(
    ThemeData theme,
    String label,
    String value,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  static Widget _labeledProgress(
    ThemeData theme, {
    required String label,
    required double value,
    required String caption,
    required Color textPrimary,
    required Color textSecondary,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(color: textPrimary),
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: value > 0 ? value : null,
            minHeight: 10,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          caption,
          style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({
    required this.detail,
    required this.textPrimary,
    required this.textSecondary,
  });

  final ServerHostStatusDetail detail;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    String bytesToMb(int b) => (b / (1024 * 1024)).toStringAsFixed(1);

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tiến trình & Dọn rác (GC)',
            style: theme.textTheme.titleSmall?.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
          _kv(theme, 'PID', '${detail.processId}', textPrimary, textSecondary),
          _kv(theme, 'Luồng', '${detail.threadCount}', textPrimary,
              textSecondary),
          _kv(theme, 'Tay cầm (Handles)', '${detail.handleCount}', textPrimary,
              textSecondary),
          if (detail.processStartTimeUtc != null)
            _kv(
              theme,
              'Bắt đầu (UTC)',
              detail.processStartTimeUtc!.toIso8601String(),
              textPrimary,
              textSecondary,
            ),
          const SizedBox(height: 8),
          Text(
            detail.osDescription,
            style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            'GC heap ${bytesToMb(detail.gcHeapSizeBytes)} MB · '
            'tổng theo dõi ${bytesToMb(detail.gcTotalMemoryBytes)} MB',
            style: theme.textTheme.bodySmall?.copyWith(color: textPrimary),
          ),
          Text(
            'Ngưỡng tải cao ${bytesToMb(detail.gcHighMemoryLoadThresholdBytes)} MB',
            style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
          const SizedBox(height: 6),
          Text(
            'Lượt thu gom  gen0 ${detail.gcGen0Collections} · '
            'gen1 ${detail.gcGen1Collections} · gen2 ${detail.gcGen2Collections}',
            style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
        ],
      ),
    );
  }

  static Widget _kv(
    ThemeData theme,
    String k,
    String v,
    Color textPrimary,
    Color textSecondary,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 112,
            child: Text(
              k,
              style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
            ),
          ),
          Expanded(
            child: SelectableText(
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
}

class _ServiceStrip extends StatelessWidget {
  const _ServiceStrip({
    required this.health,
    required this.predictionOk,
    required this.textPrimary,
    required this.textSecondary,
  });

  final Map<String, dynamic> health;
  final bool predictionOk;
  final Color textPrimary;
  final Color textSecondary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _pill(
            theme,
            '/health/live',
            health['liveError'] == null,
            textPrimary,
            textSecondary,
          ),
          _pill(
            theme,
            '/health/ready',
            health['readyError'] == null,
            textPrimary,
            textSecondary,
          ),
          _pill(
            theme,
            '/health',
            health['rootError'] == null,
            textPrimary,
            textSecondary,
          ),
          _pill(
            theme,
            ApiPaths.predictionHealth,
            predictionOk,
            textPrimary,
            textSecondary,
          ),
        ],
      ),
    );
  }

  static Widget _pill(
    ThemeData theme,
    String label,
    bool ok,
    Color textPrimary,
    Color textSecondary,
  ) {
    final color = ok ? Colors.green.shade700 : Colors.red.shade700;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
        color: color.withValues(alpha: 0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ok ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
