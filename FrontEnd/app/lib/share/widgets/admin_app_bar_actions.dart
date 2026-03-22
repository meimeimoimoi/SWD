import 'package:flutter/material.dart';

import '../../routes/app_router.dart';

/// Secondary entry points (feedback, settings) while using the 4-tab admin shell.
List<Widget> adminSecondaryAppBarActions(BuildContext context) {
  return [
    IconButton(
      tooltip: 'Feedback',
      onPressed: () => Navigator.pushNamed(context, AppRouter.adminFeedback),
      icon: const Icon(Icons.rate_review_outlined),
    ),
    IconButton(
      tooltip: 'Settings',
      onPressed: () => Navigator.pushNamed(context, AppRouter.adminSettings),
      icon: const Icon(Icons.settings_outlined),
    ),
  ];
}
