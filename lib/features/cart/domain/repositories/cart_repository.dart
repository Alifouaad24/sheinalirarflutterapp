import 'package:dartz/dartz.dart';

import 'package:shein_cart_app/core/errors/failures.dart';
import 'package:shein_cart_app/features/cart/domain/entities/cart_item.dart';
import 'package:shein_cart_app/features/shop/domain/entities/product.dart';

/// Cart contract used by the presentation layer.
/// Every mutation returns the full, updated cart.
abstract interface class CartRepository {
  Future<Either<Failure, List<CartItem>>> getCartItems();
  Future<Either<Failure, List<CartItem>>> addProduct(Product product);
  Future<Either<Failure, List<CartItem>>> updateQuantity(String itemKey, int quantity);
  Future<Either<Failure, List<CartItem>>> removeItem(String itemKey);
  Future<Either<Failure, List<CartItem>>> clearCart();
    Future<Either<Failure, List<CartItem>>> addItems(List<CartItem> items);
}
