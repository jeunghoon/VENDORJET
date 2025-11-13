import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/product.dart';
import 'package:vendorjet/repositories/mock_repository.dart';
import 'package:vendorjet/services/import/mock_import_service.dart';
import 'package:vendorjet/services/sync/data_refresh_coordinator.dart';
import 'package:vendorjet/ui/pages/products/product_edit_sheet.dart';
import 'package:vendorjet/ui/widgets/state_views.dart';

class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _repo = MockProductRepository();
  final _importService = MockCsvImportService();
  final _queryCtrl = TextEditingController();
  List<Product> _items = const [];
  bool _loading = true;
  String? _error;
  ProductCategory? _categoryFilter;
  DataRefreshCoordinator? _refreshCoordinator;
  int _lastProductsVersion = 0;

  @override
  void initState() {
    super.initState();
    _load();
    _queryCtrl.addListener(_onQuery);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final coordinator = context.read<DataRefreshCoordinator>();
    if (_refreshCoordinator != coordinator) {
      _refreshCoordinator?.removeListener(_handleRefreshEvent);
      _refreshCoordinator = coordinator;
      _lastProductsVersion = coordinator.productsVersion;
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
      final items = await _repo.fetch(query: query, category: _categoryFilter);
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

  void _onQuery() {
    _load();
  }

  void _handleRefreshEvent() {
    final coordinator = _refreshCoordinator;
    if (coordinator == null) return;
    if (coordinator.productsVersion != _lastProductsVersion) {
      _lastProductsVersion = coordinator.productsVersion;
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
                  hintText: t.productsSearchHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              _CategoryChips(
                selected: _categoryFilter,
                onSelected: (value) {
                  setState(() => _categoryFilter = value);
                  _load();
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: OutlinedButton.icon(
                  onPressed: _runCsvImport,
                  icon: const Icon(Icons.upload_file),
                  label: Text(t.productsCsvMock),
                ),
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
                      final filterLabel = _categoryFilter == null
                          ? null
                          : _categoryLabel(_categoryFilter!, t);
                      return StateMessageView(
                        icon: Icons.inventory_outlined,
                        title: t.productsEmptyMessage,
                        message: filterLabel == null
                            ? null
                            : t.productsEmptyFiltered(filterLabel),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: _load,
                      child: GridView.builder(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                              childAspectRatio: 1.2,
                            ),
                        itemCount: _items.length,
                        itemBuilder: (context, i) {
                          final p = _items[i];
                          return Card(
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () => context.go('/products/${p.id}'),
                              child: Padding(
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: color.primary.withValues(
                                            alpha: 0.08,
                                          ),
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                        child: const Center(
                                          child: Icon(
                                            Icons.inventory_2_outlined,
                                            size: 42,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(
                                      p.sku,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            t.productCardSummary(
                                              p.name,
                                              p.variantsCount,
                                            ),
                                            style: TextStyle(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface
                                                  .withValues(alpha: 0.7),
                                            ),
                                          ),
                                        ),
                                        PopupMenuButton<String>(
                                          onSelected: (value) {
                                            switch (value) {
                                              case 'edit':
                                                _openProductForm(initial: p);
                                                break;
                                              case 'delete':
                                                _confirmDelete(p);
                                                break;
                                            }
                                          },
                                          itemBuilder: (context) => [
                                            PopupMenuItem(
                                              value: 'edit',
                                              child: Text(t.edit),
                                            ),
                                            PopupMenuItem(
                                              value: 'delete',
                                              child: Text(t.productsDelete),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: -6,
                                      children: [
                                        _Tag(
                                          label: _categoryLabel(p.category, t),
                                        ),
                                        if (p.lowStock)
                                          _Tag(
                                            label: t.productLowStockTag,
                                            highlight: true,
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
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
            onPressed: () => _openProductForm(),
            icon: const Icon(Icons.add),
            label: Text(t.productsCreate),
          ),
        ),
      ],
    );
  }

  Future<void> _openProductForm({Product? initial}) async {
    final t = AppLocalizations.of(context)!;
    final base = initial ?? _emptyProduct();
    final result = await showModalBottomSheet<ProductEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductEditSheet(t: t, product: base),
    );
    if (result == null) return;
    final product = base.copyWith(
      sku: result.sku,
      name: result.name,
      price: result.price,
      variantsCount: result.variantsCount,
      category: result.category,
      lowStock: result.lowStock,
    );
    final saved = await _repo.save(product);
    if (!mounted) return;
    context.read<DataRefreshCoordinator>().notifyProductChanged(saved);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(initial == null ? t.productsCreated : t.productEditSaved),
      ),
    );
  }

  Future<void> _confirmDelete(Product product) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.productsDelete),
          content: Text(t.productsDeleteConfirm(product.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.orderEditCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t.productsDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await _repo.delete(product.id);
    if (!mounted) return;
    context.read<DataRefreshCoordinator>().notifyProductChanged(product);
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.productsDeleted)));
  }

  Future<void> _runCsvImport() async {
    final t = AppLocalizations.of(context)!;
    const mockCsv =
        'sku,name,price,variants,category\nSKU-9001,Citrus Soda,14.5,2,beverages\nSKU-9002,Urban Snack Mix,9.99,3,snacks';
    final result = await _importService.importProducts(mockCsv);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(t.productsCsvImported(result.success, result.processed)),
      ),
    );
  }

  Product _emptyProduct() {
    return Product(
      id: '',
      sku: 'SKU-${DateTime.now().millisecondsSinceEpoch}',
      name: '',
      variantsCount: 1,
      price: 10,
      category: ProductCategory.values.first,
      lowStock: false,
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

class _CategoryChips extends StatelessWidget {
  final ProductCategory? selected;
  final ValueChanged<ProductCategory?> onSelected;

  const _CategoryChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final items = <ProductCategory?>[null, ...ProductCategory.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (final category in items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(_label(category, t)),
                selected: selected == category,
                onSelected: (_) => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }

  String _label(ProductCategory? category, AppLocalizations t) {
    if (category == null) return t.productsFilterAll;
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

class _Tag extends StatelessWidget {
  final String label;
  final bool highlight;

  const _Tag({required this.label, this.highlight = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final background = highlight
        ? scheme.errorContainer
        : scheme.surfaceContainerHighest;
    final foreground = highlight ? scheme.onErrorContainer : scheme.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: foreground,
        ),
      ),
    );
  }
}
