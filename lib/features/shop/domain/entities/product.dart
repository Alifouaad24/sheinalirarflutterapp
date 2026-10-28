/// A product picked from a SHEIN product page.
class Product {
  const Product({
    required this.id,
    required this.title,
    required this.price,
    required this.url,
    this.currency,
    this.imageUrl,
    this.size,
    this.color,
    this.sku,
    this.images = const [],
  });

  final String id;
  final String title;
  final double price;
  final String? currency;
  final String? imageUrl;
  final String? size;
  final String? color;
  final String url;

  /// SHEIN SKU (goods_sn), e.g. "sw2208123456789".
  final String? sku;

  /// All gallery images of the product (main image first).
  final List<String> images;

  /// Images to show in the gallery, falling back to the main image.
  List<String> get allImages =>
      images.isNotEmpty ? images : [if (imageUrl != null) imageUrl!];

  /// Same product in a different size/color is a different cart line.
  String get variantKey => [id, size ?? '', color ?? ''].join('|').toLowerCase();
}