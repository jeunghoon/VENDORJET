import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/order.dart';

class OrderEditResult {
  final OrderStatus status;
  final DateTime plannedShip;
  final String note;

  const OrderEditResult({
    required this.status,
    required this.plannedShip,
    required this.note,
  });
}

class OrderEditSheet extends StatefulWidget {
  final AppLocalizations t;
  final String localeName;
  final OrderStatus initialStatus;
  final DateTime initialPlannedShip;
  final String initialNote;

  const OrderEditSheet({
    super.key,
    required this.t,
    required this.localeName,
    required this.initialStatus,
    required this.initialPlannedShip,
    required this.initialNote,
  });

  @override
  State<OrderEditSheet> createState() => _OrderEditSheetState();
}

class _OrderEditSheetState extends State<OrderEditSheet> {
  late OrderStatus _status = widget.initialStatus;
  late DateTime _plannedShip = widget.initialPlannedShip;
  late final TextEditingController _dateController = TextEditingController(
    text: DateFormat.yMMMd(widget.localeName).format(widget.initialPlannedShip),
  );
  late final TextEditingController _noteController = TextEditingController(
    text: widget.initialNote,
  );
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _dateController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final statuses = OrderStatus.values;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      t.orderEditTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: t.orderEditCancel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(t.orderEditStatusLabel, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              DropdownButtonFormField<OrderStatus>(
                initialValue: _status,
                items: [
                  for (final status in statuses)
                    DropdownMenuItem(
                      value: status,
                      child: Text(_statusLabel(status, t)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
                decoration: InputDecoration(
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
              ),
              const SizedBox(height: 16),
              Text(t.orderEditPlannedShip, style: Theme.of(context).textTheme.labelMedium),
              const SizedBox(height: 6),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                decoration: InputDecoration(
                  suffixIcon: const Icon(Icons.calendar_today_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onTap: _pickDate,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _noteController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: t.orderEditNote,
                  hintText: t.orderEditNoteHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(t.orderEditSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _plannedShip,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() {
        _plannedShip = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _plannedShip.hour,
          _plannedShip.minute,
        );
        _dateController.text = DateFormat.yMMMd(widget.localeName).format(_plannedShip);
      });
    }
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop(
      OrderEditResult(
        status: _status,
        plannedShip: _plannedShip,
        note: _noteController.text.trim(),
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
