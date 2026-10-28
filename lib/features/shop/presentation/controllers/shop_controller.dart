import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'dart:async';
import 'package:shein_cart_app/core/config/app_config.dart';
import 'package:shein_cart_app/core/localization/locale_keys.dart';
import 'package:shein_cart_app/core/utils/app_snackbar.dart';
import 'package:shein_cart_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:shein_cart_app/features/shop/data/js/shein_js_scripts.dart';
import 'package:shein_cart_app/features/shop/data/services/product_extractor.dart';
import 'package:shein_cart_app/features/shop/domain/failures/shop_failures.dart';
import 'package:shein_cart_app/features/shop/domain/utils/product_url_matcher.dart';
import 'package:shein_cart_app/routes/app_routes.dart';
import 'package:shein_cart_app/features/shop/data/services/cart_page_extractor.dart';

/// Owns the WebView, tracks navigation state and orchestrates
/// "extract product → add to cart".
class ShopController extends GetxController {
  ShopController({
    required ProductExtractor extractor,
    required CartPageExtractor cartPageExtractor,
    required CartController cartController,
  })  : _extractor = extractor,
        _cartPageExtractor = cartPageExtractor,
        _cart = cartController;

  final ProductExtractor _extractor;
  final CartPageExtractor _cartPageExtractor;
  final CartController _cart;

  final TextEditingController urlTextController = TextEditingController();

  late final WebViewController webViewController;

  // ---------------------------------------------------------------------------
  // Reactive state
  // ---------------------------------------------------------------------------
  final RxInt loadingProgress = 0.obs;
  final RxBool isPageLoading = true.obs;
  final RxBool hasLoadError = false.obs;
  final RxString currentUrl = AppConfig.startUrl.obs;
  final RxBool isProductPage = false.obs;
  final RxBool isAddingToCart = false.obs;

  bool get canAddToCart => isProductPage.value && !isAddingToCart.value;

  final RxBool isCartPage = false.obs;
  final RxInt cartPageItemCount = 0.obs;
  final RxBool isImportingCart = false.obs;

  bool get canImportCart => isCartPage.value && !isImportingCart.value;

  String? _pastedLandingPath;
  DateTime? _pastedAt;
  Timer? _probeTimer;

  @override
  void onInit() {
    super.onInit();
    webViewController = _buildWebViewController();
    _configureAndroid();
    webViewController.loadRequest(Uri.parse(AppConfig.startUrl));
  }

  /// Android-only WebView settings. Must run before the first loadRequest.
  void _configureAndroid() {
    final platform = webViewController.platform;
    if (platform is! AndroidWebViewController) return;

    // Lets you inspect the page from desktop Chrome (chrome://inspect).
    AndroidWebViewController.enableDebugging(kDebugMode);

    // Android blocks third-party cookies by default; SHEIN's APIs and
    // anti-bot checks rely on them, otherwise the page renders empty.
    final cookieManager = WebViewCookieManager().platform;
    if (cookieManager is AndroidWebViewCookieManager) {
      cookieManager.setAcceptThirdPartyCookies(platform, true);
    }
  }

  @override
  void onClose() {
    _probeTimer?.cancel();
    _extractor.dispose();
    _cartPageExtractor.dispose();
    urlTextController.dispose();
    super.onClose();
  }

  // ---------------------------------------------------------------------------
  // WebView setup
  // ---------------------------------------------------------------------------
  WebViewController _buildWebViewController() {
    return WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..setUserAgent(AppConfig.webViewUserAgent)
      ..addJavaScriptChannel(
        AppConfig.jsChannelName,
        onMessageReceived: (message) {
          _extractor.handleMessage(message.message);
          _cartPageExtractor.handleMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onPageStarted: _onPageStarted,
          onProgress: _onProgress,
          onPageFinished: _onPageFinished,
          // Fires for SPA navigations (history.pushState) too.
          onUrlChange: (change) {
            final url = change.url;
            if (url == null) return;
            final pastedAt = _pastedAt;
            if (pastedAt != null &&
                DateTime.now().difference(pastedAt).inSeconds < 20) {
              _pastedLandingPath = Uri.tryParse(url)?.path;
            }
            _updateUrl(url);
            _scheduleCartProbe();
            _injectHideScript();
          },
          onWebResourceError: _onWebResourceError,
        ),
      );
  }

