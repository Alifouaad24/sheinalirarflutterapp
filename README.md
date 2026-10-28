# Shein Cart

Browse SHEIN inside a WebView and collect products in the app's own cart.
Flutter 3.27+ · GetX · dartz · shared_preferences · webview_flutter · http.

## Setup

```bash
flutter create --org com.yourcompany --project-name shein_cart_app .   # generates android/ & ios/
# then copy lib/, pubspec.yaml, analysis_options.yaml and
# android/app/src/main/AndroidManifest.xml from this package over the generated ones
flutter pub get
flutter run
```

**Android** — `AndroidManifest.xml` already has the INTERNET permission. In
`android/app/build.gradle.kts` make sure the min SDK satisfies webview_flutter:

```kotlin
defaultConfig {
    minSdk = maxOf(flutter.minSdkVersion, 21)
}
```

**iOS** — no Info.plist changes are needed (SHEIN is HTTPS). In `ios/Podfile`
use `platform :ios, '13.0'` (or higher), then `cd ios && pod install`.

JavaScript is enabled in code (`JavaScriptMode.unrestricted` in `ShopController`).

## Structure

```
lib/
  main.dart                   init storage → GetMaterialApp (Arabic, RTL, theme, routes)
  core/
    config/app_config.dart    start URL, API base URL, timeouts, JS channel name, 80% factor
    constants/                spacing/radius/shadows, StorageKeys, SheinSelectors (all SHEIN markup)
    theme/                    AppColors (brand color) + AppTheme (Material 3, Cairo, light/dark)
    localization/             LocaleKeys + ar_SA / en_US translations
    errors/                   Failure hierarchy, exceptions, ErrorMapper (status/exception → Failure)
    network/                  ApiClient (get/post/put/delete → Either), ApiEndpoints
    storage/                  LocalStorageService (SharedPreferences wrapper, GetxService)
    utils/ widgets/           snackbars, price formatting, shared UI pieces
  features/
    shop/                     WebView screen + controller, JS scripts, ProductExtractor, Product
    cart/                     CartLocalDataSource → CartRepository (Either) → CartController
    orders/                   EXAMPLE API feature (remote data source + repository + binding)
  routes/                     AppRoutes, AppPages (with bindings), InitialBinding
```

Flow when tapping **أضف إلى السلة**: `ShopController` → `ProductExtractor` runs the
extraction script → the page posts JSON on the `FlutterCart` JavaScriptChannel →
`ProductModel` → `CartController.addProduct` → `CartRepository` → saved as JSON
in SharedPreferences.

## Updating SHEIN selectors

Everything SHEIN-specific is in **`lib/core/constants/shein_selectors.dart`**. The
JavaScript in `shein_js_scripts.dart` is generic and normally never needs editing.
The class names shipped here are a best-effort starting point — verify them on a
real device before release, because SHEIN changes its markup often and may serve its
mobile site inside the WebView.

1. Inspect the page *as the WebView sees it*:
   - Android: add `webview_flutter_android` to pubspec, call
     `AndroidWebViewController.enableDebugging(true)` in debug builds, run the app,
     then open `chrome://inspect` in desktop Chrome.
   - iOS: add `webview_flutter_wkwebview` and call `setInspectable(true)` on the
     `WebKitWebViewController`, then use Safari → Develop → your device.
2. Right-click the element → Inspect, and pick a stable class (prefer
   `product-intro__…`-style names over generated hashes; `[class*="part"]` works for
   partial matches).
3. Add it to the **top** of the matching list (`title`, `price`, `selectedSize`,
   `nativeAddToCart`, `stickyPurchaseBar`, …). Lists are tried in order.
4. If SHEIN renames its button text, add the new wording to `nativeButtonTexts`
   (Arabic Alef/Yaa variants are normalized automatically).
5. If product URLs change format, update `productUrlPattern` (group 1 = product id).

Debug builds log every extraction result as `[ProductExtractor] …` in the console.
Title, price, currency and image are read from JSON-LD and `og:` meta tags first,
so the DOM selectors are only fallbacks.

## Adding a new API endpoint

1. Add the path to `core/network/api_endpoints.dart`:
   `static const String orders = '/orders';`
2. Create (or extend) a remote data source that calls `ApiClient` and returns its
   `Either` — see `features/orders/data/datasources/order_remote_data_source.dart`:
   ```dart
   Future<Either<Failure, List<OrderModel>>> fetchOrders() => _api.get(
         ApiEndpoints.orders,
         decoder: (json) => (json as List).map((e) => OrderModel.fromJson(e)).toList(),
       );
   ```
3. Expose it through a domain repository interface + implementation (map entities
   to request bodies there).
4. Register data source and repository in a GetX `Bindings` (see `OrdersBinding`)
   and attach it to the route in `routes/app_pages.dart`.
5. In the controller: `result.fold((f) => AppSnackbar.error(f.message), (data) => …)`.

`ApiClient` already adds JSON headers, the `Bearer` token saved under
`StorageKeys.authToken`, the timeout from `AppConfig`, UTF-8 decoding and maps every
error to an Arabic, user-friendly `Failure`. Set the real base URL in
`AppConfig.apiBaseUrl`.
