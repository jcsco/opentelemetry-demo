import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:splunk_otel_flutter/splunk_otel_flutter.dart';

import 'providers/cart_provider.dart';
import 'providers/products_provider.dart';
import 'screens/cart_screen.dart';
import 'screens/products_screen.dart';
import 'screens/settings_screen.dart';
import 'telemetry.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Mirrors the react-native-app's splash-screen gate in `app/_layout.tsx`:
  // the RUM agent finishes installing before the first frame is drawn.
  await installTelemetry();
  runApp(const AstronomyShopApp());
}

class AstronomyShopApp extends StatelessWidget {
  const AstronomyShopApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ProductsProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()..loadCart()),
      ],
      child: MaterialApp(
        title: 'Astronomy Shop',
        theme: AppTheme.light,
        darkTheme: AppTheme.dark,
        themeMode: ThemeMode.system,
        navigatorObservers: [SplunkNavigatorObserver()],
        home: const RootTabs(),
      ),
    );
  }
}

class RootTabs extends StatefulWidget {
  const RootTabs({super.key});

  @override
  State<RootTabs> createState() => _RootTabsState();
}

class _RootTabsState extends State<RootTabs> {
  int _index = 0;

  void _goToProducts() => setState(() => _index = 0);

  @override
  Widget build(BuildContext context) {
    final itemsInCart = context.watch<CartProvider>().cart.totalQuantity;

    final screens = [
      const ProductsScreen(),
      CartScreen(onOrderComplete: _goToProducts),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (i) => setState(() => _index = i),
        // react-native-app's tab bar is icon-only (tabBarShowLabel: false).
        labelBehavior: NavigationDestinationLabelBehavior.alwaysHide,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.list_outlined),
            selectedIcon: Icon(Icons.list),
            label: 'Products',
          ),
          NavigationDestination(
            icon: itemsInCart > 0
                ? Badge(label: Text('$itemsInCart'), child: const Icon(Icons.shopping_cart_outlined))
                : const Icon(Icons.shopping_cart_outlined),
            selectedIcon: itemsInCart > 0
                ? Badge(label: Text('$itemsInCart'), child: const Icon(Icons.shopping_cart))
                : const Icon(Icons.shopping_cart),
            label: 'Cart',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
