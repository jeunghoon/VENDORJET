class Order {
  final String id;
  final String code; // 예: PO-2025-1001
  final int itemCount;
  final double total;
  final DateTime createdAt;

  const Order({
    required this.id,
    required this.code,
    required this.itemCount,
    required this.total,
    required this.createdAt,
  });
}

