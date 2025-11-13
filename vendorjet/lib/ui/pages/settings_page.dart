import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/tenant.dart';
import 'package:vendorjet/services/auth/auth_controller.dart';

class SettingsPage extends StatefulWidget {
  final Locale? currentLocale;
  final ValueChanged<Locale> onLocaleChanged;
  final VoidCallback? onSignOut;

  const SettingsPage({
    super.key,
    required this.currentLocale,
    required this.onLocaleChanged,
    this.onSignOut,
  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final _inviteCtrl = TextEditingController();
  TenantMemberRole _inviteRole = TenantMemberRole.manager;
  bool _inviting = false;

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

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (tenant != null) ...[
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
          if (tenants.length > 1)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
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
              ],
            ),
          const SizedBox(height: 16),
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
                onChanged: (role) {
                  if (role != null) setState(() => _inviteRole = role);
                },
                items: TenantMemberRole.values
                    .map(
                      (role) => DropdownMenuItem(
                        value: role,
                        child: Text(_roleLabel(role, t)),
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
        ],
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
          onChanged: (loc) {
            if (loc != null) widget.onLocaleChanged(loc);
          },
        ),
        const SizedBox(height: 24),
        if (widget.onSignOut != null)
          SizedBox(
            height: 44,
            child: OutlinedButton.icon(
              onPressed: widget.onSignOut,
              icon: const Icon(Icons.logout),
              label: Text(t.signOut),
            ),
          ),
      ],
    );
  }

  Locale? _normalized(Locale? locale) {
    if (locale == null) return null;
    return Locale(locale.languageCode);
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.tenantSwitchFailed)));
    }
  }

  Future<void> _inviteMember() async {
    final email = _inviteCtrl.text.trim();
    final t = AppLocalizations.of(context)!;
    if (email.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(t.inviteEmailPlaceholder)));
      return;
    }
    final auth = context.read<AuthController>();
    setState(() => _inviting = true);
    await auth.inviteMember(email: email, role: _inviteRole);
    if (!mounted) return;
    setState(() => _inviting = false);
    _inviteCtrl.clear();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(t.inviteSuccess)));
  }
}
