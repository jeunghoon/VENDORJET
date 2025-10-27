import 'package:flutter/material.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/order.dart';
import 'package:vendorjet/repositories/mock_repository.dart';

// 주문 목록 화면(플레이스홀더)
class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  final _repo = MockOrderRepository();
  final _queryCtrl = TextEditingController();
  List<Order> _items = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _queryCtrl.addListener(_onQuery);
  }

  @override
  void dispose() {
    _queryCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    _items = await _repo.fetch(query: _queryCtrl.text);
    if (!mounted) return;
    setState(() => _loading = false);
  }

  void _onQuery() {
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final color = Theme.of(context).colorScheme;

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: _queryCtrl,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: '${t.ordersTitle} search',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemBuilder: (context, i) {
                final o = _items[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: color.secondary.withValues(alpha: 0.15),
                      child: Icon(Icons.shopping_bag_outlined, color: color.secondary),
                    ),
                    title: Text(o.code),
                    subtitle: Text('${o.itemCount} items · ${o.total.toStringAsFixed(2)}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemCount: _items.length,
            ),
          ),
        ],
      ),
    );
  }
}
