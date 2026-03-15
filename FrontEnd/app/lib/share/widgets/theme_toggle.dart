import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_notifier.dart';

class ThemeToggle extends StatelessWidget {
  const ThemeToggle({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, notifier, _) {
        return Row(
          children: [
            Icon(
              notifier.isDarkMode ? Icons.dark_mode : Icons.light_mode,
              size: 18,
            ),
            Switch(
              value: notifier.isDarkMode,
              onChanged: (_) => notifier.toggleTheme(),
            ),
          ],
        );
      },
    );
  }
}
