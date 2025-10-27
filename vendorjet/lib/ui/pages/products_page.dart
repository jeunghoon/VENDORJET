import 'package:flutter/material.dart';
import 'package:vendorjet/l10n/app_localizations.dart';
import 'package:vendorjet/models/product.dart';
import 'package:vendorjet/repositories/mock_repository.dart';

// 상품 목록 화면(플레이스홀더)
class ProductsPage extends StatefulWidget {
  const ProductsPage({super.key});

  @override
  State<ProductsPage> createState() => _ProductsPageState();
}

class _ProductsPageState extends State<ProductsPage> {
  final _repo = MockProductRepository();
  final _queryCtrl = TextEditingController();
  List<Product> _items = const [];
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
              hintText: '${t.productsTitle} search',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              isDense: true,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final p = _items[i];
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Container(
                            decoration: BoxDecoration(
                              color: color.primary.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Center(
                              child: Icon(Icons.inventory_2_outlined, size: 42),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(p.sku, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${p.name} · ${p.variantsCount} variants',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7))),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
