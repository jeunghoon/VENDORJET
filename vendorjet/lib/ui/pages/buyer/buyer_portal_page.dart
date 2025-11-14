import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/models/product.dart';
import 'package:vendorjet/repositories/mock_repository.dart';
import 'package:vendorjet/services/sync/data_refresh_coordinator.dart';
import 'package:vendorjet/ui/pages/buyer/buyer_cart_controller.dart';
import 'package:vendorjet/ui/widgets/state_views.dart';

class BuyerPortalPage extends StatefulWidget {
  const BuyerPortalPage({super.key});

  @override
  State<BuyerPortalPage> createState() => _BuyerPortalPageState();
}

class _BuyerPortalPageState extends State<BuyerPortalPage> {
  final _productsRepo = MockProductRepository();
  final _ordersRepo = MockOrderRepository();
  final _searchCtrl = TextEditingController();
  final Map<String, int> _quantityDrafts = {};

  List<Product> _products = const [];
  List<String> _categories = const [];
  bool _loading = true;
  String? _error;
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _searchCtrl.addListener(_handleQueryChanged);
  }

  @override
  void dispose() {
    _searchCtrl
      ..removeListener(_handleQueryChanged)
      ..dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final items = await _productsRepo.fetch(
        query: _searchCtrl.text,
        topCategory: _selectedCategory,
      );
      final categories = _productsRepo.topCategories();
      if (!mounted) return;
      setState(() {
        _products = items;
        _categories = categories;
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

  void _handleQueryChanged() {
    _loadProducts();
  }

  void _handleCategorySelected(String? value) {
    setState(() => _selectedCategory = value);
    _loadProducts();
  }

  int _quantityForProduct(String productId) {
    return _quantityDrafts[productId] ?? 1;
  }

  void _setQuantity(Product product, int quantity) {
    final normalized = quantity.clamp(1, 999);
    setState(() {
      _quantityDrafts[product.id] = normalized;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BuyerCartController(),
      child: DefaultTabController(
        length: 3,
        child: Builder(
          builder: (context) {
            final t = AppLocalizations.of(context)!;
            return Scaffold(
              appBar: AppBar(
                leading: IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => context.pop(),
                ),
                title: Text(t.buyerPortalTitle),
                bottom: TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: t.buyerPortalTabCatalog),
                    Tab(text: t.buyerPortalTabCart),
                    Tab(text: t.buyerPortalTabCheckout),
                  ],
                ),
                actions: [
                  Consumer<BuyerCartController>(
                    builder: (context, cart, _) {
                      final label = t.buyerCartSummary(cart.totalQuantity);
                      return Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Chip(
                          label: Text(label),
                          avatar: const Icon(Icons.shopping_bag_outlined, size: 18),
                        ),
                      );
                    },
                  ),
                ],
              ),
              body: TabBarView(
                children: [
                  _BuyerCatalogTab(
                    searchController: _searchCtrl,
                    products: _products,
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    loading: _loading,
                    error: _error,
                    onRefresh: _loadProducts,
                    onCategorySelected: _handleCategorySelected,
                    quantityFor: _quantityForProduct,
                    onQuantityChanged: _setQuantity,
                    onAddToCart: (product, quantity) {
                      context.read<BuyerCartController>().addWithQuantity(product, quantity);
                    },
                  ),
                  const _BuyerCartTab(),
                  _BuyerCheckoutTab(orderRepository: _ordersRepo),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _BuyerCatalogTab extends StatelessWidget {
  final TextEditingController searchController;
  final List<Product> products;
  final List<String> categories;
  final String? selectedCategory;
  final bool loading;
  final String? error;
  final Future<void> Function() onRefresh;
  final ValueChanged<String?> onCategorySelected;
  final int Function(String productId) quantityFor;
  final void Function(Product product, int quantity) onQuantityChanged;
  final void Function(Product product, int quantity) onAddToCart;

  const _BuyerCatalogTab({
    required this.searchController,
    required this.products,
    required this.categories,
    required this.selectedCategory,
    required this.loading,
    required this.error,
    required this.onRefresh,
    required this.onCategorySelected,
    required this.quantityFor,
    required this.onQuantityChanged,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              labelText: t.buyerCatalogSearchHint,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(t.productsFilterAll),
                    selected: selectedCategory == null,
                    onSelected: (_) => onCategorySelected(null),
                  ),
                ),
                for (final category in categories)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: selectedCategory == category,
                      onSelected: (_) => onCategorySelected(category),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          if (loading)
            const Center(child: CircularProgressIndicator())
          else if (error != null)
            StateMessageView(
              icon: Icons.error_outline,
              title: t.stateErrorMessage,
              message: error,
              action: OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(t.stateRetry),
              ),
            )
          else if (products.isEmpty)
            StateMessageView(
              icon: Icons.search_off_outlined,
              title: t.productsEmptyMessage,
              message: t.buyerCatalogEmptyHint,
            )
          else ...[
            for (final product in products) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(product.sku, style: Theme.of(context).textTheme.labelSmall),
                              ],
                            ),
                          ),
                          if (product.lowStock)
                            Chip(
                              avatar: const Icon(Icons.warning_amber_rounded, size: 16),
                              label: Text(t.productLowStockTag),
                              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              backgroundColor: scheme.errorContainer,
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (product.categories.isNotEmpty)
                        Text(
                          product.categories.join(' / '),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (product.tags.contains(ProductTag.featured))
                            _Tag(label: t.productTagFeatured),
                          if (product.tags.contains(ProductTag.discounted))
                            _Tag(label: t.productTagDiscounted),
                          if (product.tags.contains(ProductTag.newArrival))
                            _Tag(label: t.productTagNew),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        t.buyerCatalogPrice(product.price.toStringAsFixed(2)),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                        _QuantitySelector(
                          value: quantityFor(product.id),
                          onChanged: (value) => onQuantityChanged(product, value),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () {
                              final qty = quantityFor(product.id);
                              onAddToCart(product, qty);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t.buyerCatalogAdded(product.name))),
                              );
                            },
                            icon: const Icon(Icons.add_shopping_cart_outlined),
                            label: Text(
                              t.buyerCatalogAddWithQty(
                                _formatQuantity(quantityFor(product.id)),
                              ),
                            ),
                          ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }

}

class _BuyerCartTab extends StatelessWidget {
  const _BuyerCartTab();

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Consumer<BuyerCartController>(
      builder: (context, cart, _) {
        if (cart.isEmpty) {
          return Center(
            child: StateMessageView(
              icon: Icons.shopping_basket_outlined,
              title: t.buyerCartEmpty,
              message: t.buyerCartEmptyHint,
            ),
          );
        }
        final items = cart.items;
        final TabController tabController = DefaultTabController.of(context);
        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final item = items[index];
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.product.name,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 4),
                          Text(item.product.sku, style: Theme.of(context).textTheme.labelSmall),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _QuantitySelector(
                                value: item.quantity,
                                onChanged: (value) =>
                                    cart.setQuantity(item.product.id, value),
                              ),
                              const Spacer(),
                              Text(
                                t.buyerCartLineTotal(
                                  item.lineTotal.toStringAsFixed(2),
                                ),
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => cart.remove(item.product.id),
                              icon: const Icon(Icons.delete_outline),
                              label: Text(t.buyerCartRemove),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    t.buyerCartTotal(cart.totalAmount.toStringAsFixed(2)),
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => tabController.animateTo(2),
                    icon: const Icon(Icons.assignment_outlined),
                    label: Text(t.buyerCartProceed),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: cart.clear,
                    child: Text(t.buyerCartClear),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _BuyerCheckoutTab extends StatefulWidget {
  final MockOrderRepository orderRepository;

  const _BuyerCheckoutTab({required this.orderRepository});

  @override
  State<_BuyerCheckoutTab> createState() => _BuyerCheckoutTabState();
}

class _BuyerCheckoutTabState extends State<_BuyerCheckoutTab> {
  final _formKey = GlobalKey<FormState>();
  final _storeCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _storeCtrl.dispose();
    _contactCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final cart = context.watch<BuyerCartController>();
    final totalLabel = t.buyerCartTotal(cart.totalAmount.toStringAsFixed(2));

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: ListView(
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(totalLabel),
                subtitle: Text(t.buyerCheckoutItems(cart.totalQuantity)),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _storeCtrl,
              decoration: InputDecoration(
                labelText: t.buyerCheckoutStore,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return t.buyerCheckoutStore;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactCtrl,
              decoration: InputDecoration(
                labelText: t.buyerCheckoutContact,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              validator: (value) {
                if ((value ?? '').trim().isEmpty) {
                  return t.buyerCheckoutContact;
                }
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _noteCtrl,
              minLines: 3,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: t.buyerCheckoutNote,
                hintText: t.buyerCheckoutNoteHint,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 20),
            FilledButton.icon(
              onPressed: _submitting ? null : () => _submit(cart),
              icon: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: Text(t.buyerCheckoutSubmit),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit(BuyerCartController cart) async {
    final t = AppLocalizations.of(context)!;
    if (cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.buyerCheckoutCartEmpty)),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _submitting = true);
    final now = DateTime.now();
    final order = Order(
      id: '',
      code: '',
      itemCount: cart.totalQuantity,
      total: cart.totalAmount,
      createdAt: now,
      status: OrderStatus.pending,
      buyerName: _storeCtrl.text.trim(),
      buyerContact: _contactCtrl.text.trim(),
      buyerNote: _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
    );
    try {
      final saved = await widget.orderRepository.save(order);
      if (!mounted) return;
      context.read<DataRefreshCoordinator>().notifyOrderChanged(saved);
      cart.clear();
      _formKey.currentState?.reset();
      _storeCtrl.clear();
      _contactCtrl.clear();
      _noteCtrl.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.buyerCheckoutSuccess(saved.code))),
      );
    } catch (err) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(err.toString())),
      );
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }
}

class _QuantitySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _QuantitySelector({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > 1 ? () => onChanged((value - 1).clamp(1, 999)) : null,
        ),
        _QuantityField(
          value: value,
          onSubmitted: (next) => onChanged(next.clamp(1, 999)),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged((value + 1).clamp(1, 999)),
        ),
      ],
    );
  }
}

