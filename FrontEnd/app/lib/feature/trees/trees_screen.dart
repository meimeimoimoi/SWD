import 'package:flutter/material.dart';

import '../../routes/app_router.dart';
import '../../share/constants/app_brand.dart';
import '../../share/services/history_service.dart';
import '../../share/widgets/user_bottom_nav_bar.dart';
import 'user_tree_models.dart';

const Color _primary = Color(0xFF2D7B31);
const Color _bg = Color(0xFFF6F8F6);

/// Lists the user's trees (grouped from scan history), guide-style cards.
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
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        title: const Text('My trees'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, AppRouter.profile),
            icon: const Icon(Icons.settings_outlined),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRouter.scan),
        backgroundColor: _primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
      bottomNavigationBar: const UserBottomNavBar(selectedIndexOverride: 2),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _search,
            decoration: InputDecoration(
              hintText: 'Search by tree or disease...',
              prefixIcon: Icon(Icons.search, color: Colors.grey.shade500),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _primary, width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 40,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: TreeListFilter.values.map((f) {
                final selected = _filter == f;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(f.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _filter = f),
                    selectedColor: _primary,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : Colors.grey.shade800,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    side: BorderSide(
                      color: selected ? _primary : Colors.black.withValues(alpha: 0.08),
                    ),
                    backgroundColor: Colors.white,
                    showCheckmark: false,
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _primary))
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _load,
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.park_outlined, size: 56, color: Colors.grey.shade400),
                          const SizedBox(height: 16),
                          Text(
                            _all.isEmpty
                                ? 'No trees yet. Scan a leaf to start tracking in ${AppBrand.name}.'
                                : 'No trees match this filter.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey.shade600),
                          ),
                          if (_all.isEmpty) ...[
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () =>
                                  Navigator.pushNamed(context, AppRouter.scan),
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Scan now'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : RefreshIndicator(
                    color: _primary,
                    onRefresh: _load,
                    child: ListView.builder(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: _filtered.length,
                      itemBuilder: (context, i) {
                        final t = _filtered[i];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: _TreeCard(
                            summary: t,
                            onDetails: () => Navigator.pushNamed(
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
      ),
    );
  }
}

class _TreeCard extends StatelessWidget {
  const _TreeCard({required this.summary, required this.onDetails});

  final UserTreeSummary summary;
  final VoidCallback onDetails;

  @override
  Widget build(BuildContext context) {
    final latest = summary.predictions.first;
    final subtitle = summary.scientificName != null &&
            summary.scientificName!.isNotEmpty
        ? summary.scientificName!
        : (latest.diseaseName.isNotEmpty
              ? latest.diseaseName
              : 'No scientific name');
    final desc = (latest.treeDescription ?? latest.illnessDescription ?? '')
        .trim();
    final snippet = desc.isEmpty
        ? '${summary.scanCount} scans — updated ${_TreeCard._fmtDate(summary.latestScan)}'
        : (desc.length > 120 ? '${desc.substring(0, 117)}...' : desc);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onDetails,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _primary.withValues(alpha: 0.08)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 16 / 9,
                    child: summary.heroImageUrl.isEmpty
                        ? Container(
                            color: Colors.grey.shade200,
                            child: const Icon(Icons.park, size: 48, color: Colors.grey),
                          )
                        : Image.network(
                            summary.heroImageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              color: Colors.grey.shade200,
                              child: const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _HealthBadge(level: summary.health),
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
                            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                        Icon(Icons.more_vert, color: Colors.grey.shade400),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: _primary.withValues(alpha: 0.85),
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      snippet,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                            height: 1.35,
                          ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        FilledButton.tonal(
                          onPressed: onDetails,
                          style: FilledButton.styleFrom(
                            backgroundColor: _primary.withValues(alpha: 0.12),
                            foregroundColor: _primary,
                          ),
                          child: const Text('Details'),
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

class _HealthBadge extends StatelessWidget {
  const _HealthBadge({required this.level});

  final TreeHealthLevel level;

  @override
  Widget build(BuildContext context) {
    late Color bg;
    late Color fg;
    late String text;
    switch (level) {
      case TreeHealthLevel.healthy:
        bg = Colors.green.shade100;
        fg = Colors.green.shade800;
        text = 'Healthy';
        break;
      case TreeHealthLevel.low:
        bg = Colors.lightGreen.shade100;
        fg = Colors.green.shade900;
        text = 'Risk: Low';
        break;
      case TreeHealthLevel.medium:
        bg = Colors.orange.shade100;
        fg = Colors.orange.shade900;
        text = 'Risk: Medium';
        break;
      case TreeHealthLevel.high:
        bg = Colors.red.shade100;
        fg = Colors.red.shade900;
        text = 'Risk: High';
        break;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
