import 'package:shein_cart_app/features/cart/domain/entities/cart_item.dart';
import 'package:shein_cart_app/features/shop/data/models/product_model.dart';

class CartItemModel extends CartItem {
  const CartItemModel({
    required ProductModel super.product,
    required super.quantity,
    required super.addedAt,
  });

  factory CartItemModel.fromJson(Map<String, dynamic> json) {
    final product = json['product'];
    return CartItemModel(
      product: ProductModel.fromJson(
        product is Map ? Map<String, dynamic>.from(product) : const {},
      ),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      addedAt: DateTime.tryParse(json['addedAt']?.toString() ?? '') ?? DateTime.now(),
    );
  }

  factory CartItemModel.fromEntity(CartItem item) => item is CartItemModel
      ? item
      : CartItemModel(
          product: ProductModel.fromEntity(item.product),
          quantity: item.quantity,
          addedAt: item.addedAt,
        );

  @override
  ProductModel get product => super.product as ProductModel;

  Map<String, dynamic> toJson() => {
        'product': product.toJson(),
        'quantity': quantity,
        'addedAt': addedAt.toIso8601String(),
      };

  @override
  CartItemModel copyWith({int? quantity}) => CartItemModel(
        product: product,
        quantity: quantity ?? this.quantity,
        addedAt: addedAt,
      );
}
