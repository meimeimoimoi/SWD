import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/theme_mode_provider.dart';
import '../../routes/app_router.dart';
import '../../share/constants/app_brand.dart';
import '../../share/constants/app_version.dart';
import '../../share/services/auth_api_service.dart';
import '../../share/services/dashboard_service.dart';
import '../../share/services/storage_service.dart';
import '../../share/widgets/admin_bottom_nav.dart';
import '../../share/widgets/user_bottom_nav_bar.dart';

const Color _kPrimary = Color(0xFF2D7B31);
const Color _kBgLight = Color(0xFFF6F8F6);
const Color _kBgDark = Color(0xFF141E15);

class UnifiedAccountScreen extends StatefulWidget {
  const UnifiedAccountScreen({
    super.key,
    required this.isAdminShell,
    this.showLeadingBack = false,
  });

  final bool isAdminShell;

  final bool showLeadingBack;

  @override
  State<UnifiedAccountScreen> createState() => _UnifiedAccountScreenState();
}

class _UnifiedAccountScreenState extends State<UnifiedAccountScreen> {
  bool _loading = true;
  String? _error;
  Map<String, dynamic>? _raw;

  double? _adminAvgConfidence;
  bool _pushEnabled = true;
  bool _emailEnabled = false;

  static const _kPushKey = 'settings_push_enabled';
  static const _kEmailKey = 'settings_email_enabled';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final prefs = await SharedPreferences.getInstance();
    _pushEnabled = prefs.getBool(_kPushKey) ?? true;
    _emailEnabled = prefs.getBool(_kEmailKey) ?? false;

    final response = await AuthApiService.getProfile();
    if (!mounted) return;

    if (response['success'] == true) {
      final data = response['data'];
      setState(() {
        _loading = false;
        _raw = data is Map<String, dynamic> ? data : null;
        _error = null;
      });
    } else {
      setState(() {
        _loading = false;
        _error = response['message']?.toString() ?? 'Could not load profile';
      });
    }

