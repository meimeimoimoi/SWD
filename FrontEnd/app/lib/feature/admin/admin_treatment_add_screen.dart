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
          content: Text('Select at least one disease.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (_treeStageId == null || _treeStageId! <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Choose a tree stage.'),
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
            content: Text('Min confidence must be between 0 and 1.'),
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
            content: Text('Priority must be a positive integer.'),
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
                ? 'Solution added.'
                : 'Added $ok solutions (one per disease).',
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
                ? 'Some requests failed.'
                : 'Created $ok of ${_selectedIllnessIds.length}. Failed: ${failed.take(3).join(', ')}${failed.length > 3 ? '…' : ''}',
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
          'Add solution',
          style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
        ),
        actions: [
          IconButton(
            tooltip: 'Reload lists',
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
                                ? 'Disease and tree-stage lists are empty. Add data or pull to refresh from the Diseases tab, then reopen this screen.'
                                : _illnesses.isEmpty
                                    ? 'No diseases in the list yet. Add diseases first, then try again.'
                                    : 'No tree stages available. Define stages before linking solutions.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: textSecondary,
                            ),
                          ),
                        ),
                      Text(
                        '1 · Select diseases',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'The same solution will be registered once per selected disease.',
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
                            child: const Text('Select all'),
                          ),
                          TextButton(
                            onPressed: () =>
                                setState(_selectedIllnessIds.clear),
                            child: const Text('Clear'),
                          ),
                          const Spacer(),
                          Text(
                            '${_selectedIllnessIds.length} selected',
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
                          hintText: 'Filter diseases…',
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
                        '2 · Solution details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Tree stage',
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
                        hint: const Text('Choose stage'),
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
                        'Solution type',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SegmentedButton<String>(
                        segments: const [
                          ButtonSegment(
                            value: 'treatment',
                            label: Text('Treatment'),
                            icon: Icon(Icons.healing_outlined, size: 18),
                          ),
                          ButtonSegment(
                            value: 'medicine',
                            label: Text('Medicine'),
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
                        label: 'Solution name',
                        hint: 'e.g. Foliar fungicide rotation',
                        controller: _nameController,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Name is required';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Description (optional)',
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _descController,
                        minLines: 2,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Application notes, timing, safety…',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppInput(
                        label: 'Min confidence (0–1, optional)',
                        hint: '0.5',
                        controller: _minConfController,
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppInput(
                        label: 'Priority (optional)',
                        hint: '1',
                        controller: _priorityController,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 24),
                      AppButton(
                        label: _submitting
                            ? 'Saving…'
                            : _selectedIllnessIds.isEmpty
                                ? 'Select diseases first'
                                : 'Create for ${_selectedIllnessIds.length} disease(s)',
                        onPressed: _submitting
                            ? null
                            : () {
                                if (_selectedIllnessIds.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Choose at least one disease above.',
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
