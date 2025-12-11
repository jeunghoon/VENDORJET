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
import 'package:vendorjet/ui/widgets/notification_ticker.dart';

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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
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
          bottom: TabBar(
            tabs: [
              Tab(text: t.productTabOverview),
              Tab(text: t.productTabSettings),
            ],
          ),
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
            return TabBarView(
              children: [
                _ProductOverview(product: currentProduct),
                _ProductSettings(product: currentProduct),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openEditSheet(BuildContext context) async {
    final t = AppLocalizations.of(context)!;
    final snapshot = await _future;
    if (!context.mounted || snapshot == null) return;
    final product = _localProduct ?? snapshot;

    final presets = await _repo.fetchCategoryPresets();
    if (!context.mounted) return;

    final result = await showModalBottomSheet<ProductEditResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => ProductEditSheet(
        t: t,
        product: product,
        categoryPresets: presets,
      ),
    );

    if (!context.mounted || result == null) return;

    final updatedProduct = product.copyWith(
      sku: result.sku,
      name: result.name,
      price: result.price,
      variantsCount: result.variantsCount,
      categories: result.categoryPath,
      tags: result.tags,
      lowStock: result.lowStock,
      hsCode: result.hsCode,
      originCountry: result.originCountry,
      uom: result.uom,
      incoterm: result.incoterm,
      isPerishable: result.isPerishable,
      packaging: result.packaging,
      tradeTerm: result.tradeTerm,
      eta: result.eta,
    );

    await _repo.save(updatedProduct);

    if (!context.mounted) return;

    setState(() {
      _localProduct = updatedProduct;
    });

    context.read<DataRefreshCoordinator>().notifyProductChanged(updatedProduct);

    context.read<NotificationTicker>().push(t.productEditSaved);
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
    context.read<NotificationTicker>().push(t.productsDeleted);
    context.go('/products');
  }
}

