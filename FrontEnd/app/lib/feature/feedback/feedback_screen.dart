import 'package:flutter/material.dart';
import '../../share/services/rating_service.dart';
import '../prediction/prediction_screen.dart';

import '../../share/theme/app_colors.dart';
import '../../share/widgets/app_card.dart';

class FeedbackScreen extends StatefulWidget {
  final PredictionResult? predictionResult;
  const FeedbackScreen({super.key, this.predictionResult});

  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final TextEditingController _commentController = TextEditingController();
  int _rating = 4;
  final Set<String> _selectedTags = {'Accurate diagnosis'};
  bool _isSubmitting = false;
  final RatingService _ratingService = RatingService();

  final List<String> _tags = const [
    'Accurate diagnosis',
    'Fast processing',
    'Clear guidance',
    'Easy to use',
    'Sharp images',
  ];

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (widget.predictionResult == null) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final List<String> commentParts = [];
      if (_selectedTags.isNotEmpty) {
        commentParts.addAll(_selectedTags);
      }
      if (_commentController.text.trim().isNotEmpty) {
        commentParts.add(_commentController.text.trim());
      }
      final String finalComment = commentParts.join(', ');

      final result = await _ratingService.submitRating(
        predictionId: widget.predictionResult!.predictionId,
        score: _rating,
        comment: finalComment,
      );

      if (!mounted) return;

      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Thanks for your feedback!')),
        );
        // Navigate back to prediction screen
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['message'] ?? 'Something went wrong')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text('Rate diagnosis', style: theme.textTheme.titleLarge),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              children: [
                _SummaryCard(
                  isDark: isDark,
                  predictionResult: widget.predictionResult,
                ),
                const SizedBox(height: 20),
                _RatingSection(
                  rating: _rating,
                  onRatingChanged: (value) => setState(() => _rating = value),
                ),
                const SizedBox(height: 20),
                _QuickTagsSection(
                  tags: _tags,
                  selectedTags: _selectedTags,
                  onTagToggle: (tag) {
                    setState(() {
                      if (_selectedTags.contains(tag)) {
                        _selectedTags.remove(tag);
                      } else {
                        _selectedTags.add(tag);
                      }
                    });
                  },
                ),
                const SizedBox(height: 20),
                _CommentSection(controller: _commentController),
                const SizedBox(height: 20),
                _SubmitSection(
                  isDark: isDark,
                  isSubmitting: _isSubmitting,
                  onPressed: _handleSubmit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.isDark, this.predictionResult});

  final bool isDark;
  final PredictionResult? predictionResult;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              predictionResult?.imageUrl ??
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuAoYR4B8P_BnSy72hyfsDQUoGD23ngJW2_4aU4avE996bCr9nTQ3b-Ke4efwrGp3-7qWAcfnHzhhQppNunxYVCDHa4UeN2OVnnFhwZj1q-soEmPeaHb4G67vmF4aMvXNTcOttPOqe7rieb0OZA_ZxiWJ6s__WeCT8z-2tTn1LwJLXW2IolTboPLcSA7s9D6rwgs7wi6NIPloDgWbLbq_G2XtRMxbzuXQwG7gLT2uLZpnUT4NM0D0fCDABBLH4BlBEO1MJi1NSACvoc',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Diagnosis result',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: AppColors.primary,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  predictionResult?.vietnameseName ?? 'Leaf spot',
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 4),
                Text(
                  'ID: #${predictionResult?.predictionId ?? "---"}',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RatingSection extends StatelessWidget {
  const _RatingSection({required this.rating, required this.onRatingChanged});

  final int rating;
  final ValueChanged<int> onRatingChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text('How satisfied are you?', style: theme.textTheme.titleLarge),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final isFilled = index < rating;
            return IconButton(
              iconSize: 32,
              onPressed: () => onRatingChanged(index + 1),
              icon: Icon(
                isFilled ? Icons.star : Icons.star_border,
                color: isFilled ? AppColors.primary : theme.dividerColor,
              ),
            );
          }),
        ),
        Text(
          '${rating.toDouble().toStringAsFixed(1)} / 5.0',
          style: theme.textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _QuickTagsSection extends StatelessWidget {
  const _QuickTagsSection({
    required this.tags,
    required this.selectedTags,
    required this.onTagToggle,
  });

  final List<String> tags;
  final Set<String> selectedTags;
  final ValueChanged<String> onTagToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Quick feedback', style: theme.textTheme.titleMedium),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: tags.map((tag) {
            final isSelected = selectedTags.contains(tag);
            return InkWell(
              onTap: () => onTagToggle(tag),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.12)
                      : (isDark
                            ? AppColors.surfaceDark
                            : AppColors.surfaceLight),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : theme.dividerColor.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  tag,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected ? AppColors.primary : theme.hintColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _CommentSection extends StatelessWidget {
  const _CommentSection({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Additional comments', style: theme.textTheme.titleMedium),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: 'Share your experience with us...',
            alignLabelWithHint: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: theme.dividerColor),
            ),
          ),
        ),
      ],
    );
  }
}

class _SubmitSection extends StatelessWidget {
  const _SubmitSection({
    required this.isDark,
    required this.onPressed,
    this.isSubmitting = false,
  });

  final bool isDark;
  final VoidCallback onPressed;
  final bool isSubmitting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: isSubmitting ? null : onPressed,
            icon: isSubmitting
                ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                : const Icon(Icons.send),
            label: Text(isSubmitting ? 'Sending...' : 'Submit feedback'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: isDark ? AppColors.darkBackground : Colors.white,
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
        const SizedBox(height: 12),
        Text(
          'Thank you for contributing. Your feedback helps Argivision improve.',
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}
