import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/repositories/mock_repository.dart';
import 'package:vendorjet/services/sync/data_refresh_coordinator.dart';
import 'package:vendorjet/ui/pages/orders/order_form_sheet.dart';
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
  DataRefreshCoordinator? _refreshCoordinator;
  int _lastOrdersVersion = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _queryCtrl.addListener(_onQuery);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final coordinator = context.read<DataRefreshCoordinator>();
    if (_refreshCoordinator != coordinator) {
      _refreshCoordinator?.removeListener(_handleRefreshEvent);
      _refreshCoordinator = coordinator;
      _lastOrdersVersion = coordinator.ordersVersion;
      coordinator.addListener(_handleRefreshEvent);
    }
  }

  @override
  void dispose() {
    _refreshCoordinator?.removeListener(_handleRefreshEvent);
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

  void _handleRefreshEvent() {
    final coordinator = _refreshCoordinator;
    if (coordinator == null) return;
    if (coordinator.ordersVersion != _lastOrdersVersion) {
      _lastOrdersVersion = coordinator.ordersVersion;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              TextField(
                controller: _queryCtrl,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: t.ordersSearchHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
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
                      final filterLabel = _statusFilter == null
                          ? null
                          : _statusLabel(_statusFilter!, t);
                      return StateMessageView(
                        icon: Icons.inbox_outlined,
                        title: t.ordersEmptyMessage,
                        message: filterLabel == null
                            ? null
                            : t.ordersEmptyFiltered(filterLabel),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemBuilder: (context, i) {
                          final o = _items[i];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.secondary.withValues(
                                  alpha: 0.15,
                                ),
                                child: Icon(
                                  Icons.shopping_bag_outlined,
                                  color: color.secondary,
                                ),
                              ),
                              title: Text(o.code),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.orderListSubtitle(
                                      o.itemCount,
                                      o.total.toStringAsFixed(2),
                                    ),
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
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.chevron_right_rounded),
                                  PopupMenuButton<String>(
                                    onSelected: (value) {
                                      switch (value) {
                                        case 'edit':
                                          _openOrderForm(initial: o);
                                          break;
                                        case 'delete':
                                          _confirmDelete(o);
                                          break;
                                      }
                                    },
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        value: 'edit',
                                        child: Text(t.ordersEdit),
                                      ),
                                      PopupMenuItem(
                                        value: 'delete',
                                        child: Text(t.ordersDelete),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              onTap: () => context.go('/orders/${o.id}'),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: _items.length,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        Positioned(
          bottom: 16,
          right: 16,
          child: FloatingActionButton.extended(
            onPressed: () => _openOrderForm(),
            icon: const Icon(Icons.add),
            label: Text(t.ordersCreate),
          ),
        ),
      ],
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

  Future<void> _openOrderForm({Order? initial}) async {
    final t = AppLocalizations.of(context)!;
    final result = await showModalBottomSheet<OrderFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => OrderFormSheet(t: t, initial: initial),
    );
    if (result == null) return;
    final order = Order(
      id: initial?.id ?? '',
      code: result.code,
      itemCount: result.itemCount,
      total: result.total,
      createdAt: result.createdAt,
      status: result.status,
    );
    final saved = await _repo.save(order);
    if (!mounted) return;
    context.read<DataRefreshCoordinator>().notifyOrderChanged(saved);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(initial == null ? t.ordersCreated : t.ordersUpdated),
      ),
    );
  }

  Future<void> _confirmDelete(Order order) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.ordersDelete),
          content: Text(t.ordersDeleteConfirm(order.code)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.orderEditCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t.ordersDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await _repo.delete(order.id);
    if (!mounted) return;
    context.read<DataRefreshCoordinator>().notifyOrderChanged(order);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.ordersDeleted)));
  }
}

class _StatusChips extends StatelessWidget {
  final OrderStatus? selected;
  final ValueChanged<OrderStatus?> onSelected;

  const _StatusChips({required this.selected, required this.onSelected});

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
