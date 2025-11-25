import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/product.dart';
import 'package:vendorjet/repositories/mock_repository.dart';
import 'package:vendorjet/services/import/mock_import_service.dart';
import 'package:vendorjet/services/sync/data_refresh_coordinator.dart';
import 'package:vendorjet/ui/pages/products/category_manager_sheet.dart';
import 'package:vendorjet/ui/pages/products/product_edit_sheet.dart';
import 'package:vendorjet/ui/widgets/product_tag_pill.dart';
import 'package:vendorjet/ui/widgets/product_thumbnail.dart';
import 'package:vendorjet/ui/widgets/state_views.dart';

class ProductsPagePreset {
  final bool lowStockOnly;
  final String? topCategory;

  const ProductsPagePreset({this.lowStockOnly = false, this.topCategory});

  factory ProductsPagePreset.fromQuery(Map<String, String> query) {
    final category = query['category'];
    final lowStock = query['lowStock'] == '1';
    return ProductsPagePreset(lowStockOnly: lowStock, topCategory: category);
  }
}

class ProductsPage extends StatefulWidget {
  final ProductsPagePreset preset;

  const ProductsPage({super.key, this.preset = const ProductsPagePreset()});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _repo = MockProductRepository();
  final _importService = MockXlsxImportService();
  final _queryCtrl = TextEditingController();

  List<Product> _items = const [];
  List<String> _availableCategories = const [];
  List<List<String>> _categoryPresets = const [];
  bool _loading = true;
  String? _error;
  bool _lowStockOnly = false;
  String? _topCategoryFilter;
  bool _gridView = true;

  DataRefreshCoordinator? _refreshCoordinator;
  int _lastProductsVersion = 0;

  @override
  void initState() {
    super.initState();
    _applyPreset(widget.preset);
    _load();
    _queryCtrl.addListener(_onQuery);
  }

