import 'package:flutter/material.dart';

import '../theme/app_layout.dart';

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
  });

  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = theme.colorScheme.surface;
    final outline = theme.colorScheme.outline.withValues(alpha: isDark ? 0.9 : 1);
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: AppLayout.borderRadiusMd,
        border: Border.all(color: outline),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.07),
            blurRadius: isDark ? 18 : 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}
