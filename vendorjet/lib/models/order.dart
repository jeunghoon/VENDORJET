enum OrderStatus { pending, confirmed, shipped, completed, canceled, returned }

class OrderEvent {
  final String action;
  final String actor;
  final String? note;
  final DateTime createdAt;

  const OrderEvent({
    required this.action,
    required this.actor,
    required this.createdAt,
    this.note,
  });
}

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
  final int? _lineCount;
  final double total;
  final DateTime createdAt;
  final OrderStatus status;
  final String buyerName;
  final String buyerContact;
  final String? buyerNote;
  final String? buyerTenantId;
  final String? buyerUserId;
  final String? buyerUserName;
  final String? buyerUserEmail;
  final String? createdSource;
  final DateTime? updatedAt;
  final String? createdBy;
  final String? updatedBy;
  final String? statusUpdatedBy;
  final DateTime? statusUpdatedAt;
  final String? updateNote;
  final List<OrderLine> lines;
  final List<OrderEvent> events;
  final DateTime? desiredDeliveryDate;

  const Order({
    required this.id,
    required this.code,
    required this.itemCount,
    int? lineCount,
    required this.total,
    required this.createdAt,
    required this.status,
    this.buyerName = '',
    this.buyerContact = '',
    this.buyerNote,
    this.buyerTenantId,
    this.buyerUserId,
    this.buyerUserName,
    this.buyerUserEmail,
    this.createdSource,
    this.updatedAt,
    this.createdBy,
    this.updatedBy,
    this.statusUpdatedBy,
    this.statusUpdatedAt,
    this.updateNote,
    this.lines = const [],
    this.events = const [],
    this.desiredDeliveryDate,
  }) : _lineCount = lineCount;

  Order copyWith({
    String? id,
    String? code,
    int? itemCount,
    int? lineCount,
    double? total,
    DateTime? createdAt,
    OrderStatus? status,
    String? buyerName,
    String? buyerContact,
    String? buyerNote,
    String? buyerTenantId,
    String? buyerUserId,
    String? buyerUserName,
    String? buyerUserEmail,
    String? createdSource,
    DateTime? updatedAt,
    String? createdBy,
    String? updatedBy,
    String? statusUpdatedBy,
    DateTime? statusUpdatedAt,
    String? updateNote,
    List<OrderLine>? lines,
    List<OrderEvent>? events,
    DateTime? desiredDeliveryDate,
  }) {
    final nextLines = lines ?? this.lines;
    final nextLineCount = lineCount ??
        (identical(nextLines, this.lines) ? this.lineCount : nextLines.length);
    return Order(
      id: id ?? this.id,
      code: code ?? this.code,
      itemCount: itemCount ?? this.itemCount,
      lineCount: nextLineCount,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
      status: status ?? this.status,
      buyerName: buyerName ?? this.buyerName,
      buyerContact: buyerContact ?? this.buyerContact,
      buyerNote: buyerNote ?? this.buyerNote,
      buyerTenantId: buyerTenantId ?? this.buyerTenantId,
      buyerUserId: buyerUserId ?? this.buyerUserId,
      buyerUserName: buyerUserName ?? this.buyerUserName,
      buyerUserEmail: buyerUserEmail ?? this.buyerUserEmail,
      createdSource: createdSource ?? this.createdSource,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
      updatedBy: updatedBy ?? this.updatedBy,
      statusUpdatedBy: statusUpdatedBy ?? this.statusUpdatedBy,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      updateNote: updateNote ?? this.updateNote,
      lines: nextLines,
      events: events ?? this.events,
      desiredDeliveryDate: desiredDeliveryDate ?? this.desiredDeliveryDate,
    );
  }

  int get lineCount => _lineCount ?? lines.length;

  int get displayLineCount => lineCount > 0 ? lineCount : lines.length;
}
