import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../services/api/api_client.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _membershipRequests = [];
  List<Map<String, dynamic>> _buyerRequests = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final users = await ApiClient.get('/admin/users') as List<dynamic>;
      final req = await ApiClient.get('/admin/requests') as Map<String, dynamic>;
      setState(() {
        _users = users.cast<Map<String, dynamic>>();
        _membershipRequests =
            (req['membershipRequests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        _buyerRequests =
            (req['buyerRequests'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('관리자'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Users'),
              Tab(text: 'Approvals'),
            ],
          ),
          actions: [
            IconButton(
              onPressed: _loading ? null : _load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? _ErrorView(message: _error!, onRetry: _load)
                : TabBarView(
                    children: [
                      _UsersTab(users: _users, onChanged: _load),
                      _RequestsTab(
                        membershipRequests: _membershipRequests,
                        buyerRequests: _buyerRequests,
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _UsersTab extends StatelessWidget {
  final List<Map<String, dynamic>> users;
  final FutureOr<void> Function() onChanged;

  const _UsersTab({required this.users, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) {
      return const Center(child: Text('No users'));
    }
    final dateFormat = DateFormat.yMMMd().add_Hm();
    return ListView.builder(
      itemCount: users.length,
      itemBuilder: (context, index) {
        final u = users[index];
        final type = (u['userType'] ?? 'wholesale') == 'retail' ? 'Retail' : 'Wholesale';
        final createdAt = u['createdAt'] as String?;
        final lastLogin = u['lastLoginAt'] as String?;
        final tenants = (u['tenants'] as List<dynamic>? ?? [])
            .cast<Map<String, dynamic>>()
            .map((t) => '${t['name'] ?? ''}${t['role'] != null ? ' · ${t['role']}' : ''}')
            .where((e) => e.trim().isNotEmpty)
            .toList();
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.person_outline),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(u['email'] ?? '', style: Theme.of(context).textTheme.titleSmall),
                      Text(
                        '${u['name'] ?? ''} · $type · ${u['role'] ?? ''}${(u['status'] ?? '') == 'pending' ? ' (pending)' : ''}',
                      ),
                      if (createdAt != null && createdAt.isNotEmpty)
                        Text(
                          'Joined ${dateFormat.format(DateTime.tryParse(createdAt) ?? DateTime.now())}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (lastLogin != null && lastLogin.isNotEmpty)
                        Text(
                          'Last login ${dateFormat.format(DateTime.tryParse(lastLogin) ?? DateTime.now())}',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      if (tenants.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: -6,
                          children: tenants
                              .map((tName) => Chip(
                                    label: Text(tName),
                                    visualDensity: VisualDensity.compact,
                                  ))
                              .toList(),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Delete',
                  onPressed: () async {
                    await ApiClient.delete('/admin/users/${u['id']}');
                    onChanged();
                  },
                  icon: const Icon(Icons.delete_outline),
                  color: Theme.of(context).colorScheme.error,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RequestsTab extends StatelessWidget {
  final List<Map<String, dynamic>> membershipRequests;
  final List<Map<String, dynamic>> buyerRequests;

  const _RequestsTab({
    required this.membershipRequests,
    required this.buyerRequests,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final combined = [
      ...membershipRequests.map((r) => {...r, 'kind': '멤버 승인'}),
      ...buyerRequests.map((r) => {...r, 'kind': '소매 승인'}),
    ];
    if (combined.isEmpty) {
      return const Center(child: Text('승인 요청이 없습니다'));
    }
    return ListView.builder(
      itemCount: combined.length,
      itemBuilder: (context, index) {
        final r = combined[index];
        final status = r['status'] ?? '';
        final createdAt = r['createdAt'] as String?;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          child: ListTile(
            leading: const Icon(Icons.assignment_ind_outlined),
            title: Text('${r['kind']} · ${r['email'] ?? ''}'),
            subtitle: Text(
              '${r['name'] ?? ''} · ${status == 'pending' ? '대기' : status} · ${createdAt != null ? dateFormat.format(DateTime.tryParse(createdAt) ?? DateTime.now()) : ''}',
            ),
          ),
        );
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('다시 불러오기'),
          ),
        ],
      ),
    );
  }
}
