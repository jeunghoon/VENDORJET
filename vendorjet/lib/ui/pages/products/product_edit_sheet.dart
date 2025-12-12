import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/product.dart';
import 'package:vendorjet/services/auth/auth_controller.dart';
import 'package:vendorjet/models/tenant.dart';

class ProductEditResult {
  final String sku;
  final String name;
  final double price;
  final int variantsCount;
  final List<String> categoryPath;
  final Set<ProductTag> tags;
  final bool lowStock;
  final String? hsCode;
  final String? originCountry;
  final String? uom;
  final String? incoterm;
  final bool isPerishable;
  final ProductPackaging? packaging;
  final ProductTradeTerm? tradeTerm;
  final ProductEta? eta;

  const ProductEditResult({
    required this.sku,
    required this.name,
    required this.price,
    required this.variantsCount,
    required this.categoryPath,
    required this.tags,
    required this.lowStock,
    this.hsCode,
    this.originCountry,
    this.uom,
    this.incoterm,
    this.isPerishable = false,
    this.packaging,
    this.tradeTerm,
    this.eta,
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
  late final TextEditingController _hsCodeController;
  late final TextEditingController _originController;
  late final TextEditingController _uomController;
  late String _incoterm;
  late bool _isPerishable;
  late final TextEditingController _packLengthCtrl;
  late final TextEditingController _packWidthCtrl;
  late final TextEditingController _packHeightCtrl;
  late final TextEditingController _packUnitsCtrl;
  late final TextEditingController _packNetCtrl;
  late final TextEditingController _packGrossCtrl;
  late final TextEditingController _packBarcodeCtrl;
  late final TextEditingController _tradeCurrencyCtrl;
  late final TextEditingController _tradeFreightCtrl;
  late final TextEditingController _tradeInsuranceCtrl;
  late final TextEditingController _tradeLeadTimeCtrl;
  late final TextEditingController _tradeMoqCtrl;
  late final TextEditingController _tradeMoqUnitCtrl;
  late final TextEditingController _etaVesselCtrl;
  late final TextEditingController _etaVoyageCtrl;
  DateTime? _etaDate;
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
    _hsCodeController = TextEditingController(text: widget.product.hsCode ?? '');
    _originController =
        TextEditingController(text: widget.product.originCountry ?? '');
    _uomController = TextEditingController(text: widget.product.uom ?? 'EA');
    _incoterm = widget.product.incoterm ?? 'FOB';
    _isPerishable = widget.product.isPerishable;
    final packaging = widget.product.packaging;
    _packLengthCtrl = TextEditingController(
        text: packaging?.lengthCm?.toString() ?? '');
    _packWidthCtrl =
        TextEditingController(text: packaging?.widthCm?.toString() ?? '');
    _packHeightCtrl =
        TextEditingController(text: packaging?.heightCm?.toString() ?? '');
    _packUnitsCtrl =
        TextEditingController(text: packaging?.unitsPerPack?.toString() ?? '');
    _packNetCtrl =
        TextEditingController(text: packaging?.netWeightKg?.toString() ?? '');
    _packGrossCtrl = TextEditingController(
        text: packaging?.grossWeightKg?.toString() ?? '');
    _packBarcodeCtrl =
        TextEditingController(text: packaging?.barcode ?? '');

    final trade = widget.product.tradeTerm;
    _tradeCurrencyCtrl =
        TextEditingController(text: trade?.currency ?? 'USD');
    _tradeFreightCtrl =
        TextEditingController(text: trade?.freight?.toString() ?? '');
    _tradeInsuranceCtrl =
        TextEditingController(text: trade?.insurance?.toString() ?? '');
    _tradeLeadTimeCtrl =
        TextEditingController(text: trade?.leadTimeDays?.toString() ?? '');
    _tradeMoqCtrl =
        TextEditingController(text: trade?.minOrderQty?.toString() ?? '');
    _tradeMoqUnitCtrl =
        TextEditingController(text: trade?.moqUnit ?? 'carton');

    final eta = widget.product.eta;
    _etaDate = eta?.eta ?? eta?.etd;
    _etaVesselCtrl = TextEditingController(text: eta?.vessel ?? '');
    _etaVoyageCtrl = TextEditingController(text: eta?.voyageNo ?? '');
  }

  @override
  void dispose() {
    _skuController.dispose();
    _nameController.dispose();
    _priceController.dispose();
    _variantsController.dispose();
    _hsCodeController.dispose();
    _originController.dispose();
    _uomController.dispose();
    _packLengthCtrl.dispose();
    _packWidthCtrl.dispose();
    _packHeightCtrl.dispose();
    _packUnitsCtrl.dispose();
    _packNetCtrl.dispose();
    _packGrossCtrl.dispose();
    _packBarcodeCtrl.dispose();
    _tradeCurrencyCtrl.dispose();
    _tradeFreightCtrl.dispose();
    _tradeInsuranceCtrl.dispose();
    _tradeLeadTimeCtrl.dispose();
    _tradeMoqCtrl.dispose();
    _tradeMoqUnitCtrl.dispose();
    _etaVesselCtrl.dispose();
    _etaVoyageCtrl.dispose();
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
    final auth = context.read<AuthController>();
    final canEditFinance = auth.role != TenantMemberRole.staff;

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
          child: SingleChildScrollView(
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
                enabled: canEditFinance,
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
              const SizedBox(height: 12),
              Text(
                t.productTradeSectionTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 12),
              _buildTextField(controller: _hsCodeController, label: t.productHsCode),
              const SizedBox(height: 10),
              _buildTextField(controller: _originController, label: t.productOriginCountry),
              const SizedBox(height: 10),
              _buildTextField(controller: _uomController, label: t.productUom),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _incoterm,
                items: const [
                  DropdownMenuItem(value: 'FOB', child: Text('FOB')),
                  DropdownMenuItem(value: 'CIF', child: Text('CIF')),
                  DropdownMenuItem(value: 'EXW', child: Text('EXW')),
                  DropdownMenuItem(value: 'DAP', child: Text('DAP')),
                ],
                decoration: InputDecoration(
                  labelText: t.productIncoterm,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (value) => setState(() => _incoterm = value ?? 'FOB'),
              ),
              SwitchListTile.adaptive(
                value: _isPerishable,
                contentPadding: EdgeInsets.zero,
                title: Text(t.productPerishable),
                onChanged: (value) => setState(() => _isPerishable = value),
              ),
              const SizedBox(height: 8),
              Text(
                t.productPackagingSectionTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _packLengthCtrl,
                      label: '${t.productPackagingDimensions} (L)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _packWidthCtrl,
                      label: '${t.productPackagingDimensions} (W)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _packHeightCtrl,
                      label: '${t.productPackagingDimensions} (H)',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _packUnitsCtrl,
                      label: t.productPackagingUnitsPerPack,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _packNetCtrl,
                      label: t.productPackagingWeight,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _packGrossCtrl,
                      label: '${t.productPackagingWeight} +',
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _packBarcodeCtrl,
                label: 'Barcode',
              ),
              const SizedBox(height: 12),
              Text(
                t.productTradeTermSectionTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _tradeCurrencyCtrl,
                      label: 'Currency',
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _tradeFreightCtrl,
                      label: t.productTradeFreight,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _tradeInsuranceCtrl,
                      label: t.productTradeInsurance,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _buildTextField(
                      controller: _tradeLeadTimeCtrl,
                      label: t.productTradeLeadTime,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _tradeMoqCtrl,
                      label: t.productTradeMoq,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _tradeMoqUnitCtrl,
                      label: 'MOQ Unit',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                t.productEtaSectionTitle,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildDateField(
                      label: t.productEtaEta,
                      value: _etaDate,
                      onPick: () => _pickEtaDate(context),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _etaVesselCtrl,
                      label: t.productEtaVessel,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTextField(
                      controller: _etaVoyageCtrl,
                      label: 'Voyage',
                    ),
                  ),
                ],
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
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime? value,
    required VoidCallback onPick,
  }) {
    final t = widget.t;
    final display = value == null
        ? t.notProvided
        : DateFormat('yyyy-MM-dd').format(value);
    return InkWell(
      onTap: onPick,
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Text(display),
      ),
    );
  }

  Future<void> _pickEtaDate(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _etaDate ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365)),
    );
    if (picked != null) {
      setState(() => _etaDate = picked);
    }
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
    double? parseDouble(String? value) {
      if (value == null || value.trim().isEmpty) return null;
      return double.tryParse(value.trim());
    }

    int? parseInt(String? value) {
      if (value == null || value.trim().isEmpty) return null;
      return int.tryParse(value.trim());
    }

    ProductPackaging? packaging;
    if (_packLengthCtrl.text.isNotEmpty ||
        _packWidthCtrl.text.isNotEmpty ||
        _packHeightCtrl.text.isNotEmpty ||
        _packUnitsCtrl.text.isNotEmpty) {
      packaging = ProductPackaging(
        packType: 'carton',
        lengthCm: parseDouble(_packLengthCtrl.text),
        widthCm: parseDouble(_packWidthCtrl.text),
        heightCm: parseDouble(_packHeightCtrl.text),
        unitsPerPack: parseInt(_packUnitsCtrl.text),
        netWeightKg: parseDouble(_packNetCtrl.text),
        grossWeightKg: parseDouble(_packGrossCtrl.text),
        barcode: _packBarcodeCtrl.text.trim().isEmpty
            ? null
            : _packBarcodeCtrl.text.trim(),
      );
    }

    ProductTradeTerm? tradeTerm;
    if (_tradeCurrencyCtrl.text.isNotEmpty) {
      tradeTerm = ProductTradeTerm(
        incoterm: _incoterm,
        currency: _tradeCurrencyCtrl.text.trim(),
        price: double.tryParse(_priceController.text.trim()) ?? 0,
        portOfLoading: null,
        portOfDischarge: null,
        freight: parseDouble(_tradeFreightCtrl.text),
        insurance: parseDouble(_tradeInsuranceCtrl.text),
        leadTimeDays: parseInt(_tradeLeadTimeCtrl.text),
        minOrderQty: parseInt(_tradeMoqCtrl.text),
        moqUnit:
            _tradeMoqUnitCtrl.text.trim().isEmpty ? null : _tradeMoqUnitCtrl.text.trim(),
      );
    }

    ProductEta? eta;
    if (_etaDate != null || _etaVesselCtrl.text.isNotEmpty) {
      eta = ProductEta(
        eta: _etaDate,
        vessel: _etaVesselCtrl.text.trim().isEmpty ? null : _etaVesselCtrl.text.trim(),
        voyageNo: _etaVoyageCtrl.text.trim().isEmpty ? null : _etaVoyageCtrl.text.trim(),
      );
    }

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
        hsCode: _hsCodeController.text.trim().isEmpty
            ? null
            : _hsCodeController.text.trim(),
        originCountry: _originController.text.trim().isEmpty
            ? null
            : _originController.text.trim(),
        uom: _uomController.text.trim().isEmpty
            ? null
            : _uomController.text.trim(),
        incoterm: _incoterm,
        isPerishable: _isPerishable,
        packaging: packaging,
        tradeTerm: tradeTerm,
        eta: eta,
      ),
    );
  }
}
