import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_router.dart';
import '../../share/constants/app_brand.dart';
import '../../share/services/history_service.dart';
import '../../share/services/treatment_api_service.dart';
import '../../share/theme/app_colors.dart';
import '../../share/theme/app_layout.dart';
import '../../share/utils/disease_mapper.dart';
import 'user_illness_detail_screen.dart';
import 'user_tree_models.dart';

class TreeDetailScreen extends StatefulWidget {
  const TreeDetailScreen({super.key, required this.summary});

  final UserTreeSummary summary;

  @override
  State<TreeDetailScreen> createState() => _TreeDetailScreenState();
}

class _TreeDetailScreenState extends State<TreeDetailScreen> {
  final TreatmentApiService _treatments = TreatmentApiService();
  Map<int, List<TreatmentRecommendationItem>> _byIllnessId = {};
  bool _loadingRx = true;

  UserTreeSummary get s => widget.summary;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    final ids = s.illnessIds.toList();
    final map = <int, List<TreatmentRecommendationItem>>{};
    for (final id in ids) {
      map[id] = await _treatments.getRecommendationsForIllness(id);
    }
    if (!mounted) return;
    setState(() {
      _byIllnessId = map;
      _loadingRx = false;
    });
  }

  List<HistoryItem> get _illnessRows {
    final seen = <String>{};
    final out = <HistoryItem>[];
    for (final p in s.predictions) {
      final key = p.illnessId != null
          ? 'i${p.illnessId}'
          : 'd:${p.diseaseName}';
      if (seen.add(key)) out.add(p);
    }
    return out;
  }

  List<TreatmentRecommendationItem> get _allHealingSteps {
    final merged = <int, TreatmentRecommendationItem>{};
    for (final list in _byIllnessId.values) {
      for (final r in list) {
        merged[r.solutionId] = r;
      }
    }
    final values = merged.values.toList()
      ..sort((a, b) => a.solutionId.compareTo(b.solutionId));
    return values;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Plant details',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(
          AppLayout.screenPaddingH,
          AppLayout.screenPaddingV,
          AppLayout.screenPaddingH,
          32,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: s.heroImageUrl.isEmpty
                    ? Container(
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: const Icon(Icons.park, size: 64),
                      )
                    : Image.network(
                        s.heroImageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              s.displayName,
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w800,
                color: theme.brightness == Brightness.dark
                    ? AppColors.textPrimaryDark
                    : AppColors.textPrimaryLight,
              ),
            ),
            if (s.scientificName != null && s.scientificName!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                s.scientificName!,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            if (s.predictions.first.treeDescription != null &&
                s.predictions.first.treeDescription!.trim().isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                s.predictions.first.treeDescription!.trim(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.brightness == Brightness.dark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondaryLight,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 24),
            _sectionTitle(context, 'Disease & treatment'),
            const SizedBox(height: 10),
            if (_illnessRows.isEmpty)
              Text(
                'No disease recorded from scans yet.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ..._illnessRows.map((p) => _IllnessSolutionCard(
                    item: p,
                    recommendations: p.illnessId != null
                        ? (_byIllnessId[p.illnessId!] ?? const [])
                        : const [],
                    loading: _loadingRx,
                    onOpenDetail: () {
                      Navigator.pushNamed(
                        context,
                        AppRouter.userIllnessDetail,
                        arguments: UserIllnessDetailArgs(
                          item: p,
                          recommendations: p.illnessId != null
                              ? (_byIllnessId[p.illnessId!] ?? const [])
                              : const [],
                        ),
                      );
                    },
                  )),
            const SizedBox(height: 28),
            _sectionTitle(context, 'Monitoring history'),
            const SizedBox(height: 10),
            ...s.predictions.map((p) => _TimelineTile(item: p)),
            const SizedBox(height: 28),
            _sectionTitle(context, 'Recovery suggestions'),
            const SizedBox(height: 8),
            Text(
              'Suggestions from the ${AppBrand.name} treatment library (when a disease code is linked).',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 12),
            if (_loadingRx)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: CircularProgressIndicator(color: AppColors.brandAccent),
                ),
              )
            else if (_allHealingSteps.isEmpty)
              Text(
                s.illnessIds.isEmpty
                    ? 'Disease code not linked — record it in the system for detailed steps.'
                    : 'No treatment options in the database for this disease (these diseases).',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              )
            else
              ..._allHealingSteps.asMap().entries.map(
                    (e) => _HealingStepCard(index: e.key + 1, item: e.value),
                  ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.pushNamed(context, AppRouter.history),
              icon: const Icon(Icons.history),
              label: const Text('View full scan history'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String t) {
    final theme = Theme.of(context);
    final muted = theme.brightness == Brightness.dark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    return Text(
      t.toUpperCase(),
      style: theme.textTheme.labelSmall?.copyWith(
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
            color: muted,
          ),
    );
  }
}

