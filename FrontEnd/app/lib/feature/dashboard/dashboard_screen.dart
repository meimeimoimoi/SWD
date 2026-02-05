import 'package:flutter/material.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/app_button.dart';
import '../../share/widgets/app_card.dart';
import '../../share/widgets/app_scaffold.dart';
import '../../routes/app_router.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final stats = <_StatItem>[
      _StatItem(title: 'Trees monitored', value: '128', chip: '+12 today'),
      _StatItem(title: 'Active alerts', value: '5', chip: '2 critical'),
      _StatItem(title: 'Model accuracy', value: '94%', chip: 'Updated'),
      _StatItem(title: 'Recent scans', value: '18', chip: 'Last 24h'),
    ];

    final alerts = <_AlertItem>[
      _AlertItem(tree: 'Oak #24', status: 'Leaf blight', severity: 'High'),
      _AlertItem(tree: 'Pine #7', status: 'Drought stress', severity: 'Medium'),
      _AlertItem(tree: 'Maple #15', status: 'Healthy', severity: 'Low'),
    ];

    return AppScaffold(
      centerContent: false,
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
                              _ActivityRow(
                                title: 'Model retrained',
                                time: '2h ago',
                              ),
                              _ActivityRow(
                                title: 'Scan uploaded - Maple #12',
                                time: '4h ago',
                              ),
                              _ActivityRow(
                                title: 'Alert resolved - Oak #3',
                                time: '5h ago',
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
                          _ActivityRow(
                            title: 'Model retrained',
                            time: '2h ago',
                          ),
                          _ActivityRow(
                            title: 'Scan uploaded - Maple #12',
                            time: '4h ago',
                          ),
                          _ActivityRow(
                            title: 'Alert resolved - Oak #3',
                            time: '5h ago',
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
