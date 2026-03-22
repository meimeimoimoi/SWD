import 'package:flutter/material.dart';

import '../../routes/app_router.dart';
import '../theme/app_colors.dart';

class AdminBottomNav extends StatelessWidget {
  const AdminBottomNav({super.key, required this.currentIndex});

  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    final items = <_AdminNavItem>[
      const _AdminNavItem(
        label: 'Users',
        icon: Icons.groups_outlined,
        route: AppRouter.adminUsers,
      ),
      const _AdminNavItem(
        label: 'Models',
        icon: Icons.psychology_outlined,
        route: AppRouter.adminModels,
      ),
      const _AdminNavItem(
        label: 'Server',
        icon: Icons.dns_outlined,
        route: AppRouter.adminServer,
      ),
      const _AdminNavItem(
        label: 'Diseases',
        icon: Icons.coronavirus_outlined,
        route: AppRouter.adminIllnesses,
      ),
      const _AdminNavItem(
        label: 'Profile',
        icon: Icons.account_circle_outlined,
        route: AppRouter.adminProfile,
      ),
    ];

    return BottomAppBar(
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      elevation: 8,
      child: SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(items.length, (index) {
            final item = items[index];
            final isActive = index == currentIndex;
            final color = isActive ? AppColors.primary : textSecondary;

            return Expanded(
              child: InkWell(
                onTap: isActive
                    ? null
                    : () => Navigator.pushReplacementNamed(context, item.route),
                borderRadius: BorderRadius.circular(12),
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
  }
}

class _AdminNavItem {
  const _AdminNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });

  final String label;
  final IconData icon;
  final String route;
}
