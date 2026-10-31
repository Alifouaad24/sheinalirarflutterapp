import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';

import 'package:shein_cart_app/core/config/app_config.dart';
import 'package:shein_cart_app/core/localization/app_translations.dart';
import 'package:shein_cart_app/core/storage/local_storage_service.dart';
import 'package:shein_cart_app/core/theme/app_theme.dart';
import 'package:shein_cart_app/routes/app_pages.dart';
import 'package:shein_cart_app/routes/app_routes.dart';
import 'package:shein_cart_app/routes/initial_binding.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Get.putAsync<LocalStorageService>(
    () => LocalStorageService().init(),
    permanent: true,
  );

  runApp(const ShopApp());
}

class ShopApp extends StatelessWidget {
  const ShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,

      // Theme
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.light,
      translations: AppTranslations(),
      locale: AppTranslations.initialLocale,
      fallbackLocale: AppTranslations.fallbackLocale,
      supportedLocales: AppTranslations.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Routing + DI
      initialBinding: InitialBinding(),
      initialRoute: AppRoutes.shop,
      getPages: AppPages.pages,
    );
  }
}
