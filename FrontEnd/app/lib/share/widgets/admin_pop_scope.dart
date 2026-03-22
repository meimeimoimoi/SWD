import 'package:flutter/material.dart';

import '../../routes/app_router.dart';

class AdminPopScope extends StatelessWidget {
  const AdminPopScope({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final hasParentRoute = Navigator.of(context).canPop();
    return PopScope(
      canPop: !hasParentRoute,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (hasParentRoute && !didPop) {
          Navigator.pushNamedAndRemoveUntil(
            context,
            AppRouter.adminDashboard,
            (route) => false,
          );
        }
      },
      child: child,
    );
  }
}
