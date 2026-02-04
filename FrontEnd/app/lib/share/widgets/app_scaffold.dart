import 'package:flutter/material.dart';
import 'theme_toggle.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.centerContent = true,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool centerContent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: title != null ? Text(title!) : null,
        actions: [
          ...?actions,
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: ThemeToggle(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: centerContent ? Center(child: child) : child,
            ),
          ),
        ),
      ),
    );
  }
}