class _QuantityField extends StatefulWidget {
  final int value;
  final ValueChanged<int> onSubmitted;

  const _QuantityField({
    required this.value,
    required this.onSubmitted,
  });

  @override
  State<_QuantityField> createState() => _QuantityFieldState();
}

class _QuantityFieldState extends State<_QuantityField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value.toString());
  }

  @override
  void didUpdateWidget(covariant _QuantityField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value &&
        _controller.text != widget.value.toString()) {
      _controller.text = widget.value.toString();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _commit() {
    final parsed = int.tryParse(_controller.text);
    if (parsed == null || parsed < 1) {
      _controller.text = widget.value.toString();
      _controller.selection = TextSelection.fromPosition(
        TextPosition(offset: _controller.text.length),
      );
      return;
    }
    widget.onSubmitted(parsed);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64,
      child: TextField(
        controller: _controller,
        textAlign: TextAlign.center,
        keyboardType: const TextInputType.numberWithOptions(decimal: false),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: InputDecoration(
          contentPadding: const EdgeInsets.symmetric(vertical: 8),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          isDense: true,
        ),
        onSubmitted: (_) => _commit(),
        onEditingComplete: _commit,
      ),
    );
  }
}

String _formatQuantity(int value) => value.toString().padLeft(2, '0');

class _Tag extends StatelessWidget {
  final String label;

  const _Tag({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: scheme.onSecondaryContainer,
        ),
      ),
    );
  }
}
