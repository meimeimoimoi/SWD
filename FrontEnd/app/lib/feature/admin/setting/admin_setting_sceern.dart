import 'package:flutter/material.dart';

import '../../settings/settings_screen.dart';

class AdminSettingScreen extends StatelessWidget {
  const AdminSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SettingsScreen(isAdminShell: true);
  }
}
