import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/tenant.dart';
import 'package:vendorjet/services/api/api_client.dart';
import 'package:vendorjet/services/auth/auth_controller.dart';
import 'package:vendorjet/ui/widgets/notification_ticker.dart';

class SettingsPage extends StatefulWidget {
  final Locale? currentLocale;
  final ValueChanged<Locale> onLocaleChanged;
  final bool embedded;

  const SettingsPage({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
    this.embedded = false,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _inviteCtrl = TextEditingController();
  TenantMemberRole _inviteRole = TenantMemberRole.manager;
  bool _inviting = false;
  String? _pendingSellerName;
  bool _pendingSellerLoading = false;
  bool _tenantsRefreshing = false;
  String? _membersTenantId;
  bool _membersLoading = false;
  List<TenantMemberDetail> _members = const [];
  final Set<String> _loadedTenants = <String>{};
  final Map<String, List<TenantPosition>> _positionsByTenant = <String, List<TenantPosition>>{};
  final Set<String> _positionsLoading = <String>{};
  final Set<String> _positionAssigning = <String>{};

  Future<void> _showErrorDialog(BuildContext context, String message) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(AppLocalizations.of(context)!.stateErrorMessage),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: Text(AppLocalizations.of(context)!.orderEditCancel),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoCard(BuildContext context, AppLocalizations t, AuthController auth) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: auth.fetchProfile(),
      builder: (context, snapshot) {
        final loading = snapshot.connectionState == ConnectionState.waiting;
        final nameCtrl = TextEditingController(text: snapshot.data?['name']?.toString() ?? '');
        final phoneCtrl = TextEditingController(text: snapshot.data?['phone']?.toString() ?? '');
        final passwordCtrl = TextEditingController();
        final passwordConfirmCtrl = TextEditingController();
        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: InputDecoration(
                    labelText: t.signUpUserNameLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phoneCtrl,
                  decoration: InputDecoration(
                    labelText: t.signUpUserPhoneLabel,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: t.profileFieldPasswordNew,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: passwordConfirmCtrl,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: t.profileFieldPasswordConfirm,
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton(
                    onPressed: loading
                        ? null
                        : () async {
                            final ticker = context.read<NotificationTicker>();
                            if (passwordCtrl.text.isNotEmpty &&
                                passwordCtrl.text != passwordConfirmCtrl.text) {
                              ticker.push(t.profilePasswordMismatch);
                              return;
                            }
                            final ok = await auth.updateProfile(
                              name: nameCtrl.text.trim(),
                              phone: phoneCtrl.text.trim(),
                              password: passwordCtrl.text.trim().isEmpty ? null : passwordCtrl.text.trim(),
                            );
                            if (!mounted) return;
                            ticker.push(ok ? t.profileSaveSuccess : t.stateErrorMessage);
                          },
                    child: loading
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.orderEditSave),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshTenants();
      _loadPendingSeller();
    });
  }

  @override
  void dispose() {
    _inviteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final auth = context.watch<AuthController>();
    final tenant = auth.tenant;
    final isBuyer = auth.isBuyer;

    final tabs = [
      const Tab(text: '매장 관리'),
      const Tab(text: '직원 관리'),
      const Tab(text: '개인 설정'),
    ];

    final storeTab = ListView(
      padding: const EdgeInsets.all(16),
      children: isBuyer
          ? _buildBuyerSettings(t, auth)
          : (tenant != null ? _buildSellerSettings(context, t, auth, tenant, auth.role, auth.tenants) : const []),
    );
    final staffTab = _buildStaffTab(context, t, auth, tenant);
    final personalTab = _buildPersonalTab(context, t, auth);

    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(t.buyerMenuSettings),
          bottom: TabBar(tabs: tabs),
        ),
        body: TabBarView(
          children: [
            storeTab,
            staffTab,
            personalTab,
          ],
        ),
      ),
    );
  }

  Widget _buildStaffTab(BuildContext context, AppLocalizations t, AuthController auth, Tenant? tenant) {
    final isBuyer = auth.isBuyer;
    if (isBuyer) {
      final buyerTenant = _resolveBuyerTenant(auth.tenants);
      if (buyerTenant == null) return const SizedBox.shrink();
      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildMemberSection(
            t,
            auth,
            tenantId: buyerTenant.id,
            tenantName: buyerTenant.name,
          ),
          const SizedBox(height: 16),
          _buildPositionSection(
            t,
            auth,
            tenantId: buyerTenant.id,
            tenantName: buyerTenant.name,
          ),
          const SizedBox(height: 16),
          _buildInviteBlock(t),
        ],
      );
    }
    if (tenant == null) return const SizedBox.shrink();
    if (!_loadedTenants.contains(tenant.id)) {
      _loadMembers(tenant.id, forcePositions: true);
      _loadPositions(tenant.id, force: true);
      _loadedTenants.add(tenant.id);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildMemberSection(
          t,
          auth,
          tenantId: tenant.id,
          tenantName: tenant.name,
        ),
        const SizedBox(height: 16),
        _buildPositionSection(
          t,
          auth,
          tenantId: tenant.id,
          tenantName: tenant.name,
        ),
        const SizedBox(height: 16),
        _buildInviteBlock(t),
      ],
    );
  }

  Widget _buildInviteBlock(AppLocalizations t) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              t.tenantInviteTitle,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _inviteCtrl,
                    decoration: InputDecoration(
                      labelText: t.inviteEmailPlaceholder,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                DropdownButton<TenantMemberRole>(
                  value: _inviteRole,
                  onChanged: (value) {
                    if (value != null) setState(() => _inviteRole = value);
                  },
                  items: [
                    DropdownMenuItem(
                      value: TenantMemberRole.manager,
                      child: Text(_roleLabel(TenantMemberRole.manager, t)),
                    ),
                    DropdownMenuItem(
                      value: TenantMemberRole.staff,
                      child: Text(_roleLabel(TenantMemberRole.staff, t)),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _inviting ? null : _inviteMember,
                child: _inviting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(t.inviteSend),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalTab(BuildContext context, AppLocalizations t, AuthController auth) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          t.language,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        _buildPersonalInfoCard(context, t, auth),
        const SizedBox(height: 16),
        DropdownButtonFormField<Locale>(
          initialValue: _normalized(widget.currentLocale) ?? const Locale('en'),
          decoration: InputDecoration(
            labelText: t.selectLanguage,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 10,
            ),
          ),
          items: [
            DropdownMenuItem(value: const Locale('en'), child: Text(t.english)),
            DropdownMenuItem(value: const Locale('ko'), child: Text(t.korean)),
          ],
          onChanged: (loc) async {
            if (loc == null) return;
            widget.onLocaleChanged(loc);
            final ticker = context.read<NotificationTicker>();
            final ok = await auth.updateProfile(language: loc);
            if (!mounted) return;
            ticker.push(ok ? t.settingsLanguageSaved : t.stateErrorMessage);
          },
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () async {
            final authController = context.read<AuthController>();
            final router = GoRouter.of(context);
            await authController.signOut();
            if (!mounted) return;
            router.go('/sign-in');
          },
          icon: const Icon(Icons.logout),
          label: Text(t.buyerMenuLogout),
        ),
      ],
    );
  }

  List<Widget> _buildSellerSettings(
    BuildContext context,
    AppLocalizations t,
    AuthController auth,
    Tenant tenant,
    TenantMemberRole? role,
    List<Tenant> tenants,
  ) {
    final sellerTenants = tenants
        .where((item) => item.type != TenantType.buyer)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    final membershipRoles = <String, TenantMemberRole>{
      for (final membership in auth.memberships) membership.tenantId: membership.role,
    };
    final widgets = <Widget>[
      Text(
        t.tenantSectionTitle,
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w700,
            ),
      ),
      const SizedBox(height: 8),
      Card(
        child: ListTile(
          leading: const Icon(Icons.storefront_outlined),
          title: Text(tenant.name),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('${t.tenantRoleLabel}: ${_roleLabel(role, t)}'),
              Text(DateFormat.yMMMd(t.localeName).format(tenant.createdAt)),
            ],
          ),
          trailing: Wrap(
            spacing: 8,
            children: [
              Chip(
                label: Text(t.settingsStoreCurrentLabel),
                visualDensity: VisualDensity.compact,
              ),
              OutlinedButton.icon(
                onPressed: () => _openCompanyForm(t, auth, tenant: tenant),
                icon: const Icon(Icons.edit_outlined, size: 18),
                label: Text(t.settingsCompanyEditAction),
              ),
              if (role == TenantMemberRole.owner)
                OutlinedButton.icon(
                  onPressed: () => _confirmDeleteCompany(t, auth, tenant),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(t.settingsCompanyDeleteAction),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 12),
      _buildStoreSelector(
        context,
        t,
        stores: sellerTenants,
        activeTenantId: tenant.id,
        membershipRoles: membershipRoles,
      ),
    ];
    return widgets;
  }

  Future<void> _openCompanyForm(
    AppLocalizations t,
    AuthController auth, {
    Tenant? tenant,
  }) async {
    final nameCtrl = TextEditingController(text: tenant?.name ?? '');
    final repCtrl = TextEditingController(text: tenant?.representative ?? '');
    final phoneCtrl = TextEditingController(text: tenant?.phone ?? '');
    final addressCtrl = TextEditingController(text: tenant?.address ?? '');
    final formKey = GlobalKey<FormState>();
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetInnerContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 20,
                bottom: MediaQuery.of(sheetInnerContext).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tenant == null
                          ? t.settingsCompanyFormTitleAdd
                          : t.settingsCompanyFormTitleEdit,
                      style: Theme.of(sheetInnerContext).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: nameCtrl,
                      decoration: InputDecoration(
                        labelText: t.settingsCompanyFormNameLabel,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                          ? t.settingsCompanyFormNameRequired
                          : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: repCtrl,
                      decoration: InputDecoration(
                        labelText: t.settingsCompanyFormRepresentativeLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phoneCtrl,
                      decoration: InputDecoration(
                        labelText: t.settingsCompanyFormPhoneLabel,
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: addressCtrl,
                      decoration: InputDecoration(
                        labelText: t.settingsCompanyFormAddressLabel,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        TextButton(
                          onPressed: saving
                              ? null
                              : () => Navigator.of(sheetContext).pop(),
                          child: Text(t.orderEditCancel),
                        ),
                        const Spacer(),
                        FilledButton(
                          onPressed: saving
                              ? null
                              : () async {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  setSheetState(() => saving = true);
                                  bool ok = false;
                                  try {
                                    ok = tenant == null
                                        ? await auth.createTenantForCurrentUser(
                                            name: nameCtrl.text.trim(),
                                            representative: repCtrl.text.trim(),
                                            phone: phoneCtrl.text.trim(),
                                            address: addressCtrl.text.trim(),
                                          )
                                        : await auth.updateTenant(
                                            tenantId: tenant.id,
                                            name: nameCtrl.text.trim(),
                                            representative: repCtrl.text.trim(),
                                            phone: phoneCtrl.text.trim(),
                                            address: addressCtrl.text.trim(),
                                          );
                                  } catch (err) {
                                    ok = false;
                                    if (sheetInnerContext.mounted) {
                                      await _showErrorDialog(
                                        sheetInnerContext,
                                        err.toString(),
                                      );
                                    }
                                  }
                                  if (!mounted) return;
                                  setSheetState(() => saving = false);
                                  if (!sheetInnerContext.mounted) return;
                                  final ticker = sheetInnerContext
                                      .read<NotificationTicker>();
                                  if (!ok) {
                                    ticker.push(t.settingsCompanyFormSaveError);
                                    return;
                                  }
                                  ticker.push(t.settingsCompanyFormSaved);
                                  Navigator.of(sheetContext).pop();
                                  _refreshTenants();
                                },
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(t.settingsCompanyFormSave),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    nameCtrl.dispose();
    repCtrl.dispose();
    phoneCtrl.dispose();
    addressCtrl.dispose();
  }

  Future<void> _confirmDeleteCompany(
    AppLocalizations t,
    AuthController auth,
    Tenant tenant,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(t.settingsCompanyDeleteAction),
          content: Text(t.settingsCompanyDeleteConfirm(tenant.name)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: Text(t.orderEditCancel),
            ),
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: Text(t.settingsCompanyDeleteAction),
            ),
          ],
        );
      },
    );
    if (ok != true) return;
    final success = await auth.deleteTenant(tenant.id);
    if (!mounted) return;
    final ticker = context.read<NotificationTicker>();
    ticker.push(
      success
          ? t.settingsCompanyFormDeleteSuccess
          : t.settingsCompanyFormDeleteError,
    );
    if (success) {
      _refreshTenants();
    }
  }

  Future<void> _setPrimaryCompany(
    AppLocalizations t,
    AuthController auth,
    Tenant tenant,
  ) async {
    final ok = await auth.setPrimaryTenant(tenant.id);
    if (!mounted) return;
    final ticker = context.read<NotificationTicker>();
    ticker.push(ok ? t.settingsCompanyPrimarySaved : t.stateErrorMessage);
    if (ok) {
      _refreshTenants();
    }
  }

  void _handleBuyerSellerPreference(
    AppLocalizations t,
    AuthController auth,
    Tenant tenant,
  ) {
    auth.setActiveSellerTenant(tenant.id);
    final ticker = context.read<NotificationTicker>();
    ticker.push(t.buyerSettingsActiveSellerSaved(tenant.name));
  }

  List<Widget> _buildBuyerSettings(AppLocalizations t, AuthController auth) {
    final buyerTenants = auth.tenants
        .where((tenant) => tenant.type == TenantType.buyer)
        .toList();
    final sellerTenants = auth.tenants
        .where((tenant) => tenant.type == TenantType.seller)
        .toList();
    final pendingLabel = _pendingSellerLoading
        ? t.buyerSettingsPendingLoading
        : (_pendingSellerName?.isNotEmpty == true
              ? t.buyerSettingsPendingWithSeller(_pendingSellerName!)
              : t.buyerSettingsPendingNone);

    final widgets = <Widget>[
      Text(
        t.buyerSettingsSectionTitle,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
    ];

    if (buyerTenants.isEmpty) {
      if (_tenantsRefreshing) {
        widgets.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 32),
            child: Center(child: CircularProgressIndicator()),
          ),
        );
      } else {
        widgets.add(
          Card(
            child: ListTile(
              leading: const Icon(Icons.storefront_outlined),
              title: Text(t.buyerSettingsCompanyFallback),
              subtitle: Text(t.buyerSettingsCompanyMissing),
            ),
          ),
        );
      }
    } else {
      for (final tenant in buyerTenants) {
        widgets.add(_buildBuyerCompanyCard(t, auth, tenant));
        widgets.add(const SizedBox(height: 12));
      }
    }

    widgets.add(
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton.icon(
          onPressed: () => _openCompanyForm(t, auth),
          icon: const Icon(Icons.add),
          label: Text(t.settingsCompanyAddButton),
        ),
      ),
    );
    widgets.add(const SizedBox(height: 24));

    final primaryBuyer = _resolveBuyerTenant(buyerTenants);
    final canRequestConnection = primaryBuyer != null && _canManageMembers(auth, primaryBuyer.id);

    widgets.add(
      Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.buyerSettingsConnectionsTitle,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              if (sellerTenants.isEmpty)
                Text(
                  t.buyerSettingsNoConnections,
                  style: Theme.of(context).textTheme.bodyMedium,
                )
              else ...[
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tenant in sellerTenants)
                      ChoiceChip(
                        label: Text(tenant.name),
                        selected: tenant.id == auth.activeSellerTenantId,
                        onSelected: (selected) {
                          if (!selected) return;
                          _handleBuyerSellerPreference(t, auth, tenant);
                        },
                        avatar: const Icon(
                          Icons.store_mall_directory_outlined,
                          size: 16,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Column(
                  children: [
                    for (var i = 0; i < sellerTenants.length; i++) ...[
                      _StoreTile(
                        tenant: sellerTenants[i],
                        isActive: sellerTenants[i].id == auth.activeSellerTenantId,
                        onSwitch: () => _handleBuyerSellerPreference(
                          t,
                          auth,
                          sellerTenants[i],
                        ),
                        switchLabel: t.buyerSettingsConnectionsSwitchAction,
                        activeLabel: t.buyerSettingsConnectionsActiveLabel,
                        roleLabel: t.settingsCompanyFormRepresentativeLabel,
                        roleValue: sellerTenants[i].representative.isNotEmpty
                            ? sellerTenants[i].representative
                            : t.buyerSettingsCompanyFallback,
                      ),
                      if (i != sellerTenants.length - 1) const Divider(height: 0),
                    ],
                  ],
                ),
              ],
              if (sellerTenants.length > 1) ...[
                const SizedBox(height: 16),
                Text(
                  t.buyerSettingsActiveSellerTitle,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  key: ValueKey(auth.activeSellerTenantId ?? sellerTenants.first.id),
                  initialValue: auth.activeSellerTenantId ?? sellerTenants.first.id,
                  decoration: InputDecoration(
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    labelText: t.buyerSettingsActiveSellerTitle,
                  ),
                  items: sellerTenants
                      .map(
                        (tenant) => DropdownMenuItem(
                          value: tenant.id,
                          child: Text(tenant.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    auth.setActiveSellerTenant(value);
                    final selected = sellerTenants.firstWhere(
                      (tenant) => tenant.id == value,
                      orElse: () => sellerTenants.first,
                    );
                    context.read<NotificationTicker>().push(
                          t.buyerSettingsActiveSellerSaved(selected.name),
                        );
                  },
                ),
                const SizedBox(height: 4),
                Text(
                  t.buyerSettingsActiveSellerHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ],
          ),
        ),
      ),
    );
    widgets.add(const SizedBox(height: 12));
    widgets.add(
      Card(
        child: ListTile(
          leading: const Icon(Icons.pending_actions_outlined),
          title: Text(t.buyerSettingsPendingTitle),
          subtitle: Text(pendingLabel),
        ),
      ),
    );
    widgets.add(const SizedBox(height: 12));
    widgets.add(
      FilledButton.icon(
        onPressed: !canRequestConnection
            ? null
            : () => _openBuyerReconnectSheet(
                  auth,
                  connectedSellerIds: sellerTenants.map((tenant) => tenant.id).toList(),
                  connectedSellerNames: sellerTenants.map((tenant) => tenant.name).toList(),
                  pendingSellerName: _pendingSellerName,
                ),
        icon: const Icon(Icons.link_outlined),
        label: Text(t.buyerSettingsRequestButton),
      ),
    );
    if (!canRequestConnection) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text(
            t.buyerSettingsRequestOwnerOnly,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      );
    }
    widgets.add(const Divider(height: 32));
    return widgets;
  }

  Widget _buildBuyerCompanyCard(
    AppLocalizations t,
    AuthController auth,
    Tenant tenant,
  ) {
    final membership = auth.memberships.firstWhere(
      (m) => m.tenantId == tenant.id,
      orElse: () =>
          TenantMembership(tenantId: tenant.id, role: TenantMemberRole.staff),
    );
    final detailStyle = Theme.of(context).textTheme.bodyMedium;
    final fallback = t.buyerSettingsCompanyMissing;
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
                    tenant.name,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (tenant.isPrimary)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(t.settingsCompanyPrimaryBadge),
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.secondaryContainer,
                    ),
                  ),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'primary':
                        _setPrimaryCompany(t, auth, tenant);
                        break;
                      case 'edit':
                        _openCompanyForm(t, auth, tenant: tenant);
                        break;
                      case 'delete':
                        _confirmDeleteCompany(t, auth, tenant);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'primary',
                      enabled: !tenant.isPrimary,
                      child: Text(t.settingsCompanySetPrimary),
                    ),
                    PopupMenuItem(
                      value: 'edit',
                      child: Text(t.settingsCompanyEditAction),
                    ),
                    PopupMenuItem(
                      value: 'delete',
                      child: Text(t.settingsCompanyDeleteAction),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              '${t.settingsCompanyRepresentativeLabel}: ${tenant.representative.isNotEmpty ? tenant.representative : fallback}',
              style: detailStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '${t.settingsCompanyPhoneLabel}: ${tenant.phone.isNotEmpty ? tenant.phone : fallback}',
              style: detailStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '${t.settingsCompanyAddressLabel}: ${tenant.address.isNotEmpty ? tenant.address : fallback}',
              style: detailStyle,
            ),
            const SizedBox(height: 4),
            Text(
              '${t.settingsCompanyRoleLabel}: ${_roleLabel(membership.role, t)}',
              style: detailStyle,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _openCompanyForm(t, auth, tenant: tenant),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(t.settingsCompanyEditAction),
                ),
                OutlinedButton.icon(
                  onPressed: () => _confirmDeleteCompany(t, auth, tenant),
                  icon: const Icon(Icons.delete_outline, size: 18),
                  label: Text(t.settingsCompanyDeleteAction),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.error,
                  ),
                ),
                if (!tenant.isPrimary)
                  OutlinedButton.icon(
                    onPressed: () => _setPrimaryCompany(t, auth, tenant),
                    icon: const Icon(Icons.push_pin_outlined, size: 18),
                    label: Text(t.settingsCompanySetPrimary),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Tenant? _resolveBuyerTenant(List<Tenant> tenants) {
    if (tenants.isEmpty) return null;
    return tenants.firstWhere(
      (tenant) => tenant.type == TenantType.buyer,
      orElse: () => tenants.first,
    );
  }

  Future<void> _openBuyerReconnectSheet(
    AuthController auth, {
    required List<String> connectedSellerIds,
    required List<String> connectedSellerNames,
    String? pendingSellerName,
  }) async {
    final sellerDirectory = await _fetchSellerDirectory();
    if (!mounted) return;
    final profile = await auth.fetchProfile();
    if (!mounted) return;
    final buyerTenant = _resolveBuyerTenant(auth.tenants);
    final pendingSeller = await showModalBottomSheet<String>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      builder: (_) => _BuyerReconnectSheet(
        auth: auth,
        sellerDirectory: sellerDirectory,
        connectedSellerIds: connectedSellerIds,
        connectedSellerNames: connectedSellerNames,
        pendingSellerName: pendingSellerName,
        initialBuyerName: buyerTenant?.name ?? '',
        initialBuyerAddress:
            buyerTenant?.address ?? (profile?['address']?.toString() ?? ''),
        initialBuyerSegment: profile?['segment']?.toString() ?? '',
        initialContactName: profile?['name']?.toString() ?? '',
        initialContactPhone: profile?['phone']?.toString() ?? '',
      ),
    );
    if (!mounted || pendingSeller == null || pendingSeller.isEmpty) return;
    setState(() {
      _pendingSellerName = pendingSeller;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadPendingSeller());
  }

  Future<List<Map<String, String>>> _fetchSellerDirectory() async {
    try {
      final resp =
          await ApiClient.get(
                '/auth/tenants-public',
                query: {'type': 'wholesale'},
              )
              as List<dynamic>;
      final mapped = resp
          .map(
            (item) => {
              'id': (item['id'] ?? '').toString(),
              'name': (item['name'] ?? '').toString(),
              'phone': (item['phone'] ?? '').toString(),
              'address': (item['address'] ?? '').toString(),
            },
          )
          .where((entry) => entry['name']!.isNotEmpty)
          .toList();
      final seen = <String>{};
      final deduped = <Map<String, String>>[];
      for (final entry in mapped) {
        final id = (entry['id'] ?? '').toString();
        final key = id.isNotEmpty
            ? id
            : '${entry['name'] ?? ''}|${entry['phone'] ?? ''}|${entry['address'] ?? ''}';
        if (seen.add(key)) {
          deduped.add(entry);
        }
      }
      return deduped;
    } catch (err) {
      if (mounted) {
        context.read<NotificationTicker>().push(err.toString());
      }
      return [];
    }
  }

  Future<void> _loadMembers(String tenantId, {bool forcePositions = false}) async {
    setState(() {
      _membersLoading = true;
      _membersTenantId = tenantId;
    });
    try {
      final members = await context.read<AuthController>().fetchTenantMembers(tenantId);
      if (!mounted || _membersTenantId != tenantId) return;
      setState(() {
        _members = _sortMembers(context.read<AuthController>(), members);
        _membersLoading = false;
      });
    } catch (_) {
      if (!mounted || _membersTenantId != tenantId) return;
      setState(() {
        _membersLoading = false;
      });
    }
    _loadPositions(tenantId, force: forcePositions);
  }

  Future<void> _loadPositions(String tenantId, {bool force = false}) async {
    if (tenantId.isEmpty) return;
    if (_positionsLoading.contains(tenantId)) return;
    final hasCache = _positionsByTenant.containsKey(tenantId);
    if (hasCache && !force) return;
    setState(() {
      _positionsLoading.add(tenantId);
      if (force) {
        _positionsByTenant.remove(tenantId);
      }
    });
    try {
      final positions = await context.read<AuthController>().fetchTenantPositions(tenantId);
      if (!mounted) return;
    final sorted = [...positions]
      .where((p) => !_isForbiddenPositionName(p.title) && p.tier != TenantPositionTier.pending && p.tier != TenantPositionTier.owner)
      .toList()
      ..sort((a, b) {
        final order = a.sortOrder.compareTo(b.sortOrder);
        if (order != 0) return order;
        return a.title.toLowerCase().compareTo(b.title.toLowerCase());
      });
      setState(() {
        _positionsByTenant[tenantId] = sorted;
        _positionsLoading.remove(tenantId);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _positionsLoading.remove(tenantId);
      });
    }
  }

  bool _canManageMembers(AuthController auth, String tenantId) {
    return auth.memberships.any(
      (m) => m.tenantId == tenantId && m.role == TenantMemberRole.owner,
    );
  }

  String _positionAssignKey(String tenantId, String memberId) => '$tenantId|$memberId';

  Future<void> _assignMemberPosition(
    AppLocalizations t,
    AuthController auth, {
    required String tenantId,
    required TenantMemberDetail member,
    String? positionId,
  }) async {
    final key = _positionAssignKey(tenantId, member.id);
    setState(() => _positionAssigning.add(key));
    final ok = await auth.assignMemberPosition(
      tenantId: tenantId,
      memberId: member.id,
      positionId: positionId,
    );
    if (ok && positionId != null) {
      final positions = _positionsByTenant[tenantId] ?? const <TenantPosition>[];
      final selected = positions.firstWhere(
        (p) => p.id == positionId,
        orElse: () => const TenantPosition(
          id: '',
          tenantId: '',
          title: '',
          tier: TenantPositionTier.staff,
          sortOrder: 99,
          isLocked: false,
        ),
      );
      if (selected.id.isNotEmpty) {
        final role = switch (selected.tier) {
          TenantPositionTier.owner => TenantMemberRole.owner,
          TenantPositionTier.manager => TenantMemberRole.manager,
          _ => TenantMemberRole.staff,
        };
        await auth.updateTenantMemberRole(
          tenantId: tenantId,
          memberId: member.id,
          role: role,
        );
      }
    }
    if (!mounted) return;
    setState(() => _positionAssigning.remove(key));
    final ticker = context.read<NotificationTicker>();
    ticker.push(ok ? t.settingsMembersPositionSaved : t.stateErrorMessage);
    if (ok && _membersTenantId == tenantId) {
      _loadMembers(tenantId);
    }
  }

  Widget _buildMemberSection(
    AppLocalizations t,
    AuthController auth, {
    required String tenantId,
    required String tenantName,
  }) {
    final isActiveTenant = _membersTenantId == tenantId;
    final loading = _membersLoading && isActiveTenant;
    final members = isActiveTenant ? _members : const <TenantMemberDetail>[];
    final canManage = _canManageMembers(auth, tenantId);
    final currentEmail = (auth.email ?? '').toLowerCase();
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
                    '$tenantName · ${t.settingsMembersSectionTitle}',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: t.stateRetry,
                  onPressed: () => _loadMembers(tenantId, forcePositions: true),
                ),
              ],
            ),
            if (canManage)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  t.settingsMembersOwnerHint,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (members.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(t.buyerSettingsCompanyFallback),
              )
            else
              Column(
                children: [
                  for (final member in members) ...[
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              member.name.isNotEmpty ? member.name : member.email,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ),
                          if (member.email.toLowerCase() == currentEmail)
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Chip(
                                label: Text(t.settingsMembersSelfBadge),
                                visualDensity: VisualDensity.compact,
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text(
                        [
                          if (member.email.isNotEmpty) member.email,
                          if (member.phone.isNotEmpty) member.phone,
                        ].join(' · '),
                      ),
                      const SizedBox(height: 8),
                      _buildMemberPositionPicker(
                        t,
                        auth,
                        tenantId: tenantId,
                        member: member,
                        canManage: canManage,
                        currentUserEmail: currentEmail,
                      ),
                        ],
                      ),
                    ),
                    const Divider(height: 16),
                  ],
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberPositionPicker(
    AppLocalizations t,
    AuthController auth, {
    required String tenantId,
    required TenantMemberDetail member,
    required bool canManage,
    required String currentUserEmail,
  }) {
    final positions = (_positionsByTenant[tenantId] ?? const <TenantPosition>[])
        .where((pos) => !_isHiddenPosition(pos))
        .toList();
    final assigning = _positionAssigning.contains(_positionAssignKey(tenantId, member.id));
    final loading = _positionsLoading.contains(tenantId);
    final isOwner = member.role == TenantMemberRole.owner;
    final isSelf = member.email.toLowerCase() == currentUserEmail;
    final noneLabel = t.settingsMembersPositionNone;
    if (!canManage || isOwner || isSelf) {
      final title = member.positionTitle?.trim() ?? '';
      final label = title.isNotEmpty && !_isForbiddenPositionName(title)
          ? title
          : (isOwner ? t.roleOwner : noneLabel);
      return Text(label);
    }
    if (positions.isEmpty) {
      if (loading) {
        return const SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        );
      }
      return Text(noneLabel);
    }
    final selectable = positions.where((pos) => !_isHiddenPosition(pos)).toList();
    final initial = selectable.any((pos) => pos.id == member.positionId) ? member.positionId : null;
    final options = <String, String>{
      for (final pos in selectable) pos.id: pos.title,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(t.settingsMembersPositionLabel, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 6),
        OutlinedButton(
          onPressed: assigning || loading
              ? null
              : () async {
                  final picked = await _showOptionSheet(
                    context,
                    title: t.settingsMembersPositionLabel,
                    options: options,
                    current: initial,
                  );
                  if (picked == null) return;
                  _assignMemberPosition(
                    t,
                    auth,
                    tenantId: tenantId,
                    member: member,
                    positionId: picked,
                  );
                },
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  initial != null ? (options[initial] ?? noneLabel) : noneLabel,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
        if (assigning || loading)
          const Padding(
            padding: EdgeInsets.only(top: 4),
            child: SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
      ],
    );
  }

  Widget _buildPositionSection(
    AppLocalizations t,
    AuthController auth, {
    required String tenantId,
    required String tenantName,
  }) {
    final allPositions = _positionsByTenant[tenantId] ?? const <TenantPosition>[];
    final positions = allPositions.where((pos) => !_isHiddenPosition(pos)).toList();
    final loading = _positionsLoading.contains(tenantId);
    final canManage = _canManageMembers(auth, tenantId);
    if (!canManage && positions.isEmpty && !loading) {
      return const SizedBox.shrink();
    }
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
                    t.settingsPositionsSectionTitle(tenantName),
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  tooltip: t.stateRetry,
                  icon: const Icon(Icons.refresh),
                  onPressed: () => _loadPositions(tenantId, force: true),
                ),
              ],
            ),
            if (loading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (positions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(t.settingsPositionsEmpty),
              )
            else
              Column(
                children: [
                  for (final position in positions) ...[
                    ListTile(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      title: Text(position.title),
                      trailing: canManage
                          ? Wrap(
                              spacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (position.isLocked ||
                                    position.tier == TenantPositionTier.owner ||
                                    position.tier == TenantPositionTier.pending)
                                  Chip(
                                    label: Text(t.settingsPositionsLockedBadge),
                                    visualDensity: VisualDensity.compact,
                                  )
                                else ...[
                                  IconButton(
                                    icon: const Icon(Icons.edit_outlined),
                                    tooltip: t.settingsPositionsEdit,
                                    onPressed: () => _showPositionEditor(
                                      t,
                                      auth,
                                      tenantId: tenantId,
                                      position: position,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.delete_outline, color: Theme.of(context).colorScheme.error),
                                    tooltip: t.settingsPositionsDelete,
                                    onPressed: () => _deletePosition(t, auth, tenantId, position),
                                  ),
                                ],
                              ],
                            )
                          : null,
                    ),
                    if (position != positions.last) const Divider(height: 0),
                  ],
                ],
              ),
            if (canManage)
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () => _showPositionEditor(t, auth, tenantId: tenantId),
                  icon: const Icon(Icons.add),
                  label: Text(t.settingsPositionsAdd),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _tierLabel(TenantPositionTier tier, AppLocalizations t) {
    switch (tier) {
      case TenantPositionTier.owner:
        return t.settingsPositionsTierOwner;
      case TenantPositionTier.manager:
        return t.settingsPositionsTierManager;
      case TenantPositionTier.staff:
        return t.settingsPositionsTierStaff;
      case TenantPositionTier.pending:
        return t.settingsPositionsTierPending;
    }
  }

  bool _isHiddenPosition(TenantPosition position) {
    return position.tier == TenantPositionTier.owner ||
        position.tier == TenantPositionTier.pending ||
        _isForbiddenPositionName(position.title);
  }

  bool _isForbiddenPositionName(String title) {
    final trimmed = title.trim();
    if (trimmed.isEmpty) return true;
    if (trimmed.length < 2 || trimmed.length > 12) return true;
    final lower = trimmed.toLowerCase();
    const reserved = {'owner', 'pending', 'unassigned', '미지정', 'none'};
    if (reserved.contains(lower)) return true;
    // 숫자만으로 된 경우 거부
    if (RegExp(r'^\d+$').hasMatch(trimmed)) return true;
    return false;
  }

  List<TenantMemberDetail> _sortMembers(AuthController auth, List<TenantMemberDetail> members) {
    final selfEmail = (auth.email ?? '').toLowerCase();
    int rolePriority(TenantMemberRole role) {
      switch (role) {
        case TenantMemberRole.owner:
          return 0;
        case TenantMemberRole.manager:
          return 1;
        case TenantMemberRole.staff:
          return 2;
      }
    }

    final sorted = [...members]..sort((a, b) {
        final aSelf = a.email.toLowerCase() == selfEmail ? 0 : 1;
        final bSelf = b.email.toLowerCase() == selfEmail ? 0 : 1;
        if (aSelf != bSelf) return aSelf.compareTo(bSelf);
        final roleOrder = rolePriority(a.role).compareTo(rolePriority(b.role));
        if (roleOrder != 0) return roleOrder;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    return sorted;
  }

  Future<String?> _showOptionSheet(
    BuildContext context, {
    required String title,
    required Map<String, String> options,
    String? current,
  }) async {
    final orderedKeys = <String>[];
    if (current != null && options.containsKey(current)) {
      orderedKeys.add(current);
    }
    orderedKeys.addAll(options.keys.where((k) => k != current));
    return showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: Text(title, style: Theme.of(context).textTheme.titleMedium),
              ),
              for (final key in orderedKeys)
                ListTile(
                  title: Text(options[key] ?? ''),
                  onTap: () => Navigator.of(sheetContext).pop(key),
                  selected: key == current,
                  selectedColor: Theme.of(context).colorScheme.primary,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStoreSelector(
    BuildContext context,
    AppLocalizations t, {
    required List<Tenant> stores,
    required String activeTenantId,
    required Map<String, TenantMemberRole> membershipRoles,
  }) {
    if (stores.isEmpty) {
      return Card(
        child: ListTile(
          leading: const Icon(Icons.store_mall_directory_outlined),
          title: Text(t.buyerSettingsCompanyFallback),
          subtitle: Text(t.buyerSettingsCompanyMissing),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < stores.length; i++) ...[
            _StoreTile(
              tenant: stores[i],
              isActive: stores[i].id == activeTenantId,
              onSwitch: () => _switchTenant(stores[i].id),
              switchLabel: t.settingsStoreSwitchAction,
              activeLabel: t.settingsStoreCurrentLabel,
              roleLabel: t.settingsCompanyRoleLabel,
              roleValue: _roleLabel(membershipRoles[stores[i].id], t),
            ),
            if (i != stores.length - 1) const Divider(height: 1),
          ],
        ],
      ),
    );
  }

  // 권한 드롭다운 제거: 직책=권한 일원화로 사용 안 함

  Future<void> _loadPendingSeller() async {
    if (!mounted) return;
    final auth = context.read<AuthController>();
    if (!auth.isBuyer) return;
    setState(() {
      _pendingSellerLoading = true;
    });
    try {
      final profile = await auth.fetchProfile();
      if (!mounted) return;
      final pending = (profile?['pendingSeller'] ?? profile?['pending_seller'])
          ?.toString();
      setState(() {
        _pendingSellerName = pending?.isNotEmpty == true ? pending : null;
        _pendingSellerLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _pendingSellerLoading = false;
        _pendingSellerName = null;
      });
    }
  }

  Locale? _normalized(Locale? locale) {
    if (locale == null) return null;
    return Locale(locale.languageCode);
  }

  Future<void> _refreshTenants() async {
    final auth = context.read<AuthController>();
    if (!auth.signedIn) return;
    setState(() => _tenantsRefreshing = true);
    try {
      await auth.refreshTenants();
    } finally {
      if (mounted) {
        setState(() => _tenantsRefreshing = false);
      }
    }
  }

  String _roleLabel(TenantMemberRole? role, AppLocalizations t) {
    switch (role) {
      case TenantMemberRole.owner:
        return t.roleOwner;
      case TenantMemberRole.manager:
        return t.roleManager;
      case TenantMemberRole.staff:
      case null:
        return t.roleStaff;
    }
  }

  Future<void> _switchTenant(String? tenantId) async {
    if (tenantId == null) return;
    final auth = context.read<AuthController>();
    final ok = await auth.switchTenant(tenantId);
    if (!mounted) return;
    final t = AppLocalizations.of(context)!;
    if (!ok) {
      context.read<NotificationTicker>().push(t.tenantSwitchFailed);
    } else {
      _loadedTenants.clear();
      _positionsByTenant.clear();
      _members = const [];
      _membersTenantId = null;
      _positionsLoading.clear();
      _positionAssigning.clear();
      setState(() {});
    }
  }

  Future<void> _inviteMember() async {
    final email = _inviteCtrl.text.trim();
    final t = AppLocalizations.of(context)!;
    if (email.isEmpty) {
      context.read<NotificationTicker>().push(t.inviteEmailPlaceholder);
      return;
    }
    final auth = context.read<AuthController>();
    setState(() => _inviting = true);
    await auth.inviteMember(email: email, role: _inviteRole);
    if (!mounted) return;
    setState(() => _inviting = false);
    _inviteCtrl.clear();
    context.read<NotificationTicker>().push(t.inviteSuccess);
  }

  Future<void> _showPositionEditor(
    AppLocalizations t,
    AuthController auth, {
    required String tenantId,
    TenantPosition? position,
  }) async {
    final controller = TextEditingController(text: position?.title ?? '');
    final formKey = GlobalKey<FormState>();
    TenantPositionTier selectedTier = position?.tier == TenantPositionTier.owner
        ? TenantPositionTier.owner
        : TenantPositionTier.staff;
    final isLockedPosition = position?.tier == TenantPositionTier.owner;
    final result = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        bool saving = false;
        final navigator = Navigator.of(dialogContext);
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: Text(position == null ? t.settingsPositionsAdd : t.settingsPositionsEdit),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: controller,
                      decoration: InputDecoration(labelText: t.settingsPositionsFieldLabel),
                      enabled: !isLockedPosition,
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.isEmpty) return t.settingsPositionsRequired;
                        if (_isForbiddenPositionName(v)) return t.settingsPositionsRequired;
                        return null;
                      },
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<TenantPositionTier>(
                      initialValue: selectedTier,
                      decoration: InputDecoration(labelText: t.settingsMembersPositionLabel),
                      items: [
                        if (position?.tier == TenantPositionTier.owner)
                          DropdownMenuItem(
                            value: TenantPositionTier.owner,
                            enabled: false,
                            child: Text(_tierLabel(TenantPositionTier.owner, t)),
                          ),
                        DropdownMenuItem(
                          value: TenantPositionTier.manager,
                          child: Text(_tierLabel(TenantPositionTier.manager, t)),
                        ),
                        DropdownMenuItem(
                          value: TenantPositionTier.staff,
                          child: Text(_tierLabel(TenantPositionTier.staff, t)),
                        ),
                      ],
                      onChanged: isLockedPosition
                          ? null
                          : (value) {
                              if (value != null) {
                                setStateDialog(() => selectedTier = value);
                              }
                            },
                    ),
                    if (isLockedPosition)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          t.settingsPositionsHierarchyHint,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: saving ? null : () => Navigator.of(dialogContext).pop(false),
                  child: Text(t.orderEditCancel),
                ),
                FilledButton(
                  onPressed: saving || isLockedPosition
                      ? null
                      : () async {
                          if (!(formKey.currentState?.validate() ?? false)) return;
                          setStateDialog(() => saving = true);
                          final title = controller.text.trim();
                          bool ok;
                          if (position == null) {
                            ok = (await auth.createTenantPosition(
                                  tenantId: tenantId,
                                  title: title,
                                  tier: selectedTier,
                                )) !=
                                null;
                          } else {
                            ok = await auth.updateTenantPosition(
                              tenantId: tenantId,
                              positionId: position.id,
                              title: title,
                              tier: selectedTier,
                            );
                          }
                          if (!mounted || !navigator.mounted) return;
                          setStateDialog(() => saving = false);
                          navigator.pop(ok);
                        },
                  child: saving
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(t.settingsPositionsSave),
                ),
              ],
            );
          },
        );
      },
    );
    if (result != true) return;
    if (!mounted) return;
    final ticker = context.read<NotificationTicker>();
    ticker.push(t.settingsPositionsSaved);
    _loadPositions(tenantId, force: true);
  }

  Future<void> _deletePosition(
    AppLocalizations t,
    AuthController auth,
    String tenantId,
    TenantPosition position,
  ) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.settingsPositionsDelete),
        content: Text(t.settingsPositionsDeleteConfirm(position.title)),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.orderEditCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.settingsPositionsDelete),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final success = await auth.deleteTenantPosition(tenantId: tenantId, positionId: position.id);
    if (!mounted) return;
    final ticker = context.read<NotificationTicker>();
    ticker.push(success ? t.settingsPositionsDeleted : t.stateErrorMessage);
    if (success) {
      _loadPositions(tenantId, force: true);
      if (_membersTenantId == tenantId) {
        _loadMembers(tenantId);
      }
    }
  }
}

