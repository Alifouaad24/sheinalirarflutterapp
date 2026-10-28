import 'package:get/get.dart';

import 'package:shein_cart_app/core/config/app_config.dart';

/// Formats prices as "97.00 ر.س" (Arabic) or "97.00 SAR" (other languages).
abstract final class PriceFormatter {
  /// Local symbols shown when the app language is Arabic.
  static const Map<String, String> _arabicSymbols = {
    'SAR': 'ر.س',
    'AED': 'د.إ',
    'KWD': 'د.ك',
    'QAR': 'ر.ق',
    'BHD': 'د.ب',
    'OMR': 'ر.ع',
    'EGP': 'ج.م',
    'JOD': 'د.أ',
    'IQD': 'د.ع',
  };

  static String format(double amount, {String? currency}) {
    final value = amount.toStringAsFixed(2);
    final code = (currency?.trim().isNotEmpty ?? false)
        ? currency!.trim().toUpperCase()
        : AppConfig.fallbackCurrency;
    if (code == null) return value;

    final isArabic = Get.locale?.languageCode == 'ar';
    final symbol = isArabic ? (_arabicSymbols[code] ?? code) : code;
    return '$value $symbol';
  }
}
