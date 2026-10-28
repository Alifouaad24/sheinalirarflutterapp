import 'package:dartz/dartz.dart' hide Order;
import 'package:shein_cart_app/core/utils/currency_converter.dart';
import 'package:shein_cart_app/core/errors/failures.dart';
import 'package:shein_cart_app/features/cart/domain/entities/cart_item.dart';
import 'package:shein_cart_app/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:shein_cart_app/features/orders/domain/entities/order.dart';
import 'package:shein_cart_app/features/orders/domain/repositories/order_repository.dart';

/// EXAMPLE repository: maps domain objects to request bodies and passes the
/// Either from the data source through. Add caching/offline logic here.
class OrderRepositoryImpl implements OrderRepository {
  OrderRepositoryImpl(this._remote);

  final OrderRemoteDataSource _remote;

  @override
  Future<Either<Failure, Order>> createOrder(List<CartItem> items) {
    return _remote.createOrder({
      'items': items
          .map((item) => {
                'product_id': item.product.id,
                'title': item.product.title,
                'sku': item.product.sku,
                'price': item.product.price,
                'currency': item.product.currency,
                'size': item.product.size,
                'color': item.product.color,
                'image_url': item.product.imageUrl,
                'product_url': item.product.url,
                'images': item.product.images,
                'quantity': item.quantity,
                'price_usd': double.parse(
                  CurrencyConverter.convert(item.product.price, from: item.product.currency, to: 'USD')
                      .toStringAsFixed(2),
                ),  
              })
          .toList(),
    });
  }

  @override
  Future<Either<Failure, List<Order>>> getOrders() => _remote.fetchOrders();
}
