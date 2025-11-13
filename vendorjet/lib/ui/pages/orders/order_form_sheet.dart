import 'package:flutter/material.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/order.dart';

class OrderFormResult {
  final String code;
  final int itemCount;
  final double total;
  final DateTime createdAt;
  final OrderStatus status;

  const OrderFormResult({
    required this.code,
    required this.itemCount,
    required this.total,
    required this.createdAt,
    required this.status,
  });
}

class OrderFormSheet extends StatefulWidget {
  final AppLocalizations t;
  final Order? initial;

  const OrderFormSheet({super.key, required this.t, this.initial});

  @override
  State<OrderFormSheet> createState() => _OrderFormSheetState();
}

class _OrderFormSheetState extends State<OrderFormSheet> {
  late final TextEditingController _codeCtrl = TextEditingController(
    text: widget.initial?.code ?? '',
  );
  late final TextEditingController _itemsCtrl = TextEditingController(
    text: widget.initial?.itemCount.toString() ?? '1',
  );
  late final TextEditingController _totalCtrl = TextEditingController(
    text: widget.initial?.total.toStringAsFixed(2) ?? '100.00',
  );
  final _formKey = GlobalKey<FormState>();
  late DateTime _date = widget.initial?.createdAt ?? DateTime.now();
  late OrderStatus _status = widget.initial?.status ?? OrderStatus.pending;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _itemsCtrl.dispose();
    _totalCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;

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
                      widget.initial == null ? t.ordersCreate : t.ordersEdit,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _codeCtrl,
                decoration: InputDecoration(
                  labelText: t.ordersFormCode,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? t.ordersFormCode
                    : null,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _itemsCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: t.ordersFormItems,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        if (parsed == null || parsed < 1) {
                          return t.ordersFormItems;
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _totalCtrl,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: InputDecoration(
                        labelText: t.ordersFormTotal,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        final parsed = double.tryParse(value ?? '');
                        if (parsed == null || parsed <= 0) {
                          return t.ordersFormTotal;
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<OrderStatus>(
                initialValue: _status,
                decoration: InputDecoration(
                  labelText: t.ordersStatusLabel,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  for (final status in OrderStatus.values)
                    DropdownMenuItem(
                      value: status,
                      child: Text(_statusLabel(status, t)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _status = value);
                },
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _pickDate,
                icon: const Icon(Icons.calendar_today_outlined),
                label: Text(
                  '${t.ordersFormDate}: ${MaterialLocalizations.of(context).formatMediumDate(_date)}',
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(
                    widget.initial == null ? t.ordersCreate : t.ordersEdit,
                  ),
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
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(
        () => _date = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _date.hour,
          _date.minute,
        ),
      );
    }
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      OrderFormResult(
        code: _codeCtrl.text.trim(),
        itemCount: int.parse(_itemsCtrl.text.trim()),
        total: double.parse(
          double.parse(_totalCtrl.text.trim()).toStringAsFixed(2),
        ),
        createdAt: _date,
        status: _status,
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
