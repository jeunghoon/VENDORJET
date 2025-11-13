import 'dart:math';

import '../models/customer.dart';
import '../models/order.dart';
import '../models/product.dart';

class MockProductRepository {
  MockProductRepository._internal();

  static final MockProductRepository _instance =
      MockProductRepository._internal();

  factory MockProductRepository() => _instance;

  final _rnd = Random(2025);
  final _categories = ProductCategory.values;
  final List<Product> _items = [];
  final _idCounter = _IdCounter(prefix: 'p_');

  void _seed() {
    if (_items.isNotEmpty) return;
    for (var i = 0; i < 40; i++) {
      final id = 'p_${i + 1}';
      final sku = 'SKU-${1000 + i}';
      final variants = 1 + _rnd.nextInt(5);
      final price = (_rnd.nextDouble() * 90) + 10; // 10~100
      final category = _categories[i % _categories.length];
      final lowStock = _rnd.nextBool() && _rnd.nextBool();
      _items.add(
        Product(
          id: id,
          sku: sku,
          name: 'Sample Product ${i + 1}',
          variantsCount: variants,
          price: double.parse(price.toStringAsFixed(2)),
          category: category,
          lowStock: lowStock,
        ),
      );
    }
    _idCounter.seed(_items.map((e) => e.id));
  }

  Future<List<Product>> fetch({
    String query = '',
    ProductCategory? category,
    bool lowStockOnly = false,
  }) async {
    _seed();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    Iterable<Product> result = _items;
    if (category != null) {
      result = result.where((p) => p.category == category);
    }
    if (lowStockOnly) {
      result = result.where((p) => p.lowStock);
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where(
        (p) =>
            p.name.toLowerCase().contains(q) || p.sku.toLowerCase().contains(q),
      );
    }
    return result.toList();
  }

  Future<Product?> findById(String id) async {
    _seed();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    try {
      return _items.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Product> save(Product product) async {
    _seed();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _items.indexWhere((element) => element.id == product.id);
    if (index == -1) {
      final created = product.copyWith(
        id: product.id.isEmpty ? _idCounter.next() : product.id,
      );
      _items.add(created);
      return created;
    }
    _items[index] = product;
    return product;
  }

  Future<void> delete(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _items.removeWhere((item) => item.id == id);
  }
}

class MockOrderRepository {
  MockOrderRepository._internal();

  static final MockOrderRepository _instance = MockOrderRepository._internal();

  factory MockOrderRepository() => _instance;

  final _rnd = Random(2026);
  final _statuses = OrderStatus.values;
  final List<Order> _items = [];
  final _idCounter = _IdCounter(prefix: 'o_');

  void _seed() {
    if (_items.isNotEmpty) return;
    for (var i = 0; i < 30; i++) {
      final id = 'o_${i + 1}';
      final code = 'PO-2025-${1001 + i}';
      final itemCount = 1 + _rnd.nextInt(8);
      final total = (_rnd.nextDouble() * 900) + 100; // 100~1000
      final status = _statuses[i % _statuses.length];
      _items.add(
        Order(
          id: id,
          code: code,
          itemCount: itemCount,
          total: double.parse(total.toStringAsFixed(2)),
          createdAt: DateTime.now().subtract(Duration(days: _rnd.nextInt(30))),
          status: status,
        ),
      );
    }
    _idCounter.seed(_items.map((e) => e.id));
  }

  Future<List<Order>> fetch({
    String query = '',
    OrderStatus? status,
    bool openOnly = false,
  }) async {
    _seed();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    Iterable<Order> result = _items;
    if (status != null) {
      result = result.where((o) => o.status == status);
    }
    if (openOnly) {
      result = result.where(
        (o) =>
            o.status == OrderStatus.pending ||
            o.status == OrderStatus.confirmed ||
            o.status == OrderStatus.shipped,
      );
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((o) => o.code.toLowerCase().contains(q));
    }
    return result.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Order?> findById(String id) async {
    _seed();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    try {
      return _items.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Order> save(Order order) async {
    _seed();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _items.indexWhere((element) => element.id == order.id);
    if (index == -1) {
      final created = order.copyWith(
        id: order.id.isEmpty ? _idCounter.next() : order.id,
        createdAt: order.createdAt,
      );
      _items.add(created);
      return created;
    }
    _items[index] = order;
    return order;
  }

  Future<void> delete(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _items.removeWhere((element) => element.id == id);
  }
}

class MockCustomerRepository {
  MockCustomerRepository._internal();

  static final MockCustomerRepository _instance =
      MockCustomerRepository._internal();

  factory MockCustomerRepository() => _instance;

  final List<Customer> _items = [];
  final _idCounter = _IdCounter(prefix: 'c_');

  void _seed() {
    if (_items.isNotEmpty) return;
    final tiers = CustomerTier.values;
    final names = [
      'Bright Retail',
      'Sunrise Market',
      'Metro Shops',
      'Harbor Traders',
      'Northwind Stores',
      'Everest Mart',
    ];
    for (var i = 0; i < names.length; i++) {
      _items.add(
        Customer(
          id: 'c_${i + 1}',
          name: names[i],
          contactName: ['Alex Kim', 'Jamie Park', 'Morgan Lee'][i % 3],
          email: 'buyer${i + 1}@retail.com',
          tier: tiers[i % tiers.length],
          createdAt: DateTime.now().subtract(Duration(days: (i + 1) * 12)),
        ),
      );
    }
    _idCounter.seed(_items.map((e) => e.id));
  }

  Future<List<Customer>> fetch({String query = '', CustomerTier? tier}) async {
    _seed();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    Iterable<Customer> result = _items;
    if (tier != null) {
      result = result.where((c) => c.tier == tier);
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where(
        (c) =>
            c.name.toLowerCase().contains(q) ||
            c.contactName.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q),
      );
    }
    return result.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Customer> save(Customer customer) async {
    _seed();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final index = _items.indexWhere((element) => element.id == customer.id);
    if (index == -1) {
      final created = customer.copyWith(
        id: customer.id.isEmpty ? _idCounter.next() : customer.id,
      );
      _items.add(created);
      return created;
    }
    _items[index] = customer;
    return customer;
  }

  Future<void> delete(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _items.removeWhere((element) => element.id == id);
  }
}

class _IdCounter {
  _IdCounter({required this.prefix});

  final String prefix;
  int _counter = 0;

  void seed(Iterable<String> seeds) {
    final numbers = seeds
        .where((id) => id.startsWith(prefix))
        .map((id) => int.tryParse(id.replaceFirst(prefix, '')) ?? 0);
    _counter = numbers.isEmpty ? 0 : numbers.reduce((a, b) => a > b ? a : b);
  }

  String next() {
    _counter += 1;
    return '$prefix$_counter';
  }
}
