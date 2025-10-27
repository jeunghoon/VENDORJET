import 'package:flutter/material.dart';
import 'package:vendorjet/l10n/app_localizations.dart';

// 대시보드 화면: 핵심 카드(주문/상품/거래처) 프리뷰
class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            t.welcome,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            t.subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 20),
          _Overview(),
          const SizedBox(height: 20),
          _SectionTitle(title: t.ordersTitle),
          const SizedBox(height: 10),
          _PlaceholderList(itemPrefix: '#ORD', count: 5),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final isWide = c.maxWidth > 900;
        final isMedium = c.maxWidth > 600;
        final crossAxisCount = isWide ? 3 : (isMedium ? 3 : 1);

        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: isWide ? 3.2 : 2.6,
          children: const [
            _StatCard(title: 'Today Orders', value: '24'),
            _StatCard(title: 'Open Invoices', value: '8'),
            _StatCard(title: 'Low Stock', value: '12'),
          ],
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  const _StatCard({required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.secondary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.analytics_outlined, color: color.secondary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(value, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
    );
  }
}

class _PlaceholderList extends StatelessWidget {
  final String itemPrefix;
  final int count;
  const _PlaceholderList({required this.itemPrefix, this.count = 5});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: count,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        return Card(
          child: ListTile(
            leading: CircleAvatar(backgroundColor: color.primary.withValues(alpha: 0.15), child: Icon(Icons.receipt_long, color: color.primary)),
            title: Text('$itemPrefix-2025-${i + 1}'),
            subtitle: const Text('Preview item for layout'),
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () {},
          ),
        );
      },
    );
  }
}
