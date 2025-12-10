import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/services/dashboard/dashboard_service.dart';
import 'package:vendorjet/services/sync/data_refresh_coordinator.dart';
import 'package:vendorjet/ui/widgets/notification_ticker.dart';
import 'package:vendorjet/ui/widgets/state_views.dart';

// 대시보드: 핵심 지표 + 최근 주문 목록
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardService _service = MockDashboardService();
  DataRefreshCoordinator? _refreshCoordinator;
  int _lastOrdersVersion = 0;
  int _lastProductsVersion = 0;
  DashboardSnapshot? _snapshot;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _snapshot = _service.getCachedSnapshot();
    _loading = _snapshot == null;
    _load(forceRefresh: _snapshot == null);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final coordinator = context.read<DataRefreshCoordinator>();
    if (_refreshCoordinator != coordinator) {
      _refreshCoordinator?.removeListener(_handleRefreshEvent);
      _refreshCoordinator = coordinator;
      _lastOrdersVersion = coordinator.ordersVersion;
      _lastProductsVersion = coordinator.productsVersion;
      coordinator.addListener(_handleRefreshEvent);
    }
  }

  @override
  void dispose() {
    _refreshCoordinator?.removeListener(_handleRefreshEvent);
    super.dispose();
  }

  Future<void> _load({bool forceRefresh = false}) async {
    setState(() {
      _error = null;
      _loading = _snapshot == null || forceRefresh ? true : _loading;
    });
    try {
      final data = await _service.load(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _snapshot = data;
        _loading = false;
      });
    } on DashboardServiceException catch (err) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_snapshot == null) {
          _error = err.message;
        }
      });
      if (_snapshot != null) {
        if (mounted) {
          context.read<NotificationTicker>().push(err.message);
        }
      }
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        if (_snapshot == null) {
          _error = err.toString();
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    if (_loading && _snapshot == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null && _snapshot == null) {
      return StateMessageView(
        icon: Icons.error_outline,
        title: t.stateErrorMessage,
        message: _error,
        action: OutlinedButton.icon(
          onPressed: () => _load(forceRefresh: true),
          icon: const Icon(Icons.refresh),
          label: Text(t.stateRetry),
        ),
      );
    }

    final data = _snapshot;
    if (data == null) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        RefreshIndicator(
          onRefresh: () => _load(forceRefresh: true),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                t.welcome,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                t.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
              const SizedBox(height: 20),
              _Overview(
                today: data.todayOrders,
                open: data.openOrders,
                lowStock: data.lowStockProducts,
                onTodayTap: () => context.go('/orders?filter=today'),
                onOpenTap: () => context.go('/orders?filter=open'),
                onLowStockTap: () => context.go('/products?lowStock=1'),
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: t.dashboardRecentOrders),
              const SizedBox(height: 10),
              _RecentOrdersList(orders: data.recentOrders),
            ],
          ),
        ),
        if (_loading && _snapshot != null)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  void _handleRefreshEvent() {
    final coordinator = _refreshCoordinator;
    if (coordinator == null) return;
    final ordersChanged = coordinator.ordersVersion != _lastOrdersVersion;
    final productsChanged = coordinator.productsVersion != _lastProductsVersion;
    if (ordersChanged || productsChanged) {
      _lastOrdersVersion = coordinator.ordersVersion;
      _lastProductsVersion = coordinator.productsVersion;
      _load(forceRefresh: true);
    }
  }
}

class _Overview extends StatelessWidget {
  final int today;
  final int open;
  final int lowStock;
  final VoidCallback onTodayTap;
  final VoidCallback onOpenTap;
  final VoidCallback onLowStockTap;

  const _Overview({
    required this.today,
    required this.open,
    required this.lowStock,
    required this.onTodayTap,
    required this.onOpenTap,
    required this.onLowStockTap,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, c) {
        final maxWidth = c.maxWidth;
        final isWide = maxWidth > 900;
        final isMedium = maxWidth > 600;
        final isCompact = maxWidth < 360;
        final crossAxisCount = isWide ? 3 : (isMedium ? 3 : 1);
        final spacing = 12.0;
        final totalSpacing = spacing * (crossAxisCount - 1);
        final tileWidth = (maxWidth - totalSpacing) / crossAxisCount;
        final targetHeight = isWide
            ? 120.0
            : isMedium
                ? 140.0
                : (isCompact ? 200.0 : 170.0);
        final aspectRatio = tileWidth / targetHeight;

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: aspectRatio,
          children: [
            _StatCard(
              title: t.dashboardTodayOrders,
              value: today.toString(),
              onTap: onTodayTap,
            ),
            _StatCard(
              title: t.dashboardOpenOrders,
              value: open.toString(),
              onTap: onOpenTap,
            ),
            _StatCard(
              title: t.dashboardLowStock,
              value: lowStock.toString(),
              onTap: onLowStockTap,
            ),
          ],
        );
      },
    );
  }
}

class _RecentOrdersList extends StatelessWidget {
  final List<Order> orders;

  const _RecentOrdersList({required this.orders});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final localizations = MaterialLocalizations.of(context);
    final numberFormat = NumberFormat.decimalPattern(t.localeName);

    if (orders.isEmpty) {
      return StateMessageView(
        icon: Icons.inbox_outlined,
        title: t.dashboardRecentOrdersEmpty,
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: orders.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: color.primary.withValues(alpha: 0.15),
              child: Icon(Icons.receipt_long, color: color.primary),
            ),
            title: Text(order.code),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (order.buyerName.isNotEmpty)
                  Text(
                    order.buyerName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                const SizedBox(height: 2),
                Text(
                  '${localizations.formatShortDate(order.createdAt)} - ${numberFormat.format(order.total)}',
                ),
                const SizedBox(height: 2),
                Text(
                  _statusLabel(order.status, t),
                  style: TextStyle(
                    color: color.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () => context.go('/orders/${order.id}'),
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final VoidCallback onTap;
  const _StatCard({required this.title, required this.value, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.secondary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.analytics_outlined, color: color.secondary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      value,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    );
  }
}

String _statusLabel(OrderStatus status, AppLocalizations t) {
  switch (status) {
    case OrderStatus.pending:
      return t.ordersStatusPending;
    case OrderStatus.confirmed:
      return t.ordersStatusConfirmed;
    case OrderStatus.shipped:
      return t.ordersStatusShipped;
    case OrderStatus.completed:
      return t.ordersStatusCompleted;
    case OrderStatus.canceled:
      return t.ordersStatusCanceled;
    case OrderStatus.returned:
      return t.ordersStatusReturned;
  }
}
