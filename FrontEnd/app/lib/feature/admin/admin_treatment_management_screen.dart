import 'package:flutter/material.dart';

import 'admin_treatment_add_screen.dart';
import '../../share/services/dashboard_service.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/admin_app_bar_actions.dart';
import '../../share/widgets/admin_bottom_nav.dart';
import '../../share/widgets/admin_pop_scope.dart';
import '../../share/widgets/app_card.dart';

class AdminTreatmentManagementScreen extends StatefulWidget {
  const AdminTreatmentManagementScreen({super.key});

  @override
  State<AdminTreatmentManagementScreen> createState() =>
      _AdminTreatmentManagementScreenState();
}

class _AdminTreatmentManagementScreenState
    extends State<AdminTreatmentManagementScreen> {
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
    final list = await _api.getTreatmentManagementList();
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
          '${r['solutionName'] ?? r['SolutionName'] ?? ''}'.toLowerCase();
      final ill =
          '${r['illnessName'] ?? r['IllnessName'] ?? ''}'.toLowerCase();
      final type =
          '${r['solutionType'] ?? r['SolutionType'] ?? ''}'.toLowerCase();
      final desc = '${r['description'] ?? r['Description'] ?? ''}'.toLowerCase();
      return name.contains(q) ||
          ill.contains(q) ||
          type.contains(q) ||
          desc.contains(q);
    }).toList();
  }

  static int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  Future<void> _openAddSolution() async {
    final added = await Navigator.push<bool>(
      context,
      MaterialPageRoute<bool>(
        builder: (_) => const AdminTreatmentAddScreen(),
      ),
    );
    if (added == true && mounted) {
      await _load();
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
            'Treatments',
            style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
          ),
          actions: [
            IconButton(
              tooltip: 'Add solution',
              onPressed: _openAddSolution,
              icon: const Icon(Icons.add),
            ),
            ...adminSecondaryAppBarActions(context),
            IconButton(
              tooltip: 'Refresh',
              onPressed: _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: 'Search solutions, diseases…',
                          prefixIcon: const Icon(Icons.search),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _load,
                        child: _filtered.isEmpty
                            ? ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                children: [
                                  const SizedBox(height: 48),
                                  Icon(
                                    Icons.medical_information_outlined,
                                    size: 56,
                                    color: textSecondary.withValues(alpha: 0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _rows.isEmpty
                                        ? 'No treatment solutions yet.\nAdd one and link it to diseases.'
                                        : 'No matches for your search.',
                                    textAlign: TextAlign.center,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: textSecondary,
                                    ),
                                  ),
                                ],
                              )
                            : ListView.builder(
                                padding: const EdgeInsets.fromLTRB(
                                  16,
                                  0,
                                  16,
                                  100,
                                ),
                                itemCount: _filtered.length,
                                itemBuilder: (context, index) {
                                  final r = _filtered[index];
                                  final id = _asInt(
                                    r['solutionId'] ?? r['SolutionId'],
                                  );
                                  final name =
                                      '${r['solutionName'] ?? r['SolutionName'] ?? 'Solution #$id'}';
                                  final ill =
                                      '${r['illnessName'] ?? r['IllnessName'] ?? '—'}';
                                  final stage =
                                      '${r['treeStageName'] ?? r['TreeStageName'] ?? '—'}';
                                  final type =
                                      '${r['solutionType'] ?? r['SolutionType'] ?? ''}'
                                          .trim();
                                  final desc =
                                      '${r['description'] ?? r['Description'] ?? ''}'
                                          .trim();

                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 10),
                                    child: AppCard(
                                      padding: const EdgeInsets.all(14),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Icon(
                                                type.toLowerCase() ==
                                                        'medicine'
                                                    ? Icons.medication_outlined
                                                    : Icons.healing_outlined,
                                                color: AppColors.primary,
                                                size: 22,
                                              ),
                                              const SizedBox(width: 10),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: theme
                                                          .textTheme.titleSmall
                                                          ?.copyWith(
                                                        color: textPrimary,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      'Disease: $ill',
                                                      style: theme
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                        color: textSecondary,
                                                      ),
                                                    ),
                                                    Text(
                                                      'Tree stage: $stage · ID $id',
                                                      style: theme
                                                          .textTheme.bodySmall
                                                          ?.copyWith(
                                                        color: textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              if (type.isNotEmpty)
                                                Chip(
                                                  label: Text(
                                                    type,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                    ),
                                                  ),
                                                  visualDensity:
                                                      VisualDensity.compact,
                                                  padding: EdgeInsets.zero,
                                                ),
                                            ],
                                          ),
                                          if (desc.isNotEmpty) ...[
                                            const SizedBox(height: 8),
                                            Text(
                                              desc,
                                              maxLines: 4,
                                              overflow: TextOverflow.ellipsis,
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: textSecondary,
                                              ),
                                            ),
                                          ],
                                        ],
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
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: FloatingActionButton.extended(
            heroTag: 'admin_treatment_add_fab',
            onPressed: _openAddSolution,
            icon: const Icon(Icons.add),
            label: const Text('Add solution'),
          ),
        ),
        bottomNavigationBar:
            const AdminBottomNav(selected: AdminShellTab.treatments),
      ),
    );
  }
}
