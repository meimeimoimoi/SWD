import 'package:flutter/material.dart';

import '../../share/services/storage_service.dart';
import '../../share/theme/app_colors.dart';
import 'unified_account_screen.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: StorageService.getRole(),
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: AppColors.brandAccent),
            ),
          );
        }
        final role = snap.data?.toLowerCase().trim() ?? '';
        final staffConsole = role == 'admin' || role == 'technician';
        return UnifiedAccountScreen(isAdminShell: staffConsole);
      },
    );
  }
}
