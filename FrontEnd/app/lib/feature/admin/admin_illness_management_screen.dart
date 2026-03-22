import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../share/services/dashboard_service.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/admin_app_bar_actions.dart';
import '../../share/widgets/admin_bottom_nav.dart';
import '../../share/widgets/admin_pop_scope.dart';
import 'admin_illness_edit_screen.dart';

class AdminIllnessManagementScreen extends StatefulWidget {
  const AdminIllnessManagementScreen({super.key});

  @override
  State<AdminIllnessManagementScreen> createState() =>
      _AdminIllnessManagementScreenState();
}

const Color _kPrimary = Color(0xFF2D7B31);
const Color _kBg = Color(0xFFF6F8F6);

class _AdminIllnessManagementScreenState
    extends State<AdminIllnessManagementScreen> {
  final DashboardService _api = DashboardService();
  final TextEditingController _search = TextEditingController();

  List<Map<String, dynamic>> _rows = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _search.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await _api.getIllnesses();
    if (mounted) {
      setState(() {
        _rows = list;
        _loading = false;
      });
    }
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _search.text.trim().toLowerCase();
    if (q.isEmpty) return _rows;
    return _rows.where((r) {
      final name =
          '${r['illnessName'] ?? r['IllnessName'] ?? ''}'.toLowerCase();
      final sci =
          '${r['scientificName'] ?? r['ScientificName'] ?? ''}'.toLowerCase();
      final desc = '${r['description'] ?? r['Description'] ?? ''}'.toLowerCase();
      return name.contains(q) || sci.contains(q) || desc.contains(q);
    }).toList();
  }

  Future<void> _confirmDelete(int id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Delete disease?',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Delete "$name"? This cannot be undone.',
          style: GoogleFonts.spaceGrotesk(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.spaceGrotesk(color: Colors.grey.shade700),
            ),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: Text('Delete', style: GoogleFonts.spaceGrotesk()),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await _api.deleteIllness(id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(success ? 'Deleted' : 'Delete failed'),
        backgroundColor: success ? _kPrimary : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (success) await _load();
  }

  Future<void> _openEditor({int? id}) async {
    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => AdminIllnessEditScreen(illnessId: id),
      ),
    );
    if (changed == true) await _load();
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
    final bg = isDark ? AppColors.darkBackground : _kBg;
    final cardBg =
        isDark ? const Color(0xFF1E2320) : AppColors.surfaceLight;

    return AdminPopScope(
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          elevation: 0,
          scrolledUnderElevation: 0.5,
          surfaceTintColor: _kPrimary.withValues(alpha: 0.08),
          backgroundColor: bg,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Manage diseases',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 20,
                  color: textPrimary,
                  letterSpacing: -0.3,
                ),
              ),
              Text(
                'Add and edit diseases in the library',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: textSecondary,
                ),
              ),
            ],
          ),
          actions: [
            ...adminSecondaryAppBarActions(context),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _load,
              icon: Icon(Icons.refresh_rounded, color: textSecondary),
            ),
          ],
        ),
        body: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: _kPrimary),
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
                      child: TextField(
                        controller: _search,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 15,
                          color: textPrimary,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search by name or scientific name…',
                          hintStyle: GoogleFonts.spaceGrotesk(
                            color: textSecondary,
                            fontSize: 14,
                          ),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: _kPrimary.withValues(alpha: 0.75),
                          ),
                          filled: true,
                          fillColor: isDark
                              ? const Color(0xFF2A322E)
                              : _kPrimary.withValues(alpha: 0.05),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: _kPrimary.withValues(alpha: 0.15),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(
                              color: _kPrimary.withValues(alpha: 0.15),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: _kPrimary,
                              width: 2,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        color: _kPrimary,
                        onRefresh: _load,
                        child: _filtered.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 24,
                                  vertical: 48,
                                ),
                                children: [
                                  Icon(
                                    Icons.coronavirus_outlined,
                                    size: 56,
                                    color: _kPrimary.withValues(alpha: 0.35),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _rows.isEmpty
                                        ? 'No diseases yet. Use the button below to add one.'
                                        : 'No matching results.',
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.spaceGrotesk(
                                      fontSize: 15,
                                      height: 1.4,
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  100,
                                ),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final r = _filtered[i];
                                  final idRaw =
                                      r['illnessId'] ?? r['IllnessId'];
                                  final iid = _asInt(idRaw);
                                  final name =
                                      '${r['illnessName'] ?? r['IllnessName'] ?? 'Disease'}';
                                  final sci =
                                      '${r['scientificName'] ?? r['ScientificName'] ?? ''}'
                                          .trim();
                                  final sev =
                                      '${r['severity'] ?? r['Severity'] ?? ''}'
                                          .trim();
                                  return _IllnessCard(
                                    name: name,
                                    scientificName: sci,
                                    severity: sev,
                                    cardBg: cardBg,
                                    textPrimary: textPrimary,
                                    textSecondary: textSecondary,
                                    isDark: isDark,
                                    onTap: () => _openEditor(id: iid),
                                    onDelete: () => _confirmDelete(iid, name),
                                  );
                                },
                              ),
                      ),
                    ),
                  ],
                ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => _openEditor(),
          backgroundColor: _kPrimary,
          foregroundColor: AppColors.onPrimary,
          elevation: 3,
          icon: const Icon(Icons.add_rounded),
          label: Text(
            'Add disease',
            style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
          ),
        ),
        bottomNavigationBar: const AdminBottomNav(currentIndex: 4),
      ),
    );
  }

  int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }
}

class _IllnessCard extends StatelessWidget {
  const _IllnessCard({
    required this.name,
    required this.scientificName,
    required this.severity,
    required this.cardBg,
    required this.textPrimary,
    required this.textSecondary,
    required this.isDark,
    required this.onTap,
    required this.onDelete,
  });

  final String name;
  final String scientificName;
  final String severity;
  final Color cardBg;
  final Color textPrimary;
  final Color textSecondary;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: cardBg,
      borderRadius: BorderRadius.circular(16),
      elevation: isDark ? 0 : 0.5,
      shadowColor: Colors.black26,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _kPrimary.withValues(alpha: 0.08),
            ),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _kPrimary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.coronavirus_rounded,
                  color: _kPrimary.withValues(alpha: 0.9),
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: GoogleFonts.spaceGrotesk(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        color: textPrimary,
                        height: 1.25,
                      ),
                    ),
                    if (scientificName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        scientificName,
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                          color: textSecondary,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (severity.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _kPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          severity,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: _kPrimary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Delete',
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: Colors.red.shade400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
