enum OrderStatus {
  pending,
  confirmed,
  shipped,
  completed,
  canceled,
  returned,
}

class Order {
  final String id;
  final String code; // 예: PO-2025-1001
  final int itemCount;
  final double total;
  final DateTime createdAt;
  final OrderStatus status;

  const Order({
    required this.id,
    required this.code,
    required this.itemCount,
    required this.total,
    required this.createdAt,
    required this.status,
  });
}
