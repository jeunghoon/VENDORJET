import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/customer.dart';
import 'package:vendorjet/repositories/mock_repository.dart';
import 'package:vendorjet/services/api/api_client.dart';
import 'package:vendorjet/services/auth/auth_controller.dart';
import 'package:vendorjet/services/sync/data_refresh_coordinator.dart';
import 'package:vendorjet/ui/pages/customers/customer_form_sheet.dart';
import 'package:vendorjet/ui/pages/customers/customer_segment_manager_sheet.dart';
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
  String? _segmentFilter;
  List<String> _segments = const [];
  DataRefreshCoordinator? _refreshCoordinator;
  int _lastCustomersVersion = 0;
  bool _approvalsLoading = false;

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
      final items = await _repo.fetch(
        query: query,
        tier: _tierFilter,
        segment: _segmentFilter,
      );
      final segments = await _repo.fetchSegments();
      if (!mounted) return;
      setState(() {
        _items = items;
        _segments = segments;
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
    final usingMock = !useLocalApi;

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              if (usingMock)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '현재 목업 데이터 모드입니다. 로컬 API로 전환하려면 USE_LOCAL_API=true로 실행하세요.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                ),
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
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _SegmentChips(
                      segments: _segments,
                      selected: _segmentFilter,
                      onSelected: (value) {
                        setState(() => _segmentFilter = value);
                        _load();
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    onPressed: _openSegmentManager,
                    icon: const Icon(Icons.category_outlined),
                    label: Text(t.customersManageSegments),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton.icon(
                    onPressed: _approvalsLoading ? null : _openApprovalPanel,
                    icon: const Icon(Icons.verified_user_outlined),
                    label: const Text('승인 관리'),
                  ),
                  IconButton(
                    tooltip: t.stateRetry,
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
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
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${customer.contactName} · ${customer.email}',
                                  ),
                                  if (customer.segment.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4),
                                      child: Chip(
                                        label: Text(customer.segment),
                                        visualDensity: VisualDensity.compact,
                                        materialTapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                ],
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
          segment: '',
        );
    final result = await showModalBottomSheet<CustomerFormResult>(
      context: context,
      isScrollControlled: true,
      builder: (_) => CustomerFormSheet(
        t: t,
        customer: base,
        segments: _segments,
      ),
    );
    if (result == null) return;
    final updated = base.copyWith(
      name: result.name,
      contactName: result.contactName,
      email: result.email,
      tier: result.tier,
      segment: result.segment ?? '',
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

  Future<void> _openSegmentManager() async {
    final t = AppLocalizations.of(context)!;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CustomerSegmentManagerSheet(
        t: t,
        repository: _repo,
      ),
    );
    if (!mounted) return;
    await _load();
  }

  Future<void> _openApprovalPanel() async {
    final auth = context.read<AuthController?>();
    final tenantName = auth?.tenant?.name;
    setState(() => _approvalsLoading = true);
    List<Map<String, dynamic>> buyerRequests = [];
    try {
      final resp = await ApiClient.get('/admin/requests') as Map<String, dynamic>;
      final list = (resp['buyerRequests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      buyerRequests = tenantName == null
          ? list
          : list.where((r) => (r['sellerCompany'] as String?) == tenantName).toList();
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(err.toString())));
      }
    } finally {
      if (mounted) setState(() => _approvalsLoading = false);
    }
    if (!mounted) return;
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('승인 요청', style: Theme.of(context).textTheme.titleMedium),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (buyerRequests.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('대기 중인 승인 요청이 없습니다.'),
                  )
                else
                  SizedBox(
                    height: 420,
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: buyerRequests.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final r = buyerRequests[index];
                        final status = (r['status'] as String? ?? '').toLowerCase();
                        return Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r['buyerCompany'] ?? '',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleSmall
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text('${r['name'] ?? ''} · ${r['email'] ?? ''}'),
                                Text('상태: ${status == 'pending' ? '대기' : status}'),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    TextButton(
                                      onPressed: status == 'approved'
                                          ? null
                                          : () async {
                                              await ApiClient.patch(
                                                '/admin/requests/${r['id']}',
                                                body: {'status': 'approved'},
                                              );
                                              if (mounted) {
                                                Navigator.of(ctx).pop();
                                                _openApprovalPanel();
                                              }
                                            },
                                      child: const Text('승인'),
                                    ),
                                    const SizedBox(width: 4),
                                    TextButton(
                                      onPressed: status == 'denied'
                                          ? null
                                          : () async {
                                              await ApiClient.patch(
                                                '/admin/requests/${r['id']}',
                                                body: {'status': 'denied'},
                                              );
                                              if (mounted) {
                                                Navigator.of(ctx).pop();
                                                _openApprovalPanel();
                                              }
                                            },
                                      child: const Text('거절'),
                                    ),
                                    const SizedBox(width: 4),
                                    IconButton(
                                      tooltip: '삭제',
                                      onPressed: () async {
                                        await ApiClient.delete('/admin/requests/${r['id']}');
                                        if (mounted) {
                                          Navigator.of(ctx).pop();
                                          _openApprovalPanel();
                                        }
                                      },
                                      icon: const Icon(Icons.delete_outline),
                                      color: Theme.of(context).colorScheme.error,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
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

class _SegmentChips extends StatelessWidget {
  final List<String> segments;
  final String? selected;
  final ValueChanged<String?> onSelected;

  const _SegmentChips({
    required this.segments,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    if (segments.isEmpty) {
      return Text(
        t.customersNoSegmentsHint,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).hintColor,
            ),
      );
    }
    final options = <String?>[null, ...segments];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final segment in options)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ChoiceChip(
                label: Text(
                  segment ?? t.customersSegmentFilterAll,
                ),
                selected: segment == selected,
                onSelected: (_) => onSelected(segment),
              ),
            ),
        ],
      ),
    );
  }
}
