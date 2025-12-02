import 'dart:math';

import 'package:intl/intl.dart';

import '../models/customer.dart';
import '../models/order.dart';
import '../models/product.dart';
import '../services/api/api_client.dart';

class MockProductRepository {
  MockProductRepository._internal();

  static final MockProductRepository _instance =
      MockProductRepository._internal();

  factory MockProductRepository() => _instance;

  final _rnd = Random(2025);
  final List<Product> _items = [];
  List<List<String>> _categoryPresets = [];
  final _idCounter = _IdCounter(prefix: 'p_');
  List<Product> _apiCache = [];
  List<String>? _apiTopCategoriesCache;

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
    if (useLocalApi) return;
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
    if (useLocalApi) {
      final data =
          await ApiClient.get(
                '/products',
                query: {
                  'q': query,
                  'topCategory': topCategory,
                  'lowStockOnly': lowStockOnly ? 'true' : null,
                },
              )
              as List<dynamic>;
      final products = data
          .map((e) => _productFromJson(e as Map<String, dynamic>))
          .toList();
      _apiCache = products;
      _apiTopCategoriesCache = _computeTopCategories(
        products,
        presets: _categoryPresets,
      );
      return products;
    }
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
    if (useLocalApi) {
      try {
        final data =
            await ApiClient.get('/products/$id') as Map<String, dynamic>;
        return _productFromJson(data);
      } catch (_) {
        return null;
      }
    }
    _seed();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    try {
      return _items.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Product> save(Product product) async {
    if (useLocalApi) {
      if (product.id.isEmpty) {
        final created =
            await ApiClient.post(
                  '/products',
                  body: {
                    'sku': product.sku,
                    'name': product.name,
                    'price': product.price,
                    'variantsCount': product.variantsCount,
                    'categories': product.categories,
                    'tags': product.tags.map((e) => e.name).toList(),
                    'lowStock': product.lowStock,
                    'imageUrl': product.imageUrl,
                  },
                )
                as Map<String, dynamic>;
        final id = created['id'] as String? ?? product.id;
        return await findById(id) ?? product.copyWith(id: id);
      } else {
        await ApiClient.put(
          '/products/${product.id}',
          body: {
            'sku': product.sku,
            'name': product.name,
            'price': product.price,
            'variantsCount': product.variantsCount,
            'categories': product.categories,
            'tags': product.tags.map((e) => e.name).toList(),
            'lowStock': product.lowStock,
            'imageUrl': product.imageUrl,
          },
        );
        return await findById(product.id) ?? product;
      }
    }
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
    if (useLocalApi) {
      await ApiClient.delete('/products/$id');
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
    _items.removeWhere((item) => item.id == id);
  }

  List<String> topCategories() {
    if (useLocalApi) {
      _apiTopCategoriesCache ??= _computeTopCategories(
        _apiCache,
        presets: _categoryPresets,
      );
      return _apiTopCategoriesCache ?? [];
    }
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
    if (useLocalApi) {
      _apiTopCategoriesCache ??= _computeTopCategories(_apiCache);
      final set = <String>{
        ..._apiTopCategoriesCache ?? [],
        ..._categoryPresets.map((p) => p.isNotEmpty ? p.first : ''),
      };
      set.remove('');
      return set.map((c) => [c]).toList();
    }
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
    _apiTopCategoriesCache = null;
  }

  Future<void> deleteCategory(List<String> path) async {
    _ensureCategoryPresets();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    final key = _pathKey(path);
    _categoryPresets.removeWhere((element) => _pathKey(element) == key);
    _apiTopCategoriesCache = null;
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
    if (useLocalApi) return;
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
    if (useLocalApi) {
      final data =
          await ApiClient.get(
                '/orders',
                query: {
                  'q': query,
                  'status': status?.name,
                  'openOnly': openOnly ? 'true' : null,
                  'date': dateEquals != null
                      ? DateFormat('yyyy-MM-dd').format(dateEquals)
                      : null,
                },
              )
              as List<dynamic>;
      final orders = data
          .map((e) => _orderFromJson(e as Map<String, dynamic>))
          .toList();
      return orders..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
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
    if (useLocalApi) {
      try {
        final data = await ApiClient.get('/orders/$id') as Map<String, dynamic>;
        return _orderFromJson(data);
      } catch (_) {
        return null;
      }
    }
    await _seed();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    try {
      return _items.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<Order> save(Order order) async {
    if (useLocalApi) {
      if (order.id.isEmpty) {
        final resp =
            await ApiClient.post(
                  '/orders',
                  body: {
                    'buyerName': order.buyerName,
                    'buyerContact': order.buyerContact,
                    'buyerNote': order.buyerNote,
                    'desiredDeliveryDate': order.desiredDeliveryDate
                        ?.toIso8601String(),
                    'items': order.lines
                        .map(
                          (l) => {
                            'productId': l.productId,
                            'productName': l.productName,
                            'quantity': l.quantity,
                            'unitPrice': l.unitPrice,
                          },
                        )
                        .toList(),
                  },
                )
                as Map<String, dynamic>;
        final created = _orderFromJson(resp);
        return created.copyWith(lines: order.lines);
      } else {
        await ApiClient.patch(
          '/orders/${order.id}',
          body: {
            'status': order.status.name,
            'buyerNote': order.buyerNote,
            'updateNote': order.updateNote,
            'desiredDeliveryDate': order.desiredDeliveryDate?.toIso8601String(),
          },
        );
        return await findById(order.id) ?? order;
      }
    }
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
    if (useLocalApi) {
      await ApiClient.delete('/customers/$id');
      return;
    }
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

  Future<List<Customer>> fetch({
    String query = '',
    CustomerTier? tier,
    String? segment,
  }) async {
    final data =
        await ApiClient.get(
              '/customers',
              query: {'q': query, 'tier': tier?.name, 'segment': segment},
            )
            as List<dynamic>;
    final customers = data
        .map((e) => _customerFromJson(e as Map<String, dynamic>))
        .toList();
    return customers..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  Future<Customer> save(Customer customer) async {
    if (customer.id.isEmpty) {
      final created =
          await ApiClient.post(
                '/customers',
                body: {
                  'name': customer.name,
                  'contactName': customer.contactName,
                  'email': customer.email,
                  'tier': customer.tier.name,
                  'segment': customer.segment,
                },
              )
              as Map<String, dynamic>;
      return _customerFromJson(created);
    } else {
      await ApiClient.put(
        '/customers/${customer.id}',
        body: {
          'name': customer.name,
          'contactName': customer.contactName,
          'email': customer.email,
          'tier': customer.tier.name,
          'segment': customer.segment,
        },
      );
      return customer;
    }
  }

  Future<void> delete(String id) async {
    await ApiClient.delete('/customers/$id');
  }

  Future<List<String>> fetchSegments() async {
    final data = await ApiClient.get('/customers/segments') as List<dynamic>;
    return data.map((e) => e.toString()).toList()..sort();
  }

  Future<void> upsertSegment(String name, {String? original}) async {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return;
    await ApiClient.post(
      '/customers/segments',
      body: {'name': trimmed, 'original': original},
    );
  }

  Future<void> deleteSegment(String name) async {
    await ApiClient.delete('/customers/segments', query: {'name': name});
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

List<String> _computeTopCategories(
  List<Product> products, {
  List<List<String>> presets = const [],
}) {
  final set = <String>{};
  for (final product in products) {
    if (product.categories.isNotEmpty) {
      set.add(product.categories.first);
    }
  }
  for (final p in presets) {
    if (p.isNotEmpty) set.add(p.first);
  }
  final list = set.toList()..sort();
  return list;
}

Product _productFromJson(Map<String, dynamic> json) {
  final tags = <ProductTag>{};
  final tagList = (json['tags'] as List<dynamic>? ?? []);
  for (final t in tagList) {
    final name = t.toString();
    final tag = ProductTag.values.firstWhere(
      (e) => e.name == name,
      orElse: () => ProductTag.featured,
    );
    tags.add(tag);
  }
  final categories = (json['categories'] as List<dynamic>? ?? [])
      .map((e) => e.toString())
      .toList();
  return Product(
    id: json['id'] as String? ?? '',
    sku: json['sku'] as String? ?? '',
    name: json['name'] as String? ?? '',
    variantsCount: (json['variantsCount'] ?? json['variants_count'] ?? 1) is int
        ? (json['variantsCount'] ?? json['variants_count'] ?? 1) as int
        : int.tryParse(
                (json['variantsCount'] ?? json['variants_count'] ?? '1')
                    .toString(),
              ) ??
              1,
    price: (json['price'] as num?)?.toDouble() ?? 0,
    categories: categories,
    tags: tags,
    lowStock:
        (json['lowStock'] ?? json['low_stock'] ?? false).toString() == 'true' ||
        (json['lowStock'] ?? json['low_stock'] ?? 0) == 1,
    imageUrl: json['imageUrl'] as String?,
  );
}

Customer _customerFromJson(Map<String, dynamic> json) {
  return Customer(
    id: json['id'] as String? ?? '',
    name: json['name'] as String? ?? '',
    contactName: json['contactName'] as String? ?? '',
    email: json['email'] as String? ?? '',
    phone: json['contactPhone'] as String? ?? json['phone'] as String? ?? '',
    address:
        json['contactAddress'] as String? ?? json['address'] as String? ?? '',
    tier: _tierFromString(json['tier'] as String?),
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
    segment: json['segment'] as String? ?? '',
    status: json['buyerStatus'] as String? ?? json['status'] as String? ?? '',
  );
}

CustomerTier _tierFromString(String? value) {
  return CustomerTier.values.firstWhere(
    (t) => t.name == value,
    orElse: () => CustomerTier.silver,
  );
}

Order _orderFromJson(Map<String, dynamic> json) {
  final lines = (json['lines'] as List<dynamic>? ?? [])
      .map((l) => _orderLineFromJson(l as Map<String, dynamic>))
      .toList();
  final itemCount =
      json['itemCount'] ?? json['item_count'] ?? _calcItemCount(lines);
  return Order(
    id: json['id'] as String? ?? '',
    code: json['code'] as String? ?? '',
    itemCount: itemCount is int
        ? itemCount
        : int.tryParse(itemCount.toString()) ?? 0,
    total: (json['total'] as num?)?.toDouble() ?? 0,
    createdAt:
        DateTime.tryParse(json['createdAt'] as String? ?? '') ??
        DateTime.tryParse(json['created_at'] as String? ?? '') ??
        DateTime.now(),
    status: _statusFromString(json['status'] as String?),
    buyerName:
        json['buyerName'] as String? ?? json['buyer_name'] as String? ?? '',
    buyerContact:
        json['buyerContact'] as String? ??
        json['buyer_contact'] as String? ??
        '',
    buyerNote: json['buyerNote'] as String? ?? json['buyer_note'] as String?,
    updatedAt: DateTime.tryParse(
      json['updatedAt'] as String? ?? json['updated_at'] as String? ?? '',
    ),
    createdBy: json['createdBy'] as String? ?? json['created_by'] as String?,
    updatedBy: json['updatedBy'] as String? ?? json['updated_by'] as String?,
    statusUpdatedBy:
        json['statusUpdatedBy'] as String? ??
        json['status_updated_by'] as String?,
    statusUpdatedAt: DateTime.tryParse(
      json['statusUpdatedAt'] as String? ??
          json['status_updated_at'] as String? ??
          '',
    ),
    updateNote: json['updateNote'] as String? ?? json['update_note'] as String?,
    lines: lines,
    desiredDeliveryDate: DateTime.tryParse(
      json['desiredDeliveryDate'] as String? ??
          json['desired_delivery_date'] as String? ??
          '',
    ),
  );
}

OrderLine _orderLineFromJson(Map<String, dynamic> json) {
  return OrderLine(
    productId:
        json['productId'] as String? ?? json['product_id'] as String? ?? '',
    productName:
        json['productName'] as String? ?? json['product_name'] as String? ?? '',
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

int _calcItemCount(List<OrderLine> lines) =>
    lines.fold(0, (sum, l) => sum + l.quantity);
