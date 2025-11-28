import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/models/product.dart';
import 'package:vendorjet/repositories/mock_repository.dart';
import 'package:vendorjet/repositories/order_repository.dart';
import 'package:vendorjet/services/auth/auth_controller.dart';
import 'package:vendorjet/services/sync/data_refresh_coordinator.dart';
import 'package:vendorjet/ui/pages/buyer/buyer_cart_controller.dart';
import 'package:vendorjet/ui/widgets/notification_ticker.dart';
import 'package:vendorjet/ui/widgets/product_tag_pill.dart';
import 'package:vendorjet/ui/widgets/product_thumbnail.dart';
import 'package:vendorjet/ui/widgets/state_views.dart';

class BuyerPortalPage extends StatefulWidget {
  const BuyerPortalPage({super.key});

  @override
  State<BuyerPortalPage> createState() => _BuyerPortalPageState();
}

class _BuyerPortalPageState extends State<BuyerPortalPage> {
  static const _catalogTabIndex = 1;
  static const _orderTabIndex = 2;

  final _productsRepo = MockProductRepository();
  final _ordersRepo = OrderRepository();
  final _customersRepo = MockCustomerRepository();
  final _searchCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _orderFormKey = GlobalKey<FormState>();
  final Map<String, int> _quantityDrafts = {};

