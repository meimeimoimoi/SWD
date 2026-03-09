import 'package:flutter/material.dart';

import '../../../share/theme/app_colors.dart';
import '../../../share/widgets/app_card.dart';
import '../../../share/widgets/admin_bottom_nav.dart';
import '../../../share/widgets/theme_toggle.dart';

class AdminFeedbackListScreen extends StatelessWidget {
  const AdminFeedbackListScreen({super.key});

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

    final stats = <_FeedbackStatItem>[
      const _FeedbackStatItem(
        title: 'Total Feedback',
        value: '1,284',
        delta: '+12%',
        deltaColor: AppColors.primary,
      ),
      const _FeedbackStatItem(
        title: 'Average Rating',
        value: '4.2',
        delta: '+0.3',
        deltaColor: AppColors.primary,
      ),
      _FeedbackStatItem(
        title: 'Pending',
        value: '48',
        delta: 'Urgent',
        deltaColor: Colors.orange,
      ),
    ];

    final feedbackItems = <_FeedbackItem>[
      _FeedbackItem(
        rating: 2,
        score: '2.0',
        userMeta: 'User #8429 • 2h ago',
        message:
            'Diagnosis was incorrect. This is clearly late blight, not nitrogen deficiency.',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAlHB25NHko4K300X3qBLM4N1e8VmgjqckaZqk-L2K3-RmtXLJN7m3Jq_8IkY4GcKzPgTCRkQCLelleOq1N1_YT-H2z6qcETapCOJQuOkMDjrzjN1Dtfa9MiKIgwGq9v1W2bWtxSefqkwEtl6EfmaTt2c1qWpu-_8PvvH3-C3282La8c2ugSoFU5tiHGdHIoRCefRMiGaEhLLCkSRR0tjGIapcztmoewabDmRBB6Ip1l9dHw7WexlD2CRMpR65n0kE8b1J1X0FleIg',
        tone: _FeedbackTone.critical,
        badge: 'Needs Attention',
        primaryAction: 'Review Diagnosis',
        secondaryAction: 'Dismiss',
      ),
      _FeedbackItem(
        rating: 3,
        score: '3.0',
        userMeta: 'User #1102 • 5h ago',
        message:
            'App is a bit slow to load results today. Diagnostic was okay but took 30 seconds.',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCSOHBurhyFjCrYufB4QdiGJbuTg8ifImPgnt7SpLDpDpldRrjjkoVDw7N4HZDWi9XI6e2vCSpfnKhydet4y8kuijnmauUX8ZVX52FKgRy3anfK_8WOwa4u8GOdH-gLBZkjhkfPLHICR8J2vAzHzu99K2ds81_abveuqDNrvPTuwD0q7MYo8WIEPh2DGvkMVXyUmaFVu8Am_gS3c70wi0kGtcy1KFRsEr0efr1Zk10bxV_91K9vfAhxhI9G7SJgGMBKMetOz-gx4l8',
        tone: _FeedbackTone.warning,
      ),
      _FeedbackItem(
        rating: 5,
        score: '5.0',
        userMeta: 'User #9521 • 12h ago',
        message:
            'Saved my orchid! The suggestion for less water was spot on. Highly recommend.',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBCVz4KZX0iJX8yauSYLkwTmrvcSMOmBIw0e7lSbgnOEkbmU4oplvPPKTzgvmXtcukBAjI98vXwVz6RLTXWcXIXNM07tav7RYdlvJSZtZ1eX9CluxKy8NuVvDz3kt8IwwaqnO9VBmImO_Mo7gkii5ltGGIPcUW7wqSZB7KcwygRcG5Y5Zg5L-rgz0QEX2crxmkJ9UEhpFhJSFiFziev8oVackjDArsmpOPHdEYEgs8pZC-gekmW36y6l23gsr4CQkkl2S6_VCN4KT8',
        tone: _FeedbackTone.positive,
        dimmed: true,
      ),
      _FeedbackItem(
        rating: 1,
        score: '1.0',
        userMeta: 'User #3342 • 1d ago',
        message:
            'Payment failed twice but charged me anyway. Please fix immediately.',
        imageUrl:
            'https://lh3.googleusercontent.com/aida-public/AB6AXuCQ_2YaE8MZDOuQ-KgoR8Qgs0aHBBdOX94uo7XqpUs6mGNA-lZaRFUX8mC4sERJRc7U-pE9T5iixmn9RtTeNzW-bvLIfu2Vfp5RRidh1HIRc3i4r-pBI-OP7Vutk4FTfrWJBTE_6sYoQxRhNylM3k_9yDsMUWgFb9ezTF0clz9PTZ9GIIVIw-4IrgoBR_8r8mDrlt0Q_WYL12JgxFinghnGDNCJXuVisd_aM4gmPCJdNZ-2zmTgkv3B1uWEz0WmrDUN_2T9EZ5w_zE',
        tone: _FeedbackTone.critical,
        primaryAction: 'Contact User',
        secondaryAction: 'Refund',
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
                            SizedBox(width: 220, child: _StatCard(item: item)),
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
                ...feedbackItems.map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _FeedbackCard(item: item),
                  ),
                ),
              ],
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
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.message,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
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
