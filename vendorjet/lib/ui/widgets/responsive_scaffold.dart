import 'package:flutter/material.dart';

// 반응형 스캐폴드: 넓은 화면은 NavigationRail, 좁은 화면은 BottomNavigationBar 사용
class ResponsiveScaffold extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onIndexChanged;
  final List<NavigationDestination> destinations;
  final Widget child;
  final PreferredSizeWidget? appBar;

  const ResponsiveScaffold({
    super.key,
    required this.currentIndex,
    required this.onIndexChanged,
    required this.destinations,
    required this.child,
    this.appBar,
  });

  @override
  Widget build(BuildContext context) {
    // 화면 너비 기준으로 레이아웃 분기
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900; // 데스크톱/태블릿 가로
        if (isWide) {
          return Scaffold(
            appBar: appBar,
            body: Row(
              children: [
                _Rail(
                  currentIndex: currentIndex,
                  destinations: destinations,
                  onIndexChanged: onIndexChanged,
                ),
                const VerticalDivider(width: 1),
                Expanded(child: child),
              ],
            ),
          );
        }
        return Scaffold(
          appBar: appBar,
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onIndexChanged,
            destinations: destinations,
          ),
        );
      },
    );
  }
}

class _Rail extends StatelessWidget {
  final int currentIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onIndexChanged;

  const _Rail({
    required this.currentIndex,
    required this.destinations,
    required this.onIndexChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: currentIndex,
      onDestinationSelected: onIndexChanged,
      labelType: NavigationRailLabelType.all,
      leading: const SizedBox(height: 8),
      destinations: destinations
          .map(
            (d) => NavigationRailDestination(
              icon: d.icon,
              selectedIcon: d.selectedIcon ?? d.icon,
              label: Text(d.label),
            ),
          )
          .toList(),
    );
  }
}
