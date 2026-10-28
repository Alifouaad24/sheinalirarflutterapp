import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shein_cart_app/core/constants/app_dimens.dart';
import 'package:shein_cart_app/core/localization/locale_keys.dart';
import 'package:shein_cart_app/core/widgets/primary_button.dart';
import 'package:shein_cart_app/features/shop/presentation/controllers/shop_controller.dart';

/// Area under the WebView holding the app's own "Add to cart" button.
class AddToCartPanel extends GetView<ShopController> {
  const AddToCartPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: AppShadows.bottomBar,
      ),
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
          child: Obx(() {
            final isProductPage = controller.isProductPage.value;
            
            if (!isProductPage && controller.isCartPage.value) {
              final count = controller.cartPageItemCount.value;
              return PrimaryButton(
                label: count > 0
                    ? LocaleKeys.importCart.trParams({'count': '$count'})
                    : LocaleKeys.importCartPlain.tr,
                icon: Icons.playlist_add_rounded,
                isLoading: controller.isImportingCart.value,
                onPressed: controller.importCurrentCart,
              );
            }
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                PrimaryButton(
                  label: LocaleKeys.addToCart.tr,
                  icon: Icons.add_shopping_cart_rounded,
                  isLoading: controller.isAddingToCart.value,
                  onPressed: isProductPage ? controller.addCurrentProductToCart : null,
                ),
                AnimatedSize(
                  duration: const Duration(milliseconds: 200),
                  child: isProductPage
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.only(top: AppSpacing.xs),
                          child: Text(
                            LocaleKeys.openProductHint.tr,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