class _IllnessSolutionCard extends StatelessWidget {
  const _IllnessSolutionCard({
    required this.item,
    required this.recommendations,
    required this.loading,
    required this.onOpenDetail,
  });

  final HistoryItem item;
  final List<TreatmentRecommendationItem> recommendations;
  final bool loading;
  final VoidCallback onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = item.diseaseName.trim().isEmpty
        ? 'Unknown'
        : item.diseaseName;
    final sci = item.scientificName?.trim().isNotEmpty == true
        ? item.scientificName!
        : DiseaseMapper.getScientificName(item.diseaseName);
    final healthy = DiseaseMapper.isHealthy(item.diseaseName);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: AppColors.brandAccent.withValues(alpha: 0.12)),
      ),
      child: InkWell(
        onTap: onOpenDetail,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.outline,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                sci,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.brandAccent,
                  fontStyle: FontStyle.italic,
                ),
              ),
            if (item.symptoms != null && item.symptoms!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                'Symptoms',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item.symptoms!.trim(),
                style: theme.textTheme.bodySmall?.copyWith(height: 1.35),
              ),
            ],
            if (healthy)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  'Status: no serious disease detected.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.green.shade800,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            if (!healthy) ...[
              const SizedBox(height: 10),
              Text(
                'Suggested actions',
                style: theme.textTheme.labelLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              if (loading)
                const LinearProgressIndicator(minHeight: 2, color: AppColors.brandAccent)
              else if (recommendations.isEmpty)
                Text(
                  item.illnessId == null
                      ? 'No illness code — automatic treatments unavailable.'
                      : 'No treatment for this illness code.',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                )
              else
                ...recommendations.map(
                  (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.check_circle_outline, size: 18, color: AppColors.brandAccent),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                r.solutionName ?? 'Solution #${r.solutionId}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (r.description != null &&
                                  r.description!.trim().isNotEmpty)
                                Text(
                                  r.description!.trim(),
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    height: 1.35,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              if (r.treeStageName != null)
                                Text(
                                  'Plant stage: ${r.treeStageName}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: theme.colorScheme.outline,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.item});

  final HistoryItem item;

  static String _treeLabel(HistoryItem item) {
    final n = item.treeName?.trim();
    if (n != null && n.isNotEmpty) return n;
    if (item.treeId != null) return 'Plant #${item.treeId}';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final titleColor =
        isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final bodyColor =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    final d = item.createdAt;
    final date =
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

    final diseaseLabel = DiseaseMapper.toDisplayName(
      item.diseaseName.trim().isEmpty ? 'Unknown' : item.diseaseName,
    );
    final treeLine = _treeLabel(item);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 52,
              height: 52,
              child: item.imageUrl.isEmpty
                  ? Container(color: Colors.grey.shade200)
                  : Image.network(
                      item.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          Container(color: Colors.grey.shade200),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  diseaseLabel,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: titleColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    treeLine.isNotEmpty ? treeLine : 'No plant linked',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: treeLine.isNotEmpty
                          ? AppColors.primary
                          : bodyColor,
                      fontWeight: treeLine.isNotEmpty
                          ? FontWeight.w600
                          : FontWeight.w500,
                      fontStyle: treeLine.isEmpty
                          ? FontStyle.italic
                          : FontStyle.normal,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  date,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: bodyColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Confidence: ${(item.confidence * 100).toStringAsFixed(1)}%',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: bodyColor,
                    fontWeight: FontWeight.w500,
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

class _HealingStepCard extends StatelessWidget {
  const _HealingStepCard({required this.index, required this.item});

  final int index;
  final TreatmentRecommendationItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.brandAccent.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.brandAccent.withValues(alpha: 0.15)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 16,
            backgroundColor: AppColors.brandAccent,
            child: Text(
              '$index',
              style: const TextStyle(
                color: AppColors.onPrimary,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.solutionName ?? 'Treatment step',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (item.description != null &&
                    item.description!.trim().isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.description!.trim(),
                      style: theme.textTheme.bodySmall?.copyWith(height: 1.4),
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
