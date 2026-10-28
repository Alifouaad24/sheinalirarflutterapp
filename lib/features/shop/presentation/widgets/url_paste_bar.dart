import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:shein_cart_app/core/constants/app_dimens.dart';
import 'package:shein_cart_app/core/localization/locale_keys.dart';
import 'package:shein_cart_app/features/shop/presentation/controllers/shop_controller.dart';

class UrlPasteBar extends GetView<ShopController> implements PreferredSizeWidget {
  const UrlPasteBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final textController = controller.urlTextController;

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.xs),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: textController,
              textDirection: TextDirection.ltr,
              keyboardType: TextInputType.url,
              textInputAction: TextInputAction.go,
              autocorrect: false,
              onSubmitted: controller.openPastedUrl,
              decoration: InputDecoration(
                isDense: true,
                hintText: LocaleKeys.pasteUrlHint.tr,
                hintTextDirection: Directionality.of(context),
                prefixIcon: const Icon(Icons.link_rounded, size: 20),
                suffixIcon: ValueListenableBuilder<TextEditingValue>(
                  valueListenable: textController,
                  builder: (_, value, __) => value.text.isEmpty
                      ? IconButton(
                          tooltip: LocaleKeys.paste.tr,
                          icon: const Icon(Icons.content_paste_rounded, size: 20),
                          onPressed: controller.pasteFromClipboard,
                        )
                      : IconButton(
                          tooltip: LocaleKeys.clearText.tr,
                          icon: const Icon(Icons.close_rounded, size: 20),
                          onPressed: textController.clear,
                        ),
                ),
                filled: true,
                fillColor: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
          FilledButton(
            onPressed: () => controller.openPastedUrl(),
            style: FilledButton.styleFrom(
              minimumSize: const Size(64, 44),
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            ),
            child: Text(LocaleKeys.go.tr),
          ),
        ],
      ),
    );
  }
}