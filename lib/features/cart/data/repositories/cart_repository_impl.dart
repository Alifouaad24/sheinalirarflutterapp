import 'package:dartz/dartz.dart';

import 'package:shein_cart_app/core/config/app_config.dart';
import 'package:shein_cart_app/core/errors/exceptions.dart';
import 'package:shein_cart_app/core/errors/failures.dart';
import 'package:shein_cart_app/features/cart/data/datasources/cart_local_data_source.dart';
import 'package:shein_cart_app/features/cart/data/models/cart_item_model.dart';
import 'package:shein_cart_app/features/cart/domain/entities/cart_item.dart';
import 'package:shein_cart_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:shein_cart_app/features/shop/data/models/product_model.dart';
import 'package:shein_cart_app/features/shop/domain/entities/product.dart';

/// Cart business rules (merge identical variants, quantity bounds) on top of
/// the local data source. A remote data source can be added later without
/// changing the controller.
class CartRepositoryImpl implements CartRepository {
  CartRepositoryImpl(this._local);

  final CartLocalDataSource _local;

  @override
  Future<Either<Failure, List<CartItem>>> getCartItems() =>
      _guard(_local.getCartItems);

  @override
  Future<Either<Failure, List<CartItem>>> addProduct(Product product) =>
      _guard(() async {
        final items = await _local.getCartItems();
        final newItem = CartItemModel(
          product: ProductModel.fromEntity(product),
          quantity: 1,
          addedAt: DateTime.now(),
        );

        final index = items.indexWhere((item) => item.key == newItem.key);
        if (index >= 0) {
          final current = items[index];
          final quantity = (current.quantity + 1)
              .clamp(1, AppConfig.maxQuantityPerItem)
              .toInt();
          items[index] = current.copyWith(quantity: quantity);
        } else {
          items.insert(0, newItem); // newest first
        }

        await _local.saveCartItems(items);
        return items;
      });

  @override
  Future<Either<Failure, List<CartItem>>> updateQuantity(
          String itemKey, int quantity) =>
      _guard(() async {
        final items = await _local.getCartItems();
        if (quantity <= 0) {
          items.removeWhere((item) => item.key == itemKey);
        } else {
          final index = items.indexWhere((item) => item.key == itemKey);
          if (index >= 0) {
            items[index] = items[index].copyWith(
              quantity: quantity.clamp(1, AppConfig.maxQuantityPerItem).toInt(),
            );
          }
        }
        await _local.saveCartItems(items);
        return items;
      });

  @override
  Future<Either<Failure, List<CartItem>>> removeItem(String itemKey) =>
      _guard(() async {
        final items = await _local.getCartItems();
        items.removeWhere((item) => item.key == itemKey);
        await _local.saveCartItems(items);
        return items;
      });

  @override
  Future<Either<Failure, List<CartItem>>> clearCart() => _guard(() async {
        await _local.clear();
        return <CartItemModel>[];
      });

  /// Converts data-layer exceptions into Failures.
  Future<Either<Failure, List<CartItem>>> _guard(
    Future<List<CartItemModel>> Function() action,
  ) async {
    try {
      return Right(await action());
    } on CacheException {
      return const Left(CacheFailure());
    } catch (error) {
      return Left(UnknownFailure(error: error));
    }
  }

  @override
  Future<Either<Failure, List<CartItem>>> addItems(List<CartItem> newItems) =>
      _guard(() async {
        final items = await _local.getCartItems();
        for (final incoming in newItems.map(CartItemModel.fromEntity)) {
          final index = items.indexWhere((item) => item.key == incoming.key);
          if (index >= 0) {
            final quantity = (items[index].quantity + incoming.quantity)
                .clamp(1, AppConfig.maxQuantityPerItem)
                .toInt();
            items[index] = items[index].copyWith(quantity: quantity);
          } else {
            items.insert(0, incoming);
          }
        }
        await _local.saveCartItems(items);
        return items;
      });
}
