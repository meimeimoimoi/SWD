import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_notifier.dart';

/// Theme control: [compact] uses an app-bar-friendly icon button; full row + switch otherwise.
class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key, this.compact = false});

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, notifier, _) {
        if (compact) {
          final isDark = notifier.isDarkMode;
          return IconButton(
            tooltip: isDark ? 'Switch to light mode' : 'Switch to dark mode',
            icon: Icon(
              isDark ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
            ),
            onPressed: () => notifier.toggleTheme(),
          );
        }
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              notifier.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              size: 18,
            ),
            Switch(
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              value: notifier.isDarkMode,
              onChanged: (_) => notifier.toggleTheme(),
            ),
          ],
        );
      },
    );
  }
}
