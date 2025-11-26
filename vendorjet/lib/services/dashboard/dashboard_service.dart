import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/repositories/mock_repository.dart';
import 'package:vendorjet/repositories/order_repository.dart';

class DashboardSnapshot {
  final int todayOrders;
  final int openOrders;
  final int lowStockProducts;
  final List<Order> recentOrders;

  const DashboardSnapshot({
    required this.todayOrders,
    required this.openOrders,
    required this.lowStockProducts,
    required this.recentOrders,
  });
}

class DashboardServiceException implements Exception {
  final String message;

  DashboardServiceException(this.message);

  @override
  String toString() => 'DashboardServiceException: $message';
}

abstract class DashboardService {
  Future<DashboardSnapshot> load({bool forceRefresh = false});
  DashboardSnapshot? getCachedSnapshot();
  void clearCache();
}

class MockDashboardService implements DashboardService {
  final OrderRepository orderRepository;
  final MockProductRepository productRepository;
  final Duration cacheDuration;

  DashboardSnapshot? _cache;
  DateTime? _cacheTimestamp;

  MockDashboardService({
    OrderRepository? orderRepository,
    MockProductRepository? productRepository,
    this.cacheDuration = const Duration(seconds: 30),
  }) : orderRepository = orderRepository ?? OrderRepository(),
       productRepository = productRepository ?? MockProductRepository();

  @override
  Future<DashboardSnapshot> load({bool forceRefresh = false}) async {
    final cacheValid =
        !forceRefresh &&
        _cache != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < cacheDuration;
    if (cacheValid) {
      return _cache!;
    }

    try {
      final snapshot = await _fetchSnapshot();
      _cache = snapshot;
      _cacheTimestamp = DateTime.now();
      return snapshot;
    } catch (err) {
      if (_cache != null && !forceRefresh) {
        return _cache!;
      }
      throw DashboardServiceException(err.toString());
    }
  }

  @override
  DashboardSnapshot? getCachedSnapshot() => _cache;

  @override
  void clearCache() {
    _cache = null;
    _cacheTimestamp = null;
  }

  Future<DashboardSnapshot> _fetchSnapshot() async {
    final orders = await orderRepository.fetch();
    final products = await productRepository.fetch();
    final now = DateTime.now();

    final todayOrders = orders
        .where((o) => _isSameDay(o.createdAt, now))
        .length;
    final openOrders = orders
        .where(
          (o) =>
              o.status == OrderStatus.pending ||
              o.status == OrderStatus.confirmed ||
              o.status == OrderStatus.shipped,
        )
        .length;
    final lowStock = products.where((p) => p.lowStock).length;
    final recentOrders = [...orders]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    return DashboardSnapshot(
      todayOrders: todayOrders,
      openOrders: openOrders,
      lowStockProducts: lowStock,
      recentOrders: recentOrders.take(5).toList(),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
