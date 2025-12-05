import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/services/auth/auth_controller.dart';
import 'package:vendorjet/ui/widgets/notification_ticker.dart';

/// 개인정보 설정 페이지
class ProfilePage extends StatefulWidget {
  final bool embedded;

  const ProfilePage({super.key, this.embedded = false});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();
  bool _loading = true;
  bool _saving = false;

  NotificationTicker get _ticker => context.read<NotificationTicker>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (!mounted) return;
    setState(() => _loading = true);
    final profile = await context.read<AuthController>().fetchProfile();
    if (!mounted) return;
    _nameCtrl.text = profile?['name']?.toString() ?? '';
    _emailCtrl.text = profile?['email']?.toString() ?? '';
    _phoneCtrl.text = profile?['phone']?.toString() ?? '';
    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    final t = AppLocalizations.of(context)!;
    if (!mounted) return;
    if (_passwordCtrl.text.isNotEmpty &&
        _passwordCtrl.text != _passwordConfirmCtrl.text) {
      _ticker.push(t.profilePasswordMismatch);
      return;
    }
    setState(() => _saving = true);
    final ok = await context.read<AuthController>().updateProfile(
      name: _nameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      password: _passwordCtrl.text.trim().isEmpty ? null : _passwordCtrl.text,
    );
    if (!mounted) return;
    setState(() => _saving = false);
    _ticker.push(ok ? t.profileSaveSuccess : t.profileSaveFailure);
  }

  Future<void> _deleteAccount() async {
    final t = AppLocalizations.of(context)!;
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(t.profileDeleteTitle),
        content: Text(t.profileDeleteConfirm),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(t.orderEditCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text(t.profileDelete),
          ),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    final success = await context.read<AuthController>().deleteAccount();
    if (!mounted) return;
    _ticker.push(success ? t.profileDelete : t.stateErrorMessage);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final body = _loading
        ? const Center(child: CircularProgressIndicator())
        : ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                t.profileSectionPersonal,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _nameCtrl,
                decoration: InputDecoration(labelText: t.profileFieldName),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _emailCtrl,
                decoration: InputDecoration(labelText: t.profileFieldEmail),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneCtrl,
                decoration: InputDecoration(labelText: t.profileFieldPhone),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordCtrl,
                decoration: InputDecoration(
                  labelText: t.profileFieldPasswordNew,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordConfirmCtrl,
                decoration: InputDecoration(
                  labelText: t.profileFieldPasswordConfirm,
                ),
                obscureText: true,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  FilledButton(
                    onPressed: _saving ? null : _saveProfile,
                    child: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(t.profileSave),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed: _deleteAccount,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.error,
                    ),
                    child: Text(t.profileDelete),
                  ),
                ],
              ),
            ],
          );

    if (widget.embedded) {
      return body;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(t.profileTitle),
        actions: [
          IconButton(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: body,
    );
  }
}
