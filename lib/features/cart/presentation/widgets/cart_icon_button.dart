import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shein_cart_app/core/localization/locale_keys.dart';
import 'package:shein_cart_app/features/cart/presentation/controllers/cart_controller.dart';

/// App bar cart icon with a live item-count badge.
class CartIconButton extends GetView<CartController> {
  const CartIconButton({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final count = controller.totalQuantity;
      return IconButton(
        tooltip: LocaleKeys.cart.tr,
        onPressed: onPressed,
        icon: Badge(
          isLabelVisible: count > 0,
          label: Text(count > 99 ? '99+' : '$count'),
          child: const Icon(Icons.shopping_bag_outlined),
        ),
      );
    });
  }
}
