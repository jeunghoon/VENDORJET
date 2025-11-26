import 'package:intl/intl.dart';
import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/services/api/api_client.dart';

class OrderRepository {
  OrderRepository._internal();

  static final OrderRepository _instance = OrderRepository._internal();

  factory OrderRepository() => _instance;

  Future<List<Order>> fetch({
    String query = '',
    OrderStatus? status,
    bool openOnly = false,
    DateTime? dateEquals,
  }) async {
    final data = await ApiClient.get('/orders', query: {
      'q': query,
      'status': status?.name,
      'openOnly': openOnly ? 'true' : null,
      'date': dateEquals != null ? DateFormat('yyyy-MM-dd').format(dateEquals) : null,
    }) as List<dynamic>;
    final orders = data.map((e) => _orderFromJson(e as Map<String, dynamic>)).toList();
    return orders..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Order?> findById(String id) async {
    try {
      final data = await ApiClient.get('/orders/$id') as Map<String, dynamic>;
      return _orderFromJson(data);
    } catch (_) {
      return null;
    }
  }

  Future<Order> save(Order order) async {
    if (order.id.isEmpty) {
      final resp = await ApiClient.post('/orders', body: {
        'buyerName': order.buyerName,
        'buyerContact': order.buyerContact,
        'buyerNote': order.buyerNote,
        'desiredDeliveryDate': order.desiredDeliveryDate?.toIso8601String(),
        'items': order.lines
            .map((l) => {
                  'productId': l.productId,
                  'productName': l.productName,
                  'quantity': l.quantity,
                  'unitPrice': l.unitPrice,
                })
            .toList(),
      }) as Map<String, dynamic>;
      return _orderFromJson(resp);
    } else {
      await ApiClient.patch('/orders/${order.id}', body: {
        'status': order.status.name,
        'buyerNote': order.buyerNote,
        'updateNote': order.updateNote,
        'desiredDeliveryDate': order.desiredDeliveryDate?.toIso8601String(),
        'lines': order.lines
            .map((l) => {
                  'productId': l.productId,
                  'productName': l.productName,
                  'quantity': l.quantity,
                  'unitPrice': l.unitPrice,
                })
            .toList(),
        'total': order.total,
        'itemCount': order.itemCount,
      });
      return await findById(order.id) ?? order;
    }
  }

  Future<void> delete(String id) async {
    await ApiClient.delete('/orders/$id');
  }
}

Order _orderFromJson(Map<String, dynamic> json) {
  final events = (json['events'] as List<dynamic>? ?? [])
      .map((e) => _orderEventFromJson(e as Map<String, dynamic>))
      .toList();
  final lines = (json['lines'] as List<dynamic>? ?? [])
      .map((l) => _orderLineFromJson(l as Map<String, dynamic>))
      .toList();
  final itemCount = json['itemCount'] ?? json['item_count'] ?? _calcItemCount(lines);
  return Order(
    id: json['id'] as String? ?? '',
    code: json['code'] as String? ?? '',
    itemCount: itemCount is int ? itemCount : int.tryParse(itemCount.toString()) ?? 0,
    total: (json['total'] as num?)?.toDouble() ?? 0,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
    status: _statusFromString(json['status'] as String?),
    buyerName: json['buyerName'] as String? ?? json['buyer_name'] as String? ?? '',
    buyerContact: json['buyerContact'] as String? ?? json['buyer_contact'] as String? ?? '',
    buyerNote: json['buyerNote'] as String? ?? json['buyer_note'] as String?,
    createdSource: json['createdSource'] as String? ?? json['created_source'] as String?,
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? json['updated_at'] as String? ?? ''),
    createdBy: json['createdBy'] as String? ?? json['created_by'] as String?,
    updatedBy: json['updatedBy'] as String? ?? json['updated_by'] as String?,
    statusUpdatedBy: json['statusUpdatedBy'] as String? ?? json['status_updated_by'] as String?,
    statusUpdatedAt: DateTime.tryParse(
      json['statusUpdatedAt'] as String? ?? json['status_updated_at'] as String? ?? '',
    ),
    updateNote: json['updateNote'] as String? ?? json['update_note'] as String?,
    lines: lines,
    events: events,
    desiredDeliveryDate: DateTime.tryParse(
      json['desiredDeliveryDate'] as String? ?? json['desired_delivery_date'] as String? ?? '',
    ),
  );
}

OrderLine _orderLineFromJson(Map<String, dynamic> json) {
  return OrderLine(
    productId: json['productId'] as String? ?? json['product_id'] as String? ?? '',
    productName: json['productName'] as String? ?? json['product_name'] as String? ?? '',
    quantity: (json['quantity'] as num?)?.toInt() ?? 0,
    unitPrice: (json['unitPrice'] as num?)?.toDouble() ?? 0,
  );
}

OrderStatus _statusFromString(String? value) {
  return OrderStatus.values.firstWhere(
    (s) => s.name == value,
    orElse: () => OrderStatus.pending,
  );
}

OrderEvent _orderEventFromJson(Map<String, dynamic> json) {
  return OrderEvent(
    action: json['action'] as String? ?? '',
    actor: json['actor'] as String? ?? '',
    note: json['note'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? json['created_at'] as String? ?? '') ??
        DateTime.now(),
  );
}

int _calcItemCount(List<OrderLine> lines) => lines.fold(0, (sum, l) => sum + l.quantity);
