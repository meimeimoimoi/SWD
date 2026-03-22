import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/dashboard_provider.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/admin_app_bar_actions.dart';
import '../../share/widgets/admin_bottom_nav.dart';
import '../../share/widgets/admin_pop_scope.dart';
import '../../share/widgets/app_card.dart';

class AdminUserScreen extends StatefulWidget {
  const AdminUserScreen({super.key});

  @override
  State<AdminUserScreen> createState() => _AdminUserScreenState();
}

class _AdminUserScreenState extends State<AdminUserScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _userSearchController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchAdminData();
    });
  }

  @override
  void dispose() {
    _userSearchController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _showAddAccountDialog() {
    _emailController.clear();
    _passwordController.clear();
    _confirmPasswordController.clear();
    
    showDialog(
      context: context,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Add new account',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
              content: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        keyboardType: TextInputType.emailAddress,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter an email';
                          }
                          if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$')
                              .hasMatch(value)) {
                            return 'Invalid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() => _obscurePassword = !_obscurePassword);
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: _obscurePassword,
                        decoration: const InputDecoration(
                          labelText: 'Confirm password',
                          prefixIcon: Icon(Icons.lock_clock_outlined),
                        ),
                        validator: (value) {
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: theme.colorScheme.secondary),
                  ),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (_formKey.currentState!.validate()) {
                      final provider = context.read<DashboardProvider>();
                      final success = await provider.createUser(
                        _emailController.text,
                        _passwordController.text,
                        'User', // Default role for new accounts
                      );
                      
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success ? 'Account created' : 'Failed to create account'),
                            backgroundColor: success ? Colors.green : Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: isDark ? Colors.black : Colors.white,
                  ),
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
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
    final usersData = provider.adminUsers;

    final users = usersData.map((u) {
      final username = u['username'] ?? 'User';
      final email = u['email'] ?? '';
      final statusStr = u['accountStatus'] ?? 'Active';
      
      // Normalize role for UI consistency and to match dropdown items
      String role = u['role']?.toString() ?? 'User';
      if (role == 'Tech') role = 'Technician';
      final allowedRoles = ['Admin', 'Technician', 'User', 'Farmer', 'Staff'];
      if (!allowedRoles.contains(role)) {
        role = 'User'; // Fallback to avoid dropdown crash
      }
      
      _UserStatus status = _UserStatus.active;
      if (statusStr == 'Locked') status = _UserStatus.locked;
      if (statusStr == 'Pending') status = _UserStatus.pending;
      if (statusStr == 'Deleted') status = _UserStatus.locked; // Treat deleted as locked for UI

      return _UserItem(
        userId: u['userId'] ?? 0,
        initials: username.isNotEmpty ? username[0].toUpperCase() : 'U',
        name: username,
        email: email,
        status: status,
        role: role,
        lastLogin: u['lastLoginAt'] != null 
          ? 'Last login: ${DateTime.parse(u['lastLoginAt'].toString()).day}/${DateTime.parse(u['lastLoginAt'].toString()).month}'
          : 'Never signed in',
        primaryAction: status == _UserStatus.locked ? _UserAction.unlock : _UserAction.lock,
        showRoleDropdown: true,
      );
    }).toList();

    return AdminPopScope(
      child: Scaffold(
        appBar: AppBar(
        backgroundColor: appBarBackground,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 1,
        shadowColor: appBarShadow,
        title: Text(
          'User Management',
          style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
        ),
        actions: adminSecondaryAppBarActions(context),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(120),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: Column(
              children: [
                TextField(
                  controller: _userSearchController,
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Search by name or email...',
                    hintStyle: theme.textTheme.bodySmall?.copyWith(
                      color: textSecondary.withOpacity(0.8),
                    ),
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: isDark
                        ? AppColors.surfaceDark
                        : AppColors.surfaceLight,
                  ),
                  onSubmitted: (_) {
                    context.read<DashboardProvider>().setAdminUsersFilters(
                          search: _userSearchController.text,
                        );
                  },
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
        child: provider.isLoading && users.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: provider.fetchAdminUsers,
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1100),
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 80), 
                    itemCount: users.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      return _UserCard(user: users[index]);
                    },
                  ),
                ),
              ),
            ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showAddAccountDialog,
        backgroundColor: AppColors.primary,
        icon: Icon(
          Icons.person_add_outlined,
          color: isDark ? Colors.black : Colors.white,
        ),
        label: Text(
          'Add account',
          style: TextStyle(
            color: isDark ? Colors.black : Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 0),
      ),
    );
  }
}

class _UserItem {
  const _UserItem({
    required this.userId,
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

  final int userId;
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
        return 'Lock account';
      case _UserAction.unlock:
        return 'Unlock';
      case _UserAction.resendInvite:
        return 'Resend invite';
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
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final statusColor = _statusColor(context);
    final statusBackground = statusColor.withOpacity(isDark ? 0.2 : 0.12);
    final isPrimaryAction = user.primaryAction == _UserAction.unlock;

    final provider = context.read<DashboardProvider>();

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
                      color: textPrimary,
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
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        user.email,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textSecondary,
                        ),
                      ),
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
                  Expanded(
                    child: _MetaInfo(
                      icon: Icons.badge_outlined,
                      label: user.role,
                      emphasize: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _MetaInfo(icon: Icons.schedule, label: user.lastLogin),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: isPrimaryAction
                      ? ElevatedButton.icon(
                          onPressed: () async {
                            final success = await provider.updateUserStatus(user.userId, 'Active');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(success ? 'Account unlocked' : 'Failed to unlock'))
                              );
                            }
                          },
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
                          onPressed: () async {
                            final success = await provider.updateUserStatus(user.userId, 'Locked');
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(success ? 'Account locked' : 'Failed to lock'))
                              );
                            }
                          },
                          icon: Icon(_actionIcon(user.primaryAction), size: 16),
                          label: Text(_actionLabel(user.primaryAction)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
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
                          value: user.role,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: textPrimary,
                          ),
                          items: const [
                            DropdownMenuItem(
                              value: 'Admin',
                              child: Text('Admin'),
                            ),
                            DropdownMenuItem(
                              value: 'Technician',
                              child: Text('Technician'),
                            ),
                            DropdownMenuItem(
                              value: 'User',
                              child: Text('User'),
                            ),
                            DropdownMenuItem(
                              value: 'Farmer',
                              child: Text('Farmer'),
                            ),
                            DropdownMenuItem(
                              value: 'Staff',
                              child: Text('Staff'),
                            ),
                          ],
                          onChanged: (newRole) async {
                            if (newRole != null && newRole != user.role) {
                              final success = await provider.updateUserRole(user.userId, newRole);
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(success ? 'Role updated to $newRole' : 'Failed to update role'))
                                );
                              }
                            }
                          },
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
                            foregroundColor: textPrimary,
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
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final baseStyle = theme.textTheme.bodySmall?.copyWith(color: textSecondary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: baseStyle?.color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: emphasize
                ? baseStyle?.copyWith(fontWeight: FontWeight.w600)
                : baseStyle,
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
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
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final background = isActive
        ? (isDark ? AppColors.surfaceLight : AppColors.primary)
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final foreground = isActive
        ? (isDark ? AppColors.darkBackground : Colors.white)
        : textSecondary;

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
