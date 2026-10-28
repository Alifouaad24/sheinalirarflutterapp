import 'package:shein_cart_app/features/shop/domain/entities/product.dart';
import 'package:shein_cart_app/features/shop/domain/utils/product_url_matcher.dart';

/// JSON-aware [Product]. Parsing is defensive because the data comes from
/// a third-party page that can change at any time.
class ProductModel extends Product {
  const ProductModel({
    required super.id,
    required super.title,
    required super.price,
    required super.url,
    super.currency,
    super.imageUrl,
    super.size,
    super.color,
    super.sku,
    super.images,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    final url = _string(json['url']) ?? '';
    final images = (json['images'] is List ? json['images'] as List : const [])
        .map(_imageUrl)
        .whereType<String>()
        .toSet() // remove duplicates
        .toList();
    final mainImage = _imageUrl(json['imageUrl']) ?? (images.isEmpty ? null : images.first);
    return ProductModel(
      id: _string(json['id']) ?? ProductUrlMatcher.extractId(url) ?? '',
      title: _string(json['title']) ?? '',
      price: _double(json['price']) ?? 0,
      currency: _string(json['currency']),
      imageUrl: mainImage,
      images: images,
      sku: _string(json['sku']),
      size: _string(json['size']),
      color: _string(json['color']),
      url: url,
    );
  }

  factory ProductModel.fromEntity(Product product) => product is ProductModel
      ? product
      : ProductModel(
          id: product.id,
          title: product.title,
          price: product.price,
          url: product.url,
          currency: product.currency,
          imageUrl: product.imageUrl,
          size: product.size,
          color: product.color,
          sku: product.sku,
          images: product.images,
        );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'price': price,
        'currency': currency,
        'imageUrl': imageUrl,
        'size': size,
        'color': color,
        'url': url,
        'sku': sku,
        'images': images,
      };

  /// Minimum data required to put the product in the cart.
  bool get isValid => id.isNotEmpty && title.isNotEmpty && price > 0;

  static String? _string(Object? value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isEmpty ? null : text;
  }

  /// Flutter's image decoders don't support AVIF; SHEIN's CDN serves the
  /// same picture as WebP when the extension is changed.
  static String? _imageUrl(Object? value) {
    var url = _string(value);
    if (url == null) return null;
    if (url.startsWith('//')) url = 'https:$url';
    return url.replaceFirst(RegExp(r'\.avif(?=$|[?#])', caseSensitive: false), '.webp');
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}