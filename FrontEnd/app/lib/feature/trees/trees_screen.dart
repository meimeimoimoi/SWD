import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../routes/app_router.dart';
import '../../share/constants/app_brand.dart';
import '../../share/services/history_service.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/user_bottom_nav_bar.dart';
import 'user_tree_models.dart';

const Color _kPrimary = Color(0xFF2D7B31);
const Color _kBgLight = Color(0xFFF6F8F6);

class TreesScreen extends StatefulWidget {
  const TreesScreen({super.key});

  @override
  State<TreesScreen> createState() => _TreesScreenState();
}

class _TreesScreenState extends State<TreesScreen> {
  final HistoryService _history = HistoryService();
  final TextEditingController _search = TextEditingController();

  List<UserTreeSummary> _all = [];
  TreeListFilter _filter = TreeListFilter.all;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
    _search.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final res = await _history.getHistory();
    if (!mounted) return;
    if (!res.success) {
      setState(() {
        _loading = false;
        _error = res.message;
        _all = [];
      });
      return;
    }
    setState(() {
      _loading = false;
      _all = UserTreeSummary.fromHistory(res.data);
    });
  }

  List<UserTreeSummary> get _filtered {
    final q = _search.text.trim().toLowerCase();
    return _all.where((t) {
      if (!t.matchesFilter(_filter)) return false;
      if (q.isEmpty) return true;
      if (t.displayName.toLowerCase().contains(q)) return true;
      if ((t.scientificName ?? '').toLowerCase().contains(q)) return true;
      return t.predictions.any(
        (p) => p.diseaseName.toLowerCase().contains(q),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : _kBgLight;
    final onSurface =
        isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _TreesAppBar(
              title: 'My plant',
              onSurface: onSurface,
            ),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: _kPrimary),
                    )
                  : _error != null
                      ? _ErrorBody(
                          message: _error!,
                          onRetry: _load,
                          isDark: isDark,
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              child: _SearchField(
                                controller: _search,
                                isDark: isDark,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 40,
                              child: ListView(
                                scrollDirection: Axis.horizontal,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                children: TreeListFilter.values.map((f) {
                                  final selected = _filter == f;
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: FilterChip(
                                      label: Text(
                                        _filterLabelVi(f),
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: selected
                                              ? AppColors.textPrimaryDark
                                              : (isDark
                                                  ? const Color(0xFFCBD5E1)
                                                  : const Color(0xFF475569)),
                                        ),
                                      ),
                                      selected: selected,
                                      onSelected: (_) =>
                                          setState(() => _filter = f),
                                      selectedColor: _kPrimary,
                                      backgroundColor: isDark
                                          ? AppColors.surfaceDark
                                          : AppColors.surfaceLight,
                                      side: BorderSide(
                                        color: selected
                                            ? _kPrimary
                                            : _kPrimary.withValues(alpha: 0.12),
                                      ),
                                      showCheckmark: false,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                      ),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Expanded(
                              child: _filtered.isEmpty
                                  ? _EmptyBody(
                                      hasNoTrees: _all.isEmpty,
                                      isDark: isDark,
                                      onScan: () => Navigator.pushNamed(
                                        context,
                                        AppRouter.scan,
                                      ),
                                    )
                                  : RefreshIndicator(
                                      color: _kPrimary,
                                      onRefresh: _load,
                                      child: ListView.builder(
                                        padding: const EdgeInsets.fromLTRB(
                                          16,
                                          8,
                                          16,
                                          100,
                                        ),
                                        itemCount: _filtered.length,
                                        itemBuilder: (context, i) {
                                          final t = _filtered[i];
                                          return Padding(
                                            padding: const EdgeInsets.only(
                                              bottom: 16,
                                            ),
                                            child: _TreeCard(
                                              summary: t,
                                              isDark: isDark,
                                              onDetails: () =>
                                                  Navigator.pushNamed(
                                                context,
                                                AppRouter.treeDetail,
                                                arguments: t,
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRouter.scan),
        backgroundColor: _kPrimary,
        elevation: 4,
        child: const Icon(Icons.add, color: AppColors.onPrimary, size: 28),
      ),
      bottomNavigationBar: const UserBottomNavBar(selectedIndexOverride: 2),
    );
  }
}

String _filterLabelVi(TreeListFilter f) {
  switch (f) {
    case TreeListFilter.all:
      return 'All';
    case TreeListFilter.concern:
      return 'Needs attention';
    case TreeListFilter.healthy:
      return 'Healthy';
  }
}

class _TreesAppBar extends StatelessWidget {
  const _TreesAppBar({
    required this.title,
    required this.onSurface,
  });

  final String title;
  final Color onSurface;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
      child: Row(
        children: [
          if (Navigator.of(context).canPop())
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back_rounded, color: _kPrimary),
              tooltip: 'Back',
            )
          else
            const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.spaceGrotesk(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: onSurface,
                letterSpacing: -0.3,
              ),
            ),
          ),
        ],
      ),
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
        fontSize: 15,
        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
      ),
      decoration: InputDecoration(
        hintText: 'Search plant or disease name…',
        hintStyle: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          color: isDark ? Colors.white38 : Colors.grey.shade500,
        ),
        prefixIcon: Icon(Icons.search_rounded, color: _kPrimary.withValues(alpha: 0.85)),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: _kPrimary.withValues(alpha: 0.1),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _kPrimary, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      ),
    );
  }
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.message,
    required this.onRetry,
    required this.isDark,
  });

  final String message;
  final VoidCallback onRetry;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.spaceGrotesk(
                color: isDark ? Colors.white70 : Colors.grey.shade700,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: onRetry,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: AppColors.onPrimary,
              ),
              child: Text(
                'Retry',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody({
    required this.hasNoTrees,
    required this.isDark,
    required this.onScan,
  });

  final bool hasNoTrees;
  final bool isDark;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: [
        const SizedBox(height: 48),
        Icon(
          Icons.park_outlined,
          size: 56,
          color: _kPrimary.withValues(alpha: 0.35),
        ),
        const SizedBox(height: 16),
        Text(
          hasNoTrees
              ? 'No plants yet. Scan leaves to start tracking on ${AppBrand.name}.'
              : 'No plants match this filter.',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 15,
            height: 1.4,
            color: isDark ? AppColors.textSecondaryDark : const Color(0xFF64748B),
          ),
        ),
        if (hasNoTrees) ...[
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onScan,
            style: FilledButton.styleFrom(
              backgroundColor: _kPrimary,
              foregroundColor: AppColors.onPrimary,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            icon: const Icon(Icons.document_scanner_outlined),
            label: Text(
              'Scan now',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ],
    );
  }
}