  /// Blocks app deep links (intent://, sheinlink://…) that the WebView
  /// can't open and that would otherwise show an error page.
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    final scheme = Uri.tryParse(request.url)?.scheme.toLowerCase();
    const allowed = {'http', 'https', 'about', 'data', 'blob'};
    return allowed.contains(scheme)
        ? NavigationDecision.navigate
        : NavigationDecision.prevent;
  }

  void _onPageStarted(String url) {
    hasLoadError.value = false;
    isPageLoading.value = true;
    _updateUrl(url);
  }

  void _onProgress(int progress) {
    loadingProgress.value = progress;
    isPageLoading.value = progress < 100;
  }

  Future<void> _onPageFinished(String url) async {
    loadingProgress.value = 100;
    isPageLoading.value = false;
    _updateUrl(url);
    await _injectHideScript();
    // SHEIN renders client-side, so give it a few seconds before checking.
    Future.delayed(const Duration(seconds: 6), _logPageDiagnostics);
  }

  /// Debug only: prints what the page actually contains, so a "blank" page
  /// can be told apart from a page whose content failed to load.
  Future<void> _logPageDiagnostics() async {
    if (!kDebugMode || isClosed) return;
    try {
      final result = await webViewController.runJavaScriptReturningResult(r"""
(function () {
  function desc(e) {
    if (!e) return null;
    var cs = getComputedStyle(e);
    var cls = (e.className && e.className.toString ? e.className.toString() : '').slice(0, 60);
    return e.tagName + '.' + cls + ' bg=' + cs.backgroundColor + ' op=' + cs.opacity +
      ' pos=' + cs.position + ' z=' + cs.zIndex;
  }
  var center = document.elementFromPoint(innerWidth / 2, innerHeight / 2);
  var chain = [];
  for (var e = center; e && chain.length < 5; e = e.parentElement) chain.push(desc(e));
  var visibleImages = [].filter.call(document.images, function (i) {
    var r = i.getBoundingClientRect();
    return r.width > 20 && r.bottom > 0 && r.top < innerHeight && r.right > 0 && r.left < innerWidth;
  }).length;
  return JSON.stringify({
    url: location.href,
    title: document.title,
    textLength: ((document.body && document.body.innerText) || '').length,
    images: document.images.length,
    visibleImages: visibleImages,
    viewport: innerWidth + 'x' + innerHeight,
    bodyHeight: document.body ? document.body.scrollHeight : 0,
    hiddenByApp: document.querySelectorAll('[data-flutter-hidden]').length,
    centerElement: chain,
    ua: navigator.userAgent
  });
})()
""");
      debugPrint('[PageDiagnostics] $result');
    } catch (error) {
      debugPrint('[PageDiagnostics] failed: $error');
    }
  }

  void _onWebResourceError(WebResourceError error) {
    // Sub-resource errors (ads, trackers) are common and harmless.
    if (error.isForMainFrame ?? false) {
      hasLoadError.value = true;
      isPageLoading.value = false;
    }
  }

  void _updateUrl(String url) {
    final changed = currentUrl.value != url;
    currentUrl.value = url;
    isProductPage.value = ProductUrlMatcher.isProductUrl(url);

    final path = Uri.tryParse(url)?.path;
    isCartPage.value = !isProductPage.value &&
        (ProductUrlMatcher.isCartUrl(url) ||
            (_pastedLandingPath != null && path == _pastedLandingPath));
    if (kDebugMode)
      debugPrint('[CartProbe] isCartPage=${isCartPage.value} for $url');

    if (changed) {
      cartPageItemCount.value = 0;
      _scheduleCartProbe();
    }
  }

  Future<void> importCurrentCart() async {
    if (!canImportCart) return;
    isImportingCart.value = true;
    try {
      final result = await _cartPageExtractor.extract(webViewController);
      await result.fold<Future<void>>(
        (failure) async => AppSnackbar.error(failure.message),
        (items) async {
          final imported = await _cart.importItems(items);
          if (imported) openCart();
        },
      );
    } finally {
      isImportingCart.value = false;
    }
  }

  Future<void> openPastedUrl([String? raw]) async {
    final url = _extractUrl(raw ?? urlTextController.text);
    if (url == null) {
      AppSnackbar.error(LocaleKeys.invalidUrl.tr);
      return;
    }
    urlTextController.text = url;
    FocusManager.instance.primaryFocus?.unfocus();
    _pastedAt = DateTime.now();
    _pastedLandingPath = null;
    await webViewController.loadRequest(Uri.parse(url));
  }

  Future<void> pasteFromClipboard() async {
    final text = (await Clipboard.getData(Clipboard.kTextPlain))?.text?.trim();
    if (text == null || text.isEmpty) {
      AppSnackbar.warning(LocaleKeys.clipboardEmpty.tr);
      return;
    }
    urlTextController.text = text;
    await openPastedUrl(text);
  }

  static String? _extractUrl(String text) {
    final value = text.trim();
    final match =
        RegExp(r'https?://[^\s<>"]+', caseSensitive: false).firstMatch(value);
    if (match != null) {
      return match.group(0)!.replaceFirst(RegExp(r'[)\].,;!?،]+$'), '');
    }
    if (RegExp(r'^[\w-]+(\.[\w-]+)+(/\S*)?$').hasMatch(value))
      return 'https://$value';
    return null;
  }

  void _scheduleCartProbe({int attempt = 0}) {
    _probeTimer?.cancel();
    if (!isCartPage.value || attempt > 3) return;
    _probeTimer =
        Timer(Duration(milliseconds: attempt == 0 ? 1200 : 2500), () async {
      if (isClosed || !isCartPage.value) return;
      final count = await _cartPageExtractor.countItems(webViewController);
      cartPageItemCount.value = count;
      if (count == 0) _scheduleCartProbe(attempt: attempt + 1);
    });
  }

  Future<void> _injectHideScript() async {
    if (!AppConfig.hideNativeCartUi) return;
    try {
      await webViewController
          .runJavaScript(SheinJsScripts.hideNativeCartButtons);
    } catch (error) {
      if (kDebugMode) debugPrint('[ShopController] hide script failed: $error');
    }
  }

  // ---------------------------------------------------------------------------
  // User actions
  // ---------------------------------------------------------------------------

  Future<void> addCurrentProductToCart() async {
    if (!canAddToCart) return;
    isAddingToCart.value = true;
    try {
      final result = await _extractor.extract(webViewController);
      await result.fold<Future<void>>(
        (failure) async {
          if (failure is SizeNotSelectedFailure) {
            AppSnackbar.warning(failure.message,
                title: LocaleKeys.selectSizeTitle.tr);
          } else {
            AppSnackbar.error(failure.message);
          }
        },
        (product) => _cart.addProduct(product),
      );
    } finally {
      isAddingToCart.value = false;
    }
  }

  Future<void> retry() async {
    hasLoadError.value = false;
    await webViewController.loadRequest(Uri.parse(currentUrl.value));
  }

  void openCart() => Get.toNamed(AppRoutes.cart);

  /// Android back: go back inside the WebView first, then leave the screen.
  Future<void> handleBackPress() async {
    if (await webViewController.canGoBack()) {
      await webViewController.goBack();
      return;
    }
    if (Get.key.currentState?.canPop() ?? false) {
      Get.back();
    } else {
      await SystemNavigator.pop();
    }
  }
}
