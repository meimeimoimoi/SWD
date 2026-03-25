import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../share/services/dashboard_service.dart';
import '../../share/theme/app_colors.dart';

class AdminIllnessEditScreen extends StatefulWidget {
  const AdminIllnessEditScreen({super.key, this.illnessId});

  final int? illnessId;

  @override
  State<AdminIllnessEditScreen> createState() => _AdminIllnessEditScreenState();
}

const Color _kBg = Color(0xFFF6F8F6);

const List<String> _kSeverityLevels = [
  'Low',
  'Medium',
  'High',
  'Critical',
];

const Map<String, String> _kLegacySeverity = {
  'Low': 'Low',
  'Medium': 'Medium',
  'High': 'High',
  'Critical': 'Critical',
  'Thấp': 'Low',
  'Trung bình': 'Medium',
  'Cao': 'High',
  'Nguy hiểm': 'Critical',
};

String _normalizeSeverity(String raw) {
  final t = raw.trim();
  if (t.isEmpty) return _kSeverityLevels.first;
  if (_kSeverityLevels.contains(t)) return t;
  return _kLegacySeverity[t] ?? _kSeverityLevels.first;
}

class _AdminIllnessEditScreenState extends State<AdminIllnessEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _api = DashboardService();
  final _name = TextEditingController();
  final _sci = TextEditingController();
  final _desc = TextEditingController();
  final _symptoms = TextEditingController();
  final _causes = TextEditingController();

  String _severity = _kSeverityLevels.first;
  final List<XFile> _images = [];
  final ImagePicker _picker = ImagePicker();

  bool _saving = false;
  bool _loadExisting = true;

  @override
  void initState() {
    super.initState();
    if (widget.illnessId != null) {
      _fetch();
    } else {
      _loadExisting = false;
    }
  }

  Future<void> _fetch() async {
    final id = widget.illnessId;
    if (id == null) return;
    setState(() => _loadExisting = true);
    final row = await _api.getIllnessById(id);
    if (!mounted) return;
    if (row != null) {
      _name.text = '${row['illnessName'] ?? row['IllnessName'] ?? ''}';
      _sci.text = '${row['scientificName'] ?? row['ScientificName'] ?? ''}';
      _desc.text = '${row['description'] ?? row['Description'] ?? ''}';
      _symptoms.text = '${row['symptoms'] ?? row['Symptoms'] ?? ''}';
      _causes.text = '${row['causes'] ?? row['Causes'] ?? ''}';
      final sev = '${row['severity'] ?? row['Severity'] ?? ''}'.trim();
      _severity = _normalizeSeverity(sev);
    }
    setState(() => _loadExisting = false);
  }

  @override
  void dispose() {
    _name.dispose();
    _sci.dispose();
    _desc.dispose();
    _symptoms.dispose();
    _causes.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    if (_images.length >= 6) return;
    final x = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (x == null || !mounted) return;
    setState(() => _images.add(x));
  }

  void _removeImage(int index) {
    setState(() => _images.removeAt(index));
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final body = <String, dynamic>{
      'illnessName': _name.text.trim(),
      'scientificName': _sci.text.trim().isEmpty ? null : _sci.text.trim(),
      'description': _desc.text.trim().isEmpty ? null : _desc.text.trim(),
      'symptoms': _symptoms.text.trim().isEmpty ? null : _symptoms.text.trim(),
      'causes': _causes.text.trim().isEmpty ? null : _causes.text.trim(),
      'severity': _severity,
    };
    bool ok;
    if (widget.illnessId == null) {
      ok = await _api.createIllness(body);
    } else {
      ok = await _api.updateIllness(widget.illnessId!, body);
    }
    if (!mounted) return;
    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Đã lưu' : 'Lưu thất bại'),
        backgroundColor: ok ? AppColors.brandAccent : Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
    if (ok) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final surfaceCard =
        isDark
            ? const Color(0xFF1E2320).withValues(alpha: 0.9)
            : AppColors.surfaceLight;
    final borderColor = AppColors.brandAccent.withValues(alpha: 0.12);

    if (_loadExisting) {
      return Scaffold(
        backgroundColor: isDark ? AppColors.darkBackground : _kBg,
        appBar: AppBar(
          backgroundColor: isDark ? AppColors.darkBackground : _kBg,
          title: Text(
            'Đang tải…',
            style: GoogleFonts.spaceGrotesk(color: textPrimary),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.brandAccent),
        ),
      );
    }

    final title =
        widget.illnessId == null ? 'Thêm bệnh mới' : 'Chỉnh sửa bệnh';

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : _kBg,
      appBar: AppBar(
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: AppColors.brandAccent.withValues(alpha: 0.08),
        backgroundColor: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : AppColors.scrimLight(0.92),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          color: textPrimary,
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          title,
          style: GoogleFonts.spaceGrotesk(
            fontWeight: FontWeight.w700,
            fontSize: 20,
            color: textPrimary,
            letterSpacing: -0.3,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Form(
                key: _formKey,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: surfaceCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _LabeledField(
                        label: 'Tên bệnh',
                        requiredMark: true,
                        child: _GuideTextField(
                          controller: _name,
                          hint: 'VD: Đốm lá do vi khuẩn',
                          validator: (v) => v == null || v.trim().isEmpty
                              ? 'Vui lòng nhập tên bệnh'
                              : null,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _LabeledField(
                        label: 'Tên khoa học',
                        child: _GuideTextField(
                          controller: _sci,
                          hint: 'VD: Xanthomonas campestris',
                          style: GoogleFonts.spaceGrotesk(
                            fontStyle: FontStyle.italic,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _LabeledField(
                        label: 'Mức độ nghiêm trọng',
                        child: _SeverityDropdown(
                          value: _severity,
                          onChanged: (v) =>
                              setState(() => _severity = v ?? _kSeverityLevels.first),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _LabeledField(
                        label: 'Mô tả chi tiết',
                        child: _GuideTextField(
                          controller: _desc,
                          hint: 'Nhập tổng quan về bệnh…',
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _LabeledField(
                        label: 'Triệu chứng nhận biết',
                        child: _GuideTextField(
                          controller: _symptoms,
                          hint:
                              'Mô tả các dấu hiệu trên lá, thân, quả…',
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _LabeledField(
                        label: 'Nguyên nhân',
                        child: _GuideTextField(
                          controller: _causes,
                          hint:
                              'Do nấm, vi khuẩn hay điều kiện môi trường?',
                          maxLines: 3,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _LabeledField(
                        label: 'Hình ảnh minh họa',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hình ảnh chỉ hiển thị trên thiết bị — API chưa hỗ trợ lưu tệp đính kèm.',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 11,
                                height: 1.3,
                                color: isDark
                                    ? Colors.white54
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            _ImageGrid(
                              images: _images,
                              onAdd: _pickImage,
                              onRemove: _removeImage,
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
          Material(
            elevation: 8,
            color: isDark
                ? AppColors.darkBackground.withValues(alpha: 0.95)
                : AppColors.scrimLight(0.95),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _saving ? null : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandAccent,
                      foregroundColor: AppColors.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _saving
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.onPrimary,
                            ),
                          )
                        : Text(
                            'Lưu',
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.child,
    this.requiredMark = false,
  });

  final String label;
  final Widget child;
  final bool requiredMark;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: AppColors.brandAccent,
              ),
            ),
            if (requiredMark) ...[
              const SizedBox(width: 2),
              Text(
                '*',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  color: Colors.red.shade600,
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _GuideTextField extends StatelessWidget {
  const _GuideTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.validator,
    this.style,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final String? Function(String?)? validator;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? const Color(0xFF2A322E)
        : AppColors.brandAccent.withValues(alpha: 0.05);
    final border = AppColors.brandAccent.withValues(alpha: 0.2);

    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      validator: validator,
      style: style ??
          GoogleFonts.spaceGrotesk(
            fontSize: 15,
            color: isDark ? AppColors.textPrimaryDark : const Color(0xFF181D17),
          ),
      decoration: InputDecoration(
        hintText: hint,
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
      ),
    );
  }
}

class _SeverityDropdown extends StatelessWidget {
  const _SeverityDropdown({
    required this.value,
    required this.onChanged,
  });

  final String value;
  final void Function(String?) onChanged;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fill = isDark
        ? const Color(0xFF2A322E)
        : AppColors.brandAccent.withValues(alpha: 0.05);
    final border = AppColors.brandAccent.withValues(alpha: 0.2);

    return DropdownButtonFormField<String>(
      value: value,
      onChanged: onChanged,
      isExpanded: true,
      icon: const Icon(Icons.expand_more_rounded, color: AppColors.brandAccent),
      style: GoogleFonts.spaceGrotesk(
        fontSize: 15,
        color: isDark ? AppColors.textPrimaryDark : const Color(0xFF181D17),
      ),
      decoration: InputDecoration(
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
      ),
      items: _kSeverityLevels
          .map(
            (e) => DropdownMenuItem(
              value: e,
              child: Text(_severityLabels[e] ?? e),
            ),
          )
          .toList(),
    );
  }

  static const Map<String, String> _severityLabels = {
    'Low': 'Thấp',
    'Medium': 'Trung bình',
    'High': 'Cao',
    'Critical': 'Nguy hiểm',
  };
}

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({
    required this.images,
    required this.onAdd,
    required this.onRemove,
  });

  final List<XFile> images;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    if (images.length < 6) {
      cells.add(_AddTile(onTap: onAdd));
    }
    for (var i = 0; i < images.length; i++) {
      cells.add(_ThumbTile(
        file: images[i],
        onRemove: () => onRemove(i),
      ));
    }

    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1,
      children: cells,
    );
  }
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.brandAccent.withValues(alpha: 0.35),
              width: 2,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_a_photo_outlined, color: AppColors.brandAccent.withValues(alpha: 0.7)),
              const SizedBox(height: 4),
              Text(
                'Thêm ảnh',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandAccent.withValues(alpha: 0.65),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThumbTile extends StatelessWidget {
  const _ThumbTile({required this.file, required this.onRemove});

  final XFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          _ThumbImage(file: file),
          Positioned(
            top: 4,
            right: 4,
            child: Material(
              color: Colors.black54,
              shape: const CircleBorder(),
              child: IconButton(
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.close, size: 16, color: AppColors.onPrimary),
                onPressed: onRemove,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbImage extends StatelessWidget {
  const _ThumbImage({required this.file});

  final XFile file;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Uint8List>(
      future: file.readAsBytes(),
      builder: (context, snap) {
        if (snap.hasError || !snap.hasData) {
          return Container(color: Colors.grey.shade300);
        }
        return Image.memory(
          snap.data!,
          fit: BoxFit.cover,
        );
      },
    );
  }
}
