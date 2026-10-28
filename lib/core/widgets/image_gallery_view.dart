import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import 'package:shein_cart_app/core/constants/app_dimens.dart';
import 'package:shein_cart_app/core/localization/locale_keys.dart';

/// Full-screen image viewer: swipe between images, pinch to zoom,
/// thumbnail strip at the bottom.
class ImageGalleryView extends StatefulWidget {
  const ImageGalleryView({super.key, required this.images, this.initialIndex = 0});

  final List<String> images;
  final int initialIndex;

  /// Opens the gallery as a full-screen page.
  static Future<void>? open(List<String> images, {int initialIndex = 0}) {
    if (images.isEmpty) return null;
    return Get.to<void>(
      () => ImageGalleryView(images: images, initialIndex: initialIndex),
      fullscreenDialog: true,
      transition: Transition.fadeIn,
    );
  }

  @override
  State<ImageGalleryView> createState() => _ImageGalleryViewState();
}

class _ImageGalleryViewState extends State<ImageGalleryView> {
  late final PageController _pageController;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.images.length - 1).toInt();
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goTo(int index) => _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );

  @override
  Widget build(BuildContext context) {
    final images = widget.images;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Swipeable, zoomable images.
            PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (i) => setState(() => _index = i),
              itemBuilder: (_, i) => InteractiveViewer(
                minScale: 1,
                maxScale: 4,
                child: Center(
                  child: Image.network(
                    images[i],
                    fit: BoxFit.contain,
                    loadingBuilder: (_, child, progress) => progress == null
                        ? child
                        : const CircularProgressIndicator(color: Colors.white),
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white54,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),

            // Top bar: close + counter.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xs),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: LocaleKeys.close.tr,
                      onPressed: () => Get.back(),
                      icon: const Icon(Icons.close_rounded, color: Colors.white),
                    ),
                    const Spacer(),
                    if (images.length > 1)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xxs,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          '${_index + 1} / ${images.length}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                        ),
                      ),
                    const SizedBox(width: AppSpacing.xs),
                  ],
                ),
              ),
            ),

            // Thumbnails.
            if (images.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: SafeArea(
                  top: false,
                  child: SizedBox(
                    height: 72,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.xs,
                      ),
                      itemCount: images.length,
                      separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs),
                      itemBuilder: (_, i) => GestureDetector(
                        onTap: () => _goTo(i),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 48,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            border: Border.all(
                              color: i == _index ? Colors.white : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(AppRadius.sm - 2),
                            child: Opacity(
                              opacity: i == _index ? 1 : 0.55,
                              child: Image.network(
                                images[i],
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const ColoredBox(color: Colors.white10),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}