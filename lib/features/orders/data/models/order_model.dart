import 'package:shein_cart_app/features/orders/domain/entities/order.dart';

class OrderModel extends Order {
  const OrderModel({
    required super.id,
    required super.status,
    required super.total,
    super.currency,
    super.createdAt,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        id: json['id'].toString(),
        status: json['status']?.toString() ?? 'pending',
        total: (json['total'] as num?)?.toDouble() ?? 0,
        currency: json['currency'] as String?,
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
      );
}
