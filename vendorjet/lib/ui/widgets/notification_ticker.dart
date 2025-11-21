import 'dart:async';

import 'package:flutter/material.dart';

class TickerNotification {
  final String id;
  final String message;
  final DateTime createdAt;

  TickerNotification({
    required this.id,
    required this.message,
    required this.createdAt,
  });
}

/// 전광판 스타일 알림 관리자
class NotificationTicker extends ChangeNotifier {
  final _items = <TickerNotification>[];
  final _life = const Duration(seconds: 4);

  List<TickerNotification> get items => List.unmodifiable(_items);

  void push(String message) {
    final item = TickerNotification(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      message: message,
      createdAt: DateTime.now(),
    );
    _items.add(item);
    notifyListeners();

    Timer(_life, () {
      _items.removeWhere((e) => e.id == item.id);
      notifyListeners();
    });
  }
}

/// 하단에 표시되는 좌→우 흐르는 알림 바
class NotificationTickerBar extends StatefulWidget {
  final NotificationTicker ticker;

  const NotificationTickerBar({super.key, required this.ticker});

  @override
  State<NotificationTickerBar> createState() => _NotificationTickerBarState();
}

class _NotificationTickerBarState extends State<NotificationTickerBar> {
  final _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AnimatedBuilder(
      animation: widget.ticker,
      builder: (context, _) {
        final items = widget.ticker.items;
        if (items.isEmpty) return const SizedBox.shrink();

        // 새 알림이 올 때마다 오른쪽 끝으로 스크롤
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_scrollCtrl.hasClients) {
            _scrollCtrl
                .animateTo(
                  _scrollCtrl.position.maxScrollExtent,
                  duration: const Duration(milliseconds: 400),
                  curve: Curves.easeOut,
                )
                .ignore();
          }
        });

        return Container(
          height: 36,
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withValues(alpha: 0.9),
            border: Border(top: BorderSide(color: theme.dividerColor.withValues(alpha: 0.2))),
          ),
          child: ListView.separated(
            controller: _scrollCtrl,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, index) {
              final item = items[index];
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(Icons.campaign_outlined,
                        size: 16, color: theme.colorScheme.primary),
                    const SizedBox(width: 6),
                    Text(
                      item.message,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _formatTime(item.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    final s = dt.second.toString().padLeft(2, '0');
    return '$h:$m:$s';
  }
}