  @override
  void didUpdateWidget(covariant ProductsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.preset.lowStockOnly != widget.preset.lowStockOnly ||
        oldWidget.preset.topCategory != widget.preset.topCategory) {
      _applyPreset(widget.preset);
      _load();
    }
  }

  void _applyPreset(ProductsPagePreset preset) {
    _lowStockOnly = preset.lowStockOnly;
    _topCategoryFilter = preset.topCategory;
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
      final items = await _repo.fetch(
        query: query,
        topCategory: _topCategoryFilter,
        lowStockOnly: _lowStockOnly,
      );
      final categories = _repo.topCategories();
      final presets = await _repo.fetchCategoryPresets();
      if (!mounted) return;
      setState(() {
        _items = items;
        _availableCategories = categories;
        _categoryPresets = presets;
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

  void _onQuery() => _load();

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
                categories: _availableCategories,
                selected: _topCategoryFilter,
                onSelected: (value) {
                  setState(() => _topCategoryFilter = value);
                  _load();
                },
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerLeft,
                child: FilterChip(
                  label: Text(t.productsLowStockFilter),
                  selected: _lowStockOnly,
                  onSelected: (value) {
                    setState(() => _lowStockOnly = value);
                    _load();
                  },
                ),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: _runXlsxImport,
                    icon: const Icon(Icons.upload_file),
                    label: Text(t.productsXlsxUpload),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _openCategoryManager,
                    icon: const Icon(Icons.category_outlined),
                    label: Text(t.productsManageCategories),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _gridView ? 'Grid view' : 'List view',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  IconButton(
                    tooltip: _gridView ? 'List view' : 'Grid view',
                    onPressed: () => setState(() => _gridView = !_gridView),
                    icon: Icon(_gridView ? Icons.view_list : Icons.grid_view),
                  ),
                ],
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
                      return StateMessageView(
                        icon: Icons.inventory_outlined,
                        title: t.productsEmptyMessage,
                        message: _topCategoryFilter == null
                            ? null
                            : t.productsEmptyFiltered(_topCategoryFilter!),
                      );
                    }
                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 900;
                        final crossAxisCount = isWide ? 4 : 2;
                        final aspectRatio = isWide ? 0.9 : 0.85;
                        if (_gridView) {
                          return RefreshIndicator(
                            onRefresh: _load,
                            child: GridView.builder(
                              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: crossAxisCount,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: aspectRatio,
                              ),
                              itemCount: _items.length,
                              itemBuilder: (context, i) => _ProductCard(
                                product: _items[i],
                                t: t,
                                color: color,
                                onEdit: _openProductForm,
                                onDelete: _confirmDelete,
                                compact: true,
                              ),
                            ),
                          );
                        }
                        return RefreshIndicator(
                          onRefresh: _load,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                            itemCount: _items.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 12),
                            itemBuilder: (context, i) => _ProductCard(
                              product: _items[i],
                              t: t,
                              color: color,
                              onEdit: _openProductForm,
                              onDelete: _confirmDelete,
                              compact: false,
                            ),
                          ),
                        );
                      },
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
    final base =
        initial ??
        Product(
          id: '',
          sku: 'SKU-${DateTime.now().millisecondsSinceEpoch}',
          name: '',
          variantsCount: 1,
          price: 10,
          categories: const [],
          tags: const {},
          lowStock: false,
        );
    final result = await showModalBottomSheet<ProductEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductEditSheet(
        t: t,
        product: base,
        categoryPresets: _categoryPresets,
      ),
    );
    if (result == null) return;
    final product = base.copyWith(
      sku: result.sku,
      name: result.name,
      price: result.price,
      variantsCount: result.variantsCount,
      categories: result.categoryPath,
      tags: result.tags,
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

  Future<void> _runXlsxImport() async {
    final t = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['xlsx'],
    );
    if (result == null) return;
    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null) {
      messenger.showSnackBar(SnackBar(content: Text(t.productsXlsxNoData)));
      return;
    }
    final importResult = await _importService.importProducts(bytes);
    if (!mounted) return;
    await _load();
    if (!mounted) return;
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          t.productsXlsxImported(importResult.success, importResult.processed),
        ),
      ),
    );
  }

  Future<void> _openCategoryManager() async {
    final t = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryManagerSheet(t: t, repository: _repo),
    );
    if (!mounted) return;
    await _load();
  }
}

class _ProductCard extends StatelessWidget {
  final Product product;
  final AppLocalizations t;
  final ColorScheme color;
  final void Function(Product) onDelete;
  final void Function({Product? initial}) onEdit;
  final bool compact;

  const _ProductCard({
    required this.product,
    required this.t,
    required this.color,
    required this.onDelete,
    required this.onEdit,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final categoryLabel =
        product.categories.isEmpty ? t.productCategoryUnassigned : product.categories.join(' > ');
    final tagLabels = <String>[];
    if (product.lowStock) tagLabels.add(t.productLowStockTag);
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => context.go('/products/${product.id}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: ProductThumbnail(
                imageUrl: product.imageUrl,
                aspectRatio: compact ? 4 / 3 : 16 / 9,
                borderRadius: 12,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          product.name,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.sku,
                          style: Theme.of(context).textTheme.labelSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          categoryLabel,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: color.onSurface.withValues(alpha: 0.6),
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: -6,
                          children: [
                            for (final label in tagLabels)
                              ProductTagPill(label: label, highlight: label == t.productLowStockTag),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'edit':
                          onEdit(initial: product);
                          break;
                        case 'delete':
                          onDelete(product);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(value: 'edit', child: Text(t.edit)),
                      PopupMenuItem(value: 'delete', child: Text(t.productsDelete)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChips extends StatelessWidget {
  final List<String> categories;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _CategoryChips({
    required this.categories,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final chips = [null, ...categories];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (final category in chips)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(category ?? t.productCategoryUnassigned),
                selected: selected == category,
                onSelected: (_) => onSelected(category),
              ),
            ),
        ],
      ),
    );
  }
}

