import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/services/dashboard/dashboard_service.dart';
import 'package:vendorjet/ui/widgets/state_views.dart';

// 대시보드: 핵심 지표 + 최근 주문 목록
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final DashboardService _service = MockDashboardService();
  late Future<DashboardSnapshot> _future;

  @override
  void initState() {
    super.initState();
    _future = _service.load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return FutureBuilder<DashboardSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return StateMessageView(
            icon: Icons.error_outline,
            title: t.stateErrorMessage,
            action: OutlinedButton.icon(
              onPressed: () => setState(() => _future = _service.load()),
              icon: const Icon(Icons.refresh),
              label: Text(t.stateRetry),
            ),
          );
        }
        final data = snapshot.data!;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
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
              ),
              const SizedBox(height: 20),
              _SectionTitle(title: t.dashboardRecentOrders),
              const SizedBox(height: 10),
              _RecentOrdersList(orders: data.recentOrders),
            ],
          ),
        );
      },
    );
  }
}

class _Overview extends StatelessWidget {
  final int today;
  final int open;
  final int lowStock;

  const _Overview({
    required this.today,
    required this.open,
    required this.lowStock,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth > 900;
        final isMedium = c.maxWidth > 600;
        final crossAxisCount = isWide ? 3 : (isMedium ? 3 : 1);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWide ? 3.2 : 2.6,
          children: [
            _StatCard(title: t.dashboardTodayOrders, value: today.toString()),
            _StatCard(title: t.dashboardOpenOrders, value: open.toString()),
            _StatCard(title: t.dashboardLowStock, value: lowStock.toString()),
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
                Text('${localizations.formatShortDate(order.createdAt)} · ${numberFormat.format(order.total)}'),
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
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Card(
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
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
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
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
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
