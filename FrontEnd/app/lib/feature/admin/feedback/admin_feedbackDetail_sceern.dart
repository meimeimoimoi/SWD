import 'package:flutter/material.dart';

import '../../../share/theme/app_colors.dart';
import '../../../share/widgets/app_card.dart';
class AdminFeedbackDetailScreen extends StatelessWidget {
  const AdminFeedbackDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    final appBarBackground = isDark
        ? Colors.transparent
        : AppColors.surfaceLight;
    final appBarShadow = isDark ? Colors.transparent : Colors.black12;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: appBarBackground,
        surfaceTintColor: Colors.transparent,
        elevation: isDark ? 0 : 1,
        shadowColor: appBarShadow,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          'Feedback Detail',
          style: theme.textTheme.titleLarge?.copyWith(color: textPrimary),
        ),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.more_vert)),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 860),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _HeroSection(isDark: isDark),
                const SizedBox(height: 12),
                _ScanMetadataCard(isDark: isDark),
                const SizedBox(height: 20),
                _UserCommentCard(isDark: isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.isDark});

  final bool isDark;

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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                'https://lh3.googleusercontent.com/aida-public/AB6AXuDWCK1Uo9-N0Gqsi58gO6PvdFub7ErW2gxVXgTEH_Gk21nZP0k-O2LftAxDuOvPI645LTuN9woZA71PUp2FBEt1SVI1I05yudSG6GbUbaydcZo5ROKuNLBjqSvOIQR9HKuPK3H6Dad30g6325wUP9oJXmXTKCOc0YjcwB5XcVe_MtMxhTISPZOePjSGs4NQF2m168EtXvCGn4DIOqqVtx08wUEzV_KXXMg1AgtHRvp23_piI4smE3aFWA8lcf4Qk5LHBCvFosiY9Mk',
                height: 190,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            Positioned(
              right: 12,
              bottom: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  'High Alert',
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: AppColors.onPrimary,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.6,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Blight Detected',
              style: theme.textTheme.displaySmall?.copyWith(
                color: textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tomato V2.4',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Automated classification triggered user report.',
          style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
        ),
      ],
    );
  }
}

class _ScanMetadataCard extends StatelessWidget {
  const _ScanMetadataCard({required this.isDark});

  final bool isDark;

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
            'Scan Information',
            style: theme.textTheme.labelLarge?.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 12),
          _MetaRow(
            label: 'Scan ID',
            value: '',
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '#PG-88291',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          _MetaRow(label: 'Date', value: 'Oct 24, 2023, 14:22'),
          _MetaRow(
            label: 'User ID',
            value: 'USR-4402',
            valueColor: AppColors.primary,
          ),
          _AccuracyRow(),
          _SentimentRow(),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({
    required this.label,
    required this.value,
    this.valueColor,
    this.trailing,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
          trailing ??
              Text(
                value,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: valueColor ?? textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
        ],
      ),
    );
  }
}

class _AccuracyRow extends StatelessWidget {
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Model Accuracy',
            style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
          Row(
            children: [
              Container(
                width: 80,
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FractionallySizedBox(
                    widthFactor: 0.942,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '94.2%',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SentimentRow extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textSecondary = isDark
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'User Sentiment',
            style: theme.textTheme.bodySmall?.copyWith(color: textSecondary),
          ),
          Row(
            children: [
              const Icon(
                Icons.sentiment_dissatisfied,
                size: 18,
                color: Colors.orange,
              ),
              const SizedBox(width: 6),
              Text(
                'Frustrated',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.orange,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _UserCommentCard extends StatelessWidget {
  const _UserCommentCard({required this.isDark});

  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark
        ? AppColors.textPrimaryDark
        : AppColors.textPrimaryLight;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'User Comment',
          style: theme.textTheme.labelLarge?.copyWith(
            color: AppColors.primary,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 10),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Text(
            '"The app identified this as Early Blight, but I\'m fairly certain it\'s Late Blight based on the stem lesions. The care instructions might be wrong for my specific climate zone."',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: textPrimary,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }
}