class _ProductOverview extends StatelessWidget {
  const _ProductOverview({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final numberFormat = NumberFormat.decimalPattern(t.localeName);
    final dateFormat = DateFormat('yyyy-MM-dd');
    final color = Theme.of(context).colorScheme;
    final highlights = _mockHighlights(product, t);
    final categoryLabel = product.categories.isEmpty
        ? t.productsFilterAll
        : product.categories.join(' · ');
    final lastSync = DateTime.now().subtract(
      Duration(hours: product.id.hashCode.abs() % 30),
    );
    final packaging = product.packaging;
    final tradeTerm = product.tradeTerm;
    final eta = product.eta;
    final incoterm = product.incoterm ?? tradeTerm?.incoterm;
    final placeholder = t.notProvided;
    final vesselLabel = [
      eta?.vessel,
      eta?.voyageNo,
    ].whereType<String>().where((e) => e.isNotEmpty).join(' / ');
    String fmtDims(ProductPackaging p) {
      final l = p.lengthCm, w = p.widthCm, h = p.heightCm;
      if (l == null || w == null || h == null) return placeholder;
      return '${l.toStringAsFixed(1)} x ${w.toStringAsFixed(1)} x ${h.toStringAsFixed(1)} cm';
    }

    String fmtWeight(ProductPackaging p) {
      final net = p.netWeightKg;
      final gross = p.grossWeightKg;
      if (net == null && gross == null) return placeholder;
      final netStr = net?.toStringAsFixed(2) ?? '?';
      final grossStr = gross?.toStringAsFixed(2) ?? '?';
      return '$netStr / $grossStr kg';
    }

    String fmtCbm(ProductPackaging p) {
      final cbm = p.computedCbm;
      if (cbm == null) return placeholder;
      return cbm.toStringAsFixed(3);
    }

    String fmtMoney(String currency, double? value) {
      if (value == null) return placeholder;
      return '$currency ${numberFormat.format(value)}';
    }

    String fmtDate(DateTime? value) =>
        value == null ? placeholder : dateFormat.format(value);

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
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  children: [
                    _InfoChip(label: t.productSku, value: product.sku),
                    _InfoChip(
                      label: t.productPrice,
                      value: numberFormat.format(product.price),
                    ),
                    _InfoChip(
                      label: t.productVariants,
                      value: '${product.variantsCount}',
                    ),
                    _InfoChip(
                      label: t.productIncoterm,
                      value: incoterm ?? placeholder,
                    ),
                    _InfoChip(
                      label: t.productHsCode,
                      value: product.hsCode ?? placeholder,
                    ),
                    _InfoChip(
                      label: t.productOriginCountry,
                      value: product.originCountry ?? placeholder,
                    ),
                    _InfoChip(
                      label: t.productUom,
                      value: product.uom ?? placeholder,
                    ),
                    _InfoChip(
                      label: t.productPerishable,
                      value: product.isPerishable
                          ? t.productPerishableYes
                          : t.productPerishableNo,
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
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _InfoRow(
                  icon: Icons.category_outlined,
                  label: t.productMetaCategory,
                  value: categoryLabel,
                ),
                const SizedBox(height: 10),
                _InfoRow(
                  icon: Icons.shield_outlined,
                  label: t.productMetaStockHealthy,
                  value: product.lowStock
                      ? t.productMetaStockLow
                      : t.productMetaStockHealthy,
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
        if (packaging != null || tradeTerm != null || eta != null) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t.productTradeSectionTitle,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  if (packaging != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      t.productPackagingSectionTitle,
                      style:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          label: t.productPackagingType,
                          value: packaging.packType,
                        ),
                        _InfoChip(
                          label: t.productPackagingDimensions,
                          value: fmtDims(packaging),
                        ),
                        _InfoChip(
                          label: t.productPackagingWeight,
                          value: fmtWeight(packaging),
                        ),
                        _InfoChip(
                          label: t.productPackagingUnitsPerPack,
                          value: packaging.unitsPerPack?.toString() ??
                              placeholder,
                        ),
                        _InfoChip(
                          label: t.productPackagingCbm,
                          value: fmtCbm(packaging),
                        ),
                      ],
                    ),
                  ],
                  if (tradeTerm != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      t.productTradeTermSectionTitle,
                      style:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          label: t.productTradePrice,
                          value: fmtMoney(tradeTerm.currency, tradeTerm.price),
                        ),
                        _InfoChip(
                          label: t.productTradeFreight,
                          value: fmtMoney(
                            tradeTerm.currency,
                            tradeTerm.freight,
                          ),
                        ),
                        _InfoChip(
                          label: t.productTradeInsurance,
                          value: fmtMoney(
                            tradeTerm.currency,
                            tradeTerm.insurance,
                          ),
                        ),
                        _InfoChip(
                          label: t.productTradeLeadTime,
                          value: tradeTerm.leadTimeDays != null
                              ? '${tradeTerm.leadTimeDays} d'
                              : placeholder,
                        ),
                        _InfoChip(
                          label: t.productTradeMoq,
                          value: tradeTerm.minOrderQty != null
                              ? '${tradeTerm.minOrderQty} ${tradeTerm.moqUnit ?? ''}'.trim()
                              : placeholder,
                        ),
                      ],
                    ),
                  ],
                  if (eta != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      t.productEtaSectionTitle,
                      style:
                          Theme.of(context).textTheme.labelLarge?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 12,
                      runSpacing: 8,
                      children: [
                        _InfoChip(
                          label: t.productEtaEtd,
                          value: fmtDate(eta.etd),
                        ),
                        _InfoChip(
                          label: t.productEtaEta,
                          value: fmtDate(eta.eta),
                        ),
                        if (vesselLabel.isNotEmpty)
                          _InfoChip(
                            label: t.productEtaVessel,
                            value: vesselLabel,
                          ),
                        if (eta.status != null)
                          _InfoChip(
                            label: t.productEtaStatus,
                            value: eta.status ?? placeholder,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
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
  }
}

class _ProductSettings extends StatelessWidget {
  const _ProductSettings({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final categories = product.categories;
    final tags = product.tags;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  t.productSettingsCategories,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                if (categories.isEmpty)
                  Text(t.productCategoryLevelRequired)
                else
                  ...List.generate(
                    categories.length,
                    (index) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.productCategoryLevel(index + 1)),
                      subtitle: Text(categories[index]),
                    ),
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
                  t.productTagsSection,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: -6,
                  children: [
                    _Tag(
                      label: t.productTagFeatured,
                      highlight: tags.contains(ProductTag.featured),
                    ),
                    _Tag(
                      label: t.productTagDiscounted,
                      highlight: tags.contains(ProductTag.discounted),
                    ),
                    _Tag(
                      label: t.productTagNew,
                      highlight: tags.contains(ProductTag.newArrival),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
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
        ? scheme.primaryContainer
        : scheme.surfaceContainerHighest;
    final foreground = highlight ? scheme.onPrimaryContainer : scheme.onSurface;
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

