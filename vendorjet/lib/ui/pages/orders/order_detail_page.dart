import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/ui/widgets/notification_ticker.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/repositories/order_repository.dart';
import 'package:vendorjet/services/sync/data_refresh_coordinator.dart';
import 'package:vendorjet/ui/pages/orders/order_edit_sheet.dart';

class OrderDetailPage extends StatefulWidget {
  final String orderId;

  const OrderDetailPage({
    super.key,
    required this.orderId,
  });

  @override
  State<OrderDetailPage> createState() => _OrderDetailPageState();
}

class _OrderDetailPageState extends State<OrderDetailPage> {
  final _repo = OrderRepository();
  late final Future<Order?> _future = _repo.findById(widget.orderId);

  Order? _localOrder;
  DateTime? _plannedShipOverride;
  DateTime? _lastUpdatedOverride;
  String? _noteOverride;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;
    final numberFormat = NumberFormat.decimalPattern(t.localeName);

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/orders')),
        title: FutureBuilder<Order?>(
          future: _future,
          builder: (context, snapshot) {
            final code = (_localOrder ?? snapshot.data)?.code;
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.ordersDetailTitle),
                if (code != null) ...[
                  const SizedBox(width: 8),
                  Chip(label: Text(code)),
                ],
              ],
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: t.edit,
            onPressed: () => _openEditSheet(context),
          ),
        ],
      ),
      body: FutureBuilder<Order?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final order = snapshot.data;
          if (order == null) {
            return Center(
              child: Text(
                t.notFound,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          final currentOrder = _localOrder ?? order;
          final plannedShip = _plannedShipOverride ??
              currentOrder.desiredDeliveryDate ??
              _defaultPlannedShip(currentOrder);
          final lastUpdated = _lastUpdatedOverride ??
              currentOrder.statusUpdatedAt ??
              currentOrder.updatedAt ??
              currentOrder.createdAt;
          final note = (_noteOverride ?? currentOrder.updateNote ?? '').trim();

          final lines = _buildLines(currentOrder);
          final statusLabel = _statusLabel(currentOrder.status, t);
          final localizations = MaterialLocalizations.of(context);
          final fallbackOwner = currentOrder.createdBy?.trim().isNotEmpty == true
              ? currentOrder.createdBy!.trim()
              : t.orderBuyerUnknown;
          final channel = currentOrder.createdSource ?? 'manual';
          final buyerStaffName = (currentOrder.buyerUserName ?? '')
              .trim()
              .isNotEmpty
              ? currentOrder.buyerUserName!.trim()
              : (currentOrder.createdBy ?? '').trim();
          final buyerStaffEmail = currentOrder.buyerUserEmail?.trim() ?? '';
          final buyerStaffLabel =
              buyerStaffEmail.isNotEmpty ? '$buyerStaffName ($buyerStaffEmail)' : buyerStaffName;
          final owner = buyerStaffLabel.isNotEmpty ? buyerStaffLabel : fallbackOwner;

          final sortedEvents = [...currentOrder.events]
            ..sort((a, b) => a.createdAt.compareTo(b.createdAt));

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            flex: 7,
                            child: Text(
                              currentOrder.buyerName.isEmpty
                                  ? t.orderBuyerUnknown
                                  : currentOrder.buyerName,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                            ),
                          ),
                          Expanded(
                            flex: 3,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: Chip(
                                label: Text(
                                  statusLabel,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (buyerStaffLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              const Icon(Icons.person_outline, size: 18),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  '주문자 $buyerStaffLabel',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (currentOrder.buyerNote != null && currentOrder.buyerNote!.trim().isNotEmpty)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.sticky_note_2_outlined, size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                currentOrder.buyerNote!.trim(),
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              if ((currentOrder.buyerNote ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.sticky_note_2_outlined),
                    title: Text('구매자 메모'),
                    subtitle: Text(currentOrder.buyerNote ?? ''),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '주문 정보',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            label: '주문 입력일자',
                            value: localizations.formatMediumDate(currentOrder.createdAt),
                          ),
                          _InfoChip(
                            label: t.orderTotal,
                            value: numberFormat.format(currentOrder.total),
                          ),
                          _InfoChip(
                            label: t.orderItems,
                            value: '${currentOrder.itemCount}',
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: '접수자',
                        value: owner,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.campaign_outlined,
                        label: '접수 방식',
                        value: channel,
                      ),
                      const SizedBox(height: 8),
                      _InfoRow(
                        icon: Icons.update_outlined,
                        label: t.orderMetaLastUpdated,
                        value:
                            '${localizations.formatMediumDate(lastUpdated)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(lastUpdated))}',
                      ),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _InfoRow(
                          icon: Icons.note_outlined,
                          label: t.orderMetaNote,
                          value: note,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '품목 내역',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  Row(
                    children: [
                      const Icon(Icons.event_available_outlined, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        localizations.formatMediumDate(plannedShip),
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...lines.map(
                (line) => Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.primary.withValues(alpha: 0.1),
                      child: Text(line.position.toString()),
                    ),
                    title: Text(line.name),
                    subtitle: Text('${line.quantity} × ${numberFormat.format(line.unitPrice)}'),
                    trailing: Text(
                      numberFormat.format(line.total),
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ),
              if (lines.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(t.ordersEmptyMessage),
                  ),
                ),
              const SizedBox(height: 12),
              ExpansionTile(
                initiallyExpanded: false,
                leading: const Icon(Icons.history),
                title: const Text('변경 기록'),
                children: sortedEvents.isEmpty
                    ? [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text('변경 기록이 없습니다.'),
                        ),
                      ]
                    : sortedEvents
                        .map(
                          (e) => ListTile(
                            leading: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: color.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            title: Text(_timelineTitle(e)),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${localizations.formatMediumDate(e.createdAt)} · ${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(e.createdAt))}',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                if ((e.note ?? '').isNotEmpty)
                                  Text(
                                    e.note!,
                                    style: Theme.of(context).textTheme.bodyMedium,
                                  ),
                              ],
                            ),
                            trailing: Text(e.actor.isEmpty ? t.orderBuyerUnknown : e.actor),
                          ),
                        )
                        .toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final snapshot = await _future;
    if (!context.mounted || snapshot == null) return;
    final currentOrder = _localOrder ?? snapshot;
    final plannedShip = _plannedShipOverride ??
        currentOrder.desiredDeliveryDate ??
        _defaultPlannedShip(currentOrder);
    final note = (_noteOverride ?? currentOrder.updateNote ?? '').trim();

    final result = await showModalBottomSheet<OrderEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => OrderEditSheet(
        t: t,
        localeName: t.localeName,
        initialStatus: currentOrder.status,
        initialPlannedShip: plannedShip,
        initialNote: note,
        initialLines: currentOrder.lines,
        compactMode: false,
        orderCode: currentOrder.code,
        buyerName: currentOrder.buyerName,
        buyerContact: currentOrder.buyerContact,
        buyerNote: currentOrder.buyerNote ?? '',
        createdAt: currentOrder.createdAt,
      ),
    );

    if (!context.mounted || result == null) return;
    final updatedLines = result.lines;
    final updatedItemCount = updatedLines.fold<int>(0, (sum, l) => sum + l.quantity);
    final updatedTotal = updatedLines.fold<double>(0, (sum, l) => sum + l.lineTotal);

    final updatedOrder = currentOrder.copyWith(
      status: result.status,
      updateNote: result.note,
      desiredDeliveryDate: result.plannedShip,
      updatedAt: DateTime.now(),
      lines: updatedLines,
      itemCount: updatedItemCount,
      total: updatedTotal,
    );

    await _repo.save(updatedOrder);

    if (!context.mounted) return;

    setState(() {
      _localOrder = updatedOrder;
      _plannedShipOverride = updatedOrder.desiredDeliveryDate;
      _lastUpdatedOverride = updatedOrder.updatedAt;
      _noteOverride = updatedOrder.updateNote;
    });

    context.read<DataRefreshCoordinator>().notifyOrderChanged(updatedOrder);

    context.read<NotificationTicker>().push(t.orderEditSaved);
  }

  List<_OrderLine> _buildLines(Order order) {
    if (order.lines.isEmpty) return const [];
    return order.lines.asMap().entries.map((entry) {
      final idx = entry.key;
      final line = entry.value;
      final total = double.parse((line.quantity * line.unitPrice).toStringAsFixed(2));
      return _OrderLine(
        position: idx + 1,
        name: line.productName.isNotEmpty ? line.productName : line.productId,
        quantity: line.quantity,
        unitPrice: line.unitPrice,
        total: total,
      );
    }).toList();
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

DateTime _defaultPlannedShip(Order order) =>
    order.desiredDeliveryDate ?? order.createdAt.add(const Duration(days: 1));

String _timelineTitle(OrderEvent event) {
  if ((event.note ?? '').isNotEmpty) return event.note!;
  switch (event.action) {
    case 'created':
      return '주문 접수';
    case 'status_changed':
      return '상태 변경';
    case 'updated':
      return '주문 정보 수정';
    default:
      return event.action;
  }
}

class _OrderLine {
  final int position;
  final String name;
  final int quantity;
  final double unitPrice;
  final double total;

  const _OrderLine({
    required this.position,
    required this.name,
    required this.quantity,
    required this.unitPrice,
    required this.total,
  });
}

class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: theme.textTheme.labelSmall),
            const SizedBox(height: 2),
            Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
}
