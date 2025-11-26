import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/repositories/order_repository.dart';
import 'package:vendorjet/services/sync/data_refresh_coordinator.dart';
import 'package:vendorjet/ui/pages/orders/order_edit_sheet.dart';
import 'package:vendorjet/ui/widgets/notification_ticker.dart';
import 'package:vendorjet/ui/widgets/state_views.dart';

class OrderListPreset {
  final bool todayOnly;
  final bool openOnly;

  const OrderListPreset({this.todayOnly = false, this.openOnly = false});

  factory OrderListPreset.fromQuery(Map<String, String> query) {
    final filter = query['filter'];
    return OrderListPreset(
      todayOnly: filter == 'today',
      openOnly: filter == 'open',
    );
  }
}

class OrdersPage extends StatefulWidget {
  final OrderListPreset preset;

  const OrdersPage({super.key, this.preset = const OrderListPreset()});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final _repo = OrderRepository();
  final _queryCtrl = TextEditingController();

  List<Order> _items = const [];
  bool _loading = true;
  String? _error;
  OrderStatus? _statusFilter;
  bool _presetToday = false;
  bool _presetOpen = false;

  DataRefreshCoordinator? _refreshCoordinator;
  int _lastOrdersVersion = 0;

  @override
  void initState() {
    super.initState();
    _applyPreset(widget.preset);
    _load();
    _queryCtrl.addListener(_onQuery);
  }

