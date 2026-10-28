import 'package:flutter/material.dart';

/// Brand palette. Change [primary] to rebrand the whole app.
abstract final class AppColors {
  /// Deep teal-green: calm, premium, reads well next to SHEIN's black/white UI.
  static const Color primary = Color(0xFF0F5C4D);

  static const Color success = Color(0xFF15803D);
  static const Color error = Color(0xFFB42318);
  static const Color warning = Color(0xFFB45309);

  static const Color lightBackground = Color(0xFFF4F6F6);
  static const Color darkBackground = Color(0xFF0E1413);
}
