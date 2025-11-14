import 'package:flutter/material.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/customer.dart';

class CustomerFormResult {
  final String name;
  final String contactName;
  final String email;
  final CustomerTier tier;

  const CustomerFormResult({
    required this.name,
    required this.contactName,
    required this.email,
    required this.tier,
  });
}

class CustomerFormSheet extends StatefulWidget {
  final AppLocalizations t;
  final Customer customer;

  const CustomerFormSheet({super.key, required this.t, required this.customer});

  @override
  State<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<CustomerFormSheet> {
  late final TextEditingController _nameCtrl = TextEditingController(
    text: widget.customer.name,
  );
  late final TextEditingController _contactCtrl = TextEditingController(
    text: widget.customer.contactName,
  );
  late final TextEditingController _emailCtrl = TextEditingController(
    text: widget.customer.email,
  );
  final _formKey = GlobalKey<FormState>();
  late CustomerTier _tier = widget.customer.tier;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _contactCtrl.dispose();
    _emailCtrl.dispose();
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
                      widget.customer.id.isEmpty
                          ? t.customersCreate
                          : t.customersEdit,
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
                controller: _nameCtrl,
                decoration: InputDecoration(
                  labelText: t.customersFormName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? t.customersFormName
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactCtrl,
                decoration: InputDecoration(
                  labelText: t.customersFormContact,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? t.customersFormContact
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: t.customersFormEmail,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) =>
                    value == null || value.isEmpty || !value.contains('@')
                    ? t.customersFormEmail
                    : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<CustomerTier>(
                initialValue: _tier,
                decoration: InputDecoration(
                  labelText: t.customersFormTier,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: [
                  for (final tier in CustomerTier.values)
                    DropdownMenuItem(
                      value: tier,
                      child: Text(_tierLabel(tier, t)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _tier = value);
                },
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(
                    widget.customer.id.isEmpty
                        ? t.customersCreate
                        : t.customersEdit,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    Navigator.of(context).pop(
      CustomerFormResult(
        name: _nameCtrl.text.trim(),
        contactName: _contactCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        tier: _tier,
      ),
    );
  }

  String _tierLabel(CustomerTier tier, AppLocalizations t) {
    switch (tier) {
      case CustomerTier.platinum:
        return t.customersTierPlatinum;
      case CustomerTier.gold:
        return t.customersTierGold;
      case CustomerTier.silver:
        return t.customersTierSilver;
    }
  }
}
