import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:shein_cart_app/core/constants/app_dimens.dart';
import 'package:shein_cart_app/core/theme/app_colors.dart';

/// Central Material 3 theme (light + dark-ready), Cairo font everywhere.
abstract final class AppTheme {
  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isLight = brightness == Brightness.light;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: isLight ? AppColors.primary : null,
      error: isLight ? AppColors.error : null,
    );

    final base = ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
    );
    final textTheme = GoogleFonts.cairoTextTheme(base.textTheme).apply(
      bodyColor: scheme.onSurface,
      displayColor: scheme.onSurface,
    );

    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppRadius.md),
    );
    final buttonText = textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700);

    return base.copyWith(
      textTheme: textTheme,
      scaffoldBackgroundColor:
          isLight ? AppColors.lightBackground : AppColors.darkBackground,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        backgroundColor: scheme.surface,
        foregroundColor: scheme.onSurface,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(AppSizes.buttonHeight),
          shape: buttonShape,
          textStyle: buttonText,
          elevation: 0,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(0, AppSizes.buttonHeight),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, AppSizes.buttonHeight),
          shape: buttonShape,
          textStyle: buttonText,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(shape: buttonShape, textStyle: buttonText),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: scheme.primary,
        linearTrackColor: Colors.transparent,
      ),
      badgeTheme: BadgeThemeData(
        backgroundColor: scheme.primary,
        textColor: scheme.onPrimary,
        textStyle: textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
      ),
      dividerTheme: DividerThemeData(
        color: scheme.outlineVariant.withValues(alpha: 0.5),
        thickness: 1,
        space: 1,
      ),
    );
  }
}
