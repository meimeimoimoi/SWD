import 'package:flutter/material.dart';

import '../../../share/theme/app_colors.dart';
import '../../../share/widgets/app_card.dart';

class AdminSettingScreen extends StatelessWidget {
  const AdminSettingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final configItems = <_ConfigItem>[
      const _ConfigItem(
        title: 'Account',
        subtitle: 'Manage administrator privileges, billing, and profiles.',
        icon: Icons.manage_accounts,
      ),
      const _ConfigItem(
        title: 'AI Model Control',
        subtitle: 'Update recognition algorithms and training data.',
        icon: Icons.psychology,
        isHighlighted: true,
      ),
      const _ConfigItem(
        title: 'System Health Config',
        subtitle: 'Configure diagnostics, maintenance, and reporting.',
        icon: Icons.monitor_heart,
      ),
      const _ConfigItem(
        title: 'Notification Center',
        subtitle: 'Set alert thresholds and escalation protocols.',
        icon: Icons.notifications_active,
      ),
      const _ConfigItem(
        title: 'Security Center',
        subtitle: 'Audit logs, 2FA enforcement, API keys.',
        icon: Icons.admin_panel_settings,
      ),
      const _ConfigItem(
        title: 'Integration Hub',
        subtitle: 'Connect IoT devices and external platforms.',
        icon: Icons.hub,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Settings', style: theme.textTheme.titleLarge),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                _ProfileOverviewCard(isDark: isDark),
                const SizedBox(height: 20),
                Text(
                  'System Configuration',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWide = constraints.maxWidth >= 900;
                    final itemWidth = isWide
                        ? (constraints.maxWidth - 24) / 3
                        : (constraints.maxWidth - 12) / 2;

                    return Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: configItems
                          .map(
                            (item) => SizedBox(
                              width: itemWidth,
                              child: _ConfigCard(item: item),
                            ),
                          )
                          .toList(),
                    );
                  },
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.logout),
                    label: const Text('Sign Out Admin'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.redAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      textStyle: theme.textTheme.labelLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ProfileOverviewCard extends StatelessWidget {
  const _ProfileOverviewCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(48),
                child: Image.network(
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuAxdAbpMppOXmuSewpLjp8i38pENAP0tWHNYHL3fVej1ZzPjE62fHyxfhK-HctKHXGK0kCtBZnThxfxnGZfFJyYZmmKowsVaQ7ZFs_Np2Fffoic0nm2e4fek6QuWhvXBiRFlAgldz2EeleSQNyTZP_cOhJWT-ZUHfSF9gxUNATVH2sOMQeRDqyVjQzYPVsxlCjQJiwjD4bNhliGG--glWjywaObcZAY7R2dD9LGqIZpggq9Gt_H4AXnQFEiUYhT9jN6Akiy53sdTLc',
                  width: 84,
                  height: 84,
                  fit: BoxFit.cover,
                ),
              ),
              Positioned(
                right: 4,
                bottom: 4,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBackground
                          : AppColors.surfaceLight,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('System Administrator', style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(Icons.history, size: 14, color: theme.hintColor),
                    const SizedBox(width: 6),
                    Text(
                      'Last active: 2 minutes ago',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.hintColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    _TagChip(label: 'Superuser', isHighlighted: true),
                    _TagChip(label: 'Global Access'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.edit, size: 18),
            label: const Text('Edit Profile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              textStyle: theme.textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, this.isHighlighted = false});

  final String label;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isHighlighted
        ? AppColors.primary.withOpacity(0.2)
        : (isDark ? Colors.white10 : Colors.black12);
    final foreground = isHighlighted
        ? AppColors.primary
        : theme.textTheme.bodySmall?.color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _ConfigItem {
  const _ConfigItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    this.isHighlighted = false,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final bool isHighlighted;
}

class _ConfigCard extends StatelessWidget {
  const _ConfigCard({required this.item});

  final _ConfigItem item;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white10 : Colors.black12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(item.icon, color: AppColors.primary),
              ),
              Icon(
                Icons.chevron_right,
                color: theme.textTheme.bodySmall?.color?.withOpacity(0.6),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (item.isHighlighted)
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(item.subtitle, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
