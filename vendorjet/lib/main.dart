import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'l10n/app_localizations.dart';

// UI 테마
import 'theme/app_theme.dart';
// 페이지
import 'ui/pages/dashboard_page.dart';
import 'ui/pages/orders_page.dart';
import 'ui/pages/products_page.dart';
import 'ui/pages/settings_page.dart';
import 'ui/widgets/responsive_scaffold.dart';
import 'ui/pages/auth/sign_in_page.dart';
import 'services/auth/auth_controller.dart';
import 'services/auth/auth_service.dart';

void main() {
  // 앱 실행 (디폴트 언어는 영어)
  runApp(const MyApp());
}

// 최상위 앱: 로케일(언어) 상태를 보유하여 설정 화면에서 변경 가능
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  // 기본 사용 언어는 영어
  Locale? _locale = const Locale('en');

  void _changeLocale(Locale locale) {
    setState(() => _locale = locale);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthController(MockAuthService())..load(),
      child: Consumer<AuthController>(
        builder: (context, auth, _) {
          return MaterialApp(
            title: 'VendorJet',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            locale: _locale,
            // 다국어 설정 (영어 기본 + 한국어)
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ko')],
            home: auth.loading
                ? const _Splash()
                : auth.signedIn
                ? _HomeShell(
                    onLocaleChanged: _changeLocale,
                    currentLocale: _locale,
                    onSignOut: auth.signOut,
                  )
                : SignInPage(
                    currentLocale: _locale,
                    onLocaleChanged: _changeLocale,
                  ),
          );
        },
      ),
    );
  }
}

// 홈 셸: 하단탭/네비게이션 레일 + 각 화면 구성
class _HomeShell extends StatefulWidget {
  final ValueChanged<Locale> onLocaleChanged;
  final Locale? currentLocale;
  final VoidCallback onSignOut;
  const _HomeShell({
    required this.onLocaleChanged,
    required this.currentLocale,
    required this.onSignOut,
  });

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final destinations = [
      NavigationDestination(
        icon: const Icon(Icons.dashboard_outlined),
        selectedIcon: const Icon(Icons.dashboard),
        label: t.homeTitle,
      ),
      NavigationDestination(
        icon: const Icon(Icons.receipt_long_outlined),
        selectedIcon: const Icon(Icons.receipt_long),
        label: t.ordersTitle,
      ),
      NavigationDestination(
        icon: const Icon(Icons.inventory_2_outlined),
        selectedIcon: const Icon(Icons.inventory_2),
        label: t.productsTitle,
      ),
      NavigationDestination(
        icon: const Icon(Icons.settings_outlined),
        selectedIcon: const Icon(Icons.settings),
        label: t.settingsTitle,
      ),
    ];

    final pages = [
      const DashboardPage(),
      const OrdersPage(),
      const ProductsPage(),
      SettingsPage(
        currentLocale: widget.currentLocale,
        onLocaleChanged: widget.onLocaleChanged,
        onSignOut: widget.onSignOut,
      ),
    ];

    return ResponsiveScaffold(
      currentIndex: _index,
      onIndexChanged: (i) => setState(() => _index = i),
      destinations: destinations,
      pages: pages,
      appBar: AppBar(title: Text(t.appTitle)),
    );
  }
}

// 간단한 스플래시: 인증 상태 로드 중 표시
class _Splash extends StatelessWidget {
  const _Splash();
  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
