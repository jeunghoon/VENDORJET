import 'package:intl/intl.dart';
import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/repositories/mock_repository.dart';
import 'package:vendorjet/repositories/order_repository.dart';

class DashboardSnapshot {
  final int todayOrders;
  final int openOrders;
  final int lowStockProducts;
  final List<Order> recentOrders;
  final double monthlySales;
  final List<DashboardTopItem> topProducts;
  final List<DashboardTopItem> topCustomers;
  final List<IncomingShipment> incomingShipments;
  final List<ExpiringProduct> expiringProducts;
  final double receivables;
  final int returnsCount;
  final StaffStats? staffStats;
  final List<DailyMetric> dailyMetrics;
  final int perishableCount;

  const DashboardSnapshot({
    required this.todayOrders,
    required this.openOrders,
    required this.lowStockProducts,
    required this.recentOrders,
    required this.monthlySales,
    required this.topProducts,
    required this.topCustomers,
    required this.incomingShipments,
    required this.expiringProducts,
    required this.receivables,
    required this.returnsCount,
    required this.staffStats,
    required this.dailyMetrics,
    required this.perishableCount,
  });
}

class DashboardTopItem {
  final String name;
  final double amount;
  final int quantity;

  const DashboardTopItem({
    required this.name,
    required this.amount,
    required this.quantity,
  });
}

class IncomingShipment {
  final String productName;
  final DateTime eta;
  final String incoterm;
  final String? vessel;

  const IncomingShipment({
    required this.productName,
    required this.eta,
    required this.incoterm,
    this.vessel,
  });
}

class ExpiringProduct {
  final String productName;
  final DateTime expiry;
  final int daysLeft;

  const ExpiringProduct({
    required this.productName,
    required this.expiry,
    required this.daysLeft,
  });
}

class StaffStats {
  final int total;
  final int onDuty;
  final int onLeave;
  final int onSick;

  const StaffStats({
    required this.total,
    required this.onDuty,
    required this.onLeave,
    required this.onSick,
  });
}

class DailyMetric {
  final DateTime date;
  final double sales;
  final double receivables;
  final double returns;

  const DailyMetric({
    required this.date,
    required this.sales,
    required this.receivables,
    required this.returns,
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

    // 월간 매출 및 TOP 지표 계산
    final monthStart = DateTime(now.year, now.month, 1);
    double monthlySales = 0;
    final productSales = <String, double>{};
    final productQty = <String, int>{};
    final customerSales = <String, double>{};
    int returnsCount = 0;
    double receivables = 0;
    final daily = <String, _DailyMetricBuilder>{};

    for (final o in orders) {
      final orderTotal = o.total;
      if (o.status == OrderStatus.returned) returnsCount += 1;
      if (o.status == OrderStatus.pending || o.status == OrderStatus.confirmed) {
        receivables += orderTotal;
      }
      if (o.createdAt.isAfter(monthStart)) {
        monthlySales += orderTotal;
        customerSales[o.buyerName] = (customerSales[o.buyerName] ?? 0) + orderTotal;
      }
      final dateKey = DateFormat('yyyy-MM-dd').format(o.createdAt);
      final builder = daily.putIfAbsent(dateKey, () => _DailyMetricBuilder(date: o.createdAt));
      if (o.status == OrderStatus.completed || o.status == OrderStatus.shipped || o.status == OrderStatus.confirmed) {
        builder.sales += orderTotal;
      }
      if (o.status == OrderStatus.pending || o.status == OrderStatus.confirmed) {
        builder.receivables += orderTotal;
      }
      if (o.status == OrderStatus.returned) {
        builder.returns += orderTotal;
      }
      for (final line in o.lines) {
        final key = line.productName;
        productSales[key] = (productSales[key] ?? 0) + line.lineTotal;
        productQty[key] = (productQty[key] ?? 0) + line.quantity;
      }
    }

    List<DashboardTopItem> topProducts = productSales.entries
        .map(
          (e) => DashboardTopItem(
            name: e.key,
            amount: e.value,
            quantity: productQty[e.key] ?? 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    topProducts = topProducts.take(5).toList();

    List<DashboardTopItem> topCustomers = customerSales.entries
        .map(
          (e) => DashboardTopItem(
            name: e.key,
            amount: e.value,
            quantity: 0,
          ),
        )
        .toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));
    topCustomers = topCustomers.take(5).toList();

    // 입고 예정/유통기한 임박
    final incoming = <IncomingShipment>[];
    final expiring = <ExpiringProduct>[];
    for (final p in products) {
      final etaDate = p.eta?.eta ?? p.eta?.etd;
      if (etaDate != null && etaDate.isAfter(now)) {
        incoming.add(
          IncomingShipment(
            productName: p.name,
            eta: etaDate,
            incoterm: p.incoterm ?? p.tradeTerm?.incoterm ?? '-',
            vessel: p.eta?.vessel,
          ),
        );
      }
      // 유통기한 정보는 DB에 없으므로 표시하지 않음
    }
    incoming.sort((a, b) => a.eta.compareTo(b.eta));
    expiring.sort((a, b) => a.daysLeft.compareTo(b.daysLeft));

    return DashboardSnapshot(
      todayOrders: todayOrders,
      openOrders: openOrders,
      lowStockProducts: lowStock,
      recentOrders: recentOrders.take(5).toList(),
      monthlySales: monthlySales,
      topProducts: topProducts,
      topCustomers: topCustomers,
      incomingShipments: incoming.take(5).toList(),
      expiringProducts: expiring.take(5).toList(),
      receivables: receivables,
      returnsCount: returnsCount,
      staffStats: null,
      dailyMetrics: daily.values.map((e) => e.build()).toList()
        ..sort((a, b) => a.date.compareTo(b.date)),
      perishableCount: products.where((p) => p.isPerishable).length,
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DailyMetricBuilder {
  final DateTime date;
  double sales = 0;
  double receivables = 0;
  double returns = 0;

  _DailyMetricBuilder({required this.date});

  DailyMetric build() => DailyMetric(
        date: date,
        sales: sales,
        receivables: receivables,
        returns: returns,
      );
}
