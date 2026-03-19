import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../share/theme/app_colors.dart';
import '../../../share/widgets/app_card.dart';
import '../../../share/widgets/admin_bottom_nav.dart';
import '../../../share/widgets/theme_toggle.dart';
import '../../../providers/dashboard_provider.dart';

class AdminFeedbackListScreen extends StatefulWidget {
  const AdminFeedbackListScreen({super.key});

  @override
  State<AdminFeedbackListScreen> createState() => _AdminFeedbackListScreenState();
}

class _AdminFeedbackListScreenState extends State<AdminFeedbackListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().fetchFeedbackList();
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
    final feedbackList = provider.feedbackList;

    // Calculate dynamic stats from real data
    int totalCount = feedbackList.length;
    double avgRating = 0;
    if (totalCount > 0) {
      double sum = feedbackList.fold(0.0, (prev, curr) => prev + (curr['score'] ?? 0.0).toDouble());
      avgRating = sum / totalCount;
    }

    final stats = <_FeedbackStatItem>[
      _FeedbackStatItem(
        title: 'Total Feedback',
        value: totalCount.toString(),
        delta: '',
        deltaColor: AppColors.primary,
      ),
      _FeedbackStatItem(
        title: 'Average Rating',
        value: avgRating.toStringAsFixed(1),
        delta: '★',
        deltaColor: AppColors.primary,
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarBackground,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 1,
        shadowColor: appBarShadow,
        titleSpacing: 16,
        title: Row(
          children: [
            const SizedBox(width: 8),
            Text(
              'Feedback',
              style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
            ),
          ],
        ),
        actions: [const ThemeToggle(), const SizedBox(width: 8)],
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
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: stats
                        .map(
                          (item) =>
                              SizedBox(width: 180, child: _StatCard(item: item)),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 42,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: const [
                        _FilterPill(label: 'All Reviews', isActive: true),
                        _FilterPill(label: 'Critical (1-2★)'),
                        _FilterPill(label: 'Negative (3★)'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Recent Feedback',
                    style: theme.textTheme.labelLarge?.copyWith(
                      letterSpacing: 1.4,
                      color: textSecondary.withOpacity(0.7),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (provider.isLoading && feedbackList.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.only(top: 40.0),
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (feedbackList.isEmpty)
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 40.0),
                        child: Text(
                          'No feedback records found',
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    )
                  else
                    ...feedbackList.map((data) {
                      final prediction = data['prediction'] ?? {};
                      final upload = prediction['upload'] ?? {};
                      final user = upload['user'] ?? {};
                      final username = user['username'] ?? 'User';
                      final illness = prediction['illness']?['name'] ?? 'Unknown';
                      
                      // Format relative time (naive)
                      String timeAgo = 'Just now';
                      if (data['createdAt'] != null) {
                        try {
                          final date = DateTime.parse(data['createdAt']);
                          final diff = DateTime.now().difference(date);
                          if (diff.inDays > 0) {
                            timeAgo = '${diff.inDays}d ago';
                          } else if (diff.inHours > 0) {
                            timeAgo = '${diff.inHours}h ago';
                          } else if (diff.inMinutes > 0) {
                            timeAgo = '${diff.inMinutes}m ago';
                          }
                        } catch (_) {}
                      }

                      final item = _FeedbackItem(
                        rating: (data['score'] ?? 0).toInt(),
                        score: (data['score'] ?? 0).toString(),
                        userMeta: '$username • $timeAgo',
                        message: data['comment'] ?? 'No comment provided.',
                        imageUrl: upload['imageUrl'] ?? 'https://via.placeholder.com/150',
                        tone: (data['score'] ?? 0) <= 2 
                            ? _FeedbackTone.critical 
                            : ((data['score'] ?? 0) <= 3 ? _FeedbackTone.warning : _FeedbackTone.positive),
                        badge: illness,
                      );
                      
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FeedbackCard(item: item),
                      );
                    }).toList(),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: const AdminBottomNav(currentIndex: 2),
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
  const _FilterPill({required this.label, this.isActive = false});

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
        ? AppColors.primary
        : (isDark ? AppColors.surfaceDark : AppColors.surfaceLight);
    final foreground = isActive
        ? (isDark ? AppColors.darkBackground : Colors.white)
        : textSecondary;

    return Container(
      margin: const EdgeInsets.only(right: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: isActive
              ? Colors.transparent
              : theme.dividerColor.withOpacity(0.3),
        ),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelSmall?.copyWith(
          color: foreground,
          fontWeight: FontWeight.w700,
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
    this.dimmed = false,
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
  final bool dimmed;
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
    final background = toneColor.withOpacity(isDark ? 0.12 : 0.08);
    final borderColor = toneColor.withOpacity(isDark ? 0.35 : 0.25);

    return Opacity(
      opacity: item.dimmed ? 0.8 : 1,
      child: Container(
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
                    color: toneColor.withOpacity(0.18),
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
                  child: Image.network(
                    item.imageUrl,
                    width: 76,
                    height: 76,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 76,
                      height: 76,
                      color: Colors.grey.withOpacity(0.2),
                      child: const Icon(Icons.broken_image, size: 24),
                    ),
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
                        maxLines: 2,
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
                                : Colors.white,
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
                              color: theme.dividerColor.withOpacity(0.4),
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
            color: textSecondary.withOpacity(0.8),
          ),
        ),
      ],
    );
  }
}
