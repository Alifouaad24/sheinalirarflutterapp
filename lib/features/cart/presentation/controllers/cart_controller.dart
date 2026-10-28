import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:shein_cart_app/core/widgets/image_gallery_view.dart';
import 'package:shein_cart_app/core/localization/locale_keys.dart';
import 'package:shein_cart_app/core/utils/app_snackbar.dart';
import 'package:shein_cart_app/features/cart/domain/entities/cart_item.dart';
import 'package:shein_cart_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:shein_cart_app/features/shop/domain/entities/product.dart';
import 'package:shein_cart_app/core/config/app_config.dart';
import 'package:shein_cart_app/core/utils/currency_converter.dart';

/// Global cart state. Registered permanently because the cart badge on the
/// shop screen and the cart screen share it.
class CartController extends GetxController {
  CartController({required CartRepository repository})
      : _repository = repository;

  final CartRepository _repository;

  final RxList<CartItem> items = <CartItem>[].obs;
  final RxBool isLoading = false.obs;
  final RxBool isCheckingOut = false.obs;

  bool get isEmpty => items.isEmpty;

  /// Number of pieces (sum of quantities) — shown in the badge.
  int get totalQuantity => items.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice => items.fold(
        0.0,
        (sum, item) =>
            sum +
            CurrencyConverter.convert(item.totalPrice,
                from: item.product.currency),
      );

  /// Currency of the cart (SHEIN shows a single currency per region).
  String? get currency => AppConfig.displayCurrency;
  @override
  void onInit() {
    super.onInit();
    loadCart();
  }

  Future<void> loadCart() async {
    isLoading.value = true;
    final result = await _repository.getCartItems();
    result.fold(
      // Runs before the first frame, so log instead of showing a snackbar.
      (failure) => debugPrint('[CartController] load failed: $failure'),
      items.assignAll,
    );
    isLoading.value = false;
  }

  /// Returns true when the product was added.
  Future<bool> addProduct(Product product) async {
    final result = await _repository.addProduct(product);
    return result.fold(
      (failure) {
        AppSnackbar.error(failure.message);
        return false;
      },
      (updated) {
        items.assignAll(updated);
        AppSnackbar.success(LocaleKeys.addedToCart.tr);
        return true;
      },
    );
  }

  Future<void> increment(CartItem item) =>
      _setQuantity(item, item.quantity + 1);

  Future<void> decrement(CartItem item) async {
    if (item.quantity <= 1) return; // Use remove() to delete the line.
    await _setQuantity(item, item.quantity - 1);
  }

  Future<void> remove(CartItem item) async {
    final result = await _repository.removeItem(item.key);
    result.fold(
      (failure) => AppSnackbar.error(failure.message),
      (updated) {
        items.assignAll(updated);
        AppSnackbar.success(LocaleKeys.itemRemoved.tr);
      },
    );
  }

  Future<bool> importItems(List<CartItem> imported) async {
    if (imported.isEmpty) return false;
    final result = await _repository.addItems(imported);
    return result.fold(
      (failure) {
        AppSnackbar.error(failure.message);
        return false;
      },
      (updated) {
        items.assignAll(updated);
        AppSnackbar.success(
          LocaleKeys.importedItems.trParams({'count': '${imported.length}'}),
        );
        return true;
      },
    );
  }

  void openGallery(CartItem item, {int initialIndex = 0}) =>
      ImageGalleryView.open(item.product.allImages, initialIndex: initialIndex);

  Future<void> clearCart() async {
    final result = await _repository.clearCart();
    result.fold(
        (failure) => AppSnackbar.error(failure.message), items.assignAll);
  }

  /// Placeholder. Later: call `OrderRepository.createOrder(items)` (see
  /// features/orders) and clear the cart on success.
  Future<void> checkout() async {
    if (items.isEmpty || isCheckingOut.value) return;
    isCheckingOut.value = true;
    try {
      AppSnackbar.warning(LocaleKeys.checkoutComingSoon.tr);
    } finally {
      isCheckingOut.value = false;
    }
  }

  Future<void> _setQuantity(CartItem item, int quantity) async {
    final result = await _repository.updateQuantity(item.key, quantity);
    result.fold(
        (failure) => AppSnackbar.error(failure.message), items.assignAll);
  }
}
