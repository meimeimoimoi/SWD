import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/dashboard_provider.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/app_button.dart';
import '../../share/widgets/app_card.dart';
import '../../share/widgets/app_scaffold.dart';
import '../../routes/app_router.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchUserData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final notifications = provider.userNotifications;
    final activitiesData = provider.userActivities;

    final stats = <_StatItem>[
      _StatItem(
        title: 'Cảnh báo',
        value: notifications.where((n) => !n.isRead).length.toString(),
        chip: '${notifications.length} tổng cộng',
      ),
      _StatItem(
        title: 'Hoạt động',
        value: activitiesData.length.toString(),
        chip: 'Gần đây',
      ),
      const _StatItem(title: 'Độ chính xác', value: '94%', chip: 'Ổn định'),
      const _StatItem(title: 'Lịch sử', value: '-', chip: 'Xem lịch sử'),
    ];

    final alerts = notifications.take(3).map((n) {
      return _AlertItem(
        tree: n.title,
        status: n.message,
        severity: n.type ?? 'Low',
      );
    }).toList();

    return AppScaffold(
      centerContent: false,
      showUserBottomNav: true,
      title: 'Dashboard',
      actions: [
        AppButton(
          label: 'New scan',
          icon: Icons.add_a_photo_outlined,
          expand: false,
          onPressed: () => Navigator.pushNamed(context, AppRouter.scan),
        ),
      ],
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Overview', style: Theme.of(context).textTheme.displayMedium),
            const SizedBox(height: 8),
            Text(
              'Real-time insight into tree health, alerts, and recent activity.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                AppButton(
                  label: 'New scan',
                  icon: Icons.add_a_photo_outlined,
                  expand: false,
                  onPressed: () => Navigator.pushNamed(context, AppRouter.scan),
                ),

                AppButton(
                  label: 'View profile',
                  variant: AppButtonVariant.ghost,
                  expand: false,
                  onPressed: () =>
                      Navigator.pushNamed(context, AppRouter.profile),
                ),
              ],
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                final itemWidth = isWide
                    ? (constraints.maxWidth - 48) / 2
                    : constraints.maxWidth;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: stats
                      .map(
                        (item) => SizedBox(
                          width: itemWidth,
                          child: _StatCard(item: item),
                        ),
                      )
                      .toList(),
                );
              },
            ),
            const SizedBox(height: 24),
            LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth > 900;
                if (isWide) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(title: 'Recent alerts'),
                              const SizedBox(height: 12),
                              ...alerts.map(
                                (alert) => _AlertTile(alert: alert),
                              ),
                              const SizedBox(height: 12),
                              AppButton(
                                label: 'View all alerts',
                                variant: AppButtonVariant.outlined,
                                onPressed: () {},
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SectionHeader(title: 'Latest activity'),
                              const SizedBox(height: 12),
                              if (activitiesData.isEmpty && !provider.isLoading)
                                const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 20),
                                  child: Text('Chưa có hoạt động nào.'),
                                )
                              else
                                ...activitiesData.take(5).map(
                                      (a) => _ActivityRow(
                                        title: '${a.action} - ${a.entityName}',
                                        time: _formatTime(a.createdAt),
                                      ),
                                    ),
                              const SizedBox(height: 16),
                              AppButton(
                                label: 'Go to profile',
                                variant: AppButtonVariant.ghost,
                                onPressed: () => Navigator.pushNamed(
                                  context,
                                  AppRouter.profile,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(title: 'Recent alerts'),
                          const SizedBox(height: 12),
                          ...alerts.map((alert) => _AlertTile(alert: alert)),
                          const SizedBox(height: 12),
                          AppButton(
                            label: 'View all alerts',
                            variant: AppButtonVariant.outlined,
                            onPressed: () {},
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionHeader(title: 'Latest activity'),
                          const SizedBox(height: 12),
                          if (activitiesData.isEmpty && !provider.isLoading)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Text('Chưa có hoạt động nào.'),
                            )
                          else
                            ...activitiesData.take(5).map(
                                  (a) => _ActivityRow(
                                    title: '${a.action} - ${a.entityName}',
                                    time: _formatTime(a.createdAt),
                                  ),
                                ),
                          const SizedBox(height: 16),
                          AppButton(
                            label: 'Go to profile',
                            variant: AppButtonVariant.ghost,
                            onPressed: () =>
                                Navigator.pushNamed(context, AppRouter.profile),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }
}

class _StatItem {
  const _StatItem({
    required this.title,
    required this.value,
    required this.chip,
  });
  final String title;
  final String value;
  final String chip;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});
  final _StatItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(item.title, style: theme.textTheme.bodyLarge),
          const SizedBox(height: 8),
          Text(item.value, style: theme.textTheme.displayMedium),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.accent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              item.chip,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AlertItem {
  const _AlertItem({
    required this.tree,
    required this.status,
    required this.severity,
  });
  final String tree;
  final String status;
  final String severity;
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({required this.alert});
  final _AlertItem alert;

  Color _severityColor() {
    switch (alert.severity.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.amber;
      default:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.dividerColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: _severityColor(),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(alert.tree, style: theme.textTheme.titleMedium),
                Text(alert.status, style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          Text(
            alert.severity,
            style: theme.textTheme.labelLarge?.copyWith(
              color: _severityColor(),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(title, style: Theme.of(context).textTheme.titleLarge)],
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.title, required this.time});
  final String title;
  final String time;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(Icons.check_circle, size: 18, color: theme.colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(child: Text(title, style: theme.textTheme.bodyLarge)),
          Text(time, style: theme.textTheme.bodyMedium),
        ],
      ),
    );
  }
}
