import 'package:flutter/material.dart';

import '../../share/theme/app_colors.dart';
import '../../share/widgets/app_card.dart';
import '../../share/widgets/theme_toggle.dart';

class AdminUserScreen extends StatelessWidget {
  const AdminUserScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final users = <_UserItem>[
      _UserItem(
        initials: 'JD',
        name: 'John Doe',
        email: 'john.doe@plantguard.ai',
        status: _UserStatus.active,
        role: 'Admin',
        lastLogin: 'Last login: 2h ago',
        primaryAction: _UserAction.lock,
        showRoleDropdown: true,
      ),
      _UserItem(
        initials: 'AS',
        name: 'Alice Smith',
        email: 'alice.s@farms.net',
        status: _UserStatus.locked,
        role: 'Farmer',
        lastLogin: 'Last login: 5d ago',
        primaryAction: _UserAction.unlock,
        showRoleDropdown: true,
      ),
      _UserItem(
        initials: 'RJ',
        name: 'Robert Johnson',
        email: 'r.johnson@tech-ops.io',
        status: _UserStatus.active,
        role: 'Tech',
        lastLogin: 'Last login: 15m ago',
        primaryAction: _UserAction.lock,
        showRoleDropdown: true,
      ),
      _UserItem(
        initials: 'MK',
        name: 'Maria K.',
        email: 'maria.k@farmco.com',
        status: _UserStatus.pending,
        role: 'Farmer',
        lastLogin: 'Invited: 1d ago',
        primaryAction: _UserAction.resendInvite,
        secondaryAction: _UserAction.revoke,
        showRoleDropdown: false,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('User Management', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.person_add_alt_1_outlined),
            tooltip: 'Add user',
          ),
          const ThemeToggle(),
          const SizedBox(width: 8),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 36,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(label: 'All Users', isActive: true),
                        _FilterDivider(isDark: isDark),
                        _FilterChip(label: 'Role: Admin'),
                        _FilterChip(label: 'Role: Tech'),
                        _FilterChip(label: 'Status: Locked'),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                return _UserCard(user: users[index]);
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _UserItem {
  const _UserItem({
    required this.initials,
    required this.name,
    required this.email,
    required this.status,
    required this.role,
    required this.lastLogin,
    required this.primaryAction,
    this.secondaryAction,
    required this.showRoleDropdown,
  });

  final String initials;
  final String name;
  final String email;
  final _UserStatus status;
  final String role;
  final String lastLogin;
  final _UserAction primaryAction;
  final _UserAction? secondaryAction;
  final bool showRoleDropdown;
}

enum _UserStatus { active, locked, pending }

enum _UserAction { lock, unlock, resendInvite, revoke }

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user});

  final _UserItem user;

  Color _statusColor(BuildContext context) {
    switch (user.status) {
      case _UserStatus.active:
        return Colors.green;
      case _UserStatus.locked:
        return Colors.redAccent;
      case _UserStatus.pending:
        return Theme.of(context).textTheme.bodySmall?.color ?? Colors.grey;
    }
  }

  String _statusLabel() {
    switch (user.status) {
      case _UserStatus.active:
        return 'Active';
      case _UserStatus.locked:
        return 'Locked';
      case _UserStatus.pending:
        return 'Pending';
    }
  }

  String _actionLabel(_UserAction action) {
    switch (action) {
      case _UserAction.lock:
        return 'Lock Account';
      case _UserAction.unlock:
        return 'Unlock';
      case _UserAction.resendInvite:
        return 'Resend Invite';
      case _UserAction.revoke:
        return 'Revoke';
    }
  }

  IconData _actionIcon(_UserAction action) {
    switch (action) {
      case _UserAction.lock:
        return Icons.lock_outline;
      case _UserAction.unlock:
        return Icons.lock_open_outlined;
      case _UserAction.resendInvite:
        return Icons.mail_outline;
      case _UserAction.revoke:
        return Icons.delete_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final statusColor = _statusColor(context);
    final statusBackground = statusColor.withOpacity(isDark ? 0.2 : 0.12);
    final isPrimaryAction = user.primaryAction == _UserAction.unlock;

    return Opacity(
      opacity: user.status == _UserStatus.pending ? 0.6 : 1,
      child: AppCard(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.surfaceDark
                        : AppColors.lightBackground,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    user.initials,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(user.email, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: statusBackground,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _statusLabel(),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: theme.dividerColor.withOpacity(0.2)),
                ),
              ),
              padding: const EdgeInsets.only(top: 12),
              child: Row(
                children: [
                  _MetaInfo(
                    icon: Icons.badge_outlined,
                    label: user.role,
                    emphasize: true,
                  ),
                  const SizedBox(width: 16),
                  _MetaInfo(icon: Icons.schedule, label: user.lastLogin),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: isPrimaryAction
                      ? ElevatedButton.icon(
                          onPressed: () {},
                          icon: Icon(_actionIcon(user.primaryAction), size: 16),
                          label: Text(_actionLabel(user.primaryAction)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: isDark
                                ? AppColors.darkBackground
                                : Colors.white,
                            textStyle: theme.textTheme.labelLarge,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(_actionIcon(user.primaryAction), size: 16),
                          label: Text(_actionLabel(user.primaryAction)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textTheme.bodyMedium?.color,
                            side: BorderSide(
                              color: theme.dividerColor.withOpacity(0.4),
                            ),
                            textStyle: theme.textTheme.labelLarge,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: user.showRoleDropdown
                      ? DropdownButtonFormField<String>(
                          value: 'Change Role',
                          items: const [
                            DropdownMenuItem(
                              value: 'Change Role',
                              child: Text('Change Role'),
                            ),
                            DropdownMenuItem(
                              value: 'Admin',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'Tech',
                              child: Text('Tech'),
                            ),
                            DropdownMenuItem(
                              value: 'Farmer',
                              child: Text('Farmer'),
                            ),
                          ],
                          onChanged: (_) {},
                          decoration: InputDecoration(
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: BorderSide(
                                color: theme.dividerColor.withOpacity(0.4),
                              ),
                            ),
                          ),
                        )
                      : OutlinedButton.icon(
                          onPressed: () {},
                          icon: Icon(
                            _actionIcon(
                              user.secondaryAction ?? _UserAction.revoke,
                            ),
                            size: 16,
                          ),
                          label: Text(
                            _actionLabel(
                              user.secondaryAction ?? _UserAction.revoke,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: theme.textTheme.bodyMedium?.color,
                            side: BorderSide(
                              color: theme.dividerColor.withOpacity(0.4),
                            ),
                            textStyle: theme.textTheme.labelLarge,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaInfo extends StatelessWidget {
  const _MetaInfo({
    required this.icon,
    required this.label,
    this.emphasize = false,
  });

  final IconData icon;
  final String label;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final baseStyle = theme.textTheme.bodySmall;

    return Row(
      children: [
        Icon(icon, size: 16, color: baseStyle?.color),
        const SizedBox(width: 6),
        Text(
          label,
          style: emphasize
              ? baseStyle?.copyWith(fontWeight: FontWeight.w600)
              : baseStyle,
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label, this.isActive = false});

  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final background = isActive
        ? (isDark ? AppColors.surfaceLight : AppColors.primary)
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final foreground = isActive
        ? (isDark ? AppColors.darkBackground : Colors.white)
        : theme.textTheme.bodySmall?.color;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isActive
              ? Colors.transparent
              : theme.dividerColor.withOpacity(0.4),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _FilterDivider extends StatelessWidget {
  const _FilterDivider({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 20,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isDark ? AppColors.borderDark : AppColors.borderLight,
    );
  }
}