    if (widget.isAdminShell && mounted) {
      final api = DashboardService();
      final acc = await api.getModelAccuracy();
      if (!mounted) return;
      double? avg;
      if (acc.isNotEmpty) {
        var sum = 0.0;
        var n = 0;
        for (final m in acc) {
          final c = m['averageConfidence'] ?? m['AverageConfidence'];
          if (c != null) {
            sum += (c is num) ? c.toDouble() : double.tryParse('$c') ?? 0;
            n++;
          }
        }
        if (n > 0) avg = sum / n;
      }
      setState(() => _adminAvgConfidence = avg);
    }
  }

  Future<void> _persistNotif() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_kPushKey, _pushEnabled);
    await p.setBool(_kEmailKey, _emailEnabled);
  }

  Map<String, dynamic>? _user() {
    final r = _raw;
    if (r == null) return null;
    final nested = r['data'];
    if (nested is Map<String, dynamic>) return nested;
    final u = r['user'];
    if (u is Map<String, dynamic>) return u;
    return r;
  }

  String? _t(Map<String, dynamic>? m, List<String> keys) {
    if (m == null) return null;
    for (final k in keys) {
      final v = m[k]?.toString();
      if (v != null && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Sign out?',
          style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
        ),
        content: Text(
          'You will need to sign in again to continue.',
          style: GoogleFonts.spaceGrotesk(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.spaceGrotesk()),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: _kPrimary),
            child: Text(
              'Sign out',
              style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await AuthApiService.logout();
    if (!mounted) return;
    await StorageService.clearAuth();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRouter.login,
      (route) => false,
    );
  }

  Future<void> _openEditProfile() async {
    final raw = _raw;
    if (raw == null) return;
    final result = await Navigator.pushNamed(
      context,
      AppRouter.updateProfile,
      arguments: raw,
    );
    if (result == true && mounted) await _load();
  }

  void _showAbout() {
    showAboutDialog(
      context: context,
      applicationName: AppBrand.name,
      applicationVersion: AppVersion.semantic,
      applicationIcon: const Icon(Icons.eco, color: _kPrimary, size: 40),
      children: [
        Text(
          AppBrand.heroSubtitle,
          style: GoogleFonts.spaceGrotesk(fontSize: 13, height: 1.35),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? _kBgDark : _kBgLight;
    final u = _user();

    final displayName = _t(u, ['fullName', 'name', 'username']) ?? '—';
    final role = _t(u, ['role']) ?? (widget.isAdminShell ? 'Admin' : 'User');
    final avatar = _t(u, ['avatarUrl', 'avatar', 'profileImagePath']);
    final lastLogin = _t(u, ['lastLoginAt', 'lastLogin', 'LastLoginAt']);
    String lastLoginLabel = '—';
    if (lastLogin != null) {
      final parsed = DateTime.tryParse(lastLogin);
      lastLoginLabel = parsed != null
          ? DateFormat('yyyy-MM-dd HH:mm').format(parsed.toLocal())
          : lastLogin;
    }

    final roleLabel = role.toUpperCase();
    final double? aiPctDisplay;
    final double aiProgress;
    if (widget.isAdminShell) {
      if (_adminAvgConfidence != null) {
        final pct = (_adminAvgConfidence! * 100).clamp(0.0, 100.0);
        aiPctDisplay = pct;
        aiProgress = (pct / 100).clamp(0.0, 1.0);
      } else {
        aiPctDisplay = null;
        aiProgress = 0;
      }
    } else {
      aiPctDisplay = 98.5;
      aiProgress = 0.985;
    }

    final showBack =
        widget.showLeadingBack && Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator(color: _kPrimary))
            : RefreshIndicator(
                color: _kPrimary,
                onRefresh: _load,
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    SliverToBoxAdapter(
                      child: _TopBrandBar(
                        isDark: isDark,
                        onBack: showBack ? () => Navigator.of(context).pop() : null,
                        onMore: (v) {
                          if (v == 'notif') {
                            Navigator.pushNamed(context, AppRouter.notifications);
                          } else if (v == 'feedback') {
                            Navigator.pushNamed(context, AppRouter.adminFeedback);
                          }
                        },
                        showAdminShortcuts: widget.isAdminShell,
                      ),
                    ),
                    SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      sliver: SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'System settings',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : const Color(0xFF181D17),
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Manage your ${AppBrand.name} account and customize your experience.',
                              style: GoogleFonts.spaceGrotesk(
                                fontSize: 13,
                                height: 1.35,
                                color: isDark
                                    ? const Color(0xFF94A3B8)
                                    : const Color(0xFF40493D),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    if (_error != null)
                      SliverPadding(
                        padding: const EdgeInsets.all(24),
                        sliver: SliverToBoxAdapter(
                          child: Text(_error!, textAlign: TextAlign.center),
                        ),
                      )
                    else ...[
                      SliverPadding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        sliver: SliverToBoxAdapter(
                          child: _ProfileHeroCard(
                            displayName: displayName,
                            roleLabel: roleLabel,
                            avatarUrl: avatar,
                            lastLoginLabel: lastLoginLabel,
                            isDark: isDark,
                            onEditProfile: _openEditProfile,
                            onEditAvatar: _openEditProfile,
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _AiStatusCard(
                            isDark: isDark,
                            percent: aiPctDisplay,
                            progress: aiProgress,
                            isAdmin: widget.isAdminShell,
                          ),
                        ),
                      ),
                      if (widget.isAdminShell)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: _SectionCard(
                              title: 'CONTROL CENTER',
                              icon: Icons.dashboard_outlined,
                              isDark: isDark,
                              child: Column(
                                children: [
                                  _QuickLink(
                                    icon: Icons.groups_outlined,
                                    title: 'Users',
                                    subtitle: 'Manage accounts',
                                    isDark: isDark,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AppRouter.adminUsers,
                                    ),
                                  ),
                                  _div(isDark),
                                  _QuickLink(
                                    icon: Icons.psychology_outlined,
                                    title: 'AI models',
                                    subtitle: 'ONNX & accuracy',
                                    isDark: isDark,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AppRouter.adminModels,
                                    ),
                                  ),
                                  _div(isDark),
                                  _QuickLink(
                                    icon: Icons.coronavirus_outlined,
                                    title: 'Diseases',
                                    subtitle: 'Disease library',
                                    isDark: isDark,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      AppRouter.adminIllnesses,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _SectionCard(
                            title: 'ACCOUNT & SECURITY',
                            icon: Icons.lock_person_outlined,
                            isDark: isDark,
                            child: Column(
                              children: [
                                _SecurityRow(
                                  icon: Icons.password_outlined,
                                  title: 'Change password',
                                  subtitle:
                                      'Update your password regularly for security',
                                  isDark: isDark,
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                          'Change password — coming soon',
                                        ),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                                _div(isDark),
                                _SecurityRow(
                                  icon: Icons.verified_user_outlined,
                                  title: 'Two-factor authentication',
                                  subtitle:
                                      'Protect your account with SMS or email codes',
                                  isDark: isDark,
                                  trailing: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFDCFCE7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      'SOON',
                                      style: GoogleFonts.spaceGrotesk(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF166534),
                                      ),
                                    ),
                                  ),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('2FA — coming soon'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _SectionCard(
                            title: 'NOTIFICATIONS',
                            icon: Icons.notifications_active_outlined,
                            isDark: isDark,
                            child: Column(
                              children: [
                                _ToggleRow(
                                  icon: Icons.app_registration_outlined,
                                  title: 'Push notifications',
                                  subtitle: 'Get pest and disease alerts instantly',
                                  value: _pushEnabled,
                                  isDark: isDark,
                                  onChanged: (v) {
                                    setState(() => _pushEnabled = v);
                                    _persistNotif();
                                  },
                                ),
                                _div(isDark),
                                _ToggleRow(
                                  icon: Icons.email_outlined,
                                  title: 'Email digest',
                                  subtitle: 'Periodic summaries from the app',
                                  value: _emailEnabled,
                                  isDark: isDark,
                                  onChanged: (v) {
                                    setState(() => _emailEnabled = v);
                                    _persistNotif();
                                  },
                                ),
                                _div(isDark),
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  leading: Icon(
                                    Icons.notifications_outlined,
                                    color: isDark
                                        ? const Color(0xFF94A3B8)
                                        : const Color(0xFF64748B),
                                  ),
                                  title: Text(
                                    'View all notifications',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    AppRouter.notifications,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: Consumer<ThemeModeProvider>(
                            builder: (context, tm, _) {
                              return _SectionCard(
                                title: 'APP PREFERENCES',
                                icon: Icons.tune_outlined,
                                isDark: isDark,
                                child: Column(
                                  children: [
                                    ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 12),
                                      leading: Icon(
                                        Icons.language_outlined,
                                        color: _kPrimary,
                                      ),
                                      title: Text(
                                        'Language',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      trailing: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _kPrimary.withValues(alpha: 0.12),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          'English',
                                          style: GoogleFonts.spaceGrotesk(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                            color: _kPrimary,
                                          ),
                                        ),
                                      ),
                                      onTap: () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Multiple languages — coming soon'),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                    _div(isDark),
                                    SwitchListTile.adaptive(
                                      contentPadding:
                                          const EdgeInsets.symmetric(horizontal: 12),
                                      secondary: Icon(
                                        isDark
                                            ? Icons.dark_mode_outlined
                                            : Icons.light_mode_outlined,
                                        color: _kPrimary,
                                      ),
                                      title: Text(
                                        'Dark mode',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      subtitle: Text(
                                        'Use dark theme for easier viewing',
                                        style: GoogleFonts.spaceGrotesk(
                                          fontSize: 12,
                                          color: isDark
                                              ? const Color(0xFF94A3B8)
                                              : const Color(0xFF64748B),
                                        ),
                                      ),
                                      value: isDark,
                                      onChanged: (v) {
                                        tm.setThemeMode(
                                          v ? ThemeMode.dark : ThemeMode.light,
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _SectionCard(
                            title: 'ADVANCED APPEARANCE',
                            icon: Icons.palette_outlined,
                            isDark: isDark,
                            child: Consumer<ThemeModeProvider>(
                              builder: (context, tm, _) => Column(
                                children: [
                                  _ThemePick(
                                    title: 'System default',
                                    selected: tm.themeMode == ThemeMode.system,
                                    isDark: isDark,
                                    onTap: () =>
                                        tm.setThemeMode(ThemeMode.system),
                                  ),
                                  _div(isDark),
                                  _ThemePick(
                                    title: 'Light',
                                    selected: tm.themeMode == ThemeMode.light,
                                    isDark: isDark,
                                    onTap: () =>
                                        tm.setThemeMode(ThemeMode.light),
                                  ),
                                  _div(isDark),
                                  _ThemePick(
                                    title: 'Dark',
                                    selected: tm.themeMode == ThemeMode.dark,
                                    isDark: isDark,
                                    onTap: () =>
                                        tm.setThemeMode(ThemeMode.dark),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        sliver: SliverToBoxAdapter(
                          child: _SectionCard(
                            title: 'ABOUT',
                            icon: Icons.info_outline_rounded,
                            isDark: isDark,
                            child: Column(
                              children: [
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  leading: const Icon(Icons.tag_outlined),
                                  title: Text(
                                    'Current version',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: Text(
                                    'v${AppVersion.semantic}',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w700,
                                      color: _kPrimary,
                                    ),
                                  ),
                                ),
                                _div(isDark),
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  leading: const Icon(Icons.open_in_new_outlined),
                                  title: Text(
                                    'Privacy policy',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Link coming soon'),
                                        behavior: SnackBarBehavior.floating,
                                      ),
                                    );
                                  },
                                ),
                                _div(isDark),
                                ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  leading: const Icon(Icons.eco_outlined),
                                  title: Text(
                                    'About ${AppBrand.name}',
                                    style: GoogleFonts.spaceGrotesk(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: _showAbout,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      if (!widget.isAdminShell)
                        SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                          sliver: SliverToBoxAdapter(
                            child: ListTile(
                              leading: const Icon(Icons.feedback_outlined),
                              title: Text(
                                'Send feedback',
                                style: GoogleFonts.spaceGrotesk(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.pushNamed(
                                context,
                                AppRouter.feedback,
                              ),
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 100),
                        sliver: SliverToBoxAdapter(
                          child: OutlinedButton.icon(
                            onPressed: _logout,
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(52),
                              foregroundColor: const Color(0xFFB91C1C),
                              backgroundColor: const Color(0xFFFFF1F2),
                              side: BorderSide(
                                color: Colors.red.shade200.withValues(alpha: 0.8),
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: Text(
                              'Sign out of the app',
                              style: GoogleFonts.spaceGrotesk(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      bottomNavigationBar: widget.isAdminShell
          ? const AdminBottomNav(currentIndex: 4)
          : const UserBottomNavBar(selectedIndexOverride: 3),
    );
  }

  static Widget _div(bool isDark) => Divider(
        height: 1,
        color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EDE3),
      );
}

class _TopBrandBar extends StatelessWidget {
  const _TopBrandBar({
    required this.isDark,
    this.onBack,
    required this.onMore,
    required this.showAdminShortcuts,
  });

  final bool isDark;
  final VoidCallback? onBack;
  final void Function(String) onMore;
  final bool showAdminShortcuts;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
      child: Row(
        children: [
          if (onBack != null) ...[
            IconButton(
              onPressed: onBack,
              icon: Icon(
                Icons.arrow_back_rounded,
                color: isDark ? Colors.white70 : const Color(0xFF0F172A),
              ),
            ),
          ],
          const Icon(Icons.eco, color: _kPrimary, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppBrand.homeHeader,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: _kPrimary,
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert_rounded,
              color: isDark ? Colors.white70 : const Color(0xFF64748B),
            ),
            onSelected: onMore,
            itemBuilder: (ctx) => [
              const PopupMenuItem(
                value: 'notif',
                child: Text('Notifications'),
              ),
              if (showAdminShortcuts)
                const PopupMenuItem(
                  value: 'feedback',
                  child: Text('Admin feedback'),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ProfileHeroCard extends StatelessWidget {
  const _ProfileHeroCard({
    required this.displayName,
    required this.roleLabel,
    required this.avatarUrl,
    required this.lastLoginLabel,
    required this.isDark,
    required this.onEditProfile,
    required this.onEditAvatar,
  });

  final String displayName;
  final String roleLabel;
  final String? avatarUrl;
  final String lastLoginLabel;
  final bool isDark;
  final VoidCallback onEditProfile;
  final VoidCallback onEditAvatar;

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF1E293B) : Colors.white;
    final hasImg = avatarUrl != null && avatarUrl!.startsWith('http');
    final initials = displayName.isNotEmpty
        ? displayName
            .trim()
            .split(' ')
            .where((e) => e.isNotEmpty)
            .take(2)
            .map((e) => e[0].toUpperCase())
            .join()
        : 'U';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E4DA),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _kPrimary.withValues(alpha: 0.2),
                    width: 3,
                  ),
                ),
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: _kPrimary.withValues(alpha: 0.08),
                  backgroundImage:
                      hasImg ? NetworkImage(avatarUrl!) : null,
                  child: !hasImg
                      ? Text(
                          initials,
                          style: GoogleFonts.spaceGrotesk(
                            fontSize: 32,
                            fontWeight: FontWeight.w700,
                            color: _kPrimary,
                          ),
                        )
                      : null,
                ),
              ),
              Positioned(
                right: -2,
                bottom: -2,
                child: Material(
                  color: _kPrimary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: onEditAvatar,
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.edit_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            displayName,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF181D17),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            roleLabel,
            style: GoogleFonts.spaceGrotesk(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.1,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'Last sign-in: $lastLoginLabel',
            style: TextStyle(
              fontSize: 10,
              color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onEditProfile,
              style: FilledButton.styleFrom(
                backgroundColor: _kPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(Icons.badge_outlined, size: 20),
              label: Text(
                'Edit profile',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AiStatusCard extends StatelessWidget {
  const _AiStatusCard({
    required this.isDark,
    required this.percent,
    required this.progress,
    required this.isAdmin,
  });

  final bool isDark;
  final double? percent;
  final double progress;
  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    final pctText = percent != null
        ? '${percent!.toStringAsFixed(1)}%'
        : '—';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2D322B) : const Color(0xFF2D322B),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bolt_rounded, color: const Color(0xFFA4F69C), size: 22),
              const SizedBox(width: 8),
              Text(
                'AI STATUS',
                style: GoogleFonts.spaceGrotesk(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: const Color(0xFFEEF2E8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Model accuracy',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                pctText,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFA4F69C),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.12),
              color: const Color(0xFFA4F69C),
            ),
          ),
          if (!isAdmin) ...[
            const SizedBox(height: 8),
            Text(
              'Estimated from models serving users.',
              style: TextStyle(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.45),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    required this.icon,
    required this.isDark,
    required this.child,
  });

  final String title;
  final IconData icon;
  final bool isDark;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE0E4DA),
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Icon(icon, color: _kPrimary, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white : const Color(0xFF181D17),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, color: isDark ? const Color(0xFF334155) : const Color(0xFFE8EDE3)),
          child,
        ],
      ),
    );
  }
}

class _SecurityRow extends StatelessWidget {
  const _SecurityRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.spaceGrotesk(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.spaceGrotesk(
                      fontSize: 11,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right_rounded,
                  color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                ),
          ],
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.isDark,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final bool isDark;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          Icon(icon, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.spaceGrotesk(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 11,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: value,
            activeColor: _kPrimary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

class _ThemePick extends StatelessWidget {
  const _ThemePick({
    required this.title,
    required this.selected,
    required this.isDark,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            if (selected)
              const Icon(Icons.check_circle, color: _kPrimary, size: 22)
            else
              Icon(
                Icons.circle_outlined,
                color: isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1),
                size: 22,
              ),
          ],
        ),
      ),
    );
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool isDark;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: _kPrimary),
      title: Text(title, style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w600)),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.spaceGrotesk(
          fontSize: 12,
          color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}
