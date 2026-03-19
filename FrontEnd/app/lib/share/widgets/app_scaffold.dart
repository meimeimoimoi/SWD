import 'package:flutter/material.dart';
import '../../routes/app_router.dart';
import 'theme_toggle.dart';

class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.centerContent = true,
    this.showUserBottomNav = false,
    this.selectedNavIndex,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final bool centerContent;
  final bool showUserBottomNav;
  final int? selectedNavIndex;

  @override
  Widget build(BuildContext context) {
    final currentIndex =
        selectedNavIndex ??
        _routeToIndex(ModalRoute.of(context)?.settings.name);

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
      bottomNavigationBar: showUserBottomNav
          ? BottomNavigationBar(
              currentIndex: currentIndex < 0 ? 0 : currentIndex,
              type: BottomNavigationBarType.fixed,
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(
                  icon: Icon(Icons.camera_alt),
                  label: 'Scan',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.history),
                  label: 'History',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Setting',
                ),
              ],
              onTap: (index) {
                switch (index) {
                  case 0:
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      AppRouter.dashboard,
                      (route) => false,
                    );
                    break;
                  case 1:
                    Navigator.of(context).pushNamed(AppRouter.scan);
                    break;
                  case 2:
                    Navigator.of(context).pushNamed(AppRouter.history);
                    break;
                  case 3:
                    Navigator.of(context).pushNamed(AppRouter.profile);
                    break;
                }
              },
            )
          : null,
    );
  }

  int _routeToIndex(String? route) {
    switch (route) {
      case AppRouter.dashboard:
        return 0;
      case AppRouter.scan:
        return 1;
      case AppRouter.history:
        return 2;
      case AppRouter.profile:
        return 3;
      default:
        return -1;
    }
  }
}
