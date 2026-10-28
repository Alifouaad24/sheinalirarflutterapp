import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shein_cart_app/core/constants/app_dimens.dart';
import 'package:shein_cart_app/core/localization/locale_keys.dart';
import 'package:shein_cart_app/core/theme/app_colors.dart';

/// Consistent snackbars. Shown at the top so they never cover the
/// "Add to cart" button.
abstract final class AppSnackbar {
  static void success(String message, {String? title}) => _show(
        title: title ?? LocaleKeys.success.tr,
        message: message,
        color: AppColors.success,
        icon: Icons.check_circle_rounded,
      );

  static void error(String message, {String? title}) => _show(
        title: title ?? LocaleKeys.error.tr,
        message: message,
        color: AppColors.error,
        icon: Icons.error_rounded,
      );

  static void warning(String message, {String? title}) => _show(
        title: title ?? LocaleKeys.notice.tr,
        message: message,
        color: AppColors.warning,
        icon: Icons.info_rounded,
      );

  static void _show({
    required String title,
    required String message,
    required Color color,
    required IconData icon,
  }) {
    if (Get.isSnackbarOpen) Get.closeAllSnackbars();
    final textTheme = Get.textTheme;

    Get.snackbar(
      title,
      message,
      titleText: Text(
        title,
        style: textTheme.titleSmall?.copyWith(color: Colors.white, fontWeight: FontWeight.w700),
      ),
      messageText: Text(
        message,
        style: textTheme.bodyMedium?.copyWith(color: Colors.white),
      ),
      icon: Icon(icon, color: Colors.white),
      shouldIconPulse: false,
      backgroundColor: color,
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(AppSpacing.md),
      borderRadius: AppRadius.md,
      duration: const Duration(milliseconds: 2600),
      isDismissible: true,
    );
  }
}
