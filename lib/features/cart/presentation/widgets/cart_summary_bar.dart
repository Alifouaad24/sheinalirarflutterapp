import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shein_cart_app/core/constants/app_dimens.dart';
import 'package:shein_cart_app/core/localization/locale_keys.dart';
import 'package:shein_cart_app/core/widgets/primary_button.dart';

/// Bottom bar with the cart total and the checkout button.
class CartSummaryBar extends StatelessWidget {
  const CartSummaryBar({
    super.key,
    required this.totalText,
    required this.itemCount,
    required this.onCheckout,
    this.isLoading = false,
  });

  final String totalText;
  final int itemCount;
  final VoidCallback onCheckout;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        boxShadow: AppShadows.bottomBar,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.md, AppSpacing.sm, AppSpacing.md, AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(LocaleKeys.total.tr, style: theme.textTheme.titleMedium),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    LocaleKeys.itemsCount.trParams({'count': '$itemCount'}),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    totalText,
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              PrimaryButton(
                label: LocaleKeys.checkout.tr,
                icon: Icons.lock_outline_rounded,
                isLoading: isLoading,
                onPressed: onCheckout,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
