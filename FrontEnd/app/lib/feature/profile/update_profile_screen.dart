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
            response['message']?.toString() ?? 'Profile updated successfully',
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
          response['message']?.toString() ?? 'Failed to update profile',
        ),
        backgroundColor: Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      centerContent: false,
      title: 'Update Profile',
      child: SingleChildScrollView(
        child: AppCard(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AppInput(
                  label: 'Full name',
                  hint: 'Enter your full name',
                  controller: _nameController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppInput(
                  label: 'Phone',
                  hint: 'Enter phone number',
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) {
                      return 'Phone is required';
                    }
                    final phonePattern = RegExp(r'^[0-9+()\-\s]{8,15}$');
                    if (!phonePattern.hasMatch(text)) {
                      return 'Invalid phone format';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                AppInput(
                  label: 'Address',
                  hint: 'Enter your address',
                  controller: _addressController,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Address is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: _isSubmitting ? 'Saving...' : 'Save',
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
