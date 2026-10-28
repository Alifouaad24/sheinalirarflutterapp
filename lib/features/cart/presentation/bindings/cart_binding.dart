import 'package:get/get.dart';

import 'package:shein_cart_app/core/storage/local_storage_service.dart';
import 'package:shein_cart_app/features/cart/data/datasources/cart_local_data_source.dart';
import 'package:shein_cart_app/features/cart/data/repositories/cart_repository_impl.dart';
import 'package:shein_cart_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:shein_cart_app/features/cart/presentation/controllers/cart_controller.dart';

/// Registers the cart stack: LocalDataSource → Repository → Controller.
///
/// Used by InitialBinding (so the cart loads at startup and the badge works
/// everywhere) and by the cart route. Registration is idempotent.
class CartBinding extends Bindings {
  @override
  void dependencies() {
    if (!Get.isRegistered<CartLocalDataSource>()) {
      Get.put<CartLocalDataSource>(
        CartLocalDataSourceImpl(Get.find<LocalStorageService>()),
        permanent: true,
      );
    }
    if (!Get.isRegistered<CartRepository>()) {
      Get.put<CartRepository>(CartRepositoryImpl(Get.find()), permanent: true);
    }
    if (!Get.isRegistered<CartController>()) {
      Get.put<CartController>(CartController(repository: Get.find()), permanent: true);
    }
  }
}
