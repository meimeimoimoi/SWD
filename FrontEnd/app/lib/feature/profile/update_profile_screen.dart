import 'package:flutter/material.dart';

import '../../share/services/auth_api_service.dart';
import '../../share/widgets/app_button.dart';
import '../../share/widgets/app_card.dart';
import '../../share/widgets/app_input.dart';
import '../../share/widgets/app_scaffold.dart';

class UpdateProfileScreen extends StatefulWidget {
  const UpdateProfileScreen({super.key});

  @override
  State<UpdateProfileScreen> createState() => _UpdateProfileScreenState();
}

class _UpdateProfileScreenState extends State<UpdateProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  bool _isSubmitting = false;
  bool _didInitFromArgs = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_didInitFromArgs) {
      return;
    }

    _didInitFromArgs = true;
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is! Map<String, dynamic>) {
      return;
    }

    final profile = _extractProfileMap(args);
    _nameController.text =
        _firstText(profile, ['fullName', 'name', 'username']) ?? '';
    _phoneController.text = _firstText(profile, ['phone', 'phoneNumber']) ?? '';
    _addressController.text = _firstText(profile, ['address']) ?? '';
  }

  Map<String, dynamic> _extractProfileMap(Map<String, dynamic> root) {
    final nestedData = root['data'];
    if (nestedData is Map<String, dynamic>) {
      return nestedData;
    }

    final nestedUser = root['user'];
    if (nestedUser is Map<String, dynamic>) {
      return nestedUser;
    }

    return root;
  }

  String? _firstText(Map<String, dynamic> source, List<String> keys) {
    for (final key in keys) {
      final value = source[key]?.toString();
      if (value != null && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSubmitting = true);

    final payload = <String, dynamic>{
      'fullName': _nameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'address': _addressController.text.trim(),
    };

    final response = await AuthApiService.updateProfile(payload);
    if (!mounted) {
      return;
    }

    if (response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            response['message']?.toString() ?? 'Cập nhật hồ sơ thành công',
          ),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    setState(() => _isSubmitting = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          response['message']?.toString() ?? 'Cập nhật hồ sơ thất bại',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      centerContent: false,
      title: 'Cập nhật hồ sơ',
      child: SingleChildScrollView(
        child: AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppInput(
                  label: 'Họ và tên',
                  hint: 'Nhập họ và tên của bạn',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập họ tên';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppInput(
                  label: 'Số điện thoại',
                  hint: 'Nhập số điện thoại',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    final phonePattern = RegExp(r'^[0-9+()\-\s]{8,15}$');
                    if (!phonePattern.hasMatch(text)) {
                      return 'Số điện thoại không hợp lệ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppInput(
                  label: 'Địa chỉ',
                  hint: 'Nhập địa chỉ của bạn',
                  controller: _addressController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Vui lòng nhập địa chỉ';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: _isSubmitting ? 'Đang lưu...' : 'Lưu thay đổi',
                  onPressed: _isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
