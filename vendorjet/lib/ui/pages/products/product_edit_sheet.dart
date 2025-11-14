import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/product.dart';

class ProductEditResult {
  final String sku;
  final String name;
  final double price;
  final int variantsCount;
  final List<String> categoryPath;
  final Set<ProductTag> tags;
  final bool lowStock;

  const ProductEditResult({
    required this.sku,
    required this.name,
    required this.price,
    required this.variantsCount,
    required this.categoryPath,
    required this.tags,
    required this.lowStock,
  });
}

class ProductEditSheet extends StatefulWidget {
  final AppLocalizations t;
  final Product product;
  final List<List<String>> categoryPresets;

  const ProductEditSheet({
    super.key,
    required this.t,
    required this.product,
    required this.categoryPresets,
  });

  @override
  State<ProductEditSheet> createState() => _ProductEditSheetState();
}

class _ProductEditSheetState extends State<ProductEditSheet> {
  late final TextEditingController _skuController;
  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _variantsController;
  late final List<TextEditingController> _categoryCtrls;
  late final bool _useCategoryPresets;
  List<String?> _selectedCategories = [];
  final _formKey = GlobalKey<FormState>();
  late bool _lowStock;
  late final Set<ProductTag> _tags;

  @override
  void initState() {
    super.initState();
    _skuController = TextEditingController(text: widget.product.sku);
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(
      text: widget.product.price.toStringAsFixed(2),
    );
    _variantsController = TextEditingController(
      text: widget.product.variantsCount.toString(),
    );
    _useCategoryPresets = widget.categoryPresets.isNotEmpty;
    if (_useCategoryPresets) {
      _categoryCtrls = const [];
      _selectedCategories = List.generate(
        3,
        (index) => index < widget.product.categories.length
            ? widget.product.categories[index]
            : null,
      );
    } else {
      _categoryCtrls = List.generate(
        3,
        (index) => TextEditingController(
          text: index < widget.product.categories.length
              ? widget.product.categories[index]
              : '',
        ),
      );
    }
    _lowStock = widget.product.lowStock;
    _tags = {...widget.product.tags};
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _variantsController.dispose();
    if (!_useCategoryPresets) {
      for (final ctrl in _categoryCtrls) {
        ctrl.dispose();
      }
    }
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
                validator: (value) => value == null || value.trim().isEmpty
                    ? t.productEditSku
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: t.productEditName,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                validator: (value) => value == null || value.trim().isEmpty
                    ? t.productEditNameRequired
                    : null,
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
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
              const SizedBox(height: 12),
              if (_useCategoryPresets)
                ...List.generate(3, (index) {
                  return Padding(
                    padding: EdgeInsets.only(bottom: index == 2 ? 0 : 12),
                    child: _buildCategoryDropdown(index),
                  );
                })
              else
                ...List.generate(_categoryCtrls.length, (index) {
                  final label = t.productCategoryLevel(index + 1);
                  return Padding(
                    padding: EdgeInsets.only(
                      bottom: index == _categoryCtrls.length - 1 ? 0 : 12,
                    ),
                    child: TextFormField(
                      controller: _categoryCtrls[index],
                      decoration: InputDecoration(
                        labelText: label,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (index == 0 &&
                            (value == null || value.trim().isEmpty)) {
                          return t.productCategoryLevelRequired;
                        }
                        return null;
                      },
                    ),
                  );
                }),
              if (_useCategoryPresets)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    t.productCategoriesManageHint,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Theme.of(context).hintColor),
                  ),
                ),
              const SizedBox(height: 12),
              SwitchListTile.adaptive(
                value: _lowStock,
                contentPadding: EdgeInsets.zero,
                title: Text(t.productEditLowStock),
                onChanged: (value) => setState(() => _lowStock = value),
              ),
              SwitchListTile.adaptive(
                value: _tags.contains(ProductTag.featured),
                contentPadding: EdgeInsets.zero,
                title: Text(t.productTagFeatured),
                onChanged: (value) => setState(() {
                  value
                      ? _tags.add(ProductTag.featured)
                      : _tags.remove(ProductTag.featured);
                }),
              ),
              SwitchListTile.adaptive(
                value: _tags.contains(ProductTag.discounted),
                contentPadding: EdgeInsets.zero,
                title: Text(t.productTagDiscounted),
                onChanged: (value) => setState(() {
                  value
                      ? _tags.add(ProductTag.discounted)
                      : _tags.remove(ProductTag.discounted);
                }),
              ),
              SwitchListTile.adaptive(
                value: _tags.contains(ProductTag.newArrival),
                contentPadding: EdgeInsets.zero,
                title: Text(t.productTagNew),
                onChanged: (value) => setState(() {
                  value
                      ? _tags.add(ProductTag.newArrival)
                      : _tags.remove(ProductTag.newArrival);
                }),
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

  Widget _buildCategoryDropdown(int level) {
    final t = widget.t;
    final label = t.productCategoryLevel(level + 1);
    final isFirstLevel = level == 0;
    final parentSelected =
        level == 0 ? true : (_selectedCategories[level - 1]?.isNotEmpty ?? false);
    final options = _categoryOptionsForLevel(level);
    final items = <DropdownMenuItem<String?>>[
      if (!isFirstLevel)
        DropdownMenuItem<String?>(
          value: null,
          child: Text(t.productCategoryNone),
        ),
      for (final option in options)
        DropdownMenuItem<String?>(
          value: option,
          child: Text(option),
        ),
    ];
    return DropdownButtonFormField<String?>(
      initialValue:
          _selectedCategories.length > level ? _selectedCategories[level] : null,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      items: items,
      onChanged: parentSelected ? (value) => _onCategoryChanged(level, value) : null,
      validator: (value) {
        if (isFirstLevel && (value == null || value.isEmpty)) {
          return t.productCategoryLevelRequired;
        }
        return null;
      },
    );
  }

  List<String> _categoryOptionsForLevel(int level) {
    if (level == 0) {
      final options = widget.categoryPresets.map((path) => path.first).toSet().toList()
        ..sort();
      return options;
    }
    final options = <String>{};
    for (final path in widget.categoryPresets) {
      if (path.length <= level) continue;
      var matches = true;
      for (var i = 0; i < level; i++) {
        final selected = _selectedCategories[i];
        if (selected == null || selected.isEmpty) {
          matches = false;
          break;
        }
        if (path.length <= i || path[i] != selected) {
          matches = false;
          break;
        }
      }
      if (!matches) continue;
      options.add(path[level]);
    }
    final list = options.toList()..sort();
    return list;
  }

  void _onCategoryChanged(int level, String? value) {
    if (_selectedCategories.length < 3) {
      _selectedCategories = List<String?>.from(
        _selectedCategories + List<String?>.filled(3 - _selectedCategories.length, null),
      );
    }
    setState(() {
      _selectedCategories[level] = value;
      for (var i = level + 1; i < _selectedCategories.length; i++) {
        _selectedCategories[i] = null;
      }
    });
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final categories = _useCategoryPresets
        ? _selectedCategories.whereType<String>().toList()
        : _categoryCtrls
            .map((ctrl) => ctrl.text.trim())
            .where((value) => value.isNotEmpty)
            .toList();
    Navigator.of(context).pop(
      ProductEditResult(
        sku: _skuController.text.trim(),
        name: _nameController.text.trim(),
        price: double.parse(
          double.parse(_priceController.text.trim()).toStringAsFixed(2),
        ),
        variantsCount: int.parse(_variantsController.text.trim()),
        categoryPath: categories,
        tags: _tags,
        lowStock: _lowStock,
      ),
    );
  }
}
