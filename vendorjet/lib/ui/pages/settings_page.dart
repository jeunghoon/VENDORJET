import 'package:flutter/material.dart';
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
      children.addAll(_buildSellerSettings(context, t, tenant, role, tenants));
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
          final ok = await auth.updateProfile(language: loc);
          if (!mounted) return;
          final ticker = context.read<NotificationTicker>();
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
    Tenant tenant,
    TenantMemberRole? role,
    List<Tenant> tenants,
  ) {
    final widgets = <Widget>[
      Text(
        t.tenantSectionTitle,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      ),
      const SizedBox(height: 8),
      Card(
        child: ListTile(
          leading: const Icon(Icons.apartment),
          title: Text(tenant.name),
          subtitle: Text('${t.tenantRoleLabel}: ${_roleLabel(role, t)}'),
          trailing: Text(
            DateFormat.yMMMd(t.localeName).format(tenant.createdAt),
          ),
        ),
      ),
      const SizedBox(height: 16),
    ];

    if (tenants.length > 1) {
      widgets.addAll([
        Text(
          t.tenantSwitchTitle,
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final item in tenants)
              ChoiceChip(
                label: Text(item.name),
                selected: tenant.id == item.id,
                onSelected: (_) => _switchTenant(item.id),
              ),
          ],
        ),
        const SizedBox(height: 16),
      ]);
    }

    widgets.addAll([
      Text(
        t.tenantInviteTitle,
        style: Theme.of(
          context,
        ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
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
    ]);
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
                      Chip(
                        avatar: const Icon(
                          Icons.check_circle_outline,
                          size: 16,
                        ),
                        label: Text(tenant.name),
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
      isScrollControlled: true,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
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
                                      context,
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
                                : () => Navigator.of(context).pop(),
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
                                      if (!context.mounted) return;
                                      context.read<NotificationTicker>().push(
                                        t.buyerSettingsRequestSuccess(
                                          sellerCtrl.text.trim(),
                                        ),
                                      );
                                      Navigator.of(context).pop();
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
      return resp
          .map(
            (item) => {
              'name': (item['name'] ?? '').toString(),
              'phone': (item['phone'] ?? '').toString(),
              'address': (item['address'] ?? '').toString(),
            },
          )
          .where((entry) => entry['name']!.isNotEmpty)
          .toList();
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
