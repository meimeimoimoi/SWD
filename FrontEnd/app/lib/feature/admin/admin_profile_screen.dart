import 'package:flutter/material.dart';

import '../profile/unified_account_screen.dart';
import '../../share/widgets/admin_pop_scope.dart';

/// Admin tab hồ sơ — cùng UI với [ProfileScreen] (role admin).
class AdminProfileScreen extends StatelessWidget {
  const AdminProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const AdminPopScope(
      child: UnifiedAccountScreen(isAdminShell: true),
    );
  }
}
