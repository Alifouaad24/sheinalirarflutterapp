import 'package:get/get.dart';

import 'package:shein_cart_app/core/network/api_client.dart';
import 'package:shein_cart_app/features/orders/data/datasources/order_remote_data_source.dart';
import 'package:shein_cart_app/features/orders/data/repositories/order_repository_impl.dart';
import 'package:shein_cart_app/features/orders/domain/repositories/order_repository.dart';

/// EXAMPLE binding. Attach it to a GetPage (or call it from CartBinding when
/// checkout goes live) and inject OrderRepository into a controller.
class OrdersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OrderRemoteDataSource>(() => OrderRemoteDataSourceImpl(Get.find<ApiClient>()));
    Get.lazyPut<OrderRepository>(() => OrderRepositoryImpl(Get.find()));
  }
}
