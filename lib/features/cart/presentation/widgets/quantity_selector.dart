import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shein_cart_app/core/constants/app_dimens.dart';
import 'package:shein_cart_app/core/localization/locale_keys.dart';

/// Compact "−  2  +" stepper.
class QuantitySelector extends StatelessWidget {
  const QuantitySelector({
    super.key,
    required this.quantity,
    this.onIncrement,
    this.onDecrement,
  });

  final int quantity;
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _StepButton(
            icon: Icons.remove_rounded,
            tooltip: LocaleKeys.decreaseQuantity.tr,
            onPressed: quantity > 1 ? onDecrement : null,
          ),
          SizedBox(
            width: 28,
            child: Text(
              '$quantity',
              textAlign: TextAlign.center,
              style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
          ),
          _StepButton(
            icon: Icons.add_rounded,
            tooltip: LocaleKeys.increaseQuantity.tr,
            onPressed: onIncrement,
          ),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.tooltip, this.onPressed});

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(icon, size: 18),
      tooltip: tooltip,
      onPressed: onPressed,
      visualDensity: VisualDensity.compact,
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: EdgeInsets.zero,
    );
  }
}
