import 'dart:math';

import '../models/product.dart';
import '../models/order.dart';

// 목업 데이터 리포지토리: 실제 API 연동 전까지 임시 데이터 제공
class MockProductRepository {
  final _rnd = Random(2025);
  final _categories = ProductCategory.values;
  late final List<Product> _all = List.generate(40, (i) {
    final id = 'p_${i + 1}';
    final sku = 'SKU-${1000 + i}';
    final variants = 1 + _rnd.nextInt(5);
    final price = (_rnd.nextDouble() * 90) + 10; // 10~100
    final category = _categories[i % _categories.length];
    final lowStock = _rnd.nextBool() && _rnd.nextBool();
    return Product(
      id: id,
      sku: sku,
      name: 'Sample Product ${i + 1}',
      variantsCount: variants,
      price: double.parse(price.toStringAsFixed(2)),
      category: category,
      lowStock: lowStock,
    );
  });

  Future<List<Product>> fetch({String query = '', ProductCategory? category}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    Iterable<Product> result = _all;
    if (category != null) {
      result = result.where((p) => p.category == category);
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q));
    }
    return result.toList();
  }

  Future<Product?> findById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    try {
      return _all.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}

class MockOrderRepository {
  final _rnd = Random(2026);
  final _statuses = OrderStatus.values;
  late final List<Order> _all = List.generate(30, (i) {
    final id = 'o_${i + 1}';
    final code = 'PO-2025-${1001 + i}';
    final itemCount = 1 + _rnd.nextInt(8);
    final total = (_rnd.nextDouble() * 900) + 100; // 100~1000
    final status = _statuses[i % _statuses.length];
    return Order(
      id: id,
      code: code,
      itemCount: itemCount,
      total: double.parse(total.toStringAsFixed(2)),
      createdAt: DateTime.now().subtract(Duration(days: _rnd.nextInt(30))),
      status: status,
    );
  });

  Future<List<Order>> fetch({String query = '', OrderStatus? status}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    Iterable<Order> result = _all;
    if (status != null) {
      result = result.where((o) => o.status == status);
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((o) => o.code.toLowerCase().contains(q));
    }
    return result.toList();
  }

  Future<Order?> findById(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 160));
    try {
      return _all.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
}
