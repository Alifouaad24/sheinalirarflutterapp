import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shein_cart_app/core/config/app_config.dart';

import 'package:shein_cart_app/core/constants/app_dimens.dart';
import 'package:shein_cart_app/core/localization/locale_keys.dart';
import 'package:shein_cart_app/core/utils/currency_converter.dart';
import 'package:shein_cart_app/core/utils/price_formatter.dart';
import 'package:shein_cart_app/core/widgets/app_network_image.dart';
import 'package:shein_cart_app/features/cart/domain/entities/cart_item.dart';
import 'package:shein_cart_app/features/cart/presentation/widgets/quantity_selector.dart';

/// One cart line: image, title, variant, price, quantity stepper, remove.
class CartItemTile extends StatelessWidget {
  const CartItemTile({
    super.key,
    required this.item,
    required this.onIncrement,
    required this.onDecrement,
    required this.onRemove,
    this.onImageTap,
  });

  final CartItem item;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final VoidCallback onRemove;
  final VoidCallback? onImageTap;

  String? get _variantText {
    final product = item.product;
    final parts = [
      if (product.size != null) '${LocaleKeys.size.tr}: ${product.size}',
      if (product.color != null) '${LocaleKeys.color.tr}: ${product.color}',
    ];
    return parts.isEmpty ? null : parts.join('   ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final product = item.product;
    final variant = _variantText;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        boxShadow: AppShadows.subtle,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Thumbnail(
            url: product.imageUrl,
            imageCount: product.allImages.length,
            onTap: onImageTap,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          height: 1.4,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onRemove,
                      tooltip: LocaleKeys.remove.tr,
                      icon: const Icon(Icons.delete_outline_rounded, size: 20),
                      color: scheme.onSurfaceVariant,
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                if (variant != null)
                  Text(
                    variant,
                    style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                if (product.sku != null)
                  Text(
                    '${LocaleKeys.sku.tr}: ${product.sku}',
                    style: theme.textTheme.bodySmall?.copyWith(color: Colors.black),
                  ),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            PriceFormatter.format(
                              CurrencyConverter.convert(item.totalPrice, from: product.currency),
                              currency: AppConfig.displayCurrency,
                            ),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: scheme.primary,
                            ),
                          ),
                          if (CurrencyConverter.needsConversion(product.currency))
                            Text(
                              PriceFormatter.format(item.totalPrice, currency: product.currency),
                              style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                            ),
                        ],
                      ),
                    ),
                    QuantitySelector(
                      quantity: item.quantity,
                      onIncrement: onIncrement,
                      onDecrement: onDecrement,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Product photo with a photo-count badge; tap opens the full-screen gallery.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.url, required this.imageCount, this.onTap});

  final String? url;
  final int imageCount;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: imageCount > 0 ? onTap : null,
      child: Stack(
        children: [
          AppNetworkImage(
            url: url,
            width: AppSizes.cartThumbWidth,
            height: AppSizes.cartThumbHeight,
          ),
          if (imageCount > 1)
            PositionedDirectional(
              bottom: AppSpacing.xxs,
              start: AppSpacing.xxs,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.photo_library_outlined, size: 12, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      '$imageCount',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}