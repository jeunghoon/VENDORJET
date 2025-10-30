import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/repositories/mock_repository.dart';

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

abstract class DashboardService {
  Future<DashboardSnapshot> load();
}

class MockDashboardService implements DashboardService {
  final MockOrderRepository orderRepository;
  final MockProductRepository productRepository;

  MockDashboardService({
    MockOrderRepository? orderRepository,
    MockProductRepository? productRepository,
  })  : orderRepository = orderRepository ?? MockOrderRepository(),
        productRepository = productRepository ?? MockProductRepository();

  @override
  Future<DashboardSnapshot> load() async {
    final orders = await orderRepository.fetch();
    final products = await productRepository.fetch();
    final now = DateTime.now();

    final todayOrders = orders.where((o) => _isSameDay(o.createdAt, now)).length;
    final openOrders = orders.where((o) => o.status == OrderStatus.pending || o.status == OrderStatus.confirmed || o.status == OrderStatus.shipped).length;
    final lowStock = products.where((p) => p.lowStock).length;
    final recentOrders = [...orders]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

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
