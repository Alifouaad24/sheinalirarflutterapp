import 'package:flutter/material.dart';

/// Spacing scale used across the app (multiples of 4).
abstract final class AppSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
}

/// Corner radii. Buttons use [md] (12px) as requested.
abstract final class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double pill = 999;
}

/// Fixed component sizes.
abstract final class AppSizes {
  static const double buttonHeight = 52;
  static const double progressBarHeight = 2.5;
  static const double cartThumbWidth = 76;
  static const double cartThumbHeight = 96;
  static const double emptyStateIcon = 44;
}

/// Subtle elevation shadows (kept very light on purpose).
abstract final class AppShadows {
  static const List<BoxShadow> subtle = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 12, offset: Offset(0, 4)),
  ];

  /// Shadow for bars pinned to the bottom of the screen.
  static const List<BoxShadow> bottomBar = [
    BoxShadow(color: Color(0x14000000), blurRadius: 16, offset: Offset(0, -4)),
  ];
}
