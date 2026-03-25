import 'package:flutter/material.dart';

import '../../share/services/dashboard_service.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/app_button.dart';
import '../../share/widgets/app_card.dart';
import '../../share/widgets/app_input.dart';

/// Flow: pick one or more diseases, then enter solution details. Creates one API
/// row per disease (same name/type/description, shared tree stage).
class AdminTreatmentAddScreen extends StatefulWidget {
  const AdminTreatmentAddScreen({super.key});

  @override
  State<AdminTreatmentAddScreen> createState() =>
      _AdminTreatmentAddScreenState();
}

class _AdminTreatmentAddScreenState extends State<AdminTreatmentAddScreen> {
  final DashboardService _api = DashboardService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final _minConfController = TextEditingController();
  final _priorityController = TextEditingController();
  final _diseaseSearch = TextEditingController();

  List<Map<String, dynamic>> _illnesses = [];
  List<Map<String, dynamic>> _stages = [];
  final Set<int> _selectedIllnessIds = {};
  int? _treeStageId;
  String _solutionType = 'treatment';

  bool _loadingMeta = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _diseaseSearch.addListener(() => setState(() {}));
    _loadMeta();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    _minConfController.dispose();
    _priorityController.dispose();
    _diseaseSearch.dispose();
    super.dispose();
  }

  Future<void> _loadMeta() async {
    setState(() => _loadingMeta = true);
    final ill = await _api.getIllnesses();
    final st = await _api.getTechnicianStages();
    if (!mounted) return;
    setState(() {
      _illnesses = ill;
      _stages = st;
      _loadingMeta = false;
      if (st.isNotEmpty) {
        final ids = st.map(_stageId).toSet();
        if (_treeStageId == null || !ids.contains(_treeStageId)) {
          _treeStageId = _stageId(st.first);
        }
      } else {
        _treeStageId = null;
      }
    });
  }

  static int _illnessId(Map<String, dynamic> m) {
    final v = m['illnessId'] ?? m['IllnessId'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static String _illnessName(Map<String, dynamic> m) {
    return '${m['illnessName'] ?? m['IllnessName'] ?? 'Disease'}'.trim();
  }

  static int _stageId(Map<String, dynamic> m) {
    final v = m['stageId'] ?? m['StageId'];
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('$v') ?? 0;
  }

  static String _stageName(Map<String, dynamic> m) {
    return '${m['stageName'] ?? m['StageName'] ?? 'Stage'}'.trim();
  }

  List<Map<String, dynamic>> get _filteredIllnesses {
    final q = _diseaseSearch.text.trim().toLowerCase();
    if (q.isEmpty) return _illnesses;
    return _illnesses.where((m) {
      final n = _illnessName(m).toLowerCase();
      final sci =
          '${m['scientificName'] ?? m['ScientificName'] ?? ''}'.toLowerCase();
      return n.contains(q) || sci.contains(q);
    }).toList();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedIllnessIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chọn ít nhất một loại bệnh.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_treeStageId == null || _treeStageId! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Chọn giai đoạn cây.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final name = _nameController.text.trim();
    final desc = _descController.text.trim();
    double? minConf;
    if (_minConfController.text.trim().isNotEmpty) {
      minConf = double.tryParse(_minConfController.text.trim());
      if (minConf == null || minConf < 0 || minConf > 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Độ tin cậy tối thiểu phải từ 0 đến 1.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }
    int? priority;
    if (_priorityController.text.trim().isNotEmpty) {
      priority = int.tryParse(_priorityController.text.trim());
      if (priority == null || priority < 1) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Độ ưu tiên phải là số nguyên dương.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    setState(() => _submitting = true);
    var ok = 0;
    final failed = <String>[];

    for (final illnessId in _selectedIllnessIds) {
      final body = <String, dynamic>{
        'illnessId': illnessId,
        'treeStageId': _treeStageId,
        'solutionName': name,
        'solutionType': _solutionType,
        if (desc.isNotEmpty) 'description': desc,
        if (minConf != null) 'minConfidence': minConf,
        if (priority != null) 'priority': priority,
      };
      final r = await _api.createTreatmentManagement(body);
      if (r != null) {
        ok++;
      } else {
        failed.add(_illnessName(
          _illnesses.firstWhere(
            (e) => _illnessId(e) == illnessId,
            orElse: () => {'illnessName': '#$illnessId'},
          ),
        ));
      }
    }

    if (!mounted) return;
    setState(() => _submitting = false);

    final theme = Theme.of(context);
    if (ok == _selectedIllnessIds.length) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok == 1
                ? 'Đã thêm giải pháp.'
                : 'Đã thêm $ok giải pháp (mỗi giải pháp cho một loại bệnh).',
          ),
          backgroundColor: theme.colorScheme.primary,
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            failed.isEmpty
                ? 'Một số yêu cầu thất bại.'
                : 'Đã tạo $ok trên ${_selectedIllnessIds.length}. Thất bại: ${failed.take(3).join(', ')}${failed.length > 3 ? '…' : ''}',
          ),
          backgroundColor: theme.colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      if (ok > 0) {
        Navigator.pop(context, true);
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

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Thêm giải pháp',
          style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
        ),
        actions: [
          IconButton(
            tooltip: 'Tải lại danh sách',
            onPressed: _loadingMeta ? null : _loadMeta,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loadingMeta
          ? const Center(child: CircularProgressIndicator())
          : Form(
                  key: _formKey,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                    children: [
                      if (_illnesses.isEmpty || _stages.isEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            _illnesses.isEmpty && _stages.isEmpty
                                ? 'Danh sách bệnh và giai đoạn cây đang trống. Thêm dữ liệu hoặc làm mới từ tab Bệnh hại, sau đó mở lại màn hình này.'
                                : _illnesses.isEmpty
                                    ? 'Chưa có bệnh nào trong danh sách. Hãy thêm bệnh trước rồi thử lại.'
                                    : 'Không có giai đoạn cây nào khả dụng. Hãy định nghĩa giai đoạn trước khi liên kết giải pháp.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: textSecondary,
                            ),
                          ),
                        ),
                      Text(
                        '1 · Chọn bệnh hại',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Giải pháp giống nhau sẽ được đăng ký cho mỗi loại bệnh được chọn.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textSecondary,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          TextButton(
                            onPressed: () {
                              setState(() {
                                _selectedIllnessIds.clear();
                                for (final m in _illnesses) {
                                  _selectedIllnessIds.add(_illnessId(m));
                                }
                              });
                            },
                            child: const Text('Chọn tất cả'),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(_selectedIllnessIds.clear),
                            child: const Text('Xóa chọn'),
                          ),
                          const Spacer(),
                          Text(
                            'Đã chọn ${_selectedIllnessIds.length}',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      TextField(
                        controller: _diseaseSearch,
                        decoration: InputDecoration(
                          hintText: 'Lọc bệnh hại…',
                          prefixIcon: const Icon(Icons.filter_list),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          isDense: true,
                        ),
                      ),
                      const SizedBox(height: 8),
                      AppCard(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 220),
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _filteredIllnesses.length,
                            itemBuilder: (context, i) {
                              final m = _filteredIllnesses[i];
                              final id = _illnessId(m);
                              final checked = _selectedIllnessIds.contains(id);
                              return CheckboxListTile(
                                value: checked,
                                onChanged: (v) {
                                  setState(() {
                                    if (v == true) {
                                      _selectedIllnessIds.add(id);
                                    } else {
                                      _selectedIllnessIds.remove(id);
                                    }
                                  });
                                },
                                dense: true,
                                title: Text(
                                  _illnessName(m),
                                  style: TextStyle(
                                    color: textPrimary,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                                subtitle: Text(
                                  '${m['scientificName'] ?? m['ScientificName'] ?? ''}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Text(
                        '2 · Chi tiết giải pháp',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Giai đoạn cây',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<int>(
                        value: _stages.isEmpty ? null : _treeStageId,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        hint: const Text('Chọn giai đoạn'),
                        items: _stages
                            .map(
                              (s) => DropdownMenuItem<int>(
                                value: _stageId(s),
                                child: Text(_stageName(s)),
                              ),
                            )
                            .toList(),
                        onChanged: _stages.isEmpty
                            ? null
                            : (v) => setState(() => _treeStageId = v),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Loại giải pháp',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'treatment',
                            label: Text('Điều trị'),
                            icon: Icon(Icons.healing_outlined, size: 18),
                          ),
                          ButtonSegment(
                            value: 'medicine',
                            label: Text('Thuốc'),
                            icon: Icon(Icons.medication_outlined, size: 18),
                          ),
                        ],
                        selected: {_solutionType},
                        onSelectionChanged: (s) {
                          setState(() => _solutionType = s.first);
                        },
                      ),
                      const SizedBox(height: 16),
                      AppInput(
                        label: 'Tên giải pháp',
                        hint: 'VD: Phun thuốc diệt nấm định kỳ',
                        controller: _nameController,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Tên là bắt buộc';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Mô tả (tùy chọn)',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Ghi chú sử dụng, thời điểm, an toàn…',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppInput(
                        label: 'Độ tin cậy tối thiểu (0–1, tùy chọn)',
                        hint: '0.5',
                        controller: _minConfController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppInput(
                        label: 'Độ ưu tiên (tùy chọn)',
                        hint: '1',
                        controller: _priorityController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: _submitting
                            ? 'Đang lưu…'
                            : _selectedIllnessIds.isEmpty
                                ? 'Hãy chọn bệnh hại trước'
                                : 'Tạo cho ${_selectedIllnessIds.length} loại bệnh',
                        onPressed: _submitting
                            ? null
                            : () {
                                if (_selectedIllnessIds.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Chọn ít nhất một loại bệnh ở trên.',
                                      ),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                  return;
                                }
                                _submit();
                              },
                      ),
                    ],
                  ),
                ),
    );
  }
}
