enum OrderStatus { pending, confirmed, shipped, completed, canceled, returned }

class OrderLine {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  const OrderLine({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  double get lineTotal => unitPrice * quantity;

  OrderLine copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
  }) {
    return OrderLine(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
    );
  }
}

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
  final DateTime? updatedAt;
  final String? updateNote;
  final List<OrderLine> lines;
  final DateTime? desiredDeliveryDate;

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
    this.updatedAt,
    this.updateNote,
    this.lines = const [],
    this.desiredDeliveryDate,
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
    DateTime? updatedAt,
    String? updateNote,
    List<OrderLine>? lines,
    DateTime? desiredDeliveryDate,
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
      updatedAt: updatedAt ?? this.updatedAt,
      updateNote: updateNote ?? this.updateNote,
      lines: lines ?? this.lines,
      desiredDeliveryDate: desiredDeliveryDate ?? this.desiredDeliveryDate,
    );
  }
}
