import 'package:shein_cart_app/core/constants/storage_keys.dart';
import 'package:shein_cart_app/core/errors/exceptions.dart';
import 'package:shein_cart_app/core/storage/local_storage_service.dart';
import 'package:shein_cart_app/features/cart/data/models/cart_item_model.dart';

/// Persists the cart as a JSON list in SharedPreferences.
/// Throws [CacheException] — the repository converts it to a Failure.
abstract interface class CartLocalDataSource {
  Future<List<CartItemModel>> getCartItems();
  Future<void> saveCartItems(List<CartItemModel> items);
  Future<void> clear();
}

class CartLocalDataSourceImpl implements CartLocalDataSource {
  CartLocalDataSourceImpl(this._storage);

  final LocalStorageService _storage;

  @override
  Future<List<CartItemModel>> getCartItems() async {
    try {
      final raw = _storage.getJsonList(StorageKeys.cartItems) ?? const [];
      return raw
          .map(CartItemModel.fromJson)
          .where((item) => item.product.isValid && item.quantity > 0)
          .toList();
    } catch (error) {
      throw CacheException(error.toString());
    }
  }

  @override
  Future<void> saveCartItems(List<CartItemModel> items) async {
    final saved = await _storage.setJsonList(
      StorageKeys.cartItems,
      items.map((item) => item.toJson()).toList(),
    );
    if (!saved) throw const CacheException('Could not save cart');
  }

  @override
  Future<void> clear() async {
    await _storage.remove(StorageKeys.cartItems);
  }
}
