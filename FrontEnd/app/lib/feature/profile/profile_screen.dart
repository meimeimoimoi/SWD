import 'package:flutter/material.dart';

import '../../share/services/storage_service.dart';
import 'unified_account_screen.dart';

const Color _kPrimary = Color(0xFF2D7B31);

/// Hồ sơ + cài đặt (user & admin) — [UnifiedAccountScreen].
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
              child: CircularProgressIndicator(color: _kPrimary),
            ),
          );
        }
        final role = snap.data?.toLowerCase() ?? '';
        return UnifiedAccountScreen(isAdminShell: role == 'admin');
      },
    );
  }
}
