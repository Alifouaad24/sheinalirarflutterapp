import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shein_cart_app/core/constants/storage_keys.dart';
import 'package:shein_cart_app/core/localization/lang/ar_sa.dart';
import 'package:shein_cart_app/core/localization/lang/en_us.dart';
import 'package:shein_cart_app/core/storage/local_storage_service.dart';

/// GetX translations. To add a language: create `lang/xx_yy.dart`,
/// register it in [keys] and add its [Locale] to [supportedLocales].
class AppTranslations extends Translations {
  static const Locale defaultLocale = Locale('ar', 'SA');
  static const Locale fallbackLocale = Locale('en', 'US');
  static const List<Locale> supportedLocales = [defaultLocale, fallbackLocale];

  /// Saved language (if the user changed it) or Arabic.
  static Locale get initialLocale {
    if (!Get.isRegistered<LocalStorageService>()) return defaultLocale;
    final code = Get.find<LocalStorageService>().getString(StorageKeys.languageCode);
    return supportedLocales.firstWhere(
      (locale) => locale.languageCode == code,
      orElse: () => defaultLocale,
    );
  }

  /// Changes the language at runtime and remembers the choice.
  static Future<void> changeLocale(Locale locale) async {
    await Get.updateLocale(locale);
    await Get.find<LocalStorageService>()
        .setString(StorageKeys.languageCode, locale.languageCode);
  }

  @override
  Map<String, Map<String, String>> get keys => const {
        'ar_SA': arSA,
        'en_US': enUS,
      };
}
