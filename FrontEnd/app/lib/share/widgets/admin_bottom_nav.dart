import 'package:flutter/material.dart';

import '../../routes/app_router.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_layout.dart';

enum AdminShellTab {
  dashboard,
  users,
  models,
  server,
  diseases,
  profile,
}

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({super.key, required this.selected});

  final AdminShellTab selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return FutureBuilder<bool>(
      future: StorageService.canManageUsers(),
      builder: (context, snap) {
        final canManageUsers = snap.data ?? false;

        final items = <_AdminNavItem>[
          const _AdminNavItem(
            tab: AdminShellTab.dashboard,
            label: 'Home',
            icon: Icons.dashboard_outlined,
            route: AppRouter.adminDashboard,
          ),
          if (canManageUsers)
            const _AdminNavItem(
              tab: AdminShellTab.users,
              label: 'Users',
              icon: Icons.groups_outlined,
              route: AppRouter.adminUsers,
            ),
          const _AdminNavItem(
            tab: AdminShellTab.models,
            label: 'Models',
            icon: Icons.psychology_outlined,
            route: AppRouter.adminModels,
          ),
          const _AdminNavItem(
            tab: AdminShellTab.server,
            label: 'Server',
            icon: Icons.dns_outlined,
            route: AppRouter.adminServer,
          ),
          const _AdminNavItem(
            tab: AdminShellTab.diseases,
            label: 'Diseases',
            icon: Icons.coronavirus_outlined,
            route: AppRouter.adminIllnesses,
          ),
          const _AdminNavItem(
            tab: AdminShellTab.profile,
            label: 'Profile',
            icon: Icons.account_circle_outlined,
            route: AppRouter.adminProfile,
          ),
        ];

        final activeIndex = items.indexWhere((e) => e.tab == selected);
        final safeIndex = activeIndex >= 0 ? activeIndex : 0;

        return BottomAppBar(
          color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
          elevation: 8,
          child: SizedBox(
            height: 72,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(items.length, (index) {
                final item = items[index];
                final isActive = index == safeIndex;
                final color = isActive ? AppColors.primary : textSecondary;

                return Expanded(
                  child: InkWell(
                    onTap: isActive
                        ? null
                        : () => Navigator.pushReplacementNamed(
                              context,
                              item.route,
                            ),
                    borderRadius: AppLayout.borderRadiusSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 2),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(item.icon, size: 22, color: color),
                          const SizedBox(height: 2),
                          Text(
                            item.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: color,
                              fontSize: 9,
                              fontWeight: isActive
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

class _AdminNavItem {
  const _AdminNavItem({
    required this.tab,
    required this.label,
    required this.icon,
    required this.route,
  });

  final AdminShellTab tab;
  final String label;
  final IconData icon;
  final String route;
}
