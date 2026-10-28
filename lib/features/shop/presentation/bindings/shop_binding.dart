import 'package:get/get.dart';
import 'package:shein_cart_app/features/shop/data/services/cart_page_extractor.dart';
import 'package:shein_cart_app/features/shop/data/services/product_extractor.dart';
import 'package:shein_cart_app/features/shop/presentation/controllers/shop_controller.dart';

class ShopBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ProductExtractor>(() => ProductExtractor());
 Get.lazyPut<CartPageExtractor>(() => CartPageExtractor());
    Get.lazyPut<ShopController>(
      () => ShopController(
        extractor: Get.find(),
        cartPageExtractor: Get.find(),
        cartController: Get.find(),
      ),
    );
  }
}
