import 'package:flutter/material.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/order.dart';

class OrderFormResult {
  final int itemCount;
  final double total;
  final DateTime createdAt;
  final OrderStatus status;
  final String buyerName;
  final String buyerContact;
  final String? buyerNote;

  const OrderFormResult({
    required this.itemCount,
    required this.total,
    required this.createdAt,
    required this.status,
    required this.buyerName,
    required this.buyerContact,
    this.buyerNote,
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
  late final TextEditingController _itemsCtrl = TextEditingController(
    text: widget.initial?.itemCount.toString() ?? '1',
  );
  late final TextEditingController _totalCtrl = TextEditingController(
    text: widget.initial?.total.toStringAsFixed(2) ?? '100.00',
  );
  late final TextEditingController _buyerNameCtrl = TextEditingController(
    text: widget.initial?.buyerName ?? '',
  );
  late final TextEditingController _buyerContactCtrl = TextEditingController(
    text: widget.initial?.buyerContact ?? '',
  );
  late final TextEditingController _buyerNoteCtrl = TextEditingController(
    text: widget.initial?.buyerNote ?? '',
  );
  final _formKey = GlobalKey<FormState>();
  late DateTime _date = widget.initial?.createdAt ?? DateTime.now();
  late OrderStatus _status = widget.initial?.status ?? OrderStatus.pending;
  late final bool _lockBuyer =
      widget.initial != null && widget.initial!.id.isNotEmpty;
  late final bool _lockLines =
      widget.initial != null && widget.initial!.id.isNotEmpty;

  @override
  void dispose() {
    _itemsCtrl.dispose();
    _totalCtrl.dispose();
    _buyerNameCtrl.dispose();
    _buyerContactCtrl.dispose();
    _buyerNoteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final codePreview = widget.initial?.code ?? t.ordersCodeAutoHint;

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
              const SizedBox(height: 12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.ordersFormCode),
                subtitle: Text(codePreview),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _buyerNameCtrl,
                readOnly: _lockBuyer,
                decoration: InputDecoration(
                  labelText: t.ordersFormBuyerName,
                  helperText: _lockBuyer ? t.ordersFormBuyerLockedHint : null,
                  prefixIcon: _lockBuyer ? const Icon(Icons.lock_outline) : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (_lockBuyer) return null;
                  if ((value ?? '').trim().isEmpty) {
                    return t.ordersFormBuyerName;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _buyerContactCtrl,
                readOnly: _lockBuyer,
                decoration: InputDecoration(
                  labelText: t.ordersFormBuyerContact,
                  helperText: _lockBuyer ? t.ordersFormBuyerLockedHint : null,
                  prefixIcon: _lockBuyer ? const Icon(Icons.lock_outline) : null,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (value) {
                  if (_lockBuyer) return null;
                  if ((value ?? '').trim().isEmpty) {
                    return t.ordersFormBuyerContact;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _buyerNoteCtrl,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: t.ordersFormBuyerNote,
                  hintText: t.ordersFormBuyerNoteHint,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _itemsCtrl,
                      readOnly: _lockLines,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: t.ordersFormItems,
                        helperText: _lockLines ? t.ordersFormQuantityLockedHint : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (_lockLines) return null;
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
                      readOnly: _lockLines,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(
                        labelText: t.ordersFormTotal,
                        helperText: _lockLines ? t.ordersFormQuantityLockedHint : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (_lockLines) return null;
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
                  child: Text(widget.initial == null ? t.ordersCreate : t.ordersEdit),
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
        itemCount: int.parse(_itemsCtrl.text.trim()),
        total: double.parse(
          double.parse(_totalCtrl.text.trim()).toStringAsFixed(2),
        ),
        createdAt: _date,
        status: _status,
        buyerName: _buyerNameCtrl.text.trim(),
        buyerContact: _buyerContactCtrl.text.trim(),
        buyerNote: _buyerNoteCtrl.text.trim().isEmpty ? null : _buyerNoteCtrl.text.trim(),
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
