import 'dart:math';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/product.dart';
import 'package:vendorjet/repositories/mock_repository.dart';
import 'package:vendorjet/services/sync/data_refresh_coordinator.dart';
import 'package:vendorjet/ui/pages/products/product_edit_sheet.dart';

class ProductDetailPage extends StatefulWidget {
  final String productId;

  const ProductDetailPage({super.key, required this.productId});

  @override
  State<ProductDetailPage> createState() => _ProductDetailPageState();
}

class _ProductDetailPageState extends State<ProductDetailPage> {
  final _repo = MockProductRepository();
  late final Future<Product?> _future = _repo.findById(widget.productId);
  Product? _localProduct;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat.decimalPattern(t.localeName);
    final color = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => context.go('/products')),
        title: Text(t.productsDetailTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            tooltip: t.edit,
            onPressed: () => _openEditSheet(context),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _confirmDelete(context);
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'delete', child: Text(t.productsDelete)),
            ],
          ),
        ],
      ),
      body: FutureBuilder<Product?>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final product = snapshot.data;
          if (product == null) {
            return Center(
              child: Text(
                t.notFound,
                style: Theme.of(context).textTheme.titleMedium,
              ),
            );
          }

          final currentProduct = _localProduct ?? product;
          final highlights = _mockHighlights(currentProduct, t);
          final categoryLabel = _categoryLabel(currentProduct.category, t);
          final lastSync = DateTime.now().subtract(
            Duration(hours: currentProduct.id.hashCode.abs() % 30),
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            color: color.primary.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Center(
                            child: Icon(Icons.inventory_2_outlined, size: 64),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        currentProduct.name,
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 16,
                        runSpacing: 8,
                        children: [
                          _InfoChip(
                            label: t.productSku,
                            value: currentProduct.sku,
                          ),
                          _InfoChip(
                            label: t.productPrice,
                            value: numberFormat.format(currentProduct.price),
                          ),
                          _InfoChip(
                            label: t.productVariants,
                            value: '${currentProduct.variantsCount}',
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
                        t.productMetaTitle,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _Tag(label: categoryLabel),
                          _Tag(
                            label: currentProduct.lowStock
                                ? t.productMetaStockLow
                                : t.productMetaStockHealthy,
                            highlight: currentProduct.lowStock,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoRow(
                        icon: Icons.category_outlined,
                        label: t.productMetaCategory,
                        value: categoryLabel,
                      ),
                      const SizedBox(height: 10),
                      _InfoRow(
                        icon: Icons.update_outlined,
                        label: t.productMetaLastSync,
                        value: DateFormat.yMMMd(t.localeName).format(lastSync),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                t.productHighlights,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              ...highlights.map(
                (item) => Card(
                  child: ListTile(
                    leading: Icon(item.icon, color: color.primary),
                    title: Text(item.title),
                    subtitle: Text(item.subtitle),
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
    final product = _localProduct ?? snapshot;

    final result = await showModalBottomSheet<ProductEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductEditSheet(t: t, product: product),
    );

    if (!context.mounted || result == null) return;

    final updatedProduct = product.copyWith(
      sku: result.sku,
      name: result.name,
      price: result.price,
      variantsCount: result.variantsCount,
      category: result.category,
      lowStock: result.lowStock,
    );

    await _repo.save(updatedProduct);

    if (!context.mounted) return;

    setState(() {
      _localProduct = updatedProduct;
    });

    context.read<DataRefreshCoordinator>().notifyProductChanged(updatedProduct);

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.productEditSaved)));
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final snapshot = await _future;
    if (!context.mounted || snapshot == null) return;
    final product = _localProduct ?? snapshot;
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
    if (!context.mounted) return;
    context.read<DataRefreshCoordinator>().notifyProductChanged(product);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.productsDeleted)));
    context.go('/products');
  }

  List<_Highlight> _mockHighlights(Product product, AppLocalizations t) {
    final rnd = Random(product.id.hashCode);
    final availability = [
      t.productAvailabilityInStock,
      t.productAvailabilityLowStock,
      t.productAvailabilityBackordered,
    ];
    final leadTime = [
      t.productLeadTimeSameDay,
      t.productLeadTimeTwoDays,
      t.productLeadTimeWeek,
    ];
    final badges = [
      t.productBadgeBestseller,
      t.productBadgeNew,
      t.productBadgeSeasonal,
    ];

    return [
      _Highlight(
        icon: Icons.inventory_rounded,
        title: availability[rnd.nextInt(availability.length)],
        subtitle: t.productHighlightAvailabilityNote,
      ),
      _Highlight(
        icon: Icons.local_shipping_outlined,
        title: leadTime[rnd.nextInt(leadTime.length)],
        subtitle: t.productHighlightLeadTimeNote,
      ),
      _Highlight(
        icon: Icons.loyalty_outlined,
        title: badges[rnd.nextInt(badges.length)],
        subtitle: t.productHighlightBadgeNote,
      ),
    ];
  }
}

class _Highlight {
  final IconData icon;
  final String title;
  final String subtitle;

  const _Highlight({
    required this.icon,
    required this.title,
    required this.subtitle,
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
            Text(
              value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
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
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(value, style: theme.textTheme.bodyMedium),
            ],
          ),
        ),
      ],
    );
  }
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
