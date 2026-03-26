import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import 'admin_treatment_add_screen.dart';
import '../../share/services/dashboard_service.dart';
import '../../share/theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import '../../share/constants/api_config.dart';
import '../../share/widgets/admin_app_bar_actions.dart';
import '../../share/widgets/admin_bottom_nav.dart';
import '../../share/widgets/admin_pop_scope.dart';
import '../../share/widgets/app_card.dart';
import '../../share/widgets/app_button.dart';
import '../../share/widgets/app_input.dart';

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
      final name = '${r['solutionName'] ?? r['SolutionName'] ?? ''}'
          .toLowerCase();
      final ill = '${r['illnessName'] ?? r['IllnessName'] ?? ''}'.toLowerCase();
      final type = '${r['solutionType'] ?? r['SolutionType'] ?? ''}'
          .toLowerCase();
      final desc = '${r['description'] ?? r['Description'] ?? ''}'
          .toLowerCase();
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
      MaterialPageRoute<bool>(builder: (_) => const AdminTreatmentAddScreen()),
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
            'Giải pháp điều trị',
            style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
          ),
          actions: [
            IconButton(
              tooltip: 'Thêm giải pháp',
              onPressed: _openAddSolution,
              icon: const Icon(Icons.add),
            ),
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
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                      child: TextField(
                        controller: _search,
                        decoration: InputDecoration(
                          hintText: 'Tìm kiếm giải pháp, bệnh hại…',
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
                                        ? 'Chưa có giải pháp điều trị nào.\nHãy thêm mới và liên kết với bệnh hại.'
                                        : 'Không tìm thấy kết quả phù hợp.',
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
                                    child: InkWell(
                                      onTap: () => _showEditSheet(r),
                                      borderRadius: BorderRadius.circular(16),
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
                                                      ? Icons
                                                            .medication_outlined
                                                      : Icons.healing_outlined,
                                                  color: AppColors.primary,
                                                  size: 22,
                                                ),
                                                const SizedBox(width: 10),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        name,
                                                        style: theme
                                                            .textTheme
                                                            .titleSmall
                                                            ?.copyWith(
                                                              color:
                                                                  textPrimary,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                            ),
                                                      ),
                                                      const SizedBox(height: 4),
                                                      Text(
                                                        'Bệnh: $ill',
                                                        style: theme
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color:
                                                                  textSecondary,
                                                            ),
                                                      ),
                                                      Text(
                                                        'Giai đoạn cây: $stage · ID $id',
                                                        style: theme
                                                            .textTheme
                                                            .bodySmall
                                                            ?.copyWith(
                                                              color:
                                                                  textSecondary,
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
            label: const Text('Thêm giải pháp'),
          ),
        ),
        bottomNavigationBar: const AdminBottomNav(
          selected: AdminShellTab.treatments,
        ),
      ),
    );
  }

  Future<void> _showEditSheet(Map<String, dynamic> row) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _EditSheet(row: row, api: _api, onRefresh: _load),
    );
  }
}

class _EditSheet extends StatefulWidget {
  final Map<String, dynamic> row;
  final DashboardService api;
  final VoidCallback onRefresh;

  const _EditSheet({
    required this.row,
    required this.api,
    required this.onRefresh,
  });

  @override
  State<_EditSheet> createState() => _EditSheetState();
}