class _BuyerReconnectSheet extends StatefulWidget {
  final AuthController auth;
  final List<Map<String, String>> sellerDirectory;
  final List<String> connectedSellerIds;
  final List<String> connectedSellerNames;
  final String? pendingSellerName;
  final String initialBuyerName;
  final String initialBuyerAddress;
  final String initialBuyerSegment;
  final String initialContactName;
  final String initialContactPhone;

  const _BuyerReconnectSheet({
    required this.auth,
    required this.sellerDirectory,
    required this.connectedSellerIds,
    required this.connectedSellerNames,
    required this.pendingSellerName,
    required this.initialBuyerName,
    required this.initialBuyerAddress,
    required this.initialBuyerSegment,
    required this.initialContactName,
    required this.initialContactPhone,
  });

  @override
  State<_BuyerReconnectSheet> createState() => _BuyerReconnectSheetState();
}

class _BuyerReconnectSheetState extends State<_BuyerReconnectSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _sellerCtrl;
  late final TextEditingController _buyerCompanyCtrl;
  late final TextEditingController _buyerAddressCtrl;
  late final TextEditingController _buyerSegmentCtrl;
  late final TextEditingController _contactNameCtrl;
  late final TextEditingController _contactPhoneCtrl;
  late final TextEditingController _attachmentCtrl;
  Map<String, String>? _selectedSeller;
  bool _submitting = false;
  String? _selectionWarning;
  late final Set<String> _connectedSellerIdSet;
  late final Set<String> _connectedSellerNameSet;

  @override
  void initState() {
    super.initState();
    _sellerCtrl = TextEditingController();
    _buyerCompanyCtrl = TextEditingController(text: widget.initialBuyerName);
    _buyerAddressCtrl = TextEditingController(text: widget.initialBuyerAddress);
    _buyerSegmentCtrl = TextEditingController(text: widget.initialBuyerSegment);
    _contactNameCtrl = TextEditingController(text: widget.initialContactName);
    _contactPhoneCtrl = TextEditingController(text: widget.initialContactPhone);
    _attachmentCtrl = TextEditingController();
    _connectedSellerIdSet =
        widget.connectedSellerIds.map((e) => e.trim().toLowerCase()).toSet();
    _connectedSellerNameSet =
        widget.connectedSellerNames.map((e) => e.trim().toLowerCase()).toSet();
  }

  @override
  void dispose() {
    _sellerCtrl.dispose();
    _buyerCompanyCtrl.dispose();
    _buyerAddressCtrl.dispose();
    _buyerSegmentCtrl.dispose();
    _contactNameCtrl.dispose();
    _contactPhoneCtrl.dispose();
    _attachmentCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectionWarning == null &&
      _sellerCtrl.text.trim().isNotEmpty &&
      !_submitting;

  void _applySelection(Map<String, String> picked) {
    setState(() {
      _selectedSeller = picked;
      _sellerCtrl.text = picked['name'] ?? '';
      _selectionWarning = _deriveSelectionWarning(picked);
    });
  }

  bool _isConnectedSeller(Map<String, String>? seller) {
    if (seller == null) return false;
    final id = (seller['id'] ?? '').trim().toLowerCase();
    if (id.isNotEmpty && _connectedSellerIdSet.contains(id)) {
      return true;
    }
    final name = (seller['name'] ?? '').trim().toLowerCase();
    if (name.isEmpty) return false;
    return _connectedSellerNameSet.contains(name);
  }

  bool _isPendingSeller(Map<String, String>? seller) {
    if (seller == null) return false;
    final pending = widget.pendingSellerName?.trim().toLowerCase();
    if (pending == null || pending.isEmpty) return false;
    final name = (seller['name'] ?? '').trim().toLowerCase();
    return name.isNotEmpty && name == pending;
  }

  String? _deriveSelectionWarning(Map<String, String>? seller) {
    if (seller == null) return null;
    final name = seller['name'] ?? '';
    if (_isConnectedSeller(seller)) {
      return AppLocalizations.of(context)!
          .buyerSettingsRequestAlreadyConnected(name);
    }
    if (_isPendingSeller(seller)) {
      return AppLocalizations.of(context)!
          .buyerSettingsRequestAlreadyPending(name);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom + 20;
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 20,
        bottom: bottomInset,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                t.buyerSettingsSheetTitle,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _sellerCtrl,
                      readOnly: true,
                      decoration: InputDecoration(
                        labelText: t.buyerSettingsSellerFieldLabel,
                      ),
                      validator: (value) =>
                          (value == null || value.trim().isEmpty)
                              ? t.buyerSettingsRequiredField
                              : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  OutlinedButton(
                    onPressed: widget.sellerDirectory.isEmpty
                        ? null
                        : () async {
                            final picked = await _pickSellerCompany(
                              context,
                              widget.sellerDirectory,
                              t,
                            );
                            if (picked != null) {
                              _applySelection(picked);
                            }
                          },
                    child: Text(t.buyerSettingsSearchAction),
                  ),
                ],
              ),
              if (_selectedSeller != null) ...[
                const SizedBox(height: 6),
                Text(
                  t.buyerSettingsSellerSummary(
                    _selectedSeller?['phone'] ?? '',
                    _selectedSeller?['address'] ?? '',
                  ),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
              if (_selectionWarning != null) ...[
                const SizedBox(height: 6),
                Text(
                  _selectionWarning!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                ),
              ],
              const SizedBox(height: 12),
              TextFormField(
                controller: _buyerCompanyCtrl,
                decoration: InputDecoration(
                  labelText: t.buyerSettingsBuyerFieldLabel,
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? t.buyerSettingsRequiredField
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _buyerAddressCtrl,
                decoration: InputDecoration(
                  labelText: t.buyerSettingsBuyerAddressLabel,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _buyerSegmentCtrl,
                decoration: InputDecoration(
                  labelText: t.buyerSettingsBuyerSegmentLabel,
                ),
                validator: (value) =>
                    (value == null || value.trim().isEmpty)
                        ? t.buyerSettingsRequiredField
                        : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactNameCtrl,
                decoration: InputDecoration(
                  labelText: t.buyerSettingsContactNameLabel,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _contactPhoneCtrl,
                decoration: InputDecoration(
                  labelText: t.buyerSettingsContactPhoneLabel,
                ),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _attachmentCtrl,
                decoration: InputDecoration(
                  labelText: t.buyerSettingsAttachmentLabel,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  TextButton(
                    onPressed:
                        _submitting ? null : () => Navigator.of(context).pop(),
                    child: Text(t.orderEditCancel),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _canSubmit ? _submit : null,
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.buyerSettingsSubmit),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    if (_selectionWarning != null) {
      context.read<NotificationTicker>().push(_selectionWarning!);
      return;
    }
    setState(() => _submitting = true);
    final result = await widget.auth.requestBuyerReconnect(
      sellerCompanyName: _sellerCtrl.text.trim(),
      buyerCompanyName: _buyerCompanyCtrl.text.trim(),
      buyerAddress: _buyerAddressCtrl.text.trim(),
      buyerSegment: _buyerSegmentCtrl.text.trim(),
      name: _contactNameCtrl.text.trim(),
      phone: _contactPhoneCtrl.text.trim(),
      attachmentUrl: _attachmentCtrl.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);
    final t = AppLocalizations.of(context)!;
    final ticker = context.read<NotificationTicker>();
    final sellerName = _sellerCtrl.text.trim();
    if (result.success) {
      ticker.push(
        result.message?.isNotEmpty == true
            ? result.message!
            : t.buyerSettingsRequestSuccess(sellerName),
      );
      Navigator.of(context).pop(sellerName);
      return;
    }
    if (result.pendingExists) {
      ticker.push(
        result.message?.isNotEmpty == true
            ? result.message!
            : t.buyerSettingsRequestAlreadyPending(sellerName),
      );
      Navigator.of(context).pop(sellerName);
      return;
    }
    if (result.alreadyConnected) {
      ticker.push(
        result.message?.isNotEmpty == true
            ? result.message!
            : t.buyerSettingsRequestAlreadyConnected(sellerName),
      );
      Navigator.of(context).pop(sellerName);
      return;
    }
    ticker.push(result.message?.isNotEmpty == true ? result.message! : t.stateErrorMessage);
  }

  Future<Map<String, String>?> _pickSellerCompany(
    BuildContext context,
    List<Map<String, String>> options,
    AppLocalizations t,
  ) async {
    String query = '';
    return showDialog<Map<String, String>>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            final filtered = options
                .where(
                  (item) =>
                      item['name']!.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
            return AlertDialog(
              title: Text(t.buyerSettingsSearchSeller),
              content: SizedBox(
                width: 420,
                height: 360,
                child: Column(
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        labelText: t.buyerSettingsSearchFieldLabel,
                      ),
                      onChanged: (value) => setStateDialog(() {
                        query = value;
                      }),
                    ),
                    const SizedBox(height: 12),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filtered.length,
                        itemBuilder: (context, index) {
                          final item = filtered[index];
                          return ListTile(
                            title: Text(item['name'] ?? ''),
                            subtitle: Text(
                              '${item['phone'] ?? ''} · ${item['address'] ?? ''}',
                            ),
                            onTap: () => Navigator.of(dialogContext).pop(item),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: Text(t.orderEditCancel),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _StoreTile extends StatelessWidget {
  final Tenant tenant;
  final bool isActive;
  final VoidCallback onSwitch;
  final String switchLabel;
  final String activeLabel;
  final String roleLabel;
  final String roleValue;

  const _StoreTile({
    required this.tenant,
    required this.isActive,
    required this.onSwitch,
    required this.switchLabel,
    required this.activeLabel,
    required this.roleLabel,
    required this.roleValue,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final subtitle = <String>[
      '$roleLabel: $roleValue',
      if (tenant.address.isNotEmpty) tenant.address,
      if (tenant.phone.isNotEmpty) tenant.phone,
    ];
    return ListTile(
      leading: Icon(
        Icons.storefront_outlined,
        color: isActive ? theme.colorScheme.primary : null,
      ),
      title: Text(
        tenant.name,
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final line in subtitle) if (line.isNotEmpty) Text(line),
        ],
      ),
      trailing: isActive
          ? Chip(
              label: Text(activeLabel),
              visualDensity: VisualDensity.compact,
            )
          : OutlinedButton(
              onPressed: onSwitch,
              child: Text(switchLabel),
            ),
    );
  }
}
