import 'package:flutter/material.dart';

import '../profile/unified_account_screen.dart';

/// Cùng nội dung với tab Hồ sơ; dùng khi mở từ biểu tượng bánh răng (có nút quay lại).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key, this.isAdminShell = false});

  final bool isAdminShell;

  @override
  Widget build(BuildContext context) {
    return UnifiedAccountScreen(
      isAdminShell: isAdminShell,
      showLeadingBack: true,
    );
  }
}
