import 'dart:math';

import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/order.dart';
import '../models/product.dart';

class MockProductRepository {
  MockProductRepository._internal();

  static final MockProductRepository _instance =
      MockProductRepository._internal();

  factory MockProductRepository() => _instance;

  final _rnd = Random(2025);
  final List<Product> _items = [];
  List<List<String>> _categoryPresets = [];
  final _idCounter = _IdCounter(prefix: 'p_');

  static const _sampleCategories = [
    ['Beverages', 'Sparkling'],
    ['Snacks', 'Chips'],
    ['Household', 'Cleaning'],
    ['Fashion', 'Apparel', 'Outerwear'],
    ['Electronics', 'Accessories'],
  ];

  void _ensureCategoryPresets() {
    if (_categoryPresets.isNotEmpty) return;
    _categoryPresets = _sampleCategories
        .map((path) => List<String>.from(path))
        .toList();
  }

  void _seed() {
    _ensureCategoryPresets();
    if (_items.isNotEmpty) return;
    for (var i = 0; i < 40; i++) {
      final baseCategories = _sampleCategories[i % _sampleCategories.length];
      final depth = 1 + _rnd.nextInt(baseCategories.length.clamp(1, 3));
      final categories = baseCategories.take(depth).toList();
      final tags = <ProductTag>{};
      if (_rnd.nextBool()) tags.add(ProductTag.featured);
      if (_rnd.nextBool()) tags.add(ProductTag.discounted);
      if (_rnd.nextBool()) tags.add(ProductTag.newArrival);
      final price = (_rnd.nextDouble() * 90) + 10;
      _items.add(
        Product(
          id: 'p_${i + 1}',
          sku: 'SKU-${1000 + i}',
          name: 'Sample Product ${i + 1}',
          variantsCount: 1 + _rnd.nextInt(4),
          price: double.parse(price.toStringAsFixed(2)),
          categories: categories,
          tags: tags,
          lowStock: _rnd.nextBool() && _rnd.nextBool(),
        ),
      );
    }
    _idCounter.seed(_items.map((e) => e.id));
  }

