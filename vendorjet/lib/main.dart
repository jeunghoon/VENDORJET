import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import 'l10n/app_localizations.dart';
import 'services/auth/api_auth_service.dart';
import 'services/auth/auth_controller.dart';
import 'services/sync/data_refresh_coordinator.dart';
import 'theme/app_theme.dart';
import 'ui/pages/auth/sign_in_page.dart';
import 'ui/pages/buyer/buyer_portal_page.dart';
import 'ui/pages/customers_page.dart';
import 'ui/pages/dashboard_page.dart';
import 'ui/pages/orders/order_detail_page.dart';
import 'ui/pages/orders_page.dart';
import 'ui/pages/products/product_detail_page.dart';
import 'ui/pages/products_page.dart';
import 'ui/pages/settings_page.dart';
import 'ui/widgets/responsive_scaffold.dart';
import 'ui/widgets/notification_ticker.dart';
import 'ui/pages/admin/admin_page.dart';
import 'ui/pages/profile/profile_page.dart';

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
    final authService = ApiAuthService();
    _authController = AuthController(authService)..load();
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

        if (signedIn && _authController.isBuyer && !state.matchedLocation.startsWith('/buyer')) {
          return '/buyer';
        }

        if (signedIn && loggingIn) {
          return state.uri.queryParameters['from'] ?? '/dashboard';
        }

        return null;
      },
      routes: [
        GoRoute(path: '/', redirect: (_, __) => '/dashboard'),
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
              builder: (context, state) => OrdersPage(
                preset: OrderListPreset.fromQuery(state.uri.queryParameters),
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  name: 'order-detail',
                  builder: (context, state) =>
                      OrderDetailPage(orderId: state.pathParameters['id']!),
                ),
              ],
            ),
            GoRoute(
              path: '/customers',
              name: 'customers',
              builder: (context, state) => const CustomersPage(),
            ),
            GoRoute(
              path: '/products',
              name: 'products',
              builder: (context, state) => ProductsPage(
                preset: ProductsPagePreset.fromQuery(state.uri.queryParameters),
              ),
              routes: [
                GoRoute(
                  path: ':id',
                  name: 'product-detail',
                  builder: (context, state) =>
                      ProductDetailPage(productId: state.pathParameters['id']!),
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
            GoRoute(
              path: '/admin',
              name: 'admin',
              builder: (context, state) {
                final auth = context.read<AuthController>();
                if (auth.email?.toLowerCase() != 'admin@vendorjet.com') {
                  return const SizedBox.shrink();
                }
                return const AdminPage();
              },
            ),
            GoRoute(
              path: '/profile',
              name: 'profile',
              builder: (context, state) => const ProfilePage(),
            ),
          ],
        ),
        GoRoute(
          path: '/buyer',
          name: 'buyer-preview',
          builder: (context, state) => const BuyerPortalPage(),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthController>.value(value: _authController),
        ChangeNotifierProvider<DataRefreshCoordinator>(
          create: (_) => DataRefreshCoordinator(),
        ),
        ChangeNotifierProvider<NotificationTicker>(
          create: (_) => NotificationTicker(),
        ),
      ],
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
              final ticker = context.watch<NotificationTicker>();
              const tickerHeight = 36.0;
              final bgColor = Theme.of(context).scaffoldBackgroundColor;
              return Stack(
                children: [
                  Container(
                    color: bgColor,
                    padding: const EdgeInsets.only(bottom: tickerHeight * 1.5),
                    child: child ?? const SizedBox.shrink(),
                  ),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: 0,
                    child: NotificationTickerBar(ticker: ticker),
                  ),
                ],
              );
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
    '/customers',
    '/products',
    '/settings',
  ];

  int _indexForLocation(String location) {
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/customers')) return 2;
    if (location.startsWith('/products')) return 3;
    if (location.startsWith('/settings')) return 4;
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
    final isDetail =
        segments.length > 1 &&
        (segments.first == 'orders' || segments.first == 'products');
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
        icon: const Icon(Icons.people_alt_outlined),
        selectedIcon: const Icon(Icons.people_alt),
        label: t.customersTitle,
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

    final appBar = isDetail
        ? null
        : AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(t.appTitle),
                const SizedBox(width: 8),
                Consumer<AuthController>(
                  builder: (context, auth, _) {
                    final isGlobalAdmin = auth.email?.toLowerCase() == 'admin@vendorjet.com';
                    if (!isGlobalAdmin) return const SizedBox.shrink();
                    return IconButton(
                      tooltip: '글로벌 관리자',
                      icon: const Icon(Icons.admin_panel_settings_outlined),
                      onPressed: () => context.go('/admin'),
                    );
                  },
                ),
              ],
            ),
          );

    return ResponsiveScaffold(
      currentIndex: currentIndex,
      onIndexChanged: (index) => _handleNavigation(context, index),
      destinations: destinations,
      appBar: appBar,
      child: child,
    );
  }
}

class _Splash extends StatelessWidget {
  const _Splash();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
