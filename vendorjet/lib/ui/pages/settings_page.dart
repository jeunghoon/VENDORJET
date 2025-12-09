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
  final Set<String> _memberUpdating = <String>{};

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
    final role = auth.role;
    final tenants = auth.tenants;
    final isBuyer = auth.isBuyer;

    final children = <Widget>[];

    if (isBuyer) {
      children.addAll(_buildBuyerSettings(t, auth));
    } else if (tenant != null) {
      children.addAll(_buildSellerSettings(context, t, auth, tenant, role, tenants));
    }

    if (children.isNotEmpty) {
      children.add(const SizedBox(height: 24));
    }

    children.addAll([
      Text(
        t.language,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
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
      const SizedBox(height: 4),
      Text(
        t.settingsLanguageApplyHint,
        style: Theme.of(context).textTheme.bodySmall,
      ),
      const SizedBox(height: 24),
    ]);

    children.add(
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
    );
    children.add(const SizedBox(height: 24));

    final body = ListView(
      padding: const EdgeInsets.all(16),
      children: children,
    );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(title: Text(t.buyerMenuSettings)),
      body: body,
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
      const SizedBox(height: 24),
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
            items: TenantMemberRole.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text(_roleLabel(value, t)),
                  ),
                )
                .toList(),
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
      const Divider(height: 32),
    ];
    _ensureMembersLoaded(tenant.id);
    widgets.add(
      _buildMemberSection(
        t,
        auth,
        tenantId: tenant.id,
        tenantName: tenant.name,
      ),
    );
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
                                  final ok = tenant == null
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
                                  if (!mounted) return;
                                  setSheetState(() => saving = false);
                                  if (!sheetInnerContext.mounted) return;
                                  final ticker = sheetInnerContext
                                      .read<NotificationTicker>();
                                  ticker.push(
                                    ok
                                        ? t.settingsCompanyFormSaved
                                        : t.settingsCompanyFormSaveError,
                                  );
                                  if (ok) {
                                    Navigator.of(sheetContext).pop();
                                    _refreshTenants();
                                  }
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

    final activeSellerId = auth.tenant != null && auth.tenant!.type == TenantType.seller
        ? auth.tenant!.id
        : null;
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
    if (primaryBuyer != null) {
      _ensureMembersLoaded(primaryBuyer.id);
      widgets.add(
        _buildMemberSection(
          t,
          auth,
          tenantId: primaryBuyer.id,
          tenantName: primaryBuyer.name,
        ),
      );
      widgets.add(const SizedBox(height: 24));
    }

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
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final tenant in sellerTenants)
                      ChoiceChip(
                        label: Text(tenant.name),
                        selected: tenant.id == activeSellerId,
                        onSelected: (selected) {
                          if (!selected) return;
                          _switchTenant(tenant.id);
                        },
                        avatar: const Icon(
                          Icons.store_mall_directory_outlined,
                          size: 16,
                        ),
                      ),
                  ],
                ),
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
        onPressed: () => _openBuyerReconnectSheet(t, auth),
        icon: const Icon(Icons.link_outlined),
        label: Text(t.buyerSettingsRequestButton),
      ),
    );
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
    AppLocalizations t,
    AuthController auth,
  ) async {
    final sellerDirectory = await _fetchSellerDirectory();
    if (!mounted) return;
    final profile = await auth.fetchProfile();
    if (!mounted) return;
    final buyerTenant = _resolveBuyerTenant(auth.tenants);
    final formKey = GlobalKey<FormState>();
    final sellerCtrl = TextEditingController();
    final buyerCompanyCtrl = TextEditingController(
      text: buyerTenant?.name ?? '',
    );
    final buyerAddressCtrl = TextEditingController(
      text: buyerTenant?.address ?? (profile?['address']?.toString() ?? ''),
    );
    final buyerSegmentCtrl = TextEditingController();
    final contactNameCtrl = TextEditingController(
      text: profile?['name']?.toString() ?? '',
    );
    final contactPhoneCtrl = TextEditingController(
      text: profile?['phone']?.toString() ?? '',
    );
    final attachmentCtrl = TextEditingController();
    Map<String, String>? selectedSeller;
    bool submitting = false;

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
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
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
                              controller: sellerCtrl,
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
                            onPressed: sellerDirectory.isEmpty
                                ? null
                                : () async {
                                    final picked = await _pickSellerCompany(
                                      sheetInnerContext,
                                      sellerDirectory,
                                      t.buyerSettingsSearchSeller,
                                      t,
                                    );
                                    if (picked != null) {
                                      setSheetState(() {
                                        selectedSeller = picked;
                                        sellerCtrl.text = picked['name'] ?? '';
                                      });
                                    }
                                  },
                            child: Text(t.buyerSettingsSearchAction),
                          ),
                        ],
                      ),
                      if (selectedSeller != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          t.buyerSettingsSellerSummary(
                            selectedSeller?['phone'] ?? '',
                            selectedSeller?['address'] ?? '',
                          ),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: buyerCompanyCtrl,
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
                        controller: buyerAddressCtrl,
                        decoration: InputDecoration(
                          labelText: t.buyerSettingsBuyerAddressLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: buyerSegmentCtrl,
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
                        controller: contactNameCtrl,
                        decoration: InputDecoration(
                          labelText: t.buyerSettingsContactNameLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: contactPhoneCtrl,
                        decoration: InputDecoration(
                          labelText: t.buyerSettingsContactPhoneLabel,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: attachmentCtrl,
                        decoration: InputDecoration(
                          labelText: t.buyerSettingsAttachmentLabel,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        children: [
                          TextButton(
                            onPressed: submitting
                                ? null
                                : () => Navigator.of(sheetInnerContext).pop(),
                            child: Text(t.orderEditCancel),
                          ),
                          const Spacer(),
                          FilledButton(
                          onPressed: submitting
                              ? null
                              : () async {
                                  if (!(formKey.currentState?.validate() ??
                                      false)) {
                                    return;
                                  }
                                  setSheetState(() => submitting = true);
                                    final ok = await auth.requestBuyerReconnect(
                                      sellerCompanyName: sellerCtrl.text.trim(),
                                      buyerCompanyName: buyerCompanyCtrl.text
                                          .trim(),
                                      buyerAddress: buyerAddressCtrl.text
                                          .trim(),
                                      buyerSegment: buyerSegmentCtrl.text
                                          .trim(),
                                      name: contactNameCtrl.text.trim(),
                                      phone: contactPhoneCtrl.text.trim(),
                                      attachmentUrl: attachmentCtrl.text.trim(),
                                    );
                                    if (!mounted) return;
                                    setSheetState(() => submitting = false);
                                    if (ok) {
                                      if (!mounted) return;
                                      setState(() {
                                        _pendingSellerName = sellerCtrl.text
                                            .trim();
                                      });
                                      if (!sheetInnerContext.mounted) return;
                                      sheetInnerContext
                                          .read<NotificationTicker>()
                                          .push(
                                            t.buyerSettingsRequestSuccess(
                                              sellerCtrl.text.trim(),
                                            ),
                                          );
                                      Navigator.of(sheetInnerContext).pop();
                                      if (mounted) {
                                        WidgetsBinding.instance
                                            .addPostFrameCallback(
                                              (_) => _loadPendingSeller(),
                                            );
                                      }
                                    } else {
                                      if (!context.mounted) return;
                                      context.read<NotificationTicker>().push(
                                        t.stateErrorMessage,
                                      );
                                    }
                                  },
                            child: submitting
                                ? const SizedBox(
                                    height: 18,
                                    width: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
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
          },
        );
      },
    );

    sellerCtrl.dispose();
    buyerCompanyCtrl.dispose();
    buyerAddressCtrl.dispose();
    buyerSegmentCtrl.dispose();
    contactNameCtrl.dispose();
    contactPhoneCtrl.dispose();
    attachmentCtrl.dispose();
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
        final key =
            '${entry['name'] ?? ''}|${entry['phone'] ?? ''}|${entry['address'] ?? ''}';
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

  Future<Map<String, String>?> _pickSellerCompany(
    BuildContext context,
    List<Map<String, String>> options,
    String title,
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
              title: Text(title),
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

  void _ensureMembersLoaded(String tenantId) {
    if (tenantId.isEmpty) return;
    if (_membersTenantId == tenantId && (_membersLoading || _members.isNotEmpty)) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _loadMembers(tenantId);
    });
  }

  Future<void> _loadMembers(String tenantId) async {
    setState(() {
      _membersLoading = true;
      _membersTenantId = tenantId;
    });
    final members = await context.read<AuthController>().fetchTenantMembers(tenantId);
    if (!mounted || _membersTenantId != tenantId) return;
    setState(() {
      _members = members;
      _membersLoading = false;
    });
  }

  bool _canManageMembers(AuthController auth, String tenantId) {
    return auth.memberships.any(
      (m) => m.tenantId == tenantId && m.role == TenantMemberRole.owner,
    );
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
                  onPressed: () => _loadMembers(tenantId),
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
                      subtitle: Text(
                        [
                          if (member.email.isNotEmpty) member.email,
                          if (member.phone.isNotEmpty) member.phone,
                        ].join(' · '),
                      ),
                      trailing: _buildMemberRoleControl(
                        t,
                        tenantId,
                        member,
                        canManage: canManage,
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

  Widget _buildMemberRoleControl(
    AppLocalizations t,
    String tenantId,
    TenantMemberDetail member, {
    required bool canManage,
  }) {
    final isOwner = member.role == TenantMemberRole.owner;
    if (!canManage || isOwner) {
      return Text(_roleLabel(member.role, t));
    }
    final isUpdating = _memberUpdating.contains(member.id);
    return isUpdating
        ? const SizedBox(
            width: 24,
            height: 24,
            child: CircularProgressIndicator(strokeWidth: 2),
          )
        : DropdownButton<TenantMemberRole>(
            value: member.role == TenantMemberRole.owner ? TenantMemberRole.manager : member.role,
            onChanged: (value) {
              if (value == null || value == member.role) return;
              _updateMemberRole(t, tenantId, member, value);
            },
            items: [
              TenantMemberRole.manager,
              TenantMemberRole.staff,
            ].map(
              (role) {
                return DropdownMenuItem(
                  value: role,
                  child: Text(_roleLabel(role, t)),
                );
              },
            ).toList(),
          );
  }

  Future<void> _updateMemberRole(
    AppLocalizations t,
    String tenantId,
    TenantMemberDetail member,
    TenantMemberRole role,
  ) async {
    setState(() {
      _memberUpdating.add(member.id);
    });
    final ok = await context.read<AuthController>().updateTenantMemberRole(
          tenantId: tenantId,
          memberId: member.id,
          role: role,
        );
    if (!mounted) return;
    setState(() {
      _memberUpdating.remove(member.id);
    });
    final ticker = context.read<NotificationTicker>();
    ticker.push(ok ? t.settingsMembersUpdateSuccess : t.settingsMembersUpdateError);
    if (ok && _membersTenantId == tenantId) {
      _loadMembers(tenantId);
    }
  }

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
