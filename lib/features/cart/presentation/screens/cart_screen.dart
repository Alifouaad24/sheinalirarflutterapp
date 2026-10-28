import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shein_cart_app/core/constants/app_dimens.dart';
import 'package:shein_cart_app/core/localization/locale_keys.dart';
import 'package:shein_cart_app/core/utils/price_formatter.dart';
import 'package:shein_cart_app/core/widgets/empty_state.dart';
import 'package:shein_cart_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:shein_cart_app/features/cart/presentation/widgets/cart_item_tile.dart';
import 'package:shein_cart_app/features/cart/presentation/widgets/cart_summary_bar.dart';

class CartScreen extends GetView<CartController> {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(LocaleKeys.cart.tr),
        actions: [
          Obx(
            () => controller.isEmpty
                ? const SizedBox.shrink()
                : IconButton(
                    tooltip: LocaleKeys.clearCart.tr,
                    icon: const Icon(Icons.delete_sweep_outlined),
                    onPressed: _confirmClear,
                  ),
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }
        if (controller.isEmpty) {
          return EmptyState(
            icon: Icons.shopping_bag_outlined,
            title: LocaleKeys.cartEmptyTitle.tr,
            subtitle: LocaleKeys.cartEmptySubtitle.tr,
            actionLabel: LocaleKeys.continueShopping.tr,
            onAction: () => Get.back(),
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: controller.items.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, index) {
            final item = controller.items[index];
            return CartItemTile(
              key: ValueKey(item.key),
              item: item,
              onIncrement: () => controller.increment(item),
              onDecrement: () => controller.decrement(item),
              onRemove: () => controller.remove(item),
              onImageTap: () => controller.openGallery(item),
            );
          },
        );
      }),
      bottomNavigationBar: Obx(
        () => controller.isEmpty
            ? const SizedBox.shrink()
            : CartSummaryBar(
                totalText: PriceFormatter.format(
                  controller.totalPrice,
                  currency: controller.currency,
                ),
                itemCount: controller.totalQuantity,
                isLoading: controller.isCheckingOut.value,
                onCheckout: controller.checkout,
              ),
      ),
    );
  }

  Future<void> _confirmClear() async {
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: Text(LocaleKeys.clearCart.tr),
        content: Text(LocaleKeys.clearCartConfirm.tr),
        actions: [
          TextButton(
            onPressed: () => Get.back(result: false),
            child: Text(LocaleKeys.cancel.tr),
          ),
          TextButton(
            onPressed: () => Get.back(result: true),
            child: Text(LocaleKeys.confirm.tr),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await controller.clearCart();
  }
}
