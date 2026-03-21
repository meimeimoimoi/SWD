import 'package:flutter/material.dart';
import 'theme_toggle.dart';
import 'user_bottom_nav_bar.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.centerContent = true,
    this.showUserBottomNav = false,
    this.selectedNavIndex,
    this.showThemeToggle = true,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool centerContent;
  final bool showUserBottomNav;
  final int? selectedNavIndex;
  final bool showThemeToggle;

  @override
  Widget build(BuildContext context) {
    final hasAppBar = title != null ||
        (actions != null && actions!.isNotEmpty) ||
        showThemeToggle;

    return Scaffold(
      appBar: hasAppBar
          ? AppBar(
              title: title != null ? Text(title!) : null,
              actions: [
                ...?actions,
                if (showThemeToggle)
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    child: ThemeToggle(compact: true),
                  ),
              ],
            )
          : null,
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
      bottomNavigationBar: showUserBottomNav
          ? UserBottomNavBar(selectedIndexOverride: selectedNavIndex)
          : null,
    );
  }
}
