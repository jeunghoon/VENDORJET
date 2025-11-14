import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/customer.dart';
import 'package:vendorjet/repositories/mock_repository.dart';
import 'package:vendorjet/services/sync/data_refresh_coordinator.dart';
import 'package:vendorjet/ui/pages/customers/customer_form_sheet.dart';
import 'package:vendorjet/ui/widgets/state_views.dart';

class CustomersPage extends StatefulWidget {
  const CustomersPage({super.key});

  @override
  State<CustomersPage> createState() => _CustomersPageState();
}

class _CustomersPageState extends State<CustomersPage> {
  final _repo = MockCustomerRepository();
  final _queryCtrl = TextEditingController();
  List<Customer> _items = const [];
  bool _loading = true;
  String? _error;
  CustomerTier? _tierFilter;
  DataRefreshCoordinator? _refreshCoordinator;
  int _lastCustomersVersion = 0;

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
      _lastCustomersVersion = coordinator.customersVersion;
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
      final items = await _repo.fetch(query: query, tier: _tierFilter);
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

  void _onQuery() => _load();

  void _handleRefreshEvent() {
    final coordinator = _refreshCoordinator;
    if (coordinator == null) return;
    if (coordinator.customersVersion != _lastCustomersVersion) {
      _lastCustomersVersion = coordinator.customersVersion;
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;

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
                  hintText: t.customersSearchHint,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              _TierChips(
                selected: _tierFilter,
                onSelected: (value) {
                  setState(() => _tierFilter = value);
                  _load();
                },
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
                      final tierLabel = _tierFilter == null
                          ? null
                          : _tierLabel(_tierFilter!, t);
                      return StateMessageView(
                        icon: Icons.account_box_outlined,
                        title: t.customersEmptyMessage,
                        message: tierLabel == null
                            ? null
                            : t.customersEmptyFiltered(tierLabel),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: _load,
                      child: ListView.separated(
                        itemBuilder: (context, index) {
                          final customer = _items[index];
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  customer.name.characters.first.toUpperCase(),
                                ),
                              ),
                              title: Text(customer.name),
                              subtitle: Text(
                                '${customer.contactName} · ${customer.email}',
                              ),
                              trailing: PopupMenuButton<String>(
                                onSelected: (value) {
                                  switch (value) {
                                    case 'edit':
                                      _openForm(customer: customer);
                                      break;
                                    case 'delete':
                                      _confirmDelete(customer);
                                      break;
                                  }
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'edit',
                                    child: Text(t.customersEdit),
                                  ),
                                  PopupMenuItem(
                                    value: 'delete',
                                    child: Text(t.customersDelete),
                                  ),
                                ],
                              ),
                              onTap: () => _openForm(customer: customer),
                            ),
                          );
                        },
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemCount: _items.length,
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
            onPressed: () => _openForm(),
            icon: const Icon(Icons.add),
            label: Text(t.customersCreate),
          ),
        ),
      ],
    );
  }

  Future<void> _openForm({Customer? customer}) async {
    final t = AppLocalizations.of(context)!;
    final base =
        customer ??
        Customer(
          id: '',
          name: '',
          contactName: '',
          email: '',
          tier: CustomerTier.platinum,
          createdAt: DateTime.now(),
        );
    final result = await showModalBottomSheet<CustomerFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CustomerFormSheet(t: t, customer: base),
    );
    if (result == null) return;
    final updated = base.copyWith(
      name: result.name,
      contactName: result.contactName,
      email: result.email,
      tier: result.tier,
    );
    await _repo.save(updated);
    if (!mounted) return;
    context.read<DataRefreshCoordinator>().notifyCustomerChanged();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          customer == null ? t.customersCreated : t.customersUpdated,
        ),
      ),
    );
  }

  Future<void> _confirmDelete(Customer customer) async {
    final t = AppLocalizations.of(context)!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t.customersDelete),
          content: Text(t.customersDeleteConfirm(customer.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(t.orderEditCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(t.customersDelete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    await _repo.delete(customer.id);
    if (!mounted) return;
    context.read<DataRefreshCoordinator>().notifyCustomerChanged();
    await _load();
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.customersDeleted)));
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

class _TierChips extends StatelessWidget {
  final CustomerTier? selected;
  final ValueChanged<CustomerTier?> onSelected;

  const _TierChips({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final tiers = <CustomerTier?>[null, ...CustomerTier.values];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          for (final tier in tiers)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(_label(tier, t)),
                selected: tier == selected,
                onSelected: (_) => onSelected(tier),
              ),
            ),
        ],
      ),
    );
  }

  String _label(CustomerTier? tier, AppLocalizations t) {
    if (tier == null) return t.customersFilterAll;
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
