import 'package:flutter/material.dart';

import '../theme/app_layout.dart';
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
    this.backgroundColor,
    this.contentPadding = const EdgeInsets.symmetric(
      horizontal: AppLayout.screenPaddingH + 8,
      vertical: AppLayout.screenPaddingV + 8,
    ),
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool centerContent;
  final bool showUserBottomNav;
  final int? selectedNavIndex;
  final Color? backgroundColor;
  final EdgeInsetsGeometry contentPadding;

  @override
  Widget build(BuildContext context) {
    final hasAppBar =
        title != null || (actions != null && actions!.isNotEmpty);

    return Scaffold(
      backgroundColor: backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
      appBar: hasAppBar
          ? AppBar(
              title: title != null ? Text(title!) : null,
              actions: actions,
            )
          : null,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: Padding(
              padding: contentPadding,
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
