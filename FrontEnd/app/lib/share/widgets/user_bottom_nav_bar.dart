import 'package:flutter/material.dart';

import '../../routes/app_router.dart';

class UserBottomNavBar extends StatelessWidget {
  const UserBottomNavBar({super.key, this.selectedIndexOverride});

  final int? selectedIndexOverride;

  static int indexForRoute(String? name) {
    switch (name) {
      case AppRouter.dashboard:
        return 0;
      case AppRouter.scan:
      case AppRouter.history:
        return 1;
      case AppRouter.trees:
        return 2;
      case AppRouter.profile:
        return 3;
      default:
        return -1;
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = ModalRoute.of(context)?.settings.name;
    var idx = selectedIndexOverride ?? indexForRoute(route);
    if (idx < 0) idx = 0;

    return NavigationBar(
      selectedIndex: idx,
      onDestinationSelected: (i) {
        switch (i) {
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
            Navigator.of(context).pushNamed(AppRouter.trees);
            break;
          case 3:
            Navigator.of(context).pushNamed(AppRouter.profile);
            break;
        }
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.dashboard_outlined),
          selectedIcon: Icon(Icons.dashboard),
          label: 'Overview',
        ),
        NavigationDestination(
          icon: Icon(Icons.document_scanner_outlined),
          selectedIcon: Icon(Icons.document_scanner),
          label: 'Scan',
        ),
        NavigationDestination(
          icon: Icon(Icons.park_outlined),
          selectedIcon: Icon(Icons.park),
          label: 'Plants',
        ),
        NavigationDestination(
          icon: Icon(Icons.account_circle_outlined),
          selectedIcon: Icon(Icons.account_circle),
          label: 'Profile',
        ),
      ],
    );
  }
}
