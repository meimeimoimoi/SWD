import 'package:flutter/material.dart';

import '../../routes/app_router.dart';

/// When the admin shell was opened on top of the user stack, system back would
/// return to [AppRouter.dashboard]. Intercept and reset to admin home instead.
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
            AppRouter.adminUsers,
            (route) => false,
          );
        }
      },
      child: child,
    );
  }
}
