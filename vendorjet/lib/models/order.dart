enum OrderStatus { pending, confirmed, shipped, completed, canceled, returned }

class Order {
  final String id;
  final String code; // POyymmdd####
  final int itemCount;
  final double total;
  final DateTime createdAt;
  final OrderStatus status;
  final String buyerName;
  final String buyerContact;
  final String? buyerNote;

  const Order({
    required this.id,
    required this.code,
    required this.itemCount,
    required this.total,
    required this.createdAt,
    required this.status,
    this.buyerName = '',
    this.buyerContact = '',
    this.buyerNote,
  });

  Order copyWith({
    String? id,
    String? code,
    int? itemCount,
    double? total,
    DateTime? createdAt,
    OrderStatus? status,
    String? buyerName,
    String? buyerContact,
    String? buyerNote,
  }) {
    return Order(
      id: id ?? this.id,
      code: code ?? this.code,
      itemCount: itemCount ?? this.itemCount,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      buyerName: buyerName ?? this.buyerName,
      buyerContact: buyerContact ?? this.buyerContact,
      buyerNote: buyerNote ?? this.buyerNote,
    );
  }
}
