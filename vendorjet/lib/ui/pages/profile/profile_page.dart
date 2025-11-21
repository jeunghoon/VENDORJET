import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vendorjet/services/auth/auth_controller.dart';
import 'package:vendorjet/ui/widgets/notification_ticker.dart';

/// 계정/업체 관리
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
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
    _addressCtrl.text = profile?['address']?.toString() ?? '';
    setState(() => _loading = false);
  }

  Future<void> _saveProfile() async {
    if (!mounted) return;
    setState(() => _saving = true);
    final ok = await context.read<AuthController>().updateProfile(
          name: _nameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          address: _addressCtrl.text.trim(),
          password: _passwordCtrl.text.trim().isEmpty ? null : _passwordCtrl.text,
        );
    if (!mounted) return;
    setState(() => _saving = false);
    _ticker.push(ok ? '저장되었습니다' : '저장에 실패했습니다');
  }

  Future<void> _deleteAccount() async {
    if (!mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('탈퇴'),
        content: const Text('계정을 탈퇴하시겠습니까? 되돌릴 수 없습니다.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('탈퇴')),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    final success = await context.read<AuthController>().deleteAccount();
    if (!mounted) return;
    _ticker.push(success ? '탈퇴되었습니다' : '탈퇴에 실패했습니다');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final tenants = auth.tenants;
    return Scaffold(
      appBar: AppBar(
        title: const Text('계정/업체 관리'),
        actions: [
          IconButton(onPressed: _loading ? null : _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Text('개인 정보', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                TextField(controller: _nameCtrl, decoration: const InputDecoration(labelText: '이름')),
                const SizedBox(height: 8),
                TextField(controller: _emailCtrl, decoration: const InputDecoration(labelText: '이메일')),
                const SizedBox(height: 8),
                TextField(controller: _phoneCtrl, decoration: const InputDecoration(labelText: '전화번호')),
                const SizedBox(height: 8),
                TextField(controller: _addressCtrl, decoration: const InputDecoration(labelText: '주소')),
                const SizedBox(height: 8),
                TextField(
                  controller: _passwordCtrl,
                  decoration: const InputDecoration(labelText: '새 비밀번호 (변경 시만 입력)'),
                  obscureText: true,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _saving ? null : _saveProfile,
                      child: _saving
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Text('저장'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _deleteAccount,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Theme.of(context).colorScheme.error,
                      ),
                      child: const Text('계정 탈퇴'),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Text('업체 관리', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                ...tenants.map(
                  (tenant) => Card(
                    child: ListTile(
                      title: Text(tenant.name),
                      subtitle: Text([
                        if (tenant.phone.isNotEmpty) '전화: ${tenant.phone}',
                        if (tenant.address.isNotEmpty) '주소: ${tenant.address}',
                      ].join('\n')),
                      trailing: PopupMenuButton<String>(
                        onSelected: (value) {
                          if (!mounted) return;
                          if (value == 'edit') {
                            _editTenant(tenant.id, tenant.name, tenant.phone, tenant.address);
                          } else if (value == 'delete') {
                            _deleteTenant(tenant.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(value: 'edit', child: Text('수정')),
                          PopupMenuItem(value: 'delete', child: Text('삭제')),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: _addTenant,
                  icon: const Icon(Icons.add_business),
                  label: const Text('업체 추가'),
                ),
              ],
            ),
    );
  }

  Future<void> _addTenant() async {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final addrCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('업체 추가'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '업체명')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: '전화번호')),
            const SizedBox(height: 8),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: '주소')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('추가')),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    await context.read<AuthController>().createTenantForCurrentUser(
          name: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          address: addrCtrl.text.trim(),
        );
    if (mounted) await _load();
    _ticker.push('업체가 추가되었습니다');
  }

  Future<void> _editTenant(String tenantId, String currentName, String currentPhone, String currentAddress) async {
    final nameCtrl = TextEditingController(text: currentName);
    final phoneCtrl = TextEditingController(text: currentPhone);
    final addrCtrl = TextEditingController(text: currentAddress);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('업체 수정'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameCtrl, decoration: const InputDecoration(labelText: '업체명')),
            const SizedBox(height: 8),
            TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: '전화번호')),
            const SizedBox(height: 8),
            TextField(controller: addrCtrl, decoration: const InputDecoration(labelText: '주소')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('수정')),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    await context.read<AuthController>().updateTenant(
          tenantId: tenantId,
          name: nameCtrl.text.trim(),
          phone: phoneCtrl.text.trim(),
          address: addrCtrl.text.trim(),
        );
    if (mounted) await _load();
    _ticker.push('업체가 수정되었습니다');
  }

  Future<void> _deleteTenant(String tenantId) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('업체 삭제'),
        content: const Text('해당 업체를 삭제하시겠습니까?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('취소')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('삭제')),
        ],
      ),
    );
    if (!mounted || ok != true) return;
    await context.read<AuthController>().deleteTenant(tenantId);
    if (mounted) await _load();
    _ticker.push('업체가 삭제되었습니다');
  }
}
