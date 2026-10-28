import 'package:dartz/dartz.dart' hide Order;

import 'package:shein_cart_app/core/errors/failures.dart';
import 'package:shein_cart_app/features/cart/domain/entities/cart_item.dart';
import 'package:shein_cart_app/features/orders/domain/entities/order.dart';

/// EXAMPLE: the contract the presentation layer depends on.
abstract interface class OrderRepository {
  Future<Either<Failure, Order>> createOrder(List<CartItem> items);
  Future<Either<Failure, List<Order>>> getOrders();
}
