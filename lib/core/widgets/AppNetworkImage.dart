import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:shein_cart_app/core/constants/app_dimens.dart';

/// Rounded network image with loading and error placeholders.
class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.url,
    required this.width,
    required this.height,
    this.radius = AppRadius.md,
  });

  final String? url;
  final double width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final placeholder = Container(
      width: width,
      height: height,
      color: scheme.surfaceContainerHighest,
      alignment: Alignment.center,
      child: Icon(Icons.image_outlined, color: scheme.onSurfaceVariant),
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: (url == null || url!.isEmpty)
          ? placeholder
          : Image.network(
              url!,
              width: width,
              height: height,
              fit: BoxFit.cover,
              loadingBuilder: (_, child, progress) => progress == null ? child : placeholder,
              errorBuilder: (_, error, __) {
                if (kDebugMode) debugPrint('[AppNetworkImage] failed: $url -> $error');
                return placeholder;
              },
            ),
    );
  }
}