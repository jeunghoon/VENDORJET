import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/product.dart';

class ProductEditResult {
  final String sku;
  final String name;
  final double price;
  final int variantsCount;
  final ProductCategory category;
  final bool lowStock;

  const ProductEditResult({
    required this.sku,
    required this.name,
    required this.price,
    required this.variantsCount,
    required this.category,
    required this.lowStock,
  });
}

class ProductEditSheet extends StatefulWidget {
  final AppLocalizations t;
  final Product product;

  const ProductEditSheet({super.key, required this.t, required this.product});

  @override
  State<ProductEditSheet> createState() => _ProductEditSheetState();
}

class _ProductEditSheetState extends State<ProductEditSheet> {
  late final TextEditingController _skuController = TextEditingController(
    text: widget.product.sku,
  );
  late final TextEditingController _nameController = TextEditingController(
    text: widget.product.name,
  );
  late final TextEditingController _priceController = TextEditingController(
    text: widget.product.price.toStringAsFixed(2),
  );
  late final TextEditingController _variantsController = TextEditingController(
    text: widget.product.variantsCount.toString(),
  );
  final _formKey = GlobalKey<FormState>();
  late ProductCategory _category = widget.product.category;
  late bool _lowStock = widget.product.lowStock;

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _variantsController.dispose();
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
                      t.productEditTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    tooltip: t.productEditCancel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _skuController,
                decoration: InputDecoration(
                  labelText: t.productEditSku,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t.productEditSku;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: t.productEditName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return t.productEditNameRequired;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                decoration: InputDecoration(
                  labelText: t.productEditPrice,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  final price = double.tryParse(value ?? '');
                  if (price == null || price <= 0) {
                    return t.productEditPriceInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _variantsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(
                  labelText: t.productEditVariants,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) {
                  final variants = int.tryParse(value ?? '');
                  if (variants == null || variants < 1) {
                    return t.productEditVariantsInvalid;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<ProductCategory>(
                initialValue: _category,
                decoration: InputDecoration(
                  labelText: t.productEditCategory,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 12,
                  ),
                ),
                items: [
                  for (final category in ProductCategory.values)
                    DropdownMenuItem(
                      value: category,
                      child: Text(_categoryLabel(category, t)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _category = value);
                  }
                },
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                value: _lowStock,
                contentPadding: EdgeInsets.zero,
                title: Text(t.productEditLowStock),
                onChanged: (value) => setState(() => _lowStock = value),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _submit,
                  child: Text(t.productEditSave),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final price = double.parse(_priceController.text.trim());
    final variants = int.parse(_variantsController.text.trim());
    Navigator.of(context).pop(
      ProductEditResult(
        sku: _skuController.text.trim(),
        name: _nameController.text.trim(),
        price: double.parse(price.toStringAsFixed(2)),
        variantsCount: variants,
        category: _category,
        lowStock: _lowStock,
      ),
    );
  }

  String _categoryLabel(ProductCategory category, AppLocalizations t) {
    switch (category) {
      case ProductCategory.beverages:
        return t.productsCategoryBeverages;
      case ProductCategory.snacks:
        return t.productsCategorySnacks;
      case ProductCategory.household:
        return t.productsCategoryHousehold;
      case ProductCategory.fashion:
        return t.productsCategoryFashion;
      case ProductCategory.electronics:
        return t.productsCategoryElectronics;
    }
  }
}
