import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'services/auth/auth_controller.dart';
import 'services/auth/auth_service.dart';
import 'theme/app_theme.dart';
import 'ui/pages/auth/sign_in_page.dart';
import 'ui/pages/dashboard_page.dart';
import 'ui/pages/orders/order_detail_page.dart';
import 'ui/pages/orders_page.dart';
import 'ui/pages/products_page.dart';
import 'ui/pages/products/product_detail_page.dart';
import 'ui/pages/settings_page.dart';
import 'ui/widgets/responsive_scaffold.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  Locale? _locale = const Locale('en');
  late final AuthController _authController;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _authController = AuthController(MockAuthService())..load();
    _router = _createRouter();
  }

  @override
  void dispose() {
    _router.dispose();
    _authController.dispose();
    super.dispose();
  }

  void _changeLocale(Locale locale) {
    if (_locale == locale) return;
    setState(() => _locale = locale);
  }

  GoRouter _createRouter() {
    return GoRouter(
      initialLocation: '/dashboard',
      refreshListenable: _authController,
      redirect: (context, state) {
        final loading = _authController.loading;
        final signedIn = _authController.signedIn;
        final loggingIn = state.matchedLocation == '/sign-in';

        if (loading) {
          return null;
        }

        if (!signedIn && !loggingIn) {
          return '/sign-in';
        }

        if (signedIn && loggingIn) {
          return state.uri.queryParameters['from'] ?? '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          redirect: (_, __) => '/dashboard',
        ),
        GoRoute(
          path: '/sign-in',
          name: 'sign-in',
          builder: (context, state) => SignInPage(
            currentLocale: _locale,
            onLocaleChanged: _changeLocale,
          ),
        ),
        ShellRoute(
          builder: (context, state, child) {
            return _HomeShell(child: child);
          },
          routes: [
            GoRoute(
              path: '/dashboard',
              name: 'dashboard',
              builder: (context, state) => const DashboardPage(),
            ),
            GoRoute(
              path: '/orders',
              name: 'orders',
              builder: (context, state) => const OrdersPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: 'order-detail',
                  builder: (context, state) => OrderDetailPage(
                    orderId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/products',
              name: 'products',
              builder: (context, state) => const ProductsPage(),
              routes: [
                GoRoute(
                  path: ':id',
                  name: 'product-detail',
                  builder: (context, state) => ProductDetailPage(
                    productId: state.pathParameters['id']!,
                  ),
                ),
              ],
            ),
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => SettingsPage(
                currentLocale: _locale,
                onLocaleChanged: _changeLocale,
                onSignOut: () {
                  _authController.signOut();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<AuthController>.value(
      value: _authController,
      child: Consumer<AuthController>(
        builder: (context, auth, _) {
          return MaterialApp.router(
            title: 'VendorJet',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            locale: _locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [Locale('en'), Locale('ko')],
            routerConfig: _router,
            builder: (context, child) {
              if (auth.loading) {
                return const _Splash();
              }
              return child ?? const SizedBox.shrink();
            },
          );
        },
      ),
    );
  }
}

class _HomeShell extends StatelessWidget {
  const _HomeShell({required this.child});

  final Widget child;

  static const _paths = [
    '/dashboard',
    '/orders',
    '/products',
    '/settings',
  ];

  int _indexForLocation(String location) {
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/products')) return 2;
    if (location.startsWith('/settings')) return 3;
    return 0;
  }

  void _handleNavigation(BuildContext context, int index) {
    final target = _paths[index];
    final current = GoRouterState.of(context).uri.toString();
    if (current != target) {
      context.go(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    final state = GoRouterState.of(context);
    final location = state.uri.toString();
    final segments = state.uri.pathSegments;
    final isDetail = segments.length > 1 && (segments.first == 'orders' || segments.first == 'products');
    final currentIndex = _indexForLocation(location);

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

    return ResponsiveScaffold(
      currentIndex: currentIndex,
      onIndexChanged: (index) => _handleNavigation(context, index),
      destinations: destinations,
      appBar: isDetail ? null : AppBar(title: Text(t.appTitle)),
      child: child,
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}
