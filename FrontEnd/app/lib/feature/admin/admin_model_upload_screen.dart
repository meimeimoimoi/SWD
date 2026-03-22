import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../../share/services/dashboard_service.dart' show DashboardService;
import '../../share/theme/app_colors.dart';
import '../../share/widgets/admin_bottom_nav.dart';
import '../../share/widgets/admin_pop_scope.dart';

class AdminModelUploadScreen extends StatefulWidget {
  const AdminModelUploadScreen({super.key});

  @override
  State<AdminModelUploadScreen> createState() => _AdminModelUploadScreenState();
}

const Color _kBgLight = Color(0xFFF6F8F6);

class _ModelTypeOption {
  const _ModelTypeOption({required this.apiValue, required this.label});
  final String apiValue;
  final String label;
}

const List<_ModelTypeOption> _kModelTypes = [
  _ModelTypeOption(apiValue: 'mobilenetv3', label: 'Image classification'),
  _ModelTypeOption(apiValue: 'yolov8', label: 'Object detection'),
  _ModelTypeOption(apiValue: 'segmentation', label: 'Segmentation'),
];

class _AdminModelUploadScreenState extends State<AdminModelUploadScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _version = TextEditingController();
  final _desc = TextEditingController();
  final DashboardService _api = DashboardService();

  _ModelTypeOption _selectedType = _kModelTypes.first;
  String? _filePath;
  String? _fileName;
  bool _submitting = false;

  @override
  void dispose() {
    _name.dispose();
    _version.dispose();
    _desc.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    final pick = await FilePicker.platform.pickFiles(type: FileType.any);
    if (pick == null || pick.files.single.path == null) return;
    final path = pick.files.single.path!;
    final name = pick.files.single.name;
    if (!path.toLowerCase().endsWith('.onnx')) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Only .onnx files are accepted'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    setState(() {
      _filePath = path;
      _fileName = name;
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final path = _filePath;
    if (path == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an .onnx file'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    setState(() => _submitting = true);
    final ok = await _api.uploadAdminModel(
      modelName: _name.text.trim(),
      version: _version.text.trim(),
      filePath: path,
      description:
          _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      modelType: _selectedType.apiValue,
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Upload succeeded' : 'Upload failed'),
        backgroundColor: ok ? AppColors.brandAccent : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) {
      await context.read<DashboardProvider>().fetchAdminData();
      if (mounted) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? AppColors.darkBackground : _kBgLight;
    final surface = isDark ? AppColors.surfaceDark : AppColors.surfaceLight;
    final fill = isDark ? AppColors.borderDark : AppColors.brandAccent.withValues(alpha: 0.05);
    final border = AppColors.brandAccent.withValues(alpha: 0.2);

    return AdminPopScope(
      child: Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_rounded, color: AppColors.brandAccent),
                    ),
                    Expanded(
                      child: Text(
                        'Upload new model',
                        style: GoogleFonts.spaceGrotesk(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: isDark
                              ? AppColors.textPrimaryDark
                              : const Color(0xFF0F172A),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: surface,
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _LabeledField(
                                label: 'Model name',
                                child: TextFormField(
                                  controller: _name,
                                  style: _inputStyle(isDark),
                                  decoration: _inputDeco(
                                    hint: 'VD: RiceBlast_ResNet18',
                                    fill: fill,
                                    border: border,
                                    isDark: isDark,
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _LabeledField(
                                label: 'Version',
                                child: TextFormField(
                                  controller: _version,
                                  style: _inputStyle(isDark),
                                  decoration: _inputDeco(
                                    hint: 'VD: v1.0.2',
                                    fill: fill,
                                    border: border,
                                    isDark: isDark,
                                  ),
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Required'
                                          : null,
                                ),
                              ),
                              const SizedBox(height: 18),
                              _LabeledField(
                                label: 'Model type',
                                child: DropdownButtonFormField<_ModelTypeOption>(
                                  value: _selectedType,
                                  isExpanded: true,
                                  decoration: _inputDeco(
                                    hint: '',
                                    fill: fill,
                                    border: border,
                                    isDark: isDark,
                                  ).copyWith(contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14)),
                                  dropdownColor: surface,
                                  icon: const Icon(Icons.expand_more_rounded, color: AppColors.brandAccent),
                                  items: _kModelTypes
                                      .map(
                                        (e) => DropdownMenuItem(
                                          value: e,
                                          child: Text(
                                            e.label,
                                            style: GoogleFonts.spaceGrotesk(
                                              fontSize: 15,
                                              color: isDark
                                                  ? AppColors.textPrimaryDark
                                                  : const Color(0xFF0F172A),
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v != null) {
                                      setState(() => _selectedType = v);
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(height: 18),
                              _LabeledField(
                                label: 'Description',
                                child: TextFormField(
                                  controller: _desc,
                                  maxLines: 5,
                                  minLines: 4,
                                  style: _inputStyle(isDark),
                                  decoration: _inputDeco(
                                    hint:
                                        'Enter detailed information about the model…',
                                    fill: fill,
                                    border: border,
                                    isDark: isDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Material(
                          color: surface,
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.brandAccent.withValues(alpha: 0.06),
                              ),
                            ),
                            padding: const EdgeInsets.all(8),
                            child: InkWell(
                              onTap: _submitting ? null : _pickFile,
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 28,
                                  horizontal: 16,
                                ),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.brandAccent.withValues(alpha: 0.35),
                                    width: 2,
                                  ),
                                  color: AppColors.brandAccent.withValues(alpha: 0.05),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: AppColors.brandAccent.withValues(alpha: 0.2),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.cloud_upload_rounded,
                                        color: AppColors.brandAccent,
                                        size: 36,
                                      ),
                                    ),
                                    const SizedBox(height: 14),
                                    Text(
                                      'Upload model file (.onnx)',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w700,
                                        color: isDark
                                            ? AppColors.textPrimaryDark
                                            : const Color(0xFF1E293B),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Drag and drop or tap to pick a file from your device',
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 13,
                                        color: isDark
                                            ? AppColors.textSecondaryDark
                                            : const Color(0xFF64748B),
                                      ),
                                    ),
                                    if (_fileName != null) ...[
                                      const SizedBox(height: 12),
                                      Text(
                                        _fileName!,
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          color: AppColors.brandAccent,
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 14),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: isDark
                                            ? AppColors.darkControlFill
                                            : AppColors.surfaceLight,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: AppColors.brandAccent.withValues(alpha: 0.2),
                                        ),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(
                                            Icons.info_outline_rounded,
                                            size: 16,
                                            color: AppColors.brandAccent.withValues(alpha: 0.9),
                                          ),
                                          const SizedBox(width: 8),
                                          Flexible(
                                            child: Text(
                                              'Only .onnx format is accepted',
                                              style: GoogleFonts.spaceGrotesk(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600,
                                                color: isDark
                                                    ? AppColors.textSecondaryDark
                                                    : const Color(0xFF475569),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 52,
                          child: FilledButton(
                            onPressed: _submitting ? null : _submit,
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.brandAccent,
                              foregroundColor: AppColors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: AppColors.onPrimary,
                                    ),
                                  )
                                : Text(
                                    'Finish upload',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        bottomNavigationBar: const AdminBottomNav(selected: AdminShellTab.models),
      ),
    );
  }

  static TextStyle _inputStyle(bool isDark) {
    return GoogleFonts.spaceGrotesk(
      fontSize: 15,
      color: isDark ? AppColors.textPrimaryDark : const Color(0xFF0F172A),
    );
  }

  static InputDecoration _inputDeco({
    required String hint,
    required Color fill,
    required Color border,
    required bool isDark,
  }) {
    return InputDecoration(
      hintText: hint.isEmpty ? null : hint,
      hintStyle: GoogleFonts.spaceGrotesk(
        fontSize: 15,
        color: isDark ? Colors.white38 : Colors.grey.shade500,
      ),
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.brandAccent, width: 2),
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textSecondaryDark : const Color(0xFF334155),
            ),
          ),
        ),
        child,
      ],
    );
  }
}