class _EditSheetState extends State<_EditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  late final TextEditingController _ingredientsCtrl;
  late final TextEditingController _shoppeUrlCtrl;
  late final TextEditingController _instructionsCtrl;
  late final TextEditingController _minConfidenceCtrl;
  late final TextEditingController _priorityCtrl;
  late String _solType;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    final row = widget.row;
    final initialName = '${row['solutionName'] ?? row['SolutionName'] ?? ''}'
        .trim();
    final initialDesc = '${row['description'] ?? row['Description'] ?? ''}'
        .trim();
    final initialType =
        '${row['solutionType'] ?? row['SolutionType'] ?? 'treatment'}'
            .toUpperCase()
            .trim();
    final initialIngredients =
        '${row['ingredients'] ?? row['Ingredients'] ?? ''}'.trim();
    final initialShoppeUrl = '${row['shoppeUrl'] ?? row['ShoppeUrl'] ?? ''}'
        .trim();
    final initialInstructions =
        '${row['instructions'] ?? row['Instructions'] ?? ''}'.trim();
    final initialMinConfidence =
        '${row['minConfidence'] ?? row['MinConfidence'] ?? '0.0'}';
    final initialPriority = '${row['priority'] ?? row['Priority'] ?? '1'}';

    _nameCtrl = TextEditingController(text: initialName);
    _descCtrl = TextEditingController(text: initialDesc);
    _ingredientsCtrl = TextEditingController(text: initialIngredients);
    _shoppeUrlCtrl = TextEditingController(text: initialShoppeUrl);
    _instructionsCtrl = TextEditingController(text: initialInstructions);
    _minConfidenceCtrl = TextEditingController(text: initialMinConfidence);
    _priorityCtrl = TextEditingController(text: initialPriority);

    _solType = initialType == 'MEDICINE' ? 'MEDICINE' : 'TREATMENT';
    // extract existing images list for manipulation
    final imgsRaw = widget.row['images'] ?? widget.row['Images'] ?? [];
    _existingImages = [];
    if (imgsRaw is List) {
      for (final it in imgsRaw) {
        if (it == null) continue;
        if (it is String) {
          _existingImages.add({'imageUrl': it});
        } else if (it is Map) {
          _existingImages.add(Map<String, dynamic>.from(it));
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _ingredientsCtrl.dispose();
    _shoppeUrlCtrl.dispose();
    _instructionsCtrl.dispose();
    _minConfidenceCtrl.dispose();
    _priorityCtrl.dispose();
    super.dispose();
  }

  final _picker = ImagePicker();
  List<Map<String, dynamic>> _existingImages = [];

  Future<void> _pickAndUploadImages(int id) async {
    try {
      final picked = await _picker.pickMultiImage();
      if (picked.isEmpty) return;
      setState(() => _updating = true);
      for (final p in picked) {
        final res = await widget.api.uploadTreatmentImage(id, p.path);
        if (res != null) {
          setState(() => _existingImages.add(res));
        }
      }
    } finally {
      setState(() => _updating = false);
    }
  }

  Future<void> _deleteImage(int imageId) async {
    setState(() => _updating = true);
    final ok = await widget.api.deleteTreatmentImage(imageId);
    if (ok) {
      setState(
        () => _existingImages.removeWhere(
          (e) => (e['imageId'] ?? e['ImageId']) == imageId,
        ),
      );
    }
    setState(() => _updating = false);
  }

  int _asInt(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final row = widget.row;
    final id = _asInt(row['solutionId'] ?? row['SolutionId']);
    final isDarkSheet = theme.brightness == Brightness.dark;

    final illnessName = '${row['illnessName'] ?? row['IllnessName'] ?? '—'}';
    final treeStageName =
        '${row['treeStageName'] ?? row['TreeStageName'] ?? '—'}';

    Widget sectionTitle(String title) {
      return Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDarkSheet ? const Color(0xFF18181B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withAlpha(80),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Chi tiết giải pháp #$id',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: _updating
                        ? null
                        : () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (d) => AlertDialog(
                                title: const Text('Xóa giải pháp?'),
                                content: const Text(
                                  'Thao tác này sẽ xóa vĩnh viễn giải pháp này. Tiếp tục?',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(d, false),
                                    child: const Text('Hủy'),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pop(d, true),
                                    child: const Text(
                                      'Xóa',
                                      style: TextStyle(color: Colors.red),
                                    ),
                                  ),
                                ],
                              ),
                            );

                            if (confirm == true) {
                              setState(() => _updating = true);
                              final ok = await widget.api
                                  .deleteTreatmentManagement(id);
                              if (ok) {
                                if (mounted) Navigator.pop(context);
                                widget.onRefresh();
                              } else {
                                setState(() => _updating = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Xóa thất bại'),
                                    ),
                                  );
                                }
                              }
                            }
                          },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Category: Information
              sectionTitle('Thông tin chung'),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bệnh', style: theme.textTheme.labelSmall),
                        Text(illnessName, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Giai đoạn', style: theme.textTheme.labelSmall),
                        Text(treeStageName, style: theme.textTheme.bodyMedium),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text('Loại giải pháp', style: theme.textTheme.labelSmall),
              const SizedBox(height: 8),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(
                    value: 'TREATMENT',
                    label: Text('Điều trị'),
                    icon: Icon(Icons.healing_outlined, size: 18),
                  ),
                  ButtonSegment(
                    value: 'MEDICINE',
                    label: Text('Thuốc'),
                    icon: Icon(Icons.medication_outlined, size: 18),
                  ),
                ],
                selected: {_solType},
                onSelectionChanged: (s) => setState(() => _solType = s.first),
              ),
              const SizedBox(height: 16),
              AppInput(
                label: 'Tên giải pháp',
                controller: _nameCtrl,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Bắt buộc' : null,
              ),
              const SizedBox(height: 16),
              AppInput(
                label: 'Mô tả',
                controller: _descCtrl,
                minLines: 2,
                maxLines: 4,
              ),

              // Category: Medicine (dynamic)
              if (_solType == 'MEDICINE') ...[
                sectionTitle('Chi tiết thuốc'),
                AppInput(
                  label: 'Thành phần',
                  controller: _ingredientsCtrl,
                  minLines: 1,
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                AppInput(
                  label: 'Hướng dẫn sử dụng',
                  controller: _instructionsCtrl,
                  minLines: 2,
                  maxLines: 5,
                ),
                const SizedBox(height: 16),
                AppInput(
                  label: 'Link Shopee',
                  controller: _shoppeUrlCtrl,
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Hình ảnh thuốc', style: theme.textTheme.labelSmall),
                    TextButton.icon(
                      onPressed: _updating ? null : () => _pickAndUploadImages(id),
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Thêm ảnh'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Images (if any)
                Builder(
                  builder: (ctx) {
                    if (_existingImages.isEmpty) return const SizedBox.shrink();
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _existingImages.map((e) {
                        final u = e['imageUrl'] ?? e['ImageUrl'] ?? e['Imageurl'];
                        if (u == null) return const SizedBox.shrink();
                        final imageId = e['imageId'] ?? e['ImageId'];
                        
                        final src = ApiConfig.resolveMediaUrl(u.toString());
                        return Stack(
                          clipBehavior: Clip.none,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                src,
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 80,
                                  height: 80,
                                  color: Colors.grey[200],
                                  child: const Icon(
                                    Icons.broken_image,
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: -8,
                              right: -8,
                              child: IconButton(
                                icon: Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.cancel,
                                    size: 20,
                                    color: Colors.redAccent,
                                  ),
                                ),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: _updating
                                    ? null
                                    : () async {
                                        int? resolvedId;
                                        if (imageId is int) {
                                          resolvedId = imageId;
                                        } else if (imageId != null) {
                                          resolvedId = int.tryParse(imageId.toString());
                                        }
                                        if (resolvedId != null && resolvedId > 0) {
                                          await _deleteImage(resolvedId);
                                        }
                                      },
                              ),
                            ),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ],

              // Category: System Metrics
              sectionTitle('Thông số hệ thống'),
              Row(
                children: [
                  Expanded(
                    child: AppInput(
                      label: 'Ưu tiên',
                      controller: _priorityCtrl,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppInput(
                      label: 'Độ tin cậy (0-1)',
                      controller: _minConfidenceCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: _updating ? 'Đang lưu...' : 'Lưu thay đổi',
                      onPressed: _updating
                          ? null
                          : () async {
                              if (!_formKey.currentState!.validate()) return;
                              setState(() => _updating = true);

                              final body = {
                                'solutionName': _nameCtrl.text.trim(),
                                'solutionType': _solType,
                                'description': _descCtrl.text.trim(),
                                'minConfidence':
                                    double.tryParse(_minConfidenceCtrl.text) ??
                                    0.0,
                                'priority':
                                    int.tryParse(_priorityCtrl.text) ?? 1,
                                'ingredients': _solType == 'MEDICINE'
                                    ? _ingredientsCtrl.text.trim()
                                    : null,
                                'shoppeUrl': _solType == 'MEDICINE'
                                    ? _shoppeUrlCtrl.text.trim()
                                    : null,
                                'instructions': _solType == 'MEDICINE'
                                    ? _instructionsCtrl.text.trim()
                                    : null,
                              };

                              final ok = await widget.api
                                  .updateTreatmentManagement(id, body);
                              if (ok) {
                                if (mounted) Navigator.pop(context);
                                widget.onRefresh();
                              } else {
                                setState(() => _updating = false);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Cập nhật thất bại'),
                                    ),
                                  );
                                }
                              }
                            },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: AppButton(
                      label: 'Đóng',
                      variant: AppButtonVariant.outlined,
                      onPressed: () => Navigator.pop(context),
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
