import 'package:flutter/material.dart';

import '../../routes/app_router.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/app_card.dart';
import '../../share/widgets/theme_toggle.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final stats = <_AdminStatItem>[
      _AdminStatItem(
        title: 'Tổng User',
        value: '12.842',
        note: '+12% từ tháng trước',
        icon: Icons.groups_outlined,
        statusColor: AppColors.primary,
        onTap: () => Navigator.pushNamed(context, AppRouter.adminUsers),
      ),
      _AdminStatItem(
        title: 'Số lần Quét',
        value: '84.201',
        note: '+24k tuần này',
        icon: Icons.camera_alt_outlined,
        statusColor: AppColors.primary,
      ),
      _AdminStatItem(
        title: 'Độ chính xác',
        value: '98.4%',
        note: 'Model v4.2 Stable',
        icon: Icons.verified_outlined,
        statusColor: AppColors.primary,
      ),
      _AdminStatItem(
        title: 'Cảnh báo',
        value: '03',
        note: 'Cần xử lý ngay',
        icon: Icons.warning_amber_rounded,
        statusColor: theme.colorScheme.error,
      ),
    ];

    final activities = <_RecentActivityItem>[
      _RecentActivityItem(
        title: 'Đốm lá Cà chua',
        subtitle: 'User ID: #8492 • 2 phút trước',
        badge: 'Phát hiện',
        badgeColor: AppColors.warning,
        icon: Icons.eco_outlined,
      ),
      _RecentActivityItem(
        title: 'Lá khỏe mạnh (Cam)',
        subtitle: 'User ID: #1102 • 15 phút trước',
        badge: 'Bình thường',
        badgeColor: AppColors.primary,
        icon: Icons.check_circle_outline,
      ),
      _RecentActivityItem(
        title: 'Rỉ sắt Cà phê',
        subtitle: 'User ID: #2398 • 40 phút trước',
        badge: 'Cảnh báo',
        badgeColor: theme.colorScheme.error,
        icon: Icons.local_florist_outlined,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'PlantGuard AI',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text('Admin Control Panel', style: theme.textTheme.bodySmall),
          ],
        ),
        actions: [
          const ThemeToggle(),
          const SizedBox(width: 8),
          InkWell(
            onTap: () => Navigator.pushNamed(context, AppRouter.adminUsers),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 36,
              height: 36,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.primary.withOpacity(0.12),
                border: Border.all(color: AppColors.primary),
              ),
              child: const Icon(Icons.person_outline, color: AppColors.primary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    itemCount: stats.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: 1.1,
                        ),
                    itemBuilder: (context, index) {
                      return _StatCard(item: stats[index]);
                    },
                  ),
                  const SizedBox(height: 18),
                  AppCard(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Hoạt động gần đây',
                              style: theme.textTheme.titleMedium,
                            ),
                            TextButton(
                              onPressed: () {},
                              child: const Text('Xem tất cả'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...activities.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ActivityTile(item: item),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: _AdminBottomNavigation(
        isDark: isDark,
        onFeedbackTap: () =>
            Navigator.pushNamed(context, AppRouter.adminFeedback),
        onSettingsTap: () =>
            Navigator.pushNamed(context, AppRouter.adminSettings),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.pushNamed(context, AppRouter.scan),
        backgroundColor: AppColors.primary,
        foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
        child: const Icon(Icons.add),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _AdminStatItem {
  const _AdminStatItem({
    required this.title,
    required this.value,
    required this.note,
    required this.icon,
    required this.statusColor,
    this.onTap,
  });

  final String title;
  final String value;
  final String note;
  final IconData icon;
  final Color statusColor;
  final VoidCallback? onTap;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _AdminStatItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final card = AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.bodySmall?.copyWith(
                    letterSpacing: 0.4,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: item.statusColor.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(item.icon, size: 16, color: item.statusColor),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(item.value, style: theme.textTheme.displaySmall),
          const SizedBox(height: 6),
          Text(
            item.note,
            style: theme.textTheme.bodySmall?.copyWith(
              color: item.statusColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );

    if (item.onTap == null) {
      return card;
    }

    return InkWell(
      onTap: item.onTap,
      borderRadius: BorderRadius.circular(16),
      child: card,
    );
  }
}

class _RecentActivityItem {
  const _RecentActivityItem({
    required this.title,
    required this.subtitle,
    required this.badge,
    required this.badgeColor,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String badge;
  final Color badgeColor;
  final IconData icon;
}

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.item});

  final _RecentActivityItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: item.badgeColor.withOpacity(0.18),
            ),
            child: Icon(item.icon, color: item.badgeColor),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(item.subtitle, style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: item.badgeColor.withOpacity(0.16),
            ),
            child: Text(
              item.badge,
              style: theme.textTheme.labelSmall?.copyWith(
                color: item.badgeColor,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBottomNavigation extends StatelessWidget {
  const _AdminBottomNavigation({
    required this.isDark,
    this.onFeedbackTap,
    this.onSettingsTap,
  });

  final bool isDark;
  final VoidCallback? onFeedbackTap;
  final VoidCallback? onSettingsTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final items = <_BottomNavItem>[
      const _BottomNavItem(label: 'Tổng quan', icon: Icons.dashboard),
      _BottomNavItem(
        label: 'Users',
        icon: Icons.groups_outlined,
        onTap: () => Navigator.pushNamed(context, AppRouter.adminUsers),
      ),
      _BottomNavItem(
        label: 'Phản hồi',
        icon: Icons.chat_bubble_outline,
        onTap: onFeedbackTap,
      ),
      _BottomNavItem(
        label: 'Cài đặt',
        icon: Icons.settings_outlined,
        onTap: onSettingsTap,
      ),
    ];

    return BottomAppBar(
      shape: const CircularNotchedRectangle(),
      notchMargin: 8,
      color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      elevation: 8,
      child: SizedBox(
        height: 72,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _BottomNavAction(item: items[0], isActive: true),
            _BottomNavAction(item: items[1]),
            const SizedBox(width: 34),
            _BottomNavAction(item: items[2]),
            _BottomNavAction(item: items[3]),
          ],
        ),
      ),
    );
  }
}

class _BottomNavItem {
  const _BottomNavItem({required this.label, required this.icon, this.onTap});

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
}

class _BottomNavAction extends StatelessWidget {
  const _BottomNavAction({required this.item, this.isActive = false});

  final _BottomNavItem item;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = isActive
        ? AppColors.primary
        : theme.textTheme.bodySmall?.color;

    return InkWell(
      onTap: item.onTap,
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
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
