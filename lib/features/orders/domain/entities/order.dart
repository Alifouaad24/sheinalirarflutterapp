/// EXAMPLE FEATURE — skeleton showing how API-backed features are built.
class Order {
  const Order({
    required this.id,
    required this.status,
    required this.total,
    this.currency,
    this.createdAt,
  });

  final String id;
  final String status;
  final double total;
  final String? currency;
  final DateTime? createdAt;
}
