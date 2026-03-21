import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../../routes/app_router.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/app_card.dart';
import '../../share/widgets/admin_bottom_nav.dart';
import '../../share/widgets/theme_toggle.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchAdminData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final appBarBackground = isDark
        ? Colors.transparent
        : AppColors.surfaceLight;
    final appBarShadow = isDark ? Colors.transparent : Colors.black12;

    final provider = context.watch<DashboardProvider>();
    final statsData = provider.adminStats;
    final adminLogs = provider.adminLogs;

    final stats = <_AdminStatItem>[
      _AdminStatItem(
        title: 'Total users',
        value: statsData?.totalUsers.toString() ?? '...',
        note: '${statsData?.activeUsers ?? 0} active',
        icon: Icons.groups_outlined,
        statusColor: AppColors.primary,
        onTap: () => Navigator.pushNamed(context, AppRouter.adminUsers),
      ),
      _AdminStatItem(
        title: 'Scans',
        value: statsData?.totalPredictions.toString() ?? '...',
        note: '+${statsData?.todayPredictions ?? 0} today',
        icon: Icons.camera_alt_outlined,
        statusColor: AppColors.primary,
      ),
      _AdminStatItem(
        title: 'Model',
        value: statsData?.totalModels.toString() ?? '...',
        note: '${statsData?.activeModels ?? 0} active',
        icon: Icons.verified_outlined,
        statusColor: AppColors.primary,
      ),
      _AdminStatItem(
        title: 'Alerts',
        value: '0',
        note: 'System stable',
        icon: Icons.warning_amber_rounded,
        statusColor: theme.colorScheme.error,
      ),
    ];

    final activities = adminLogs.map((log) {
      return _RecentActivityItem(
        title: log.action,
        subtitle: '${log.username ?? 'System'} • ${_formatTime(log.createdAt)}',
        badge: log.entityName,
        badgeColor: _getBadgeColor(log.action, theme),
        icon: _getIconForAction(log.action),
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarBackground,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 1,
        shadowColor: appBarShadow,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Argivision',
              style: theme.textTheme.titleLarge?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Text(
              'Admin Control Panel',
              style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
            ),
          ],
        ),
        actions: [const ThemeToggle(), const SizedBox(width: 8)],
      ),
      body: SafeArea(
        child: provider.isLoading && statsData == null
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: provider.fetchAdminData,
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
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
                                      'Recent activity',
                                      style: theme.textTheme.titleMedium,
                                    ),
                                    TextButton(
                                      onPressed: () {},
                                      child: const Text('See all'),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                if (activities.isEmpty && !provider.isLoading)
                                  const Center(
                                    child: Padding(
                                      padding: EdgeInsets.symmetric(vertical: 20),
                                      child: Text('No activity yet.'),
                                    ),
                                  )
                                else
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
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  Color _getBadgeColor(String action, ThemeData theme) {
    if (action.contains('Login')) return AppColors.primary;
    if (action.contains('Create')) return Colors.green;
    if (action.contains('Delete')) return theme.colorScheme.error;
    return AppColors.warning;
  }

  IconData _getIconForAction(String action) {
    if (action.contains('Login')) return Icons.login;
    if (action.contains('Prediction')) return Icons.eco_outlined;
    if (action.contains('User')) return Icons.person_outline;
    return Icons.history_edu;
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
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

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
                    color: textSecondary,
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
          Text(
            item.value,
            style: theme.textTheme.displaySmall?.copyWith(
              color: textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
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
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

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
                    color: textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  item.subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: textSecondary,
                  ),
                ),
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