  @override
  void didUpdateWidget(covariant OrdersPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset.todayOnly != widget.preset.todayOnly ||
        oldWidget.preset.openOnly != widget.preset.openOnly) {
      _applyPreset(widget.preset);
      _load();
    }
  }

  void _applyPreset(OrderListPreset preset) {
    _presetToday = preset.todayOnly;
    _presetOpen = preset.openOnly;
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
      final dateFilter = _presetToday ? DateTime.now() : null;
      final items = await _repo.fetch(
        query: query,
        status: _statusFilter,
        openOnly: _presetOpen,
        dateEquals: dateFilter,
      );
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

  void _onQuery() => _load();

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
              _QuickFilterRow(
                todaySelected: _presetToday,
                openSelected: _presetOpen,
                onTodayChanged: (value) {
                  setState(() => _presetToday = value);
                  _load();
                },
                onOpenChanged: (value) {
                  setState(() => _presetOpen = value);
                  _load();
                },
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
                      String? message;
                      if (_presetToday) {
                        message = t.ordersEmptyFiltered(t.ordersFilterToday);
                      } else if (_presetOpen) {
                        message = t.ordersEmptyFiltered(t.ordersFilterOpen);
                      } else if (_statusFilter != null) {
                        message = t.ordersEmptyFiltered(
                          _statusLabel(_statusFilter!, t),
                        );
                      }
                      return StateMessageView(
                        icon: Icons.inbox_outlined,
                        title: t.ordersEmptyMessage,
                        message: message,
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
                                  if (o.buyerName.isNotEmpty)
                                    Text(
                                      o.buyerName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        color: color.onSurface,
                                      ),
                                    ),
                                  if (o.buyerContact.isNotEmpty)
                                    Text(
                                      o.buyerContact,
                                      style: Theme.of(context)
                                          .textTheme
                                          .labelSmall
                                          ?.copyWith(
                                            color: color.onSurfaceVariant,
                                          ),
                                    ),
                                  const SizedBox(height: 4),
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
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _openOrderForm(initial: o);
                                      break;
                                    case 'status':
                                      _changeStatus(o);
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
                                    value: 'status',
                                    child: Text(t.ordersChangeStatus),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(t.ordersDelete),
                                  ),
                                ],
                              ),
                              onTap: () => _openOrderEditor(o),
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
    final base = initial ??
        Order(
          id: '',
          code: '',
          itemCount: 0,
          total: 0,
          createdAt: DateTime.now(),
          status: OrderStatus.pending,
          buyerName: '',
          buyerContact: '',
          desiredDeliveryDate: DateTime.now().add(const Duration(days: 1)),
          lines: const [],
        );

    final result = await showModalBottomSheet<OrderEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => OrderEditSheet(
        t: t,
        localeName: t.localeName,
        initialStatus: base.status,
        initialPlannedShip: base.desiredDeliveryDate ?? DateTime.now().add(const Duration(days: 1)),
        initialNote: '',
        initialLines: base.lines,
        compactMode: false,
        orderCode: '',
        buyerName: '',
        buyerContact: '',
        buyerNote: '',
        createdAt: base.createdAt,
      ),
    );
    if (result == null) return;

    final now = DateTime.now();
    final order = base.copyWith(
      itemCount: _calcItemCount(result.lines),
      total: result.lines.fold<double>(0, (s, l) => s + l.lineTotal),
      createdAt: base.createdAt,
      desiredDeliveryDate: result.plannedShip,
      status: result.status,
      buyerName: base.buyerName,
      buyerContact: base.buyerContact,
      buyerNote: result.note.isEmpty ? base.buyerNote : result.note,
      lines: result.lines,
      updatedAt: now,
      updateNote: t.ordersCreated,
    );
    final saved = await _repo.save(order);
    if (!mounted) return;
    context.read<DataRefreshCoordinator>().notifyOrderChanged(saved);
    await _load();
    if (!mounted) return;
    context.read<NotificationTicker>().push(t.ordersCreated);
  }

  Future<void> _openOrderEditor(Order order, {bool compact = false}) async {
    final t = AppLocalizations.of(context)!;
    final full = await _repo.findById(order.id) ?? order;
    if (!mounted) return;
    final result = await showModalBottomSheet<OrderEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => OrderEditSheet(
        t: t,
        localeName: t.localeName,
        initialStatus: full.status,
        initialPlannedShip: full.desiredDeliveryDate ?? DateTime.now(),
        initialNote: full.updateNote ?? '',
        initialLines: full.lines,
        compactMode: compact,
        orderCode: full.code,
        buyerName: full.buyerName,
        buyerContact: full.buyerContact,
        buyerNote: full.buyerNote ?? '',
        createdAt: full.createdAt,
      ),
    );
    if (result == null) return;
    if (!mounted) return;
    final updatedLines = compact ? full.lines : result.lines;
    final updatedItemCount = updatedLines.fold<int>(0, (sum, l) => sum + l.quantity);
    final updatedTotal = compact
        ? (result.totalOverride ?? full.total)
        : updatedLines.fold<double>(0, (sum, l) => sum + l.lineTotal);
    final updatedOrder = full.copyWith(
      status: result.status,
      updateNote: result.note,
      desiredDeliveryDate: result.plannedShip,
      updatedAt: DateTime.now(),
      lines: updatedLines,
      itemCount: updatedItemCount,
      total: updatedTotal,
    );
    final saved = await _repo.save(updatedOrder);
    if (!mounted) return;
    context.read<DataRefreshCoordinator>().notifyOrderChanged(saved);
    await _load();
    if (!mounted) return;
    context.read<NotificationTicker>().push(t.ordersUpdated);
  }

  int _calcItemCount(List<OrderLine> lines) =>
      lines.fold<int>(0, (sum, l) => sum + l.quantity);

  Future<void> _changeStatus(Order order) async {
    final t = AppLocalizations.of(context)!;
    final selected = await showModalBottomSheet<OrderStatus>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.ordersChangeStatus,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 12),
                for (final status in OrderStatus.values)
                  ListTile(
                    title: Text(_statusLabel(status, t)),
                    trailing: order.status == status
                        ? const Icon(Icons.check, color: Colors.green)
                        : null,
                    onTap: () => Navigator.of(context).pop(status),
                  ),
              ],
            ),
          ),
        );
      },
    );
    if (selected == null || selected == order.status) return;
    final updated = order.copyWith(status: selected);
    final now = DateTime.now();
    await _repo.save(
      updated.copyWith(
        updatedAt: now,
        updateNote: t.ordersStatusUpdated,
      ),
    );
    if (!mounted) return;
    context.read<DataRefreshCoordinator>().notifyOrderChanged(updated);
    await _load();
    if (!mounted) return;
    context.read<NotificationTicker>().push(t.ordersStatusUpdated);
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
    context.read<NotificationTicker>().push(t.ordersDeleted);
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

class _QuickFilterRow extends StatelessWidget {
  final bool todaySelected;
  final bool openSelected;
  final ValueChanged<bool> onTodayChanged;
  final ValueChanged<bool> onOpenChanged;

  const _QuickFilterRow({
    required this.todaySelected,
    required this.openSelected,
    required this.onTodayChanged,
    required this.onOpenChanged,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Row(
      children: [
        FilterChip(
          label: Text(t.ordersFilterToday),
          selected: todaySelected,
          onSelected: onTodayChanged,
        ),
        const SizedBox(width: 8),
        FilterChip(
          label: Text(t.ordersFilterOpen),
          selected: openSelected,
          onSelected: onOpenChanged,
        ),
      ],
    );
  }
}
