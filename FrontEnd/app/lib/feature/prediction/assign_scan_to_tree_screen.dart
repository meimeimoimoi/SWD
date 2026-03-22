import 'package:flutter/material.dart';

import '../../share/services/history_service.dart';
import '../../share/services/user_tree_service.dart';
import '../../share/theme/app_colors.dart';
import 'prediction_screen.dart';

/// After a scan, link the prediction to a [Tree] (existing or newly created).
class AssignScanToTreeScreen extends StatefulWidget {
  const AssignScanToTreeScreen({super.key, required this.result});

  final PredictionResult result;

  @override
  State<AssignScanToTreeScreen> createState() => _AssignScanToTreeScreenState();
}

class _AssignScanToTreeScreenState extends State<AssignScanToTreeScreen>
    with SingleTickerProviderStateMixin {
  final _userTreeService = UserTreeService();
  final _historyService = HistoryService();

  late final TabController _tabController;
  final _nameCtrl = TextEditingController();
  final _sciCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  List<UserTreeListItem> _trees = [];
  int? _selectedTreeId;
  int? _linkedTreeId;
  String? _linkedTreeName;

  bool _loadingTrees = true;
  bool _loadingDetail = true;
  bool _submitting = false;
  String? _treesError;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await Future.wait([_loadDetail(), _loadTrees()]);
  }

  Future<void> _loadDetail() async {
    final id = widget.result.predictionId;
    if (id <= 0) {
      if (mounted) setState(() => _loadingDetail = false);
      return;
    }
    final map = await _historyService.getPredictionById(id);
    if (!mounted) return;
    int? tid;
    String? tname;
    if (map != null) {
      final raw = map['treeId'];
      if (raw is int) tid = raw;
      if (raw is num) tid = raw.toInt();
      tname = map['treeName'] as String?;
    }
    setState(() {
      _linkedTreeId = tid;
      _linkedTreeName = tname?.trim().isNotEmpty == true ? tname : null;
      if (tid != null) _selectedTreeId = tid;
      _loadingDetail = false;
    });
  }

  Future<void> _loadTrees() async {
    setState(() {
      _loadingTrees = true;
      _treesError = null;
    });
    final r = await _userTreeService.fetchMyTrees();
    if (!mounted) return;
    setState(() {
      _trees = r.trees;
      _loadingTrees = false;
      if (!r.success) _treesError = r.message;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameCtrl.dispose();
    _sciCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _assignToTree(int treeId) async {
    setState(() => _submitting = true);
    final r = await _userTreeService.assignPredictionToTree(
      predictionId: widget.result.predictionId,
      treeId: treeId,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (r.success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.message)),
      );
    }
  }

  Future<void> _createAndAssign() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _submitting = true);
    final created = await _userTreeService.createTree(
      treeName: _nameCtrl.text,
      scientificName: _sciCtrl.text,
      description: _descCtrl.text,
    );
    if (!mounted) return;
    if (!created.success || created.tree == null) {
      setState(() => _submitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(created.message.isEmpty ? 'Could not create plant.' : created.message)),
      );
      return;
    }
    final tid = created.tree!.treeId;
    final r = await _userTreeService.assignPredictionToTree(
      predictionId: widget.result.predictionId,
      treeId: tid,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    if (r.success) {
      Navigator.of(context).pop(true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(r.message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.result;

    if (r.predictionId <= 0) {
      return Scaffold(
        appBar: AppBar(title: const Text('Assign to plant')),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('This preview has no prediction id. Run a real scan first.'),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBackground : const Color(0xFFF4F4F5),
      appBar: AppBar(
        title: const Text('Assign to a plant'),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        foregroundColor: isDark ? AppColors.textPrimaryDark : const Color(0xFF111827),
      ),
      body: _loadingDetail
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _SummaryCard(result: r, isDark: isDark),
                  if (_linkedTreeId != null) ...[
                    const SizedBox(height: 12),
                    _LinkedBanner(
                      treeName: _linkedTreeName ?? 'Plant #$_linkedTreeId',
                      isDark: isDark,
                    ),
                  ],
                  const SizedBox(height: 16),
                  TabBar(
                    controller: _tabController,
                    labelColor: const Color(0xFF2D7B31),
                    unselectedLabelColor:
                        isDark ? Colors.white54 : Colors.black54,
                    indicatorColor: const Color(0xFF2D7B31),
                    tabs: const [
                      Tab(text: 'Choose existing'),
                      Tab(text: 'New plant'),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 320,
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildExistingTab(isDark),
                        _buildNewTab(),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildExistingTab(bool isDark) {
    if (_loadingTrees) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_treesError != null && _trees.isEmpty) {
      return Center(
        child: Text(
          _treesError!,
          textAlign: TextAlign.center,
          style: TextStyle(color: isDark ? Colors.white70 : Colors.black87),
        ),
      );
    }
    if (_trees.isEmpty) {
      return Center(
        child: Text(
          'You have no plants yet from past scans. Create a plant in the next tab, then this list will show plants you have used before.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isDark ? Colors.white70 : const Color(0xFF52525B),
            height: 1.4,
          ),
        ),
      );
    }
    return ListView(
      children: [
        for (final t in _trees)
          RadioListTile<int>(
            value: t.treeId,
            groupValue: _selectedTreeId,
            onChanged: _submitting
                ? null
                : (v) => setState(() => _selectedTreeId = v),
            title: Text(t.displayLabel),
            subtitle: t.scientificName != null && t.scientificName!.trim().isNotEmpty
                ? Text(
                    t.scientificName!,
                    style: const TextStyle(fontSize: 12),
                  )
                : null,
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _submitting || _selectedTreeId == null
              ? null
              : () => _assignToTree(_selectedTreeId!),
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF2D7B31),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: _submitting
              ? const SizedBox(
                  height: 22,
                  width: 22,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('Link scan to selected plant'),
        ),
      ],
    );
  }

  Widget _buildNewTab() {
    return Form(
      key: _formKey,
      child: ListView(
        children: [
          TextFormField(
            controller: _nameCtrl,
            decoration: const InputDecoration(
              labelText: 'Plant name',
              hintText: 'e.g. Backyard lemon',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.words,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Enter a name';
              return null;
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _sciCtrl,
            decoration: const InputDecoration(
              labelText: 'Scientific name (optional)',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _descCtrl,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              border: OutlineInputBorder(),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submitting ? null : _createAndAssign,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2D7B31),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
            child: _submitting
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Create plant & link scan'),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.result, required this.isDark});

  final PredictionResult result;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 56,
              height: 56,
              child: result.imageUrl.isEmpty
                  ? const ColoredBox(
                      color: Color(0xFFE5E7EB),
                      child: Icon(Icons.image_outlined),
                    )
                  : Image.network(
                      result.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.displayName,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Prediction #${result.predictionId}',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white54 : const Color(0xFF6B7280),
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

class _LinkedBanner extends StatelessWidget {
  const _LinkedBanner({required this.treeName, required this.isDark});

  final String treeName;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2D7B31).withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: const Color(0xFF2D7B31).withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.park, color: Color(0xFF2D7B31), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Already linked to: $treeName. You can pick another plant to reassign.',
              style: TextStyle(
                fontSize: 13,
                height: 1.35,
                color: isDark ? Colors.white70 : const Color(0xFF374151),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
