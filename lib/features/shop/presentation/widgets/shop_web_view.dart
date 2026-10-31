import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import 'package:shein_cart_app/core/constants/app_dimens.dart';
import 'package:shein_cart_app/core/localization/locale_keys.dart';
import 'package:shein_cart_app/core/widgets/empty_state.dart';
import 'package:shein_cart_app/features/shop/presentation/controllers/shop_controller.dart';

/// The SHEIN WebView with a thin top progress bar, a pull-to-refresh
/// indicator and an error overlay.
class ShopWebView extends GetView<ShopController> {
  const ShopWebView({super.key});

  /// Resting position of the refresh spinner while the page reloads.
  static const double _refreshIndicatorTop = 24;
  static const double _refreshIndicatorSize = 40;

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
        _buildPullToRefreshIndicator(context),
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

  /// Chrome-style spinner: follows the finger while pulling from the top of
  /// the page, fills up as the pull nears the threshold, and spins while the
  /// page reloads. The pull itself is detected inside the page (see
  /// `SheinJsScripts.pullToRefresh`), so the WebView keeps every gesture.
  Widget _buildPullToRefreshIndicator(BuildContext context) {
    return Obx(() {
      final isRefreshing = controller.isRefreshing.value;
      final pull = controller.pullDistance.value;
      if (!isRefreshing && pull <= 0) return const SizedBox.shrink();

      const threshold = ShopController.pullToRefreshThreshold;
      final progress = (pull / threshold).clamp(0.0, 1.0);
      final top = isRefreshing
          ? _refreshIndicatorTop
          : -_refreshIndicatorSize +
              math.min(pull, threshold) /
                  threshold *
                  (_refreshIndicatorTop + _refreshIndicatorSize);

      return Positioned(
        top: top,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            type: MaterialType.circle,
            elevation: 3,
            color: Theme.of(context).colorScheme.surface,
            child: SizedBox.square(
              dimension: _refreshIndicatorSize,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  value: isRefreshing ? null : progress,
                ),
              ),
            ),
          ),
        ),
      );
    });
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