class _TreeCard extends StatelessWidget {
  const _TreeCard({
    required this.summary,
    required this.isDark,
    required this.onDetails,
  });

  final UserTreeSummary summary;
  final bool isDark;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final latest = summary.predictions.first;
    final diseaseLine = latest.diseaseName.trim().isEmpty
        ? 'Unknown'
        : latest.diseaseName;
    final sci = (summary.scientificName ?? latest.scientificName ?? '').trim();
    final desc = (latest.treeDescription ?? latest.illnessDescription ?? '')
        .trim();
    final snippet = desc.isEmpty
        ? '${summary.scanCount} scans · updated ${_fmtDate(summary.latestScan)}'
        : (desc.length > 120 ? '${desc.substring(0, 117)}…' : desc);

    final cardBg = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final border = _kPrimary.withValues(alpha: 0.06);

    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      elevation: isDark ? 0 : 0.5,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onDetails,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  SizedBox(
                    height: 192,
                    width: double.infinity,
                    child: summary.heroImageUrl.isEmpty
                        ? Container(
                            color: isDark
                                ? AppColors.borderDark
                                : Colors.grey.shade300,
                            child: Icon(
                              Icons.park_rounded,
                              size: 56,
                              color: isDark ? Colors.white24 : Colors.grey.shade500,
                            ),
                          )
                        : Image.network(
                            summary.heroImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade300,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: _SeverityBadge(level: summary.health, isDark: isDark),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            summary.displayName,
                            style: GoogleFonts.spaceGrotesk(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: isDark
                                  ? AppColors.textPrimaryDark
                                  : const Color(0xFF0F172A),
                              height: 1.2,
                            ),
                          ),
                        ),
                        PopupMenuButton<String>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: isDark
                                ? AppColors.textSecondaryDark
                                : Colors.grey.shade400,
                          ),
                          onSelected: (v) {
                            if (v == 'detail') onDetails();
                          },
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 'detail',
                              child: Text(
                                'Details',
                                style: GoogleFonts.spaceGrotesk(),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _kPrimary.withValues(alpha: 0.85),
                        ),
                        children: [
                          TextSpan(text: diseaseLine),
                          if (sci.isNotEmpty)
                            TextSpan(
                              children: [
                                const TextSpan(text: ' | '),
                                TextSpan(
                                  text: sci,
                                  style: GoogleFonts.spaceGrotesk(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    fontWeight: FontWeight.w500,
                                    color: _kPrimary.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        height: 1.4,
                        color: isDark
                            ? AppColors.textSecondaryDark
                            : const Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton(
                          onPressed: onDetails,
                          style: TextButton.styleFrom(
                            foregroundColor: isDark
                                ? const Color(0xFFCBD5E1)
                                : const Color(0xFF475569),
                            backgroundColor: isDark
                                ? AppColors.borderDark
                                : const Color(0xFFF1F5F9),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
                            'Edit',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        FilledButton.tonal(
                          onPressed: onDetails,
                          style: FilledButton.styleFrom(
                            backgroundColor: _kPrimary.withValues(alpha: 0.12),
                            foregroundColor: _kPrimary,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(
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
            ],
          ),
        ),
      ),
    );
  }

  static String _fmtDate(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}

class _SeverityBadge extends StatelessWidget {
  const _SeverityBadge({required this.level, required this.isDark});

  final TreeHealthLevel level;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    late String text;
    switch (level) {
      case TreeHealthLevel.healthy:
        bg = isDark
            ? const Color(0xFF14532D).withValues(alpha: 0.85)
            : Colors.green.shade100;
        fg = isDark ? const Color(0xFF86EFAC) : Colors.green.shade800;
        text = 'HEALTHY';
        break;
      case TreeHealthLevel.low:
        bg = isDark
            ? const Color(0xFF14532D).withValues(alpha: 0.5)
            : Colors.lightGreen.shade100;
        fg = isDark ? const Color(0xFFBBF7D0) : Colors.green.shade900;
        text = 'LEVEL: LOW';
        break;
      case TreeHealthLevel.medium:
        bg = isDark
            ? const Color(0xFF7C2D12).withValues(alpha: 0.45)
            : Colors.orange.shade100;
        fg = isDark ? const Color(0xFFFDBA74) : Colors.orange.shade900;
        text = 'LEVEL: MEDIUM';
        break;
      case TreeHealthLevel.high:
        bg = isDark
            ? const Color(0xFF7F1D1D).withValues(alpha: 0.55)
            : Colors.red.shade100;
        fg = isDark ? const Color(0xFFFECACA) : Colors.red.shade900;
        text = 'LEVEL: HIGH';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: GoogleFonts.spaceGrotesk(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
