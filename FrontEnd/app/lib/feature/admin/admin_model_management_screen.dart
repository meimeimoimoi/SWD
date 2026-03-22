import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../../routes/app_router.dart';
import '../../share/services/dashboard_service.dart' show DashboardService;
import '../../share/theme/app_colors.dart';
import '../../share/widgets/admin_bottom_nav.dart';
import '../../share/widgets/admin_pop_scope.dart';

class AdminModelManagementScreen extends StatefulWidget {
  const AdminModelManagementScreen({super.key});

  @override
  State<AdminModelManagementScreen> createState() =>
      _AdminModelManagementScreenState();
}

const Color _kGuidePrimary = Color(0xFF2D7B31);
const Color _kGuideBgLight = Color(0xFFF6F8F6);

class _AdminModelManagementScreenState
    extends State<AdminModelManagementScreen> {
  final DashboardService _api = DashboardService();
  final TextEditingController _search = TextEditingController();

  List<Map<String, dynamic>> _accuracy = [];
  List<Map<String, dynamic>> _models = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      context.read<DashboardProvider>().fetchAdminData();
      await _load();
    });
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final acc = await _api.getModelAccuracy();
    final mods = await _api.getAdminModelsList();
    if (mounted) {
      setState(() {
        _accuracy = acc;
        _models = mods;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _rows {
    final base = _models.isNotEmpty ? _models : _accuracy;
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return base;
    return base.where((m) {
      final name =
          '${m['modelName'] ?? m['ModelName'] ?? ''}'.toLowerCase();
      final ver = '${m['version'] ?? m['Version'] ?? ''}'.toLowerCase();
      return name.contains(q) || ver.contains(q);
    }).toList();
  }

  int get _runningCount {
    if (_models.isEmpty) return 0;
    return _models
        .where((m) => (m['isActive'] ?? m['IsActive']) == true)
        .length;
  }

  Map<String, dynamic>? _metricsFor(int modelVersionId) {
    for (final m in _accuracy) {
      if (_asInt(m['modelVersionId'] ?? m['ModelVersionId']) ==
          modelVersionId) {
        return m;
      }
    }
    return null;
  }

  Future<void> _onActivate(int id) async {
    final ok = await _api.activateAdminModel(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Model activated' : 'Activation failed'),
        backgroundColor: ok ? _kGuidePrimary : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) {
      await context.read<DashboardProvider>().fetchAdminData();
      await _load();
    }
  }

  Future<void> _openUploadScreen() async {
    final result = await Navigator.pushNamed<dynamic>(
      context,
      AppRouter.adminModelUpload,
    );
    if (!mounted) return;
    if (result == true) {
      await context.read<DashboardProvider>().fetchAdminData();
      await _load();
    }
  }

  void _onToggleActive({
    required bool currentlyActive,
    required int modelVersionId,
  }) {
    if (!currentlyActive) {
      _onActivate(modelVersionId);
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'To switch the running model, activate another version from the list.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showModelDetail(
    BuildContext context, {
    required Map<String, dynamic> m,
    required Map<String, dynamic>? metrics,
  }) {
    final id = _asInt(m['modelVersionId'] ?? m['ModelVersionId']);
    final name = '${m['modelName'] ?? m['ModelName'] ?? 'Model'}';
    final ver = '${m['version'] ?? m['Version'] ?? ''}';
    final preds = metrics != null
        ? (metrics['totalPredictions'] ?? metrics['TotalPredictions'] ?? 0)
        : 0;
    final conf = metrics != null
        ? (metrics['averageConfidence'] ?? metrics['AverageConfidence'] ?? 0)
        : 0;
    final rate = metrics != null
        ? (metrics['positiveRatingRate'] ?? metrics['PositiveRatingRate'] ?? 0)
        : 0;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Version: $ver · ID: $id',
              style: GoogleFonts.spaceGrotesk(
                fontSize: 13,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Predictions: $preds\nAvg confidence: ${_pct(conf)}\nPositive ratings: ${_pct(rate)}',
              style: GoogleFonts.spaceGrotesk(fontSize: 14, height: 1.45),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : _kGuideBgLight;
    final textPrimary =
        isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A);
    final textMuted =
        isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B);

    return AdminPopScope(
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: _kGuidePrimary),
                )
              : RefreshIndicator(
                  color: _kGuidePrimary,
                  onRefresh: () async {
                    await context.read<DashboardProvider>().fetchAdminData();
                    await _load();
                  },
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
                        sliver: SliverToBoxAdapter(
                          child: _ModelsAppBar(
                            textPrimary: textPrimary,
                            textMuted: textMuted,
                            onMenuSelected: (value) {
                              if (value == 'feedback') {
                                Navigator.pushNamed(
                                  context,
                                  AppRouter.adminFeedback,
                                );
                              } else if (value == 'settings') {
                                Navigator.pushNamed(
                                  context,
                                  AppRouter.adminSettings,
                                );
                              } else if (value == 'refresh') {
                                _load();
                                context.read<DashboardProvider>().fetchAdminData();
                              }
                            },
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _SearchField(
                            controller: _search,
                            isDark: isDark,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _UploadBannerButton(onPressed: _openUploadScreen),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
                        sliver: SliverToBoxAdapter(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.layers_outlined,
                                    color: _kGuidePrimary,
                                    size: 22,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Model list',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      color: textPrimary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 5,
                                ),
                                decoration: BoxDecoration(
                                  color: _kGuidePrimary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  '$_runningCount Running',
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: _kGuidePrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_rows.isEmpty)
                        SliverPadding(
                          padding: const EdgeInsets.all(32),
                          sliver: SliverToBoxAdapter(
                            child: Text(
                              _models.isEmpty && _accuracy.isEmpty
                                  ? 'No models yet.'
                                  : 'No search results.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: textMuted),
                            ),
                          ),
                        )
                      else
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final m = _rows[index];
                                final id = _asInt(
                                  m['modelVersionId'] ?? m['ModelVersionId'],
                                );
                                final name =
                                    '${m['modelName'] ?? m['ModelName'] ?? ''}';
                                final ver =
                                    '${m['version'] ?? m['Version'] ?? ''}';
                                final desc =
                                    '${m['description'] ?? m['Description'] ?? ''}'
                                        .trim();
                                final metrics = _metricsFor(id) ??
                                    (_rows == _accuracy ? m : null);
                                final conf = metrics != null
                                    ? (metrics['averageConfidence'] ??
                                        metrics['AverageConfidence'] ??
                                        0)
                                    : 0;
                                final active =
                                    (m['isActive'] ?? m['IsActive']) == true;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: _GuideModelCard(
                                    name: name.isEmpty ? 'Model #$id' : name,
                                    versionLine:
                                        'Version: ${ver.isEmpty ? '—' : ver} • ONNX Runtime'
                                        '${desc.isNotEmpty ? ' • $desc' : ''}',
                                    accuracyPct: _pct(conf),
                                    latencyLabel: '—',
                                    isActive: active == true,
                                    isDark: isDark,
                                    textPrimary: textPrimary,
                                    textMuted: textMuted,
                                    onToggle: (v) {
                                      if (v && !active) {
                                        _onActivate(id);
                                      } else if (!v && active) {
                                        _onToggleActive(
                                          currentlyActive: true,
                                          modelVersionId: id,
                                        );
                                      }
                                    },
                                    onDetail: () => _showModelDetail(
                                      context,
                                      m: m,
                                      metrics: metrics,
                                    ),
                                  ),
                                );
                              },
                              childCount: _rows.length,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
        bottomNavigationBar: const AdminBottomNav(currentIndex: 1),
      ),
    );
  }

  String _pct(dynamic v) {
    if (v == null) return '—';
    final n = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0;
    return '${(n * 100).toStringAsFixed(1)}%';
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

class _ModelsAppBar extends StatelessWidget {
  const _ModelsAppBar({
    required this.textPrimary,
    required this.textMuted,
    required this.onMenuSelected,
  });

  final Color textPrimary;
  final Color textMuted;
  final void Function(String) onMenuSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (Navigator.of(context).canPop())
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.arrow_back_rounded, color: textMuted),
            tooltip: 'Back',
          )
        else
          const SizedBox(width: 8),
        Expanded(
          child: Text(
            'Manage models',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: textPrimary,
              letterSpacing: -0.3,
            ),
          ),
        ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert_rounded, color: textMuted),
          onSelected: onMenuSelected,
          itemBuilder: (ctx) => [
            const PopupMenuItem(value: 'refresh', child: Text('Refresh')),
            const PopupMenuItem(
              value: 'feedback',
              child: Text('Feedback'),
            ),
            const PopupMenuItem(
              value: 'settings',
              child: Text('Settings'),
            ),
          ],
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.isDark,
  });

  final TextEditingController controller;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 14,
        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: 'Search models…',
        hintStyle: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          color: isDark ? Colors.white38 : Colors.grey.shade500,
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: _kGuidePrimary.withValues(alpha: 0.65),
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _kGuidePrimary.withValues(alpha: 0.15),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kGuidePrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      ),
    );
  }
}

