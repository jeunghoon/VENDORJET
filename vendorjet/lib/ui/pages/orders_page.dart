import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/repositories/mock_repository.dart';
import 'package:vendorjet/ui/widgets/state_views.dart';

// 주문 목록 화면(플레이스홀더)
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final _repo = MockOrderRepository();
  final _queryCtrl = TextEditingController();
  List<Order> _items = const [];
  bool _loading = true;
  String? _error;
  OrderStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    _load();
    _queryCtrl.addListener(_onQuery);
  }

  @override
  void dispose() {
    _queryCtrl.removeListener(_onQuery);
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final query = _queryCtrl.text;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _repo.fetch(query: query, status: _statusFilter);
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = err.toString();
      });
    }
  }

  void _onQuery() {
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _queryCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: t.ordersSearchHint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          _StatusChips(
            selected: _statusFilter,
            onSelected: (value) {
              setState(() => _statusFilter = value);
              _load();
            },
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Builder(
              builder: (context) {
                if (_loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (_error != null) {
                  return StateMessageView(
                    icon: Icons.error_outline,
                    title: t.stateErrorMessage,
                    action: OutlinedButton.icon(
                      onPressed: _load,
                      icon: const Icon(Icons.refresh),
                      label: Text(t.stateRetry),
                    ),
                  );
                }
                if (_items.isEmpty) {
                  final filterLabel = _statusFilter == null ? null : _statusLabel(_statusFilter!, t);
                  return StateMessageView(
                    icon: Icons.inbox_outlined,
                    title: t.ordersEmptyMessage,
                    message: filterLabel == null ? null : t.ordersEmptyFiltered(filterLabel),
                  );
                }
                return ListView.separated(
                  itemBuilder: (context, i) {
                    final o = _items[i];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: color.secondary.withValues(alpha: 0.15),
                          child: Icon(Icons.shopping_bag_outlined, color: color.secondary),
                        ),
                        title: Text(o.code),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.orderListSubtitle(o.itemCount, o.total.toStringAsFixed(2)),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _statusLabel(o.status, t),
                              style: TextStyle(
                                color: color.secondary,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => context.go('/orders/${o.id}'),
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemCount: _items.length,
                );
              },
            ),
          ),
        ],
      ),
    );
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
}

class _StatusChips extends StatelessWidget {
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;

  const _StatusChips({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final items = <OrderStatus?>[null, ...OrderStatus.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (final status in items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(_label(status, t)),
                selected: selected == status,
                onSelected: (_) => onSelected(status),
              ),
            ),
        ],
      ),
    );
  }

  String _label(OrderStatus? status, AppLocalizations t) {
    if (status == null) return t.ordersFilterAll;
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
}