  List<Product> _products = const [];
  List<String> _categories = const [];
  List<Order> _history = const [];
  List<String> _storeOptions = const [];
  DateTime _deliveryDate = _defaultDeliveryDate();
  bool _productsLoading = true;
  bool _historyLoading = true;
  bool _storesLoading = true;
  bool _submitting = false;
  bool _contactPrefilled = false;
  bool _catalogGridView = true;
  String? _productsError;
  String? _historyError;
  String? _storesError;
  String? _selectedCategory;
  String? _selectedStore;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadHistory();
    _loadStores();
    _searchCtrl.addListener(_handleQueryChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_contactPrefilled) return;
    final auth = context.read<AuthController?>();
    _contactCtrl.text = _deriveContactName(auth?.email);
    _contactPrefilled = true;
  }

  static DateTime _defaultDeliveryDate() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).add(const Duration(days: 1));
  }

  @override
  void dispose() {
    _searchCtrl
      ..removeListener(_handleQueryChanged)
      ..dispose();
    _noteCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    final auth = context.read<AuthController?>();
    if (auth?.pendingApproval == true) {
      setState(() {
        _productsLoading = false;
        _products = const [];
      });
      return;
    }
    final mountedContext = mounted;
    if (!mounted) return;
    setState(() {
      _productsLoading = true;
      _productsError = null;
    });
    try {
      final items = await _productsRepo.fetch(
        query: _searchCtrl.text,
        topCategory: _selectedCategory,
      );
      final categories = _productsRepo.topCategories();
      if (!mountedContext || !mounted) return;
      setState(() {
        _products = items;
        _categories = categories;
        _productsLoading = false;
      });
    } catch (err) {
      if (!mountedContext || !mounted) return;
      setState(() {
        _productsLoading = false;
        _productsError = err.toString();
      });
    }
  }

  Future<void> _loadHistory() async {
    final auth = context.read<AuthController?>();
    if (auth?.pendingApproval == true) {
      setState(() {
        _historyLoading = false;
        _history = const [];
      });
      return;
    }
    final mountedContext = mounted;
    if (!mounted) return;
    setState(() {
      _historyLoading = true;
      _historyError = null;
    });
    try {
      final items = await _ordersRepo.fetch(createdSource: 'buyer_portal');
      if (!mountedContext || !mounted) return;
      setState(() {
        _history = items;
        _historyLoading = false;
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _historyLoading = false;
        _historyError = err.toString();
      });
    }
  }

  Future<void> _loadStores() async {
    final auth = context.read<AuthController?>();
    if (auth?.pendingApproval == true) {
      setState(() {
        _storesLoading = false;
        _storeOptions = const [];
      });
      return;
    }
    final mountedContext = mounted;
    if (!mounted) return;
    setState(() {
      _storesLoading = true;
      _storesError = null;
    });
    try {
      final customers = await _customersRepo.fetch();
      final email = auth?.email?.toLowerCase();
      final filtered = email == null || email.isEmpty
          ? customers
          : customers.where((c) => c.email.toLowerCase() == email).toList();
      final list = filtered.isEmpty ? customers : filtered;
      final names = list.map((c) => c.name).toSet().toList()..sort();
      if (!mountedContext || !mounted) return;
      setState(() {
        _storeOptions = names;
        _storesLoading = false;
        if (_selectedStore != null && !_storeOptions.contains(_selectedStore)) {
          _selectedStore = null;
        }
      });
    } catch (err) {
      if (!mounted) return;
      setState(() {
        _storesLoading = false;
        _storesError = err.toString();
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

  String _deliveryDateLabel(AppLocalizations t) {
    final localeName = Localizations.localeOf(context).toString();
    final formatter = DateFormat.yMMMd(localeName);
    return formatter.format(_deliveryDate);
  }

  Future<void> _pickDeliveryDate() async {
    final t = AppLocalizations.of(context)!;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final initialDate = _deliveryDate.isBefore(today)
        ? _defaultDeliveryDate()
        : _deliveryDate;
    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
      helpText: t.buyerDeliveryDatePick,
    );
    if (selected != null) {
      setState(() => _deliveryDate = selected);
    }
  }

  void _handleStoreChanged(String? value) {
    setState(() => _selectedStore = value);
  }

  String _deriveContactName(String? email) {
    if (email == null || email.isEmpty) {
      return 'Buyer';
    }
    final lower = email.toLowerCase();
    const known = {
      'alex@vendorjet.com': 'Alex Kim',
      'morgan@vendorjet.com': 'Morgan Lee',
      'jamie@vendorjet.com': 'Jamie Park',
    };
    final preset = known[lower];
    if (preset != null) return preset;
    final local = lower.split('@').first;
    final parts = local
        .split(RegExp(r'[._-]+'))
        .where((part) => part.isNotEmpty);
    final formatted = parts
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
    return formatted.isEmpty ? 'Buyer' : formatted;
  }

  Future<void> _handleLoadFromHistory(
    BuildContext providerContext,
    Order order,
    TabController? tabController,
  ) async {
    final success = await _prefillCartFromOrder(providerContext, order);
    if (!mounted || !providerContext.mounted) return;
    final t = AppLocalizations.of(providerContext)!;
    if (!success) {
      providerContext.read<NotificationTicker>().push(t.buyerOrderPrefillMissing);
      return;
    }
    setState(() {
      _noteCtrl.text = order.buyerNote ?? '';
      final storeName = order.buyerName.trim();
      if (storeName.isNotEmpty && !_storeOptions.contains(storeName)) {
        _storeOptions = [..._storeOptions, storeName]..sort();
      }
      if (storeName.isNotEmpty) {
        _selectedStore = storeName;
      }
      final candidate = order.desiredDeliveryDate;
      if (candidate != null) {
        final today = DateTime.now();
        final normalizedToday = DateTime(today.year, today.month, today.day);
        _deliveryDate = candidate.isBefore(normalizedToday)
            ? _defaultDeliveryDate()
            : candidate;
      } else {
        _deliveryDate = _defaultDeliveryDate();
      }
    });
    tabController?.animateTo(_orderTabIndex);
    final label = order.code.isEmpty ? order.buyerName : order.code;
    providerContext.read<NotificationTicker>().push(t.buyerDashboardLoaded(label));
  }

  Future<bool> _prefillCartFromOrder(
    BuildContext providerContext,
    Order order,
  ) async {
    final cart = providerContext.read<BuyerCartController>();
    final items = <BuyerCartItem>[];
    for (final line in order.lines) {
      final product = await _productsRepo.findById(line.productId);
      if (product != null) {
        items.add(BuyerCartItem(product: product, quantity: line.quantity));
      }
    }
    if (items.isEmpty) {
      return false;
    }
    cart.replaceWith(items);
    return true;
  }

  Future<void> _submitOrder(BuyerCartController cart) async {
    final t = AppLocalizations.of(context)!;
    if (cart.isEmpty) {
      if (mounted) context.read<NotificationTicker>().push(t.buyerCheckoutCartEmpty);
      return;
    }
    if (!(_orderFormKey.currentState?.validate() ?? false)) {
      return;
    }
    setState(() => _submitting = true);
    final storeName = _selectedStore ?? '';
    final note = _noteCtrl.text.trim();
    final lines = cart.items
        .map(
          (item) => OrderLine(
            productId: item.product.id,
            productName: item.product.name,
            quantity: item.quantity,
            unitPrice: item.product.price,
          ),
        )
        .toList();
    final total = double.parse(
      lines
          .fold<double>(0, (sum, line) => sum + line.lineTotal)
          .toStringAsFixed(2),
    );
    final order = Order(
      id: '',
      code: '',
      itemCount: cart.totalQuantity,
      total: total,
      createdAt: DateTime.now(),
      status: OrderStatus.pending,
      buyerName: storeName,
      buyerContact: _contactCtrl.text.trim(),
      buyerNote: note.isEmpty ? null : note,
      lines: lines,
      desiredDeliveryDate: _deliveryDate,
    );
    try {
      final saved = await _ordersRepo.save(order);
      if (!mounted) return;
      context.read<DataRefreshCoordinator>().notifyOrderChanged(saved);
      cart.clear();
      setState(() {
        _selectedStore = null;
        _noteCtrl.clear();
      });
      await _loadHistory();
      if (mounted) {
        context.read<NotificationTicker>().push(t.buyerCheckoutSuccess(saved.code));
      }
    } catch (err) {
      if (!mounted) return;
      context.read<NotificationTicker>().push(err.toString());
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _navigateToTab(BuildContext context, int index) {
    final controller = DefaultTabController.of(context);
    controller.animateTo(index);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthController?>();
    if (auth?.pendingApproval == true) {
      return Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.buyerPortalTitle),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.hourglass_empty_outlined, size: 48),
              const SizedBox(height: 12),
              Text(
                '승인 대기 중입니다',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '담당 도매 업체에서 승인하면 상품을 조회하고 주문할 수 있습니다.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      );
    }

    return ChangeNotifierProvider(
      create: (_) => BuyerCartController(),
      child: DefaultTabController(
        length: 3,
        child: Builder(
          builder: (context) {
            final t = AppLocalizations.of(context)!;
            final tabController = DefaultTabController.of(context);
            return Scaffold(
              appBar: AppBar(
                title: Text(t.buyerPortalTitle),
                bottom: TabBar(
                  isScrollable: true,
                  tabs: [
                    Tab(text: t.buyerPortalTabDashboard),
                    Tab(text: t.buyerPortalTabCatalog),
                    Tab(text: t.buyerPortalTabOrder),
                  ],
                ),
                actions: [
                  PopupMenuButton<String>(
                    onSelected: (value) async {
                      switch (value) {
                        case 'profile':
                          if (context.mounted) context.go('/profile');
                          break;
                        case 'settings':
                          if (context.mounted) context.go('/settings');
                          break;
                        case 'logout':
                          await context.read<AuthController>().signOut();
                          if (context.mounted) context.go('/sign-in');
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'profile', child: Text('프로필/사업장 설정')),
                      const PopupMenuItem(value: 'settings', child: Text('설정')),
                      const PopupMenuItem(value: 'logout', child: Text('로그아웃')),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: TextButton.icon(
                      onPressed: _pickDeliveryDate,
                      icon: const Icon(Icons.event_outlined),
                      label: Text(
                        '${t.buyerDeliveryDateLabel}: ${_deliveryDateLabel(t)}',
                      ),
                    ),
                  ),
                ],
              ),
              body: TabBarView(
                children: [
                  _BuyerDashboardTab(
                    loading: _historyLoading,
                    error: _historyError,
                    orders: _history,
                    onRefresh: _loadHistory,
                    onLoadOrder: (order) =>
                        _handleLoadFromHistory(context, order, tabController),
                  ),
                  _BuyerCatalogTab(
                    searchController: _searchCtrl,
                    products: _products,
                    categories: _categories,
                    selectedCategory: _selectedCategory,
                    loading: _productsLoading,
                    error: _productsError,
                    onRefresh: _loadProducts,
                    onCategorySelected: _handleCategorySelected,
                    quantityFor: _quantityForProduct,
                    onQuantityChanged: _setQuantity,
                    onAddToCart: (product, quantity) {
                      context.read<BuyerCartController>().addWithQuantity(
                        product,
                        quantity,
                      );
                      setState(() {
                        _quantityDrafts[product.id] = 1;
                      });
                    },
                    gridView: _catalogGridView,
                    onToggleView: () =>
                        setState(() => _catalogGridView = !_catalogGridView),
                  ),
                  _BuyerOrderSheetTab(
                    formKey: _orderFormKey,
                    storeOptions: _storeOptions,
                    selectedStore: _selectedStore,
                    storeLoading: _storesLoading,
                    storeError: _storesError,
                    onStoreChanged: _handleStoreChanged,
                    contactController: _contactCtrl,
                    noteController: _noteCtrl,
                    submitting: _submitting,
                    onSubmit: _submitOrder,
                    onBrowseCatalog: () =>
                        _navigateToTab(context, _catalogTabIndex),
                    onDeliveryTap: _pickDeliveryDate,
                    deliveryDate: _deliveryDate,
                  ),
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
  final bool gridView;
  final VoidCallback onToggleView;

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
    required this.gridView,
    required this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final scheme = Theme.of(context).colorScheme;

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: searchController,
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search),
                    labelText: t.buyerCatalogSearchHint,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      gridView ? 'Grid view' : 'List view',
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    IconButton(
                      tooltip: gridView ? 'List view' : 'Grid view',
                      onPressed: onToggleView,
                      icon: Icon(gridView ? Icons.view_list : Icons.grid_view),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: Builder(
              builder: (context) {
                if (loading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (error != null) {
                  return StateMessageView(
                    icon: Icons.error_outline,
                    title: t.stateErrorMessage,
                    message: error,
                    action: OutlinedButton.icon(
                      onPressed: onRefresh,
                      icon: const Icon(Icons.refresh),
                      label: Text(t.stateRetry),
                    ),
                  );
                }
                if (products.isEmpty) {
                  if (products.isEmpty && error == null && !loading) {
                    return StateMessageView(
                      icon: Icons.hourglass_empty_outlined,
                      title: t.productsEmptyMessage,
                      message: t.buyerCatalogEmptyHint,
                    );
                  }
                }

                if (gridView) {
                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final isWide = constraints.maxWidth >= 900;
                      final crossAxisCount = isWide ? 4 : 2;
                      final aspectRatio = isWide ? 0.72 : 0.68;
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12,
                          childAspectRatio: aspectRatio,
                        ),
                        itemCount: products.length,
                        itemBuilder: (context, i) {
                          final product = products[i];
                          return _CatalogCard(
                            product: product,
                            t: t,
                            scheme: scheme,
                            quantity: quantityFor(product.id),
                            onQuantityChanged: (v) =>
                                onQuantityChanged(product, v),
                            onAdd: () =>
                                onAddToCart(product, quantityFor(product.id)),
                            compact: true,
                          );
                        },
                      );
                    },
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: products.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final product = products[i];
                    return _CatalogCard(
                      product: product,
                      t: t,
                      scheme: scheme,
                      quantity: quantityFor(product.id),
                      onQuantityChanged: (v) => onQuantityChanged(product, v),
                      onAdd: () =>
                          onAddToCart(product, quantityFor(product.id)),
                      compact: false,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogCard extends StatelessWidget {
  final Product product;
  final AppLocalizations t;
  final ColorScheme scheme;
  final int quantity;
  final ValueChanged<int> onQuantityChanged;
  final VoidCallback onAdd;
  final bool compact;

  const _CatalogCard({
    required this.product,
    required this.t,
    required this.scheme,
    required this.quantity,
    required this.onQuantityChanged,
    required this.onAdd,
    required this.compact,
  });

  @override
  Widget build(BuildContext context) {
    final categoryLabel = product.categories.isEmpty
        ? t.productCategoryUnassigned
        : product.categories.join(' / ');
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductThumbnail(
              imageUrl: product.imageUrl,
              aspectRatio: compact ? 4 / 3 : 16 / 10,
              borderRadius: 12,
            ),
            const SizedBox(height: 8),
            Text(
              product.name,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.sku,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
                if (product.lowStock)
                  Chip(
                    avatar: const Icon(Icons.warning_amber_rounded, size: 16),
                    label: Text(t.productLowStockTag),
                    labelStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    backgroundColor: scheme.errorContainer,
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              categoryLabel,
              style: Theme.of(context).textTheme.bodySmall,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: -6,
              children: [
                if (product.tags.contains(ProductTag.featured))
                  ProductTagPill(label: t.productTagFeatured),
                if (product.tags.contains(ProductTag.discounted))
                  ProductTagPill(label: t.productTagDiscounted),
                if (product.tags.contains(ProductTag.newArrival))
                  ProductTagPill(label: t.productTagNew),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _QuantitySelector(
                  value: quantity,
                  onChanged: onQuantityChanged,
                  onSubmit: onAdd,
                  dense: compact,
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.shopping_cart_outlined, size: 18),
                  label: const Text('Add'),
                  style: compact
                      ? FilledButton.styleFrom(
                          minimumSize: const Size(88, 36),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 8,
                          ),
                        )
                      : FilledButton.styleFrom(
                          minimumSize: const Size(110, 40),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ?占쎈웾 ?占쏀깮占?dense ?占쎌뀡?占쎈줈 洹몃━?占쎌슜 ?占쎄린 異뺤냼)
class _QuantitySelector extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final VoidCallback? onSubmit;
  final bool dense;

  const _QuantitySelector({
    required this.value,
    required this.onChanged,
    this.onSubmit,
    this.dense = false,
  });

  @override
  Widget build(BuildContext context) {
    final fieldWidth = dense ? 56.0 : 64.0;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: value > 1
              ? () => onChanged((value - 1).clamp(1, 999))
              : null,
          visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
        ),
        SizedBox(
          width: fieldWidth,
          child: TextField(
            controller: TextEditingController(text: value.toString()),
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: false),
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: InputDecoration(
              contentPadding: const EdgeInsets.symmetric(vertical: 8),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              isDense: true,
            ),
            onChanged: (text) {
              final parsed = int.tryParse(text);
              if (parsed != null) {
                onChanged(parsed.clamp(1, 999));
              }
            },
            onSubmitted: (text) {
              final parsed = int.tryParse(text);
              onChanged((parsed ?? value).clamp(1, 999));
              if (onSubmit != null) onSubmit!();
            },
          ),
        ),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: () => onChanged((value + 1).clamp(1, 999)),
          visualDensity: dense ? VisualDensity.compact : VisualDensity.standard,
        ),
      ],
    );
  }
}

class _BuyerDashboardTab extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<Order> orders;
  final Future<void> Function() onRefresh;
  final ValueChanged<Order> onLoadOrder;

  const _BuyerDashboardTab({
    required this.loading,
    required this.error,
    required this.orders,
    required this.onRefresh,
    required this.onLoadOrder,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (error != null) {
      return Center(
        child: StateMessageView(
          icon: Icons.error_outline,
          title: t.stateErrorMessage,
          message: error,
          action: OutlinedButton.icon(
            onPressed: onRefresh,
            icon: const Icon(Icons.refresh),
            label: Text(t.stateRetry),
          ),
        ),
      );
    }
    final locale = Localizations.localeOf(context);
    final localeName = locale.toString();
    final now = DateTime.now();
    final monthlySpend = orders
        .where(
          (o) => o.createdAt.year == now.year && o.createdAt.month == now.month,
        )
        .fold<double>(0, (sum, o) => sum + o.total);
    final currency = NumberFormat.simpleCurrency(locale: localeName);
    final monthlyValue = currency.format(monthlySpend);
    final totalOrders = orders.length.toString();
    final lastOrder = orders.isEmpty ? null : orders.first;
    final dateFormatter = DateFormat.yMMMd(localeName);
    final timeFormatter = DateFormat.Hm(localeName);
    final lastOrderLabel = lastOrder == null
        ? t.buyerDashboardMetricEmptyValue
        : '${dateFormatter.format(lastOrder.createdAt)} · ${timeFormatter.format(lastOrder.createdAt)}';
    final storeCounts = <String, int>{};
    for (final order in orders) {
      final name = order.buyerName.trim();
      if (name.isEmpty) continue;
      storeCounts[name] = (storeCounts[name] ?? 0) + 1;
    }
    final topStoreLabel = storeCounts.isEmpty
        ? t.buyerDashboardMetricEmptyValue
        : storeCounts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
    final recentOrders = orders.take(6).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: ListView(
        padding: const EdgeInsets.all(16),
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          Text(
            t.buyerDashboardGreeting,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _DashboardMetricCard(
                icon: Icons.auto_graph_outlined,
                label: t.buyerDashboardMetricTotalOrdersLabel,
                value: totalOrders,
              ),
              _DashboardMetricCard(
                icon: Icons.payments_outlined,
                label: t.buyerDashboardMetricMonthlySpendLabel,
                value: monthlyValue,
              ),
              _DashboardMetricCard(
                icon: Icons.history_toggle_off,
                label: t.buyerDashboardMetricLastOrderLabel,
                value: lastOrderLabel,
              ),
              _DashboardMetricCard(
                icon: Icons.store_mall_directory_outlined,
                label: t.buyerDashboardMetricTopStoreLabel,
                value: topStoreLabel,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            t.buyerDashboardHistoryTitle,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 12),
          if (orders.isEmpty)
            StateMessageView(
              icon: Icons.receipt_long_outlined,
              title: t.buyerDashboardHistoryEmpty,
              message: t.buyerDashboardHistoryEmptyHint,
              action: OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: Text(t.stateRetry),
              ),
            )
          else ...[
            for (final order in recentOrders) ...[
              _DashboardOrderCard(
                order: order,
                onLoad: () => onLoadOrder(order),
              ),
              const SizedBox(height: 12),
            ],
          ],
        ],
      ),
    );
  }
}

class _BuyerOrderSheetTab extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final List<String> storeOptions;
  final String? selectedStore;
  final bool storeLoading;
  final String? storeError;
  final ValueChanged<String?> onStoreChanged;
  final TextEditingController contactController;
  final TextEditingController noteController;
  final bool submitting;
  final Future<void> Function(BuyerCartController cart) onSubmit;
  final VoidCallback onBrowseCatalog;
  final VoidCallback onDeliveryTap;
  final DateTime deliveryDate;

  const _BuyerOrderSheetTab({
    required this.formKey,
    required this.storeOptions,
    required this.selectedStore,
    required this.storeLoading,
    required this.storeError,
    required this.onStoreChanged,
    required this.contactController,
    required this.noteController,
    required this.submitting,
    required this.onSubmit,
    required this.onBrowseCatalog,
    required this.onDeliveryTap,
    required this.deliveryDate,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return Consumer<BuyerCartController>(
      builder: (context, cart, _) {
        if (cart.isEmpty) {
          return Center(
            child: StateMessageView(
              icon: Icons.assignment_outlined,
              title: t.buyerCartEmpty,
              message: t.buyerOrderEmptyHint,
              action: FilledButton.icon(
                onPressed: onBrowseCatalog,
                icon: const Icon(Icons.storefront_outlined),
                label: Text(t.buyerOrderBrowseCatalog),
              ),
            ),
          );
        }
        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 900;
            final body = isWide
                ? Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: _CartItemsList(cart: cart)),
                      const SizedBox(width: 24),
                      SizedBox(
                        width: 360,
                        child: _OrderFormSection(
                          cart: cart,
                          storeOptions: storeOptions,
                          selectedStore: selectedStore,
                          storeLoading: storeLoading,
                          storeError: storeError,
                          onStoreChanged: onStoreChanged,
                          contactController: contactController,
                          noteController: noteController,
                          submitting: submitting,
                          onSubmit: onSubmit,
                          onDeliveryTap: onDeliveryTap,
                          deliveryDate: deliveryDate,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CartItemsList(cart: cart),
                      const SizedBox(height: 24),
                      _OrderFormSection(
                        cart: cart,
                        storeOptions: storeOptions,
                        selectedStore: selectedStore,
                        storeLoading: storeLoading,
                        storeError: storeError,
                        onStoreChanged: onStoreChanged,
                        contactController: contactController,
                        noteController: noteController,
                        submitting: submitting,
                        onSubmit: onSubmit,
                        onDeliveryTap: onDeliveryTap,
                        deliveryDate: deliveryDate,
                      ),
                    ],
                  );
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(key: formKey, child: body),
            );
          },
        );
      },
    );
  }
}

class _CartItemsList extends StatelessWidget {
  final BuyerCartController cart;

  const _CartItemsList({required this.cart});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final items = cart.items;
    return Column(
      children: [
        for (final item in items) ...[
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.product.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.product.sku,
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
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
                        t.buyerCartLineTotal(item.lineTotal.toStringAsFixed(2)),
                        style: Theme.of(context).textTheme.titleMedium
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
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _OrderFormSection extends StatelessWidget {
  final BuyerCartController cart;
  final List<String> storeOptions;
  final String? selectedStore;
  final bool storeLoading;
  final String? storeError;
  final ValueChanged<String?> onStoreChanged;
  final TextEditingController contactController;
  final TextEditingController noteController;
  final bool submitting;
  final Future<void> Function(BuyerCartController cart) onSubmit;
  final VoidCallback onDeliveryTap;
  final DateTime deliveryDate;

  const _OrderFormSection({
    required this.cart,
    required this.storeOptions,
    required this.selectedStore,
    required this.storeLoading,
    required this.storeError,
    required this.onStoreChanged,
    required this.contactController,
    required this.noteController,
    required this.submitting,
    required this.onSubmit,
    required this.onDeliveryTap,
    required this.deliveryDate,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final totalLabel = t.buyerCartTotal(cart.totalAmount.toStringAsFixed(2));
    final summaryLabel = t.buyerOrderSummary(
      cart.uniqueItemCount,
      cart.totalQuantity,
    );
    final localeName = Localizations.localeOf(context).toString();
    final deliveryLabel = DateFormat.yMMMd(localeName).format(deliveryDate);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Card(
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.receipt_long_outlined),
                title: Text(totalLabel),
                subtitle: Text(summaryLabel),
              ),
              const Divider(height: 0),
              ListTile(
                leading: const Icon(Icons.event_outlined),
                title: Text(t.buyerDeliveryDateLabel),
                subtitle: Text(deliveryLabel),
                trailing: TextButton(
                  onPressed: onDeliveryTap,
                  child: Text(t.buyerDeliveryDateEdit),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (storeLoading) const LinearProgressIndicator(),
        if (storeError != null) ...[
          const SizedBox(height: 8),
          Text(
            t.buyerOrderStoreLoadError(storeError!),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        ],
        DropdownButtonFormField<String>(
          initialValue: selectedStore,
          onChanged: storeOptions.isEmpty ? null : onStoreChanged,
          decoration: InputDecoration(
            labelText: t.buyerCheckoutStore,
            helperText: storeOptions.isEmpty
                ? t.buyerOrderStoreEmptyHint
                : null,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: storeOptions
              .map((name) => DropdownMenuItem(value: name, child: Text(name)))
              .toList(),
          validator: (_) {
            if (storeOptions.isEmpty) {
              return t.buyerOrderStoreEmptyHint;
            }
            if ((selectedStore ?? '').isEmpty) {
              return t.buyerCheckoutStore;
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: contactController,
          decoration: InputDecoration(
            labelText: t.buyerCheckoutContact,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          textCapitalization: TextCapitalization.words,
          validator: (value) {
            if ((value ?? '').trim().isEmpty) {
              return t.buyerCheckoutContact;
            }
            return null;
          },
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: noteController,
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
          onPressed: submitting ? null : () => onSubmit(cart),
          icon: submitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          label: Text(t.buyerCheckoutSubmit),
        ),
        const SizedBox(height: 8),
        TextButton.icon(
          onPressed: cart.clear,
          icon: const Icon(Icons.clear_all),
          label: Text(t.buyerCartClear),
        ),
      ],
    );
  }
}

class _DashboardMetricCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DashboardMetricCard({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 220,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: scheme.surfaceContainerHighest,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: scheme.primary),
          const SizedBox(height: 12),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}

class _DashboardOrderCard extends StatelessWidget {
  final Order order;
  final VoidCallback onLoad;

  const _DashboardOrderCard({required this.order, required this.onLoad});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final material = MaterialLocalizations.of(context);
    final dateLabel =
        '${material.formatMediumDate(order.createdAt)} · ${material.formatTimeOfDay(TimeOfDay.fromDateTime(order.createdAt))}';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.buyerName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Chip(label: Text(order.status.name.toUpperCase())),
              ],
            ),
            const SizedBox(height: 4),
            Text(
            '${order.code} · $dateLabel',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            Text(
              t.buyerCartTotal(order.total.toStringAsFixed(2)),
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            Text(t.buyerCheckoutItems(order.itemCount)),
            if (order.buyerNote != null && order.buyerNote!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                order.buyerNote!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onLoad,
                icon: const Icon(Icons.assignment_returned_outlined),
                label: Text(t.buyerDashboardHistoryLoad),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


