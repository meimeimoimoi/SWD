import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2D6A4F);
  static const Color accent = Color(0xFF52B788);

  static const Color brandAccent = Color(0xFF2D7B31);
  static const Color brandAccentOnDark = Color(0xFFA4F69C);
  static const Color scanBackgroundLight = Color(0xFFF6F8F6);
  static const Color forestCardDark = Color(0xFF2D322B);
  static const Color forestCardBorder = Color(0xFF3D433B);
  static const Color softGreenContainer = Color(0xFFC9ECC1);
  static const Color urgentTint = Color(0xFFB45309);
  static const Color urgentSurface = Color(0xFFFFF7ED);
  static const Color onBrandFixedDark = Color(0xFF1A3D16);
  static const Color warning = Color(0xFFFFB703);
  static const Color lightBackground = Color(0xFFF5F7FA);
  static const Color darkBackground = Color(0xFF000000);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121212);

  static Color scrimLight(double opacity) =>
      surfaceLight.withValues(alpha: opacity);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFA3A3A3);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF2A2A2A);
  static const Color darkMuted = Color(0xFF737373);
  static const Color darkControlFill = Color(0xFF262626);

  /// Use for text/icons on dark greys and surfaces; keeps [brandAccent] on light mode.
  static Color brandAccentReadable(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? brandAccentOnDark
        : brandAccent;
  }
}
