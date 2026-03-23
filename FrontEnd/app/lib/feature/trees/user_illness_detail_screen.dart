import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../share/services/dashboard_service.dart';
import '../../share/services/history_service.dart';
import '../../share/services/treatment_api_service.dart';
import '../../share/utils/disease_mapper.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/user_bottom_nav_bar.dart';

const Color _kBgLight = Color(0xFFF6F8F6);

class UserIllnessDetailArgs {
  const UserIllnessDetailArgs({
    required this.item,
    required this.recommendations,
  });

  final HistoryItem item;
  final List<TreatmentRecommendationItem> recommendations;
}

class UserIllnessDetailScreen extends StatefulWidget {
  const UserIllnessDetailScreen({
    super.key,
    required this.item,
    required this.recommendations,
  });

  final HistoryItem item;
  final List<TreatmentRecommendationItem> recommendations;

  @override
  State<UserIllnessDetailScreen> createState() =>
      _UserIllnessDetailScreenState();
}

class _UserIllnessDetailScreenState extends State<UserIllnessDetailScreen> {
  final DashboardService _api = DashboardService();
  final TreatmentApiService _treatmentApi = TreatmentApiService();
  Map<String, dynamic>? _illnessRow;
  bool _loadingApi = false;

  @override
  void initState() {
    super.initState();
    final id = widget.item.illnessId;
    if (id != null) {
      _fetchIllness(id);
    }
  }

  Future<void> _fetchIllness(int id) async {
    setState(() => _loadingApi = true);
    final fromPublic = await _treatmentApi.getDiseaseDetail(id);
    final row = fromPublic ?? await _api.getIllnessById(id);
    if (!mounted) return;
    setState(() {
      _loadingApi = false;
      _illnessRow = row;
    });
  }

