import 'package:get/get.dart';

import 'package:shein_cart_app/features/cart/presentation/bindings/cart_binding.dart';
import 'package:shein_cart_app/features/cart/presentation/screens/cart_screen.dart';
import 'package:shein_cart_app/features/shop/presentation/bindings/shop_binding.dart';
import 'package:shein_cart_app/features/shop/presentation/screens/shop_screen.dart';
import 'package:shein_cart_app/routes/app_routes.dart';

abstract final class AppPages {
  static final List<GetPage<dynamic>> pages = [
    GetPage(
      name: AppRoutes.shop,
      page: () => const ShopScreen(),
      binding: ShopBinding(),
    ),
    GetPage(
      name: AppRoutes.cart,
      page: () => const CartScreen(),
      binding: CartBinding(),
    ),
  ];
}
