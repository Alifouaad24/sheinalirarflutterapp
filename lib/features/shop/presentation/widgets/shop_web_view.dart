import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'package:shein_cart_app/core/constants/app_dimens.dart';
import 'package:shein_cart_app/core/localization/locale_keys.dart';
import 'package:shein_cart_app/core/widgets/empty_state.dart';
import 'package:shein_cart_app/features/shop/presentation/controllers/shop_controller.dart';

/// The SHEIN WebView with a thin top progress bar and an error overlay.
class ShopWebView extends GetView<ShopController> {
  const ShopWebView({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
       fit: StackFit.expand,
      children: [
        Positioned.fill(child: _buildWebView()),

        // Thin progress bar while loading.
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: Obx(
            () => AnimatedOpacity(
              opacity: controller.isPageLoading.value ? 1 : 0,
              duration: const Duration(milliseconds: 250),
              child: LinearProgressIndicator(
                value: controller.loadingProgress.value == 0
                    ? null
                    : controller.loadingProgress.value / 100,
                minHeight: AppSizes.progressBarHeight,
              ),
            ),
          ),
        ),

        // Main-frame load error.
        Obx(
          () => controller.hasLoadError.value
              ? Positioned.fill(
                  child: ColoredBox(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    child: EmptyState(
                      icon: Icons.wifi_off_rounded,
                      title: LocaleKeys.pageLoadError.tr,
                      subtitle: LocaleKeys.pageLoadErrorHint.tr,
                      actionLabel: LocaleKeys.retry.tr,
                      onAction: controller.retry,
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }

  /// On Android we force Hybrid Composition: the default (texture layer)
  /// mode renders a blank WebView on many emulators and some older GPUs,
  /// even though the page loads fine underneath.
  Widget _buildWebView() {
    final platform = controller.webViewController.platform;
    if (platform is AndroidWebViewController) {
      return WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams(
          controller: platform,
          displayWithHybridComposition: true,
        ),
      );
    }
    return WebViewWidget(controller: controller.webViewController);
  }
}
