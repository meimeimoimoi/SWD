import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../routes/app_router.dart';
import '../../share/constants/app_brand.dart';
import '../../share/services/dashboard_service.dart';
import '../../share/services/storage_service.dart';
import '../../share/theme/app_colors.dart';
import '../../share/widgets/user_bottom_nav_bar.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

const Color _kBg = Color(0xFFF6F8F6);

enum _AdminFilter { all, system, model, illness, user, feedback }

enum _UserFilter { all, info, warning, error }

enum _UiVisualKind { success, alert, neutral, feedback, darkInfo }

class _UiNotification {
  const _UiNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    required this.isRead,
    required this.visualKind,
    required this.adminCategory,
    required this.userTypeKey,
  });

  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final _UiVisualKind visualKind;
  final String adminCategory;
  final String userTypeKey;

  _UiNotification copyWith({bool? isRead}) => _UiNotification(
        id: id,
        title: title,
        message: message,
        createdAt: createdAt,
        isRead: isRead ?? this.isRead,
        visualKind: visualKind,
        adminCategory: adminCategory,
        userTypeKey: userTypeKey,
      );
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final DashboardService _api = DashboardService();

  bool _loading = true;
  bool _isAdmin = false;
  List<_UiNotification> _items = [];

  _AdminFilter _adminFilter = _AdminFilter.all;
  _UserFilter _userFilter = _UserFilter.all;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
    });
    final role = (await StorageService.getRole())?.toLowerCase().trim() ?? '';
    final isAdmin = role == 'admin' || role == 'technician';

    List<_UiNotification> next;
    if (isAdmin) {
      final logs = await _api.getAdminActivityLogs(count: 80);
      next = logs.map(_fromActivity).toList();
    } else {
      final raw = await _api.getUserNotifications();
      next = raw.map(_fromUserNotification).toList();
    }

    if (!mounted) return;
    setState(() {
      _isAdmin = isAdmin;
      _items = next;
      _loading = false;
    });
  }

  String _adminTag(_AdminFilter f) {
    switch (f) {
      case _AdminFilter.all:
        return 'all';
      case _AdminFilter.system:
        return 'system';
      case _AdminFilter.model:
        return 'model';
      case _AdminFilter.illness:
        return 'illness';
      case _AdminFilter.user:
        return 'user';
      case _AdminFilter.feedback:
        return 'feedback';
    }
  }

  String _userTag(_UserFilter f) {
    switch (f) {
      case _UserFilter.all:
        return 'all';
      case _UserFilter.info:
        return 'info';
      case _UserFilter.warning:
        return 'warning';
      case _UserFilter.error:
        return 'error';
    }
  }

  List<_UiNotification> get _visible {
    if (_isAdmin) {
      final tag = _adminTag(_adminFilter);
      if (tag == 'all') return _items;
      return _items.where((e) => e.adminCategory == tag).toList();
    }
    final tag = _userTag(_userFilter);
    if (tag == 'all') return _items;
    return _items.where((e) => e.userTypeKey == tag).toList();
  }

  int get _unreadCount => _items.where((e) => !e.isRead).length;

  void _markAllRead() {
    if (!_isAdmin) {
      setState(() {
        _items = _items.map((e) => e.copyWith(isRead: true)).toList();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Marked as read (on this device).'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Activity logs have no read state — not applied for now.',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _GuideHeader(
          isAdmin: _isAdmin,
          unreadCount: _unreadCount,
          onBack: () => Navigator.of(context).pop(),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isAdmin
                          ? 'CONTROL CENTER'
                          : 'YOUR UPDATES',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                        color: AppColors.brandAccent,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Recent notifications',
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppColors.textPrimaryDark
                            : const Color(0xFF181D17),
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _items.isEmpty ? null : _markAllRead,
                child: Text(
                  'Mark all read',
                  style: GoogleFonts.spaceGrotesk(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.brandAccent,
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: _isAdmin ? _buildAdminFilters(isDark) : _buildUserFilters(isDark),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppColors.brandAccent))
              : RefreshIndicator(
                  color: AppColors.brandAccent,
                  onRefresh: _load,
                  child: _visible.isEmpty
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.only(top: 80),
                          children: [
                            _EmptyState(isAdmin: _isAdmin),
                          ],
                        )
                      : ListView.builder(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                          itemCount: _visible.length +
                              (_isAdmin && _visible.isNotEmpty ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (_isAdmin &&
                                _visible.isNotEmpty &&
                                index == _visible.length) {
                              return const Padding(
                                padding: EdgeInsets.only(top: 12),
                                child: _AdminOptimizationBanner(),
                              );
                            }
                            final item = _visible[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _NotificationCard(
                                item: item,
                                timeLabel: _relativeTime(item.createdAt),
                                isDark: isDark,
                              ),
                            );
                          },
                        ),
                ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : _kBg,
      body: SafeArea(child: body),
      bottomNavigationBar:
          _isAdmin ? null : const UserBottomNavBar(selectedIndexOverride: 0),
    );
  }

  Widget _buildAdminFilters(bool isDark) {
    const options = <(_AdminFilter, String)>[
      (_AdminFilter.all, 'All'),
      (_AdminFilter.system, 'System'),
      (_AdminFilter.model, 'AI models'),
      (_AdminFilter.illness, 'Diseases & DB'),
      (_AdminFilter.user, 'Accounts'),
      (_AdminFilter.feedback, 'Feedback'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((e) {
          final sel = _adminFilter == e.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: FilterChip(
              label: Text(e.$2, style: GoogleFonts.spaceGrotesk(fontSize: 12)),
              selected: sel,
              onSelected: (_) => setState(() => _adminFilter = e.$1),
              selectedColor: AppColors.brandAccent.withValues(alpha: 0.18),
              checkmarkColor: AppColors.brandAccent,
              labelStyle: TextStyle(
                color: sel
                    ? AppColors.brandAccent
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildUserFilters(bool isDark) {
    const options = <(_UserFilter, String)>[
      (_UserFilter.all, 'All'),
      (_UserFilter.info, 'Info'),
      (_UserFilter.warning, 'Warning'),
      (_UserFilter.error, 'Error'),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((e) {
          final sel = _userFilter == e.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8, bottom: 4),
            child: FilterChip(
              label: Text(e.$2, style: GoogleFonts.spaceGrotesk(fontSize: 12)),
              selected: sel,
              onSelected: (_) => setState(() => _userFilter = e.$1),
              selectedColor: AppColors.brandAccent.withValues(alpha: 0.18),
              checkmarkColor: AppColors.brandAccent,
              labelStyle: TextStyle(
                color: sel
                    ? AppColors.brandAccent
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.isAdmin});

  final bool isAdmin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Text(
          isAdmin
              ? 'Nothing in this filter.'
              : 'No notifications in this filter.',
          textAlign: TextAlign.center,
          style: GoogleFonts.spaceGrotesk(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
  }
}

class _GuideHeader extends StatelessWidget {
  const _GuideHeader({
    required this.isAdmin,
    required this.unreadCount,
    required this.onBack,
  });

  final bool isAdmin;
  final int unreadCount;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.black.withValues(alpha: 0.2)
            : AppColors.scrimLight(0.92),
        border: Border(
          bottom: BorderSide(color: AppColors.brandAccent.withValues(alpha: 0.08)),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
            color: isDark ? Colors.white70 : Colors.black54,
          ),
          const Icon(Icons.eco, color: AppColors.brandAccent, size: 26),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              AppBrand.homeHeader,
              style: GoogleFonts.spaceGrotesk(
                fontWeight: FontWeight.w700,
                fontSize: 17,
                color: AppColors.brandAccent,
              ),
            ),
          ),
          IconButton(
            onPressed: () {},
            icon: Icon(Icons.search, color: Colors.grey.shade600),
          ),
          IconButton(
            onPressed: () {},
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(Icons.notifications_outlined, color: Colors.grey.shade600),
                if (!isAdmin && unreadCount > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFFBA1A1A),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.item,
    required this.timeLabel,
    required this.isDark,
  });

  final _UiNotification item;
  final String timeLabel;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final scheme = _cardScheme(item.visualKind, isDark);
    return Material(
      color: scheme.bg,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {},
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: scheme.iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(scheme.icon, color: scheme.iconFg, size: 26),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: GoogleFonts.spaceGrotesk(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                              color: scheme.titleColor,
                            ),
                          ),
                        ),
                        if (!item.isRead)
                          Padding(
                            padding: const EdgeInsets.only(left: 6, top: 4),
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: AppColors.brandAccent,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeLabel,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 11,
                        color: scheme.muted,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.message,
                      style: GoogleFonts.spaceGrotesk(
                        fontSize: 13,
                        height: 1.35,
                        color: scheme.bodyColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CardScheme {
  const _CardScheme({
    required this.bg,
    required this.iconBg,
    required this.iconFg,
    required this.icon,
    required this.titleColor,
    required this.bodyColor,
    required this.muted,
  });

  final Color bg;
  final Color iconBg;
  final Color iconFg;
  final IconData icon;
  final Color titleColor;
  final Color bodyColor;
  final Color muted;
}

_CardScheme _cardScheme(_UiVisualKind kind, bool isDark) {
  Color bg;
  Color iconBg;
  Color iconFg;
  IconData icon;
  switch (kind) {
    case _UiVisualKind.success:
      bg = isDark ? const Color(0xFF1A2E1C) : const Color(0xFFE8F5E9);
      iconBg = isDark ? const Color(0xFF2D4A32) : const Color(0xFFC9ECC1);
      iconFg = AppColors.brandAccent;
      icon = Icons.model_training_outlined;
      break;
    case _UiVisualKind.alert:
      bg = isDark ? const Color(0xFF2E1A1A) : const Color(0xFFFFEBEE);
      iconBg = isDark ? const Color(0xFF4A2D2D) : const Color(0xFFFFCDD2);
      iconFg = const Color(0xFFBA1A1A);
      icon = Icons.warning_amber_rounded;
      break;
    case _UiVisualKind.neutral:
      bg = isDark ? const Color(0xFF1E2320) : const Color(0xFFF1F5EB);
      iconBg = isDark ? const Color(0xFF2A322E) : const Color(0xFFE0E4DA);
      iconFg = isDark ? Colors.white70 : const Color(0xFF486644);
      icon = Icons.dns_outlined;
      break;
    case _UiVisualKind.feedback:
      bg = isDark ? const Color(0xFF2A1A22) : const Color(0xFFFFE8ED);
      iconBg = isDark ? const Color(0xFF4A2D3A) : const Color(0xFFFFD9E2);
      iconFg = const Color(0xFF903155);
      icon = Icons.feedback_outlined;
      break;
    case _UiVisualKind.darkInfo:
      bg = isDark ? const Color(0xFF1A1E1C) : const Color(0xFFE8EAE8);
      iconBg = isDark ? const Color(0xFF2D322B) : const Color(0xFFD7DBD2);
      iconFg = isDark ? Colors.white70 : const Color(0xFF2D322B);
      icon = Icons.coronavirus_outlined;
      break;
  }
  final titleColor =
      isDark ? AppColors.textPrimaryDark : const Color(0xFF181D17);
  final bodyColor = isDark ? Colors.white70 : const Color(0xFF40493D);
  final muted = isDark ? Colors.white54 : Colors.grey.shade600;
  return _CardScheme(
    bg: bg,
    iconBg: iconBg,
    iconFg: iconFg,
    icon: icon,
    titleColor: titleColor,
    bodyColor: bodyColor,
    muted: muted,
  );
}

class _AdminOptimizationBanner extends StatelessWidget {
  const _AdminOptimizationBanner();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2E1C) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.brandAccent.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.brandAccent.withValues(alpha: 0.9)),
              const SizedBox(width: 8),
              Text(
                'System optimization',
                style: GoogleFonts.spaceGrotesk(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: isDark
                      ? AppColors.textPrimaryDark
                      : const Color(0xFF181D17),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Track model versions and disease data to maintain accuracy.',
            style: GoogleFonts.spaceGrotesk(
              fontSize: 13,
              height: 1.35,
              color: isDark ? Colors.white70 : const Color(0xFF40493D),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.adminModels);
              },
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.brandAccent,
                foregroundColor: AppColors.onPrimary,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: Text(
                'Update now',
                style: GoogleFonts.spaceGrotesk(fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _relativeTime(DateTime t) {
  final now = DateTime.now();
  final d = now.difference(t);
  if (d.inSeconds < 60) return 'Just now';
  if (d.inMinutes < 60) return '${d.inMinutes} min ago';
  if (d.inHours < 24) return '${d.inHours} h ago';
  if (d.inDays == 1) return 'Yesterday';
  if (d.inDays < 7) return '${d.inDays} days ago';
  return DateFormat('dd/MM/yyyy').format(t);
}

String _adminCategoryFromText(String blob) {
  final s = blob.toLowerCase();
  if (s.contains('feedback') ||
      s.contains('rating') ||
      s.contains('đánh giá') ||
      s.contains('góp ý')) {
    return 'feedback';
  }
  if (s.contains('illness') ||
      s.contains('disease') ||
      s.contains('bệnh') ||
      s.contains('symptom') ||
      s.contains('triệu chứng')) {
    return 'illness';
  }
  if (s.contains('model') ||
      s.contains('prediction') ||
      s.contains('onnx') ||
      s.contains('upload') ||
      s.contains('activate') ||
      s.contains('mô hình')) {
    return 'model';
  }
  if (s.contains('user') ||
      s.contains('login') ||
      s.contains('register') ||
      s.contains('account') ||
      s.contains('tài khoản')) {
    return 'user';
  }
  return 'system';
}

_UiVisualKind _adminVisualForCategory(String cat, String blob) {
  final l = blob.toLowerCase();
  switch (cat) {
    case 'feedback':
      return _UiVisualKind.feedback;
    case 'illness':
      return _UiVisualKind.darkInfo;
    case 'model':
      return _UiVisualKind.success;
    case 'user':
      return _UiVisualKind.neutral;
    case 'system':
      if (l.contains('fail') ||
          l.contains('error') ||
          l.contains('high') ||
          l.contains('cpu') ||
          l.contains('alert')) {
        return _UiVisualKind.alert;
      }
      return _UiVisualKind.neutral;
    default:
      return _UiVisualKind.neutral;
  }
}

_UiNotification _fromActivity(ActivityLogItem log) {
  final blob =
      '${log.action} ${log.entityName} ${log.description ?? ''} ${log.username ?? ''}';
  final cat = _adminCategoryFromText(blob);
  final title = log.entityName.trim().isNotEmpty
      ? log.entityName
      : log.action;
  final message = (log.description != null && log.description!.trim().isNotEmpty)
      ? log.description!
      : '${log.action} · ${log.entityName}';
  final visual = _adminVisualForCategory(cat, blob);
  return _UiNotification(
    id: 'a-${log.activityLogId}',
    title: title,
    message: message,
    createdAt: log.createdAt,
    isRead: true,
    visualKind: visual,
    adminCategory: cat,
    userTypeKey: 'info',
  );
}

_UiNotification _fromUserNotification(NotificationItem n) {
  final t = (n.type ?? 'Info').toLowerCase();
  String userKey;
  if (t.contains('warn')) {
    userKey = 'warning';
  } else if (t.contains('error') || t.contains('fail')) {
    userKey = 'error';
  } else {
    userKey = 'info';
  }

  _UiVisualKind visual;
  if (userKey == 'warning' || userKey == 'error') {
    visual = _UiVisualKind.alert;
  } else {
    visual = _UiVisualKind.success;
  }

  return _UiNotification(
    id: 'u-${n.notificationId}',
    title: n.title,
    message: n.message,
    createdAt: n.createdAt,
    isRead: n.isRead,
    visualKind: visual,
    adminCategory: 'system',
    userTypeKey: userKey,
  );
}
