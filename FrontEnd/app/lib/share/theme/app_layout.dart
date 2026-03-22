import 'package:flutter/material.dart';

/// Shared layout tokens — use with [ThemeData] and shared widgets for visual consistency.
abstract final class AppLayout {
  static const double radiusXs = 8;
  static const double radiusSm = 12;
  static const double radiusMd = 16;
  static const double radiusLg = 20;
  static const double radiusSheet = 20;

  /// Typical horizontal padding for full-width scroll screens.
  static const double screenPaddingH = 16;
  static const double screenPaddingV = 8;
  static const double sectionGap = 16;

  static final BorderRadius borderRadiusSm = BorderRadius.circular(radiusSm);
  static final BorderRadius borderRadiusMd = BorderRadius.circular(radiusMd);
  static final BorderRadius borderRadiusLg = BorderRadius.circular(radiusLg);
}
