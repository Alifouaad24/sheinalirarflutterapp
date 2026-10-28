import 'package:shein_cart_app/core/constants/shein_selectors.dart';

/// Detects SHEIN product pages using [SheinSelectors.productUrlPattern].
abstract final class ProductUrlMatcher {
  static bool isProductUrl(String? url) => extractId(url) != null;
  
  static bool isCartUrl(String? url) {
    if (url == null || url.isEmpty || isProductUrl(url)) return false;
    final uri = Uri.tryParse(url);
    return SheinSelectors.sharedCartUrlPattern
        .hasMatch('${uri?.path ?? ''}?${uri?.query ?? ''}');
  }

  /// Product id from the URL path, or null if this isn't a product page.
  static String? extractId(String? url) {
    if (url == null || url.isEmpty) return null;
    final path = Uri.tryParse(url)?.path ?? url;
    return SheinSelectors.productUrlPattern.firstMatch(path)?.group(1);
  }
}
