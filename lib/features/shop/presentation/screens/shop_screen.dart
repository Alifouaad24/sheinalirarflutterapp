import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shein_cart_app/features/shop/presentation/widgets/url_paste_bar.dart';
import 'package:shein_cart_app/core/config/app_config.dart';
import 'package:shein_cart_app/core/constants/app_dimens.dart';
import 'package:shein_cart_app/core/localization/locale_keys.dart';
import 'package:shein_cart_app/features/cart/presentation/widgets/cart_icon_button.dart';
import 'package:shein_cart_app/features/shop/presentation/controllers/shop_controller.dart';
import 'package:shein_cart_app/features/shop/presentation/widgets/add_to_cart_panel.dart';
import 'package:shein_cart_app/features/shop/presentation/widgets/shop_web_view.dart';

/// WebView (80% of the body height) + our own "Add to cart" panel below it.
class ShopScreen extends GetView<ShopController> {
  const ShopScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Back is handled by the WebView history first.
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) controller.handleBackPress();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(LocaleKeys.appTitle.tr),
          actions: [
            CartIconButton(onPressed: controller.openCart),
            const SizedBox(width: AppSpacing.xxs),
          ],
          bottom: const UrlPasteBar(),
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final webViewHeight =
                  constraints.maxHeight * AppConfig.webViewHeightFactor;
              return Column(
                children: [
// بعد
                  SizedBox(
                    width: double.infinity,
                    height: webViewHeight,
                    child: const ShopWebView(),
                  ),
                  const Expanded(child: AddToCartPanel()),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
