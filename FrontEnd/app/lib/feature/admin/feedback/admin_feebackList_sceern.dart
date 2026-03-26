import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../providers/dashboard_provider.dart';
import '../../../providers/theme_mode_provider.dart';
import '../../../share/constants/api_config.dart';
import '../../../share/theme/app_colors.dart';
import '../../../share/widgets/app_card.dart';

class AdminFeedbackListScreen extends StatefulWidget {
  const AdminFeedbackListScreen({super.key});

  @override
  State<AdminFeedbackListScreen> createState() =>
      _AdminFeedbackListScreenState();
}

enum _FeedbackFilter { all, critical, negative }

class _AdminFeedbackListScreenState extends State<AdminFeedbackListScreen> {
  _FeedbackFilter _filter = _FeedbackFilter.all;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchFeedbackList();
    });
  }

  static int _score(Map<String, dynamic> data) {
    final s = data['score'];
    if (s is int) return s;
    if (s is num) return s.round();
    return int.tryParse('$s') ?? 0;
  }

  static String _resolvedImageUrl(Map<String, dynamic> data) {
    final raw = data['imageUrl'] as String?;
    if (raw == null || raw.isEmpty) {
      return '';
    }
    if (raw.startsWith('http://') || raw.startsWith('https://')) {
      return raw;
    }
    final base = Uri.parse(ApiConfig.baseUrl);
    final path = raw.startsWith('/') ? raw : '/$raw';
    return base.resolveUri(Uri.parse(path)).toString();
  }

  static String _timeAgo(dynamic createdAt) {
    if (createdAt == null) return 'Vừa xong';
    try {
      final date = DateTime.parse(createdAt.toString());
      final diff = DateTime.now().difference(date);
      if (diff.inDays > 0) return '${diff.inDays} ngày trước';
      if (diff.inHours > 0) return '${diff.inHours} giờ trước';
      if (diff.inMinutes > 0) return '${diff.inMinutes} phút trước';
    } catch (_) {}
    return 'Vừa xong';
  }

  static (String?, String?) _actionsFor(int score, String comment) {
    final c = comment.toLowerCase();
    if (c.contains('payment') ||
        c.contains('charge') ||
        c.contains('charged') ||
        c.contains('refund') ||
        c.contains('billed') ||
        c.contains('billing')) {
      return ('Liên hệ người dùng', 'Hoàn tiền');
    }
    if (score <= 2 &&
        (c.contains('diagnos') ||
            c.contains('incorrect') ||
            c.contains('wrong') ||
            c.contains('not ') ||
            c.contains('clearly'))) {
      return ('Xem lại chẩn đoán', 'Bỏ qua');
    }
    return (null, null);
  }

  List<Map<String, dynamic>> _filtered(
    List<dynamic> raw,
    _FeedbackFilter f,
  ) {
    final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();
    switch (f) {
      case _FeedbackFilter.all:
        return list;
      case _FeedbackFilter.critical:
        return list.where((m) {
          final s = _score(m);
          return s >= 1 && s <= 2;
        }).toList();
      case _FeedbackFilter.negative:
        return list.where((m) => _score(m) == 3).toList();
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
    final appBarBackground =
        isDark ? Colors.transparent : AppColors.surfaceLight;
    final appBarShadow = isDark ? Colors.transparent : Colors.black12;

    final provider = context.watch<DashboardProvider>();
    final feedbackList = provider.feedbackList;
    final filtered = _filtered(feedbackList, _filter);

    final totalCount = feedbackList.length;
    double avgRating = 0;
    if (totalCount > 0) {
      final sum = feedbackList.fold<double>(
        0,
        (p, curr) => p + _score(Map<String, dynamic>.from(curr as Map)),
      );
      avgRating = sum / totalCount;
    }

    final pending = feedbackList.where((e) {
      final m = Map<String, dynamic>.from(e as Map);
      return _score(m) <= 2;
    }).length;

    double? prevAvg;
    if (totalCount > 1) {
      final mid = totalCount ~/ 2;
      final older = feedbackList.sublist(mid);
      if (older.isNotEmpty) {
        final os = older.fold<double>(
          0,
          (p, curr) => p + _score(Map<String, dynamic>.from(curr as Map)),
        );
        prevAvg = os / older.length;
      }
    }
    final deltaAvg = prevAvg != null ? (avgRating - prevAvg) : null;

    var recent7d = 0;
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    for (final e in feedbackList) {
      final m = Map<String, dynamic>.from(e as Map);
      final ca = m['createdAt'];
      if (ca == null) continue;
      try {
        if (DateTime.parse(ca.toString()).isAfter(weekAgo)) recent7d++;
      } catch (_) {}
    }
    final recentPct = totalCount > 0
        ? ((recent7d / totalCount) * 100).round()
        : 0;

    final nf = NumberFormat.decimalPattern();
    final valueStr = nf.format(totalCount);

    final stats = <_FeedbackStatItem>[
      _FeedbackStatItem(
        title: 'Tổng phản hồi',
        value: valueStr,
        delta: totalCount > 0 ? '$recentPct% trong 7 ngày qua' : '—',
        deltaColor: AppColors.primary,
      ),
      _FeedbackStatItem(
        title: 'Đánh giá trung bình',
        value: avgRating.toStringAsFixed(1),
        delta: deltaAvg != null
            ? '${deltaAvg >= 0 ? '+' : ''}${deltaAvg.toStringAsFixed(1)}'
            : '★',
        deltaColor: AppColors.primary,
      ),
      _FeedbackStatItem(
        title: 'Đang chờ',
        value: pending.toString(),
        delta: pending > 0 ? 'Khẩn cấp' : '—',
        deltaColor: pending > 0 ? Colors.orange.shade800 : AppColors.primary,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarBackground,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 1,
        shadowColor: appBarShadow,
        titleSpacing: 16,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Phản hồi',
          style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
        ),
        actions: [
          Consumer<ThemeModeProvider>(
            builder: (context, tm, _) {
              final light = tm.themeMode == ThemeMode.light;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      light ? Icons.light_mode_outlined : Icons.dark_mode,
                      size: 20,
                      color: textSecondary,
                    ),
                    Switch(
                      value: light,
                      onChanged: (v) {
                        tm.setThemeMode(
                          v ? ThemeMode.light : ThemeMode.dark,
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => provider.fetchFeedbackList(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1100),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                children: [
                  ...stats.map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _StatCard(item: item),
                    ),
                  ),
                  SizedBox(
                    height: 44,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterPill(
                          label: 'Tất cả',
                          isActive: _filter == _FeedbackFilter.all,
                          onTap: () =>
                              setState(() => _filter = _FeedbackFilter.all),
                        ),
                        _FilterPill(
                          label: 'Nghiêm trọng (1-2★)',
                          isActive: _filter == _FeedbackFilter.critical,
                          onTap: () =>
                              setState(() => _filter = _FeedbackFilter.critical),
                        ),
                        _FilterPill(
                          label: 'Tiêu cực (3★)',
                          isActive: _filter == _FeedbackFilter.negative,
                          onTap: () =>
                              setState(() => _filter = _FeedbackFilter.negative),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Phản hồi gần đây',
                    style: theme.textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.4,
                      color: textSecondary.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (provider.isLoading && feedbackList.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (filtered.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40),
                        child: Text(
                          'Không có phản hồi nào trong bộ lọc này',
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    )
                  else
                    ...filtered.map((data) {
                      final score = _score(data);
                      final uid = data['userId'];
                      final userLabel = uid != null
                          ? 'Người dùng #$uid'
                          : (data['userName']?.toString().trim().isNotEmpty ==
                                  true)
                              ? data['userName'].toString()
                              : (data['userEmail']?.toString() ?? 'User');
                      final timeAgo = _timeAgo(data['createdAt']);
                      final userMeta = '$userLabel • $timeAgo';
                      final comment =
                          data['comment']?.toString().trim().isNotEmpty == true
                              ? data['comment'].toString()
                              : 'Không có bình luận.';
                      final imageUrl = _resolvedImageUrl(data);
                      final tone = score <= 2
                          ? _FeedbackTone.critical
                          : (score <= 3
                              ? _FeedbackTone.warning
                              : _FeedbackTone.positive);
                      final badge =
                          score <= 2 ? 'Cần chú ý' : null;
                      final actions = _actionsFor(score, comment);

                      final item = _FeedbackItem(
                        rating: score,
                        score: score.toDouble().toStringAsFixed(1),
                        userMeta: userMeta,
                        message: comment,
                        imageUrl: imageUrl,
                        tone: tone,
                        badge: badge,
                        primaryAction: actions.$1,
                        secondaryAction: actions.$2,
                      );

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FeedbackCard(item: item),
                      );
                    }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FeedbackStatItem {
  const _FeedbackStatItem({
    required this.title,
    required this.value,
    required this.delta,
    required this.deltaColor,
  });

  final String title;
  final String value;
  final String delta;
  final Color deltaColor;
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.item});

  final _FeedbackStatItem item;

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
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item.title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: textSecondary,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Text(
                item.value,
                style: theme.textTheme.displaySmall?.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                item.delta,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: item.deltaColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final background = isActive
        ? AppColors.primary
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final foreground = isActive
        ? (isDark ? AppColors.darkBackground : AppColors.surfaceLight)
        : textSecondary;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Material(
        color: background,
        borderRadius: BorderRadius.circular(999),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(999),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: isActive
                    ? Colors.transparent
                    : theme.dividerColor.withValues(alpha: 0.3),
              ),
            ),
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: foreground,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _FeedbackTone { critical, warning, positive }

class _FeedbackItem {
  const _FeedbackItem({
    required this.rating,
    required this.score,
    required this.userMeta,
    required this.message,
    required this.imageUrl,
    required this.tone,
    this.badge,
    this.primaryAction,
    this.secondaryAction,
  });

  final int rating;
  final String score;
  final String userMeta;
  final String message;
  final String imageUrl;
  final _FeedbackTone tone;
  final String? badge;
  final String? primaryAction;
  final String? secondaryAction;
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.item});

  final _FeedbackItem item;

  Color _toneColor(BuildContext context) {
    switch (item.tone) {
      case _FeedbackTone.critical:
        return Colors.redAccent;
      case _FeedbackTone.warning:
        return Colors.orange;
      case _FeedbackTone.positive:
        return AppColors.primary;
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
    final toneColor = _toneColor(context);
    final background = toneColor.withValues(alpha: isDark ? 0.12 : 0.08);
    final borderColor = toneColor.withValues(alpha: isDark ? 0.35 : 0.25);

    return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (item.badge != null)
              Align(
                alignment: Alignment.topRight,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: toneColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: borderColor),
                  ),
                  child: Text(
                    item.badge!,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: toneColor,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: item.imageUrl.isNotEmpty
                      ? Image.network(
                          item.imageUrl,
                          width: 76,
                          height: 76,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                            width: 76,
                            height: 76,
                            color: Colors.grey.withValues(alpha: 0.2),
                            child: const Icon(Icons.broken_image, size: 24),
                          ),
                        )
                      : Container(
                          width: 76,
                          height: 76,
                          color: Colors.grey.withValues(alpha: 0.2),
                          child: Icon(Icons.image_outlined, color: textSecondary),
                        ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _StarRating(
                        rating: item.rating,
                        score: item.score,
                        toneColor: toneColor,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.userMeta,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 4,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item.primaryAction != null || item.secondaryAction != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    if (item.primaryAction != null)
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {},
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: isDark
                                ? AppColors.darkBackground
                                : AppColors.onPrimary,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: theme.textTheme.labelLarge,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(item.primaryAction!),
                        ),
                      ),
                    if (item.primaryAction != null &&
                        item.secondaryAction != null)
                      const SizedBox(width: 10),
                    if (item.secondaryAction != null)
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {},
                          style: OutlinedButton.styleFrom(
                            foregroundColor: textPrimary,
                            side: BorderSide(
                              color: theme.dividerColor.withValues(alpha: 0.4),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            textStyle: theme.textTheme.labelLarge,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: Text(item.secondaryAction!),
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

class _StarRating extends StatelessWidget {
  const _StarRating({
    required this.rating,
    required this.score,
    required this.toneColor,
  });

  final int rating;
  final String score;
  final Color toneColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final stars = List.generate(5, (index) => index < rating);

    return Row(
      children: [
        ...stars.map(
          (filled) => Icon(
            filled ? Icons.star : Icons.star_border,
            size: 16,
            color: filled ? toneColor : theme.dividerColor,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          score,
          style: theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: textSecondary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}
