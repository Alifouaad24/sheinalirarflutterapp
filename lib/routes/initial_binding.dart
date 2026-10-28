import 'package:get/get.dart';

import 'package:shein_cart_app/core/network/api_client.dart';
import 'package:shein_cart_app/core/storage/local_storage_service.dart';
import 'package:shein_cart_app/features/cart/presentation/bindings/cart_binding.dart';

/// App-wide dependencies created once at startup (composition root).
/// LocalStorageService is already registered in main() before runApp.
class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put<ApiClient>(
      ApiClient(storage: Get.find<LocalStorageService>()),
      permanent: true,
    );

    // Cart is global: loaded on app start, badge visible on every screen.
    CartBinding().dependencies();
  }
}