  Future<List<Product>> fetch({
    String query = '',
    String? topCategory,
    bool lowStockOnly = false,
  }) async {
    _seed();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    Iterable<Product> result = _items;
    if (topCategory != null && topCategory.isNotEmpty) {
      result = result.where(
        (p) => p.categories.isNotEmpty && p.categories.first == topCategory,
      );
    }
    if (lowStockOnly) {
      result = result.where((p) => p.lowStock);
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where(
        (p) =>
            p.name.toLowerCase().contains(q) ||
            p.sku.toLowerCase().contains(q) ||
            p.categories.any((c) => c.toLowerCase().contains(q)),
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

  List<String> topCategories() {
    _seed();
    _ensureCategoryPresets();
    final set = <String>{};
    for (final product in _items) {
      if (product.categories.isNotEmpty) {
        set.add(product.categories.first);
      }
    }
    for (final path in _categoryPresets) {
      if (path.isNotEmpty) set.add(path.first);
    }
    final list = set.toList()..sort();
    return list;
  }

  Future<List<List<String>>> fetchCategoryPresets() async {
    _ensureCategoryPresets();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return _categoryPresets.map((path) => List<String>.from(path)).toList();
  }

  Future<void> saveCategory(
    List<String> path, {
    List<String>? originalPath,
  }) async {
    _ensureCategoryPresets();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final normalized = path
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    if (normalized.isEmpty) {
      throw ArgumentError('Category path cannot be empty');
    }
    if (originalPath != null) {
      final originalKey = _pathKey(originalPath);
      final index = _categoryPresets.indexWhere(
        (p) => _pathKey(p) == originalKey,
      );
      if (index != -1) {
        _categoryPresets[index] = normalized;
      } else {
        _insertOrReplaceCategory(normalized);
      }
    } else {
      _insertOrReplaceCategory(normalized);
    }
    _categoryPresets.sort(_comparePaths);
  }

  Future<void> deleteCategory(List<String> path) async {
    _ensureCategoryPresets();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final key = _pathKey(path);
    _categoryPresets.removeWhere((element) => _pathKey(element) == key);
  }

  void _insertOrReplaceCategory(List<String> path) {
    final key = _pathKey(path);
    final existing = _categoryPresets.indexWhere((p) => _pathKey(p) == key);
    if (existing != -1) {
      _categoryPresets[existing] = path;
    } else {
      _categoryPresets.add(path);
    }
  }

  String _pathKey(List<String> path) =>
      path.map((segment) => segment.trim()).join('>');

  int _comparePaths(List<String> a, List<String> b) {
    final maxLength = max(a.length, b.length);
    for (var i = 0; i < maxLength; i++) {
      final left = i < a.length ? a[i] : '';
      final right = i < b.length ? b[i] : '';
      final comp = left.compareTo(right);
      if (comp != 0) return comp;
    }
    return a.length.compareTo(b.length);
  }
}

class MockOrderRepository {
  MockOrderRepository._internal();

  static final MockOrderRepository _instance = MockOrderRepository._internal();

  factory MockOrderRepository() => _instance;

  final _rnd = Random(2026);
  final _statuses = OrderStatus.values;
  final List<String> _buyerNotes = [
    '재청: 다음 달 인기 상품',
    '납기 확인 및 재고 점검',
    '결제 완료, 출고만 남음',
    '제철 식물 샘플 보강 요청',
    '소량 및 묶음배송 희망',
  ];
  final List<Order> _items = [];
  final _idCounter = _IdCounter(prefix: 'o_');
  final Map<String, int> _sequenceByDate = {};
  final MockProductRepository _productRepository = MockProductRepository();
  final MockCustomerRepository _customerRepository = MockCustomerRepository();

  Future<void> _seed() async {
    if (_items.isNotEmpty) return;
    final products = await _productRepository.fetch();
    final customers = await _customerRepository.fetch();
    final fallbackNames = [
      'Sunrise Mart',
      'Harbor Lane Retail',
      'Metro Mini',
      'Evergreen Shop',
      'Bluebird Boutique',
    ];
    final fallbackContacts = [
      'Alex Kim',
      'Morgan Lee',
      'Taylor Choi',
      'Jamie Park',
      'Jordan Han',
    ];
    for (var i = 0; i < 30; i++) {
      final createdAt = DateTime.now().subtract(
        Duration(days: _rnd.nextInt(30)),
      );
      final code = _generateCodeForDate(createdAt);
      final status = _statuses[i % _statuses.length];
      final customer = customers.isEmpty
          ? null
          : customers[i % customers.length];
      final buyerName =
          customer?.name ?? fallbackNames[i % fallbackNames.length];
      final buyerContact =
          customer?.contactName ??
          fallbackContacts[i % fallbackContacts.length];
      final lineCount = 1 + _rnd.nextInt(4);
      final lines = <OrderLine>[];
      for (var j = 0; j < lineCount; j++) {
        final product = products[_rnd.nextInt(products.length)];
        final qty = 1 + _rnd.nextInt(6);
        lines.add(
          OrderLine(
            productId: product.id,
            productName: product.name,
            quantity: qty,
            unitPrice: product.price,
          ),
        );
      }
      final itemCount = lines.fold<int>(0, (sum, line) => sum + line.quantity);
      final total = lines.fold<double>(0, (sum, line) => sum + line.lineTotal);
      final buyerNote = i.isEven ? _buyerNotes[i % _buyerNotes.length] : null;
      final desiredDeliveryDate = createdAt.add(
        Duration(days: 1 + _rnd.nextInt(5)),
      );
      _items.add(
        Order(
          id: 'o_${i + 1}',
          code: code,
          itemCount: itemCount,
          total: double.parse(total.toStringAsFixed(2)),
          createdAt: createdAt,
          status: status,
          buyerName: buyerName,
          buyerContact: buyerContact,
          buyerNote: buyerNote,
          updatedAt: createdAt.add(const Duration(hours: 2)),
          updateNote: 'Auto-generated mock order',
          lines: lines,
          desiredDeliveryDate: desiredDeliveryDate,
        ),
      );
    }
    _idCounter.seed(_items.map((e) => e.id));
  }

  Future<List<Order>> fetch({
    String query = '',
    OrderStatus? status,
    bool openOnly = false,
    DateTime? dateEquals,
  }) async {
    await _seed();
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
    if (dateEquals != null) {
      result = result.where(
        (o) =>
            o.createdAt.year == dateEquals.year &&
            o.createdAt.month == dateEquals.month &&
            o.createdAt.day == dateEquals.day,
      );
    }
    if (query.isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where(
        (o) =>
            o.code.toLowerCase().contains(q) ||
            o.buyerName.toLowerCase().contains(q) ||
            o.buyerContact.toLowerCase().contains(q),
      );
    }
    return result.toList()..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Order?> findById(String id) async {
    await _seed();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    try {
      return _items.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Order> save(Order order) async {
    await _seed();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    final isNew = order.id.isEmpty;
    final index = _items.indexWhere((element) => element.id == order.id);
    final assignedId = isNew ? _idCounter.next() : order.id;
    final assignedCode = order.code.isEmpty
        ? _generateCodeForDate(DateTime.now())
        : order.code;
    final normalized = order.copyWith(
      id: assignedId,
      code: assignedCode,
      createdAt: isNew ? DateTime.now() : order.createdAt,
      updatedAt: order.updatedAt,
      updateNote: order.updateNote,
      lines: order.lines,
      desiredDeliveryDate: order.desiredDeliveryDate,
    );
    if (index == -1) {
      _items.add(normalized);
    } else {
      _items[index] = normalized;
    }
    return normalized;
  }

  Future<void> delete(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _items.removeWhere((element) => element.id == id);
  }

  String _generateCodeForDate(DateTime date) {
    final datePart = DateFormat('yyMMdd').format(date);
    final current = _sequenceByDate[datePart] ?? 0;
    final next = current + 1;
    _sequenceByDate[datePart] = next;
    return 'PO$datePart${next.toString().padLeft(4, '0')}';
  }
}

class MockCustomerRepository {
  MockCustomerRepository._internal();

  static final MockCustomerRepository _instance =
      MockCustomerRepository._internal();

  factory MockCustomerRepository() => _instance;

  final List<Customer> _items = [];
  final _idCounter = _IdCounter(prefix: 'c_');
  final List<String> _segments = [];

  void _ensureSegments() {
    if (_segments.isNotEmpty) return;
    _segments.addAll(['Restaurant', 'Hotel', 'Mart', 'Cafe']);
  }

  void _seed() {
    _ensureSegments();
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
          segment: _segments[i % _segments.length],
        ),
      );
    }
    _idCounter.seed(_items.map((e) => e.id));
  }

  Future<List<Customer>> fetch({
    String query = '',
    CustomerTier? tier,
    String? segment,
  }) async {
    _seed();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    Iterable<Customer> result = _items;
    if (tier != null) {
      result = result.where((c) => c.tier == tier);
    }
    if (segment != null && segment.isNotEmpty) {
      result = result.where((c) => c.segment == segment);
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
    final normalized = customer.segment.trim();
    final segment = normalized.isEmpty ? '' : normalized;
    final updatedCustomer = customer.copyWith(segment: segment);
    if (index == -1) {
      final created = customer.copyWith(
        id: customer.id.isEmpty ? _idCounter.next() : customer.id,
        segment: segment,
      );
      _items.add(created);
      return created;
    }
    _items[index] = updatedCustomer;
    return updatedCustomer;
  }

  Future<void> delete(String id) async {
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _items.removeWhere((element) => element.id == id);
  }

  Future<List<String>> fetchSegments() async {
    _ensureSegments();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    return List<String>.from(_segments)..sort();
  }

  Future<void> upsertSegment(String name, {String? original}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Segment cannot be empty');
    }
    _ensureSegments();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (original != null) {
      final index = _segments.indexWhere(
        (element) => element.toLowerCase() == original.toLowerCase(),
      );
      if (index != -1) {
        _segments[index] = trimmed;
        _reassignSegment(original, trimmed);
        return;
      }
    }
    if (!_segments.contains(trimmed)) {
      _segments.add(trimmed);
    }
  }

  Future<void> deleteSegment(String name) async {
    _ensureSegments();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _segments.remove(name);
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].segment == name) {
        _items[i] = _items[i].copyWith(segment: '');
      }
    }
  }

  void _reassignSegment(String from, String to) {
    for (var i = 0; i < _items.length; i++) {
      if (_items[i].segment == from) {
        _items[i] = _items[i].copyWith(segment: to);
      }
    }
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
