import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF2D6A4F);
  static const Color accent = Color(0xFF52B788);
  static const Color warning = Color(0xFFFFB703);
  static const Color lightBackground = Color(0xFFF5F7FA);
  /// True-black scaffold; avoids blue-tinted slate darks.
  static const Color darkBackground = Color(0xFF000000);
  /// Light-theme panels: cards, sheets, inputs, opaque bars. Prefer over [Colors.white].
  static const Color surfaceLight = Color(0xFFFFFFFF);
  /// Text/icons on [primary] buttons and on dark brand/hero bands.
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF121212);

  /// Frosted white scrim (app bars, overlays). Use instead of [Colors.white.withValues].
  static Color scrimLight(double opacity) =>
      surfaceLight.withValues(alpha: opacity);
  static const Color textPrimaryLight = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF475569);
  static const Color textPrimaryDark = Color(0xFFF8FAFC);
  static const Color textSecondaryDark = Color(0xFFA3A3A3);
  static const Color borderLight = Color(0xFFE2E8F0);
  static const Color borderDark = Color(0xFF2A2A2A);
  /// Muted icons/labels on dark surfaces (neutral gray).
  static const Color darkMuted = Color(0xFF737373);
  /// Inputs, tracks, nested panels on dark surfaces.
  static const Color darkControlFill = Color(0xFF262626);
}