class _UploadBannerButton extends StatelessWidget {
  const _UploadBannerButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: _kGuidePrimary,
      borderRadius: BorderRadius.circular(14),
      elevation: 3,
      shadowColor: _kGuidePrimary.withValues(alpha: 0.35),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.upload_file_rounded, color: AppColors.onPrimary),
              const SizedBox(width: 10),
              Text(
                'Upload new model (.onnx)',
                style: GoogleFonts.spaceGrotesk(
                  color: AppColors.onPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GuideModelCard extends StatelessWidget {
  const _GuideModelCard({
    required this.name,
    required this.versionLine,
    required this.accuracyPct,
    required this.latencyLabel,
    required this.isActive,
    required this.isDark,
    required this.textPrimary,
    required this.textMuted,
    required this.onToggle,
    required this.onDetail,
  });

  final String name;
  final String versionLine;
  final String accuracyPct;
  final String latencyLabel;
  final bool isActive;
  final bool isDark;
  final Color textPrimary;
  final Color textMuted;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDetail;

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final borderC = isActive
        ? _kGuidePrimary.withValues(alpha: 0.12)
        : (isDark ? AppColors.borderDark : const Color(0xFFE2E8F0));

    final metricBgActive = _kGuidePrimary.withValues(alpha: isDark ? 0.14 : 0.06);
    final metricBgIdle = isDark
        ? AppColors.borderDark.withValues(alpha: 0.45)
        : const Color(0xFFF8FAFC);

    final titleColor =
        isActive ? textPrimary : textPrimary.withValues(alpha: 0.55);
    final valueColor =
        isActive ? _kGuidePrimary : textMuted.withValues(alpha: 0.85);

    return Opacity(
      opacity: isActive ? 1 : 0.88,
      child: Material(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        elevation: isDark ? 0 : 0.5,
        shadowColor: Colors.black26,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: borderC),
          ),
          padding: const EdgeInsets.all(18),
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
                          name,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: titleColor,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          versionLine,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            color: textMuted,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: isActive,
                    activeColor: _kGuidePrimary,
                    activeTrackColor: _kGuidePrimary.withValues(alpha: 0.45),
                    onChanged: onToggle,
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: _MetricBox(
                      label: 'ACCURACY',
                      value: accuracyPct,
                      background: isActive ? metricBgActive : metricBgIdle,
                      valueColor: valueColor,
                      labelMuted: !isActive,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _MetricBox(
                      label: 'LATENCY',
                      value: latencyLabel,
                      background: isActive ? metricBgActive : metricBgIdle,
                      valueColor: valueColor,
                      labelMuted: !isActive,
                      isDark: isDark,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isActive
                              ? const Color(0xFF22C55E)
                              : textMuted.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isActive ? 'Active' : 'Paused',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? const Color(0xFF16A34A)
                              : textMuted,
                        ),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: onDetail,
                    style: TextButton.styleFrom(
                      foregroundColor:
                          isActive ? _kGuidePrimary : textMuted,
                    ),
                    icon: const Icon(Icons.chevron_right_rounded, size: 18),
                    iconAlignment: IconAlignment.end,
                    label: Text(
                      'Details',
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricBox extends StatelessWidget {
  const _MetricBox({
    required this.label,
    required this.value,
    required this.background,
    required this.valueColor,
    required this.labelMuted,
    required this.isDark,
  });

  final String label;
  final String value;
  final Color background;
  final Color valueColor;
  final bool labelMuted;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: labelMuted
                  ? textMutedConst(isDark)
                  : (isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }

  Color textMutedConst(bool isDark) =>
      isDark ? AppColors.darkMuted : const Color(0xFF94A3B8);
}