  String? _pick(Map<String, dynamic>? m, List<String> keys) {
    if (m == null) return null;
    for (final k in keys) {
      final v = m[k]?.toString();
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  String _heroImageUrl() {
    final row = _illnessRow;
    if (row != null) {
      final imgs = row['images'] ?? row['imageUrls'] ?? row['IllnessImages'];
      if (imgs is List && imgs.isNotEmpty) {
        final first = imgs.first;
        if (first is String && first.isNotEmpty) {
          return HistoryItem.resolveImageUrl(first);
        }
      }
      final path = _pick(row, [
        'imagePath',
        'primaryImageUrl',
        'ImagePath',
        'illnessImageUrl',
      ]);
      if (path != null) return HistoryItem.resolveImageUrl(path);
    }
    final u = widget.item.imageUrl.trim();
    if (u.isNotEmpty) return u;
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : _kBgLight;
    final u = widget.item;
    final row = _illnessRow;

    final name = _pick(row, ['illnessName', 'IllnessName']) ??
        u.diseaseName.trim().ifEmpty('—');
    final sci = _pick(row, ['scientificName', 'ScientificName']) ??
        (u.scientificName?.trim().isNotEmpty == true
            ? u.scientificName!
            : DiseaseMapper.getScientificName(u.diseaseName));
    final desc = _pick(row, ['description', 'Description']) ??
        u.illnessDescription?.trim();
    final symptoms = _pick(row, ['symptoms', 'Symptoms']) ?? u.symptoms?.trim();
    final causes = _pick(row, ['causes', 'Causes']) ?? u.causes?.trim();
    final severity = _pick(row, ['severity', 'Severity']) ?? u.illnessSeverity;
    final agentType = _pick(row, [
      'agentType',
      'pathogenType',
      'illnessCategory',
      'AgentType',
    ]);
    final host = _pick(row, [
      'primaryHost',
      'hostPlant',
      'mainHost',
      'treeScientificName',
    ]);

    final createdApi = _pick(row, ['createdAt', 'CreatedAt']);
    final updatedApi = _pick(row, ['updatedAt', 'UpdatedAt']);

    final idLabel = u.illnessId != null
        ? '#ILL-${u.illnessId}'
        : '#${u.predictionId}';

    final hero = _heroImageUrl();

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_rounded,
            color: isDark ? Colors.white70 : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Disease details',
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 18,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
        ),
        centerTitle: true,
      ),
      body: _loadingApi && row == null && u.illnessId != null
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandAccent))
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _HeroCard(
                    isDark: isDark,
                    heroUrl: hero,
                    severityLabel: _severityBadgeText(severity),
                    idLabel: idLabel,
                    name: name,
                    subtitleLine: _subtitleEnglishSci(u.diseaseName, sci),
                    agentType: agentType ?? '—',
                    host: host ?? (u.treeScientificName?.trim().isNotEmpty == true
                        ? u.treeScientificName!
                        : '—'),
                  ),
                  const SizedBox(height: 20),
                  if (desc != null && desc.isNotEmpty) ...[
                    _sectionTitle('Detailed description', isDark),
                    const SizedBox(height: 8),
                    _CardShell(
                      isDark: isDark,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          desc,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 14,
                            height: 1.45,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : const Color(0xFF475569),
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Icon(
                        Icons.report_problem_outlined,
                        color: AppColors.brandAccent,
                        size: 22,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Symptoms & causes',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (symptoms != null && symptoms.isNotEmpty)
                    _labelCard(
                      isDark,
                      'SYMPTOMS',
                      symptoms,
                    ),
                  if (symptoms != null && symptoms.isNotEmpty)
                    const SizedBox(height: 10),
                  if (causes != null && causes.isNotEmpty)
                    _labelCard(
                      isDark,
                      'CAUSES',
                      causes,
                    ),
                  if ((symptoms == null || symptoms.isEmpty) &&
                      (causes == null || causes.isEmpty))
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'No detailed symptom or cause description yet.',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          color: isDark
                              ? AppColors.textSecondaryDark
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),
                  _sectionTitle('System information', isDark),
                  const SizedBox(height: 8),
                  _CardShell(
                    isDark: isDark,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          if (createdApi != null)
                            _metaRow(
                              'Created',
                              _formatDt(createdApi),
                              isDark,
                            ),
                          if (createdApi != null && updatedApi != null)
                            Divider(
                              height: 20,
                              color: isDark
                                  ? AppColors.borderDark
                                  : const Color(0xFFE2E8F0),
                            ),
                          if (updatedApi != null)
                            _metaRow(
                              'Last updated',
                              _formatDt(updatedApi),
                              isDark,
                            ),
                          if (createdApi == null && updatedApi == null)
                            _metaRow(
                              'Recorded from scan',
                              _formatDateTime(u.createdAt),
                              isDark,
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  _sectionTitle('Linked solutions', isDark),
                  const SizedBox(height: 8),
                  if (widget.recommendations.isEmpty)
                    Text(
                      u.illnessId == null
                          ? 'Disease code not linked in the system — no automatic suggestions.'
                          : 'No solutions linked to this disease in the library.',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF64748B),
                      ),
                    )
                  else
                    ...widget.recommendations.map(
                      (r) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _SolutionTile(
                          item: r,
                          isDark: isDark,
                          onTap: () => _openSolution(context, r),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar:
          const UserBottomNavBar(selectedIndexOverride: 2),
    );
  }

  static String _subtitleEnglishSci(String diseaseName, String sci) {
    final en = DiseaseMapper.toDisplayName(diseaseName);
    if (sci.isEmpty || sci == 'Unknown' || sci == 'N/A') {
      return en;
    }
    return '$en | $sci';
  }

  static String _severityBadgeText(String? severity) {
    if (severity == null || severity.trim().isEmpty) {
      return 'LEVEL: UNKNOWN';
    }
    final t = severity.trim();
    const map = {
      'Low': 'Low',
      'Medium': 'Medium',
      'High': 'High',
      'Critical': 'Critical',
      'Thấp': 'Low',
      'Trung bình': 'Medium',
      'Cao': 'High',
      'Nguy hiểm': 'Critical',
    };
    final mapped = map[t] ?? t;
    return 'LEVEL: ${mapped.toUpperCase()}';
  }

  static String _formatDateTime(DateTime d) {
    return '${d.year.toString().padLeft(4, '0')}-'
        '${d.month.toString().padLeft(2, '0')}-'
        '${d.day.toString().padLeft(2, '0')} '
        '${d.hour.toString().padLeft(2, '0')}:'
        '${d.minute.toString().padLeft(2, '0')}';
  }

  static String _formatDt(String raw) {
    final p = DateTime.tryParse(raw);
    if (p != null) return _formatDateTime(p.toLocal());
    return raw;
  }

  Widget _sectionTitle(String t, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        t,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
        ),
      ),
    );
  }

  Widget _labelCard(bool isDark, String label, String body) {
    return _CardShell(
      isDark: isDark,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 14,
                height: 1.45,
                color: isDark
                    ? AppColors.textSecondaryDark
                    : const Color(0xFF475569),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metaRow(String k, String v, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$k:',
          style: GoogleFonts.spaceGrotesk(
            fontSize: 12,
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            v,
            textAlign: TextAlign.right,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }

  void _openSolution(BuildContext context, TreatmentRecommendationItem r) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.solutionName ?? 'Solution',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (r.description != null && r.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  r.description!.trim(),
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    height: 1.4,
                    color: const Color(0xFF475569),
                  ),
                ),
              ],
              if (r.treeStageName != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Plant stage: ${r.treeStageName}',
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

class _SciSubtitle extends StatelessWidget {
  const _SciSubtitle({required this.line, required this.isDark});

  final String line;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.spaceGrotesk(
      fontSize: 14,
      height: 1.35,
      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
    );
    final idx = line.indexOf(' | ');
    if (idx < 0) {
      return Text(line, style: base);
    }
    final left = line.substring(0, idx);
    final right = line.substring(idx + 3);
    return Text.rich(
      TextSpan(
        style: base,
        children: [
          TextSpan(text: left),
          TextSpan(text: ' | ', style: base),
          TextSpan(
            text: right,
            style: base.copyWith(fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.isDark,
    required this.heroUrl,
    required this.severityLabel,
    required this.idLabel,
    required this.name,
    required this.subtitleLine,
    required this.agentType,
    required this.host,
  });

  final bool isDark;
  final String heroUrl;
  final String severityLabel;
  final String idLabel;
  final String name;
  final String subtitleLine;
  final String agentType;
  final String host;

  @override
  Widget build(BuildContext context) {
    final border = Border.all(
      color: AppColors.brandAccent.withValues(alpha: 0.08),
    );
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: border,
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 192,
            child: heroUrl.isEmpty
                ? Container(
                    color: isDark ? AppColors.borderDark : const Color(0xFFE8EDE3),
                    child: Icon(
                      Icons.coronavirus_outlined,
                      size: 56,
                      color: AppColors.brandAccent.withValues(alpha: 0.35),
                    ),
                  )
                : Image.network(
                    heroUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: const Color(0xFFE8EDE3),
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.red.shade900.withValues(alpha: 0.35)
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          severityLabel,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.4,
                            color: isDark
                                ? Colors.red.shade200
                                : Colors.red.shade700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'ID: $idLabel',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.brandAccent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  name,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 6),
                _SciSubtitle(line: subtitleLine, isDark: isDark),
                const SizedBox(height: 16),
                Divider(
                  height: 1,
                  color: isDark ? AppColors.borderDark : const Color(0xFFF1F5F9),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _miniCol(
                        'AGENT TYPE',
                        agentType,
                        isDark,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _miniCol(
                        'PRIMARY HOST',
                        host,
                        isDark,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniCol(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({required this.isDark, required this.child});

  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.brandAccent.withValues(alpha: 0.06),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _SolutionTile extends StatelessWidget {
  const _SolutionTile({
    required this.item,
    required this.isDark,
    required this.onTap,
  });

  final TreatmentRecommendationItem item;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final label = '${item.solutionType ?? ''} ${item.solutionName ?? ''}'
        .toLowerCase();
    final icon = label.contains('nước') ||
            label.contains('water') ||
            label.contains('tưới') ||
            label.contains('irrigation') ||
            label.contains('drip')
        ? Icons.water_drop_outlined
        : Icons.medication_outlined;

    return Material(
      color: AppColors.brandAccent.withValues(alpha: isDark ? 0.12 : 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Icon(icon, color: AppColors.brandAccent, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  item.solutionName ?? 'Solution #${item.solutionId}',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
                  ),
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: isDark ? AppColors.darkMuted : const Color(0xFF94A3B8),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
