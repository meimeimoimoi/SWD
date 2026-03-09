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
        label: 'Tong quan',
        icon: Icons.dashboard,
        route: AppRouter.adminDashboard,
      ),
      const _AdminNavItem(
        label: 'Users',
        icon: Icons.groups_outlined,
        route: AppRouter.adminUsers,
      ),
      const _AdminNavItem(
        label: 'Phan hoi',
        icon: Icons.chat_bubble_outline,
        route: AppRouter.adminFeedback,
      ),
      const _AdminNavItem(
        label: 'Cai dat',
        icon: Icons.settings_outlined,
        route: AppRouter.adminSettings,
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

            return InkWell(
              onTap: isActive
                  ? null
                  : () => Navigator.pushNamed(context, item.route),
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
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: color,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                      ),
                    ),
                  ],
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
