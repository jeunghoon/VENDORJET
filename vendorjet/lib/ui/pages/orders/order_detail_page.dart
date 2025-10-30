import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/repositories/mock_repository.dart';
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
  final _repo = MockOrderRepository();
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
        title: Text(t.ordersDetailTitle),
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
          final plannedShip = _plannedShipOverride ?? _defaultPlannedShip(currentOrder);
          final lastUpdated = _lastUpdatedOverride ?? _defaultLastUpdated(currentOrder);
          final note = (_noteOverride ?? _defaultNote(currentOrder)).trim();

          final lines = _mockLines(currentOrder, t);
          final statusLabel = _statusLabel(currentOrder.status, t);
          final localizations = MaterialLocalizations.of(context);
          final owner = _ownerFor(currentOrder);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentOrder.code,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            label: t.orderPlacedOn,
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
                          _InfoChip(
                            label: t.ordersStatusLabel,
                            value: statusLabel,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.orderMetaTitle,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      _InfoRow(
                        icon: Icons.event_available_outlined,
                        label: t.orderMetaPlannedShip,
                        value: localizations.formatMediumDate(plannedShip),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.update_outlined,
                        label: t.orderMetaLastUpdated,
                        value: localizations.formatMediumDate(lastUpdated),
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.person_outline,
                        label: t.orderMetaOwner,
                        value: owner,
                      ),
                      if (note.isNotEmpty) ...[
                        const SizedBox(height: 10),
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
              const SizedBox(height: 16),
              Text(
                t.orderItems,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
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
    final plannedShip = _plannedShipOverride ?? _defaultPlannedShip(currentOrder);
    final note = (_noteOverride ?? _defaultNote(currentOrder)).trim();

    final result = await showModalBottomSheet<OrderEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (context) => OrderEditSheet(
        t: t,
        localeName: t.localeName,
        initialStatus: currentOrder.status,
        initialPlannedShip: plannedShip,
        initialNote: note,
      ),
    );

    if (!context.mounted || result == null) return;

    setState(() {
      _localOrder = Order(
        id: currentOrder.id,
        code: currentOrder.code,
        itemCount: currentOrder.itemCount,
        total: currentOrder.total,
        createdAt: currentOrder.createdAt,
        status: result.status,
      );
      _plannedShipOverride = result.plannedShip;
      _lastUpdatedOverride = DateTime.now();
      _noteOverride = result.note;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.orderEditSaved)),
    );
  }

  List<_OrderLine> _mockLines(Order order, AppLocalizations t) {
    final rnd = Random(order.id.hashCode);
    final count = max(1, order.itemCount);
    return List.generate(count, (index) {
      final qty = 1 + rnd.nextInt(4);
      final unit = ((rnd.nextDouble() * 80) + 20).clamp(10, 120).toDouble();
      final total = double.parse((qty * unit).toStringAsFixed(2));
      return _OrderLine(
        position: index + 1,
        name: t.orderLinePlaceholder(index + 1),
        quantity: qty,
        unitPrice: double.parse(unit.toStringAsFixed(2)),
        total: total,
      );
    });
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

String _ownerFor(Order order) {
  final owners = ['Alex Kim', 'Morgan Lee', 'Jamie Park', 'Taylor Choi', 'Jordan Han'];
  final index = order.id.hashCode.abs() % owners.length;
  return owners[index];
}

DateTime _defaultPlannedShip(Order order) => order.createdAt.add(Duration(days: 2 + order.id.hashCode.abs() % 3));

DateTime _defaultLastUpdated(Order order) => order.createdAt.add(Duration(hours: 10 + order.id.hashCode.abs() % 18));

String _defaultNote(Order order) {
  final notes = [
    'Follow up with shipping partner.',
    'Awaiting customer confirmation.',
    'Prepare return label just in case.',
    'Bundle with next outbound shipment.',
    'Flagged for finance review.',
  ];
  return notes[order.id.hashCode.abs() % notes.length];
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
