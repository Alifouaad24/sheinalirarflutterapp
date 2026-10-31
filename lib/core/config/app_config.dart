/// App-wide configuration values.
///
/// Anything that may differ between environments (staging / production)
/// belongs here, so it can later be swapped with flavors or --dart-define.
abstract final class AppConfig {
  static const String appName = 'Shein Cart';

  /// First page loaded inside the WebView.
  static const String startUrl = 'https://ar.shein.com';

  /// Backend base URL (used by ApiClient). Replace when the API is ready.
  static const String apiBaseUrl = 'https://api.example.com/v1';

  /// Network timeout for every API call.
  static const Duration apiTimeout = Duration(seconds: 30);

  /// Max time to wait for the WebView to answer a product extraction request.
  static const Duration productExtractionTimeout = Duration(seconds: 8);

  /// Name of the JavaScriptChannel exposed to the page (window.FlutterCart).
  static const String jsChannelName = 'FlutterCart';

  /// JavaScriptChannel that reports pull-to-refresh gestures
  /// (window.FlutterPullToRefresh).
  static const String pullToRefreshChannelName = 'FlutterPullToRefresh';

  /// User agent sent by the WebView. The default Android WebView agent
  /// contains "; wv)", which some sites (SHEIN included) use to detect
  /// embedded browsers and serve a degraded/empty page. Set to null to keep
  /// the platform default.
  static const String? webViewUserAgent =
      'Mozilla/5.0 (Linux; Android 13; Pixel 7) AppleWebKit/537.36 '
      '(KHTML, like Gecko) Chrome/124.0.0.0 Mobile Safari/537.36';

  /// Diagnostics switch: set to false to stop injecting the script that
  /// hides SHEIN's own add-to-bag UI (useful to rule it out when debugging).
  static const bool hideNativeCartUi = true;

  /// Fraction of the available body height given to the WebView.
  static const double webViewHeightFactor = 0.8;

  /// Currency shown when it can't be read from the product page
  /// (e.g. 'SAR' for ar.shein.com). Keep null to show the number only.
  static const String? fallbackCurrency = 'USD';

  /// Currency used to show prices and totals in the app.
  static const String displayCurrency = 'USD';

  /// How many units of each currency equal 1 USD.
  static const Map<String, double> usdRates = {
    'USD': 1,
    'SAR': 3.75, // ثابت
    'AED': 3.6725, // ثابت
    'QAR': 3.64, // ثابت
    'BHD': 0.376, // ثابت
    'OMR': 0.3845, // ثابت
    'JOD': 0.709, // ثابت
    'KWD': 0.307, // تقريبي، حدّثه
    'IQD': 1480, // السعر الرسمي، حدّثه إذا تغيّر
  };

  /// Upper bound for the quantity of a single cart line.
  static const int maxQuantityPerItem = 99;
}
