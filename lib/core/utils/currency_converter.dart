import 'package:flutter/foundation.dart';

import 'package:shein_cart_app/core/config/app_config.dart';

abstract final class CurrencyConverter {
  static double convert(double amount, {String? from, String to = AppConfig.displayCurrency}) {
    final source = (from ?? AppConfig.fallbackCurrency ?? to).toUpperCase();
    final target = to.toUpperCase();
    if (source == target) return amount;

    final sourceRate = AppConfig.usdRates[source];
    final targetRate = AppConfig.usdRates[target];
    if (sourceRate == null || targetRate == null) {
      if (kDebugMode) debugPrint('[CurrencyConverter] missing rate for $source -> $target');
      return amount;
    }
    return amount / sourceRate * targetRate;
  }

  static bool needsConversion(String? currency) =>
      currency != null && currency.toUpperCase() != AppConfig.displayCurrency;
}