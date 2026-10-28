import 'package:shein_cart_app/features/shop/domain/entities/product.dart';

/// One line in the cart: a product variant and its quantity.
class CartItem {
  const CartItem({
    required this.product,
    required this.quantity,
    required this.addedAt,
  });

  final Product product;
  final int quantity;
  final DateTime addedAt;

  /// Unique per product + size + color.
  String get key => product.variantKey;

  double get totalPrice => product.price * quantity;

  CartItem copyWith({int? quantity}) => CartItem(
        product: product,
        quantity: quantity ?? this.quantity,
        addedAt: addedAt,
      );
}
