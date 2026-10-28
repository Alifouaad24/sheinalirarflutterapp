import 'package:shein_cart_app/core/errors/failures.dart';
import 'package:shein_cart_app/core/localization/locale_keys.dart';

/// The page did not return usable product data (selectors outdated,
/// page still loading, JS error, timeout…).
class ProductExtractionFailure extends Failure {
  const ProductExtractionFailure({super.customMessage});
  @override
  String get messageKey => LocaleKeys.failureExtraction;
}

/// The product has several sizes and none is selected on the page.
class SizeNotSelectedFailure extends Failure {
  const SizeNotSelectedFailure();
  @override
  String get messageKey => LocaleKeys.selectSizeMessage;
}

class CartImportFailure extends Failure {
  const CartImportFailure();
  @override
  String get messageKey => LocaleKeys.failureCartImport;
}