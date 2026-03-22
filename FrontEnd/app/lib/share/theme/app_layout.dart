import 'package:flutter/material.dart';

import 'app_colors.dart';

abstract final class AppLayout {
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusSheet = 20;

  static const double screenPaddingH = 16;
  static const double screenPaddingV = 8;
  static const double sectionGap = 16;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);

  /// Layered shadows for cards and prominent panels.
  static List<BoxShadow> cardShadows(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.55),
          blurRadius: 22,
          offset: const Offset(0, 10),
        ),
        BoxShadow(
          color: AppColors.accent.withValues(alpha: 0.07),
          blurRadius: 32,
          offset: const Offset(0, 4),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.05),
        blurRadius: 0,
        offset: const Offset(0, 1),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.08),
        blurRadius: 14,
        offset: const Offset(0, 5),
      ),
      BoxShadow(
        color: AppColors.primary.withValues(alpha: 0.07),
        blurRadius: 22,
        offset: const Offset(0, 10),
      ),
    ];
  }

  /// Hero / scan-style cards: deeper lift + cool rim.
  static List<BoxShadow> heroCardShadows(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.65),
          blurRadius: 28,
          offset: const Offset(0, 14),
        ),
        BoxShadow(
          color: AppColors.brandAccentOnDark.withValues(alpha: 0.06),
          blurRadius: 40,
          offset: const Offset(0, 6),
        ),
      ];
    }
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.18),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: AppColors.brandAccent.withValues(alpha: 0.12),
        blurRadius: 32,
        offset: const Offset(0, 8),
      ),
    ];
  }
}
