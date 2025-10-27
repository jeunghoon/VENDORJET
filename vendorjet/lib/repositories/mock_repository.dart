import 'dart:math';

import '../models/product.dart';
import '../models/order.dart';

// 목업 데이터 리포지토리: 실제 API 연동 전까지 임시 데이터 제공
class MockProductRepository {
  final _rnd = Random(2025);
  late final List<Product> _all = List.generate(40, (i) {
    final id = 'p_${i + 1}';
    final sku = 'SKU-${1000 + i}';
    final variants = 1 + _rnd.nextInt(5);
    final price = (_rnd.nextDouble() * 90) + 10; // 10~100
    return Product(
      id: id,
      sku: sku,
      name: 'Sample Product ${i + 1}',
      variantsCount: variants,
      price: double.parse(price.toStringAsFixed(2)),
    );
  });

  Future<List<Product>> fetch({String query = ''}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (query.isEmpty) return _all;
    final q = query.toLowerCase();
    return _all
        .where((p) => p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q))
        .toList();
  }
}

class MockOrderRepository {
  final _rnd = Random(2026);
  late final List<Order> _all = List.generate(30, (i) {
    final id = 'o_${i + 1}';
    final code = 'PO-2025-${1001 + i}';
    final itemCount = 1 + _rnd.nextInt(8);
    final total = (_rnd.nextDouble() * 900) + 100; // 100~1000
    return Order(
      id: id,
      code: code,
      itemCount: itemCount,
      total: double.parse(total.toStringAsFixed(2)),
      createdAt: DateTime.now().subtract(Duration(days: _rnd.nextInt(30))),
    );
  });

  Future<List<Order>> fetch({String query = ''}) async {
    await Future<void>.delayed(const Duration(milliseconds: 180));
    if (query.isEmpty) return _all;
    final q = query.toLowerCase();
    return _all.where((o) => o.code.toLowerCase().contains(q)).toList();
  }
}

