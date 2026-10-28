import 'package:dartz/dartz.dart';

import 'package:shein_cart_app/core/errors/failures.dart';
import 'package:shein_cart_app/core/network/api_client.dart';
import 'package:shein_cart_app/features/orders/data/models/order_model.dart';

/// EXAMPLE remote data source.
///
/// It only knows HTTP paths and JSON shapes; [ApiClient] already handles
/// headers, auth token, timeouts and error mapping, and returns Either.
abstract interface class OrderRemoteDataSource {
  Future<Either<Failure, OrderModel>> createOrder(Map<String, dynamic> body);
  Future<Either<Failure, List<OrderModel>>> fetchOrders();
}

class OrderRemoteDataSourceImpl implements OrderRemoteDataSource {
  OrderRemoteDataSourceImpl(this._api);

  final ApiClient _api;

  // TODO: move to ApiEndpoints (e.g. ApiEndpoints.orders) once the API exists.
  static const String _ordersPath = '/orders';

  @override
  Future<Either<Failure, OrderModel>> createOrder(Map<String, dynamic> body) {
    return _api.post<OrderModel>(
      _ordersPath,
      body: body,
      decoder: (json) => OrderModel.fromJson(_unwrap(json) as Map<String, dynamic>),
    );
  }

  @override
  Future<Either<Failure, List<OrderModel>>> fetchOrders() {
    return _api.get<List<OrderModel>>(
      _ordersPath,
      decoder: (json) => (_unwrap(json) as List)
          .map((item) => OrderModel.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  /// Many APIs wrap payloads as `{"data": ...}`; adjust to the real backend.
  static dynamic _unwrap(dynamic json) =>
      json is Map<String, dynamic> && json.containsKey('data') ? json['data'] : json;
}
