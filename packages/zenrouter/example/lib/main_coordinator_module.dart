import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Main App Entry Point
// ============================================================================
//
// This example demonstrates Coordinator-as-RouteModule with ROUTE VERSIONING.
//
// Since Coordinator<T> implements RouteModule<T>, each version of a feature
// can live in its own Coordinator and be composed into the parent. This allows
// multiple route versions to coexist in a single application.
//
// Architecture:
//
//   MainCoordinator (CoordinatorModular)
//   ├── MainRouteModule          ← handles / (redirects to V2 shop)
//   ├── ShopCoordinatorV1        ← deprecated shop (/v1/shop/...)
//   │   └── ShopV1Layout (bottom nav + deprecation banner)
//   │       ├── /v1/shop          → ShopHomeV1
//   │       ├── /v1/shop/products → ProductListV1
//   │       └── /v1/shop/cart     → CartV1
//   ├── ShopCoordinatorV2        ← current shop (/v2/shop/...)
//   │   └── ShopV2Layout (NavigationRail, richer UI)
//   │       ├── /v2/shop              → ShopHomeV2
//   │       ├── /v2/shop/products     → ProductListV2
//   │       ├── /v2/shop/products/:id → ProductDetailV2
//   │       └── /v2/shop/cart         → CartV2
//   └── SettingsCoordinator      ← settings (/settings/...)
//       └── SettingsLayout (master-detail sidebar)
//           ├── /settings          → GeneralSettingsRoute
//           ├── /settings/account  → AccountSettingsRoute
//           └── /settings/privacy  → PrivacySettingsRoute
//
// Key patterns:
//   • Route versioning — V1 & V2 shop coexist with isolated paths/layouts
//   • Deprecation flow — V1 shows a banner linking to V2
//   • Cross-version navigation — routes navigate across coordinator versions
//   • Each version is a full Coordinator with its own state
// ============================================================================

void main() {
  runApp(const CoordinatorModuleApp());
}

class CoordinatorModuleApp extends StatelessWidget {
  const CoordinatorModuleApp({super.key});

  static final coordinator = MainCoordinator();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZenRouter Route Versioning Example',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      restorationScopeId: 'coordinator_module',
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}

// ============================================================================
// Shared Route Base Class
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

// ============================================================================
// Shop Coordinator V1 — DEPRECATED version
// ============================================================================

class ShopCoordinatorV1 extends Coordinator<AppRoute> {
  ShopCoordinatorV1(this._parent);
  final MainCoordinator _parent;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  late final NavigationPath<AppRoute> shopV1Stack = NavigationPath.createWith(
    label: 'shop-v1',
    coordinator: _parent,
  );

  @override
  List<StackPath> get paths => [...super.paths, shopV1Stack];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(ShopV1Layout, ShopV1Layout.new);
  }

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['v1', ...final pathSegments] => switch (pathSegments) {
        ['shop'] => ShopHomeV1(),
        ['shop', 'products'] => ProductListV1(),
        ['shop', 'cart'] => CartV1(),
        _ => null,
      },
      _ => null,
    };
  }
}

// V1 Layout — bottom nav with a deprecation banner
class ShopV1Layout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(MainCoordinator coordinator) =>
      coordinator.getModule<ShopCoordinatorV1>().shopV1Stack;

  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop (V1 — Deprecated)'),
        backgroundColor: Colors.grey[600],
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Deprecation banner
          MaterialBanner(
            padding: const EdgeInsets.all(12),
            backgroundColor: Colors.orange[100],
            leading: const Icon(Icons.warning_amber, color: Colors.orange),
            content: const Text(
              'This shop version is deprecated. Migrate to V2 for '
              'new features and improved experience.',
            ),
            actions: [
              TextButton(
                onPressed: () => coordinator.replace(ShopHomeV2()),
                child: const Text('Switch to V2'),
              ),
            ],
          ),
          Expanded(child: buildPath(coordinator)),
        ],
      ),
      bottomNavigationBar: ListenableBuilder(
        listenable: resolvePath(coordinator),
        builder: (context, _) {
          final active = coordinator.activePath.stack.lastOrNull;
          return BottomNavigationBar(
            currentIndex: active is ProductListV1
                ? 1
                : active is CartV1
                ? 2
                : 0,
            selectedItemColor: Colors.grey[700],
            onTap: (i) => switch (i) {
              0 => coordinator.navigate(ShopHomeV1()),
              1 => coordinator.navigate(ProductListV1()),
              2 => coordinator.navigate(CartV1()),
              _ => null,
            },
            items: const [
              BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_bag),
                label: 'Products',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.shopping_cart),
                label: 'Cart',
              ),
            ],
          );
        },
      ),
    );
  }
}

// V1 Routes
class ShopHomeV1 extends AppRoute {
  @override
  Type get layout => ShopV1Layout;
  @override
  Uri toUri() => Uri.parse('/v1/shop');

  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Shop Home (V1)',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Managed by ShopCoordinatorV1. This is the legacy version.',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('View Products'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => coordinator.push(ProductListV1()),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('View Cart'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => coordinator.push(CartV1()),
          ),
        ),
      ],
    );
  }
}

class ProductListV1 extends AppRoute {
  @override
  Type get layout => ShopV1Layout;
  @override
  Uri toUri() => Uri.parse('/v1/shop/products');

  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Products (V1)',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        for (var i = 1; i <= 3; i++)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: Colors.grey[300],
                child: Text('$i'),
              ),
              title: Text('Legacy Product $i'),
              subtitle: Text('\$${(i * 9.99).toStringAsFixed(2)}'),
            ),
          ),
      ],
    );
  }
}

class CartV1 extends AppRoute {
  @override
  Type get layout => ShopV1Layout;
  @override
  Uri toUri() => Uri.parse('/v1/shop/cart');

  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 48, color: Colors.grey),
          SizedBox(height: 16),
          Text('Cart (V1)', style: TextStyle(fontSize: 20)),
          SizedBox(height: 8),
          Text('Legacy cart — use V2 for a better experience'),
        ],
      ),
    );
  }
}

// ============================================================================
// Shop Coordinator V2 — CURRENT version
// ============================================================================

class ShopCoordinatorV2 extends Coordinator<AppRoute> {
  ShopCoordinatorV2(this._parent);
  final MainCoordinator _parent;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  late final NavigationPath<AppRoute> shopV2Stack = NavigationPath.createWith(
    label: 'shop-v2',
    coordinator: _parent,
  );

  @override
  List<StackPath> get paths => [...super.paths, shopV2Stack];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(ShopV2Layout, ShopV2Layout.new);
  }

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['v2', ...final pathSegments] => switch (pathSegments) {
        ['shop'] => ShopHomeV2(),
        ['shop', 'products'] => ProductListV2(),
        ['shop', 'products', final id] => ProductDetailV2(id: id),
        ['shop', 'cart'] => CartV2(),
        _ => null,
      },
      _ => null,
    };
  }
}

// V2 Layout — NavigationRail (modern sidebar)
class ShopV2Layout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(MainCoordinator coordinator) =>
      coordinator.getModule<ShopCoordinatorV2>().shopV2Stack;

  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop (V2)'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        actions: [
          // Cross-coordinator navigation: go to Settings
          IconButton(
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
            onPressed: () => coordinator.push(GeneralSettingsRoute()),
          ),
          // Cross-version navigation: go back to V1
          TextButton.icon(
            icon: const Icon(Icons.history, color: Colors.white70),
            label: const Text('V1', style: TextStyle(color: Colors.white70)),
            onPressed: () => coordinator.replace(ShopHomeV1()),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: resolvePath(coordinator),
        builder: (context, _) {
          final active = coordinator.activePath.stack.lastOrNull;
          final selectedIndex =
              active is ProductListV2 || active is ProductDetailV2
              ? 1
              : active is CartV2
              ? 2
              : 0;
          return Row(
            children: [
              NavigationRail(
                selectedIndex: selectedIndex,
                labelType: NavigationRailLabelType.all,
                onDestinationSelected: (i) => switch (i) {
                  0 => coordinator.push(ShopHomeV2()),
                  1 => coordinator.push(ProductListV2()),
                  2 => coordinator.push(CartV2()),
                  _ => null,
                },
                destinations: const [
                  NavigationRailDestination(
                    icon: Icon(Icons.home_outlined),
                    selectedIcon: Icon(Icons.home),
                    label: Text('Home'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.shopping_bag_outlined),
                    selectedIcon: Icon(Icons.shopping_bag),
                    label: Text('Products'),
                  ),
                  NavigationRailDestination(
                    icon: Icon(Icons.shopping_cart_outlined),
                    selectedIcon: Icon(Icons.shopping_cart),
                    label: Text('Cart'),
                  ),
                ],
              ),
              const VerticalDivider(width: 1),
              Expanded(child: buildPath(coordinator)),
            ],
          );
        },
      ),
    );
  }
}

// V2 Routes
class ShopHomeV2 extends AppRoute {
  @override
  Type get layout => ShopV2Layout;
  @override
  Uri toUri() => Uri.parse('/v2/shop');

  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Shop Home (V2)',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Managed by ShopCoordinatorV2 — the current version with '
            'NavigationRail, product details, and richer UI.',
            style: TextStyle(color: Colors.grey[600], fontSize: 14),
          ),
          const SizedBox(height: 24),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_bag, color: Colors.green),
              title: const Text('Browse Products'),
              subtitle: const Text('V2 adds product detail with :id params'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => coordinator.push(ProductListV2()),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.shopping_cart, color: Colors.green),
              title: const Text('View Cart'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => coordinator.push(CartV2()),
            ),
          ),
          const Divider(height: 32),
          const Text(
            'Cross-coordinator Navigation',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.settings, color: Colors.purple),
              title: const Text('Go to Settings'),
              subtitle: const Text('SettingsCoordinator module'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => coordinator.push(GeneralSettingsRoute()),
            ),
          ),
          Card(
            color: Colors.orange[50],
            child: ListTile(
              leading: const Icon(Icons.history, color: Colors.orange),
              title: const Text('Open Legacy Shop (V1)'),
              subtitle: const Text('ShopCoordinatorV1 — deprecated'),
              trailing: const Icon(Icons.arrow_forward),
              onTap: () => coordinator.replace(ShopHomeV1()),
            ),
          ),
        ],
      ),
    );
  }
}

class ProductListV2 extends AppRoute {
  @override
  Type get layout => ShopV2Layout;
  @override
  Uri toUri() => Uri.parse('/v2/shop/products');

  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Products (V2)',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          for (var i = 1; i <= 5; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.green[100],
                  foregroundColor: Colors.green[800],
                  child: Text('$i'),
                ),
                title: Text('Product $i'),
                subtitle: Text('\$${(i * 12.49).toStringAsFixed(2)}'),
                trailing: const Icon(Icons.arrow_forward),
                onTap: () => coordinator.push(ProductDetailV2(id: '$i')),
              ),
            ),
        ],
      ),
    );
  }
}

class ProductDetailV2 extends AppRoute {
  ProductDetailV2({required this.id});
  final String id;

  @override
  Type get layout => ShopV2Layout;
  @override
  Uri toUri() => Uri.parse('/v2/shop/products/$id');
  @override
  List<Object?> get props => [id];

  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 48,
                backgroundColor: Colors.green[100],
                child: Text(
                  id,
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Product $id',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'V2 exclusive — product detail with :id parameter',
                style: TextStyle(color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => coordinator.pop(),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back to Products'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class CartV2 extends AppRoute {
  @override
  Type get layout => ShopV2Layout;
  @override
  Uri toUri() => Uri.parse('/v2/shop/cart');

  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Cart (V2)',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: Icon(Icons.shopping_cart, color: Colors.green[700]),
              title: const Text('Widget Kit Pro'),
              subtitle: const Text('\$24.99'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {},
              ),
            ),
          ),
          Card(
            child: ListTile(
              leading: Icon(Icons.shopping_cart, color: Colors.green[700]),
              title: const Text('State Manager Ultra'),
              subtitle: const Text('\$39.99'),
              trailing: IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: () {},
              ),
            ),
          ),
          const Divider(height: 32),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'Total: \$64.98',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.green[700],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// Settings Coordinator
// ============================================================================

class SettingsCoordinator extends Coordinator<AppRoute> {
  SettingsCoordinator(this._parent);
  final MainCoordinator _parent;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  late final NavigationPath<AppRoute> settingsStack = NavigationPath.createWith(
    label: 'settings',
    coordinator: _parent,
  );

  @override
  List<StackPath> get paths => [...super.paths, settingsStack];

  @override
  void defineLayout() {
    RouteLayout.defineLayout(SettingsLayout, SettingsLayout.new);
  }

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['settings'] => GeneralSettingsRoute(),
      ['settings', 'account'] => AccountSettingsRoute(),
      ['settings', 'privacy'] => PrivacySettingsRoute(),
      _ => null,
    };
  }
}

// Settings Layout — master-detail sidebar
class SettingsLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(MainCoordinator coordinator) =>
      coordinator.getModule<SettingsCoordinator>().settingsStack;

  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => coordinator.tryPop()),
        title: const Text('Settings'),
        backgroundColor: Colors.purple[700],
        foregroundColor: Colors.white,
      ),
      body: Row(
        children: [
          SizedBox(
            width: 220,
            child: ListenableBuilder(
              listenable: resolvePath(coordinator),
              builder: (context, _) {
                return ListView(
                  padding: const EdgeInsets.all(8),
                  children: [
                    _SettingsNavTile(
                      icon: Icons.tune,
                      label: 'General',
                      isActive:
                          coordinator.activePath.stack.last
                              is GeneralSettingsRoute,
                      onTap: () => coordinator.push(GeneralSettingsRoute()),
                    ),
                    _SettingsNavTile(
                      icon: Icons.person,
                      label: 'Account',
                      isActive:
                          coordinator.activePath.stack.last
                              is AccountSettingsRoute,
                      onTap: () => coordinator.push(AccountSettingsRoute()),
                    ),
                    _SettingsNavTile(
                      icon: Icons.lock,
                      label: 'Privacy',
                      isActive:
                          coordinator.activePath.stack.last
                              is PrivacySettingsRoute,
                      onTap: () => coordinator.push(PrivacySettingsRoute()),
                    ),
                  ],
                );
              },
            ),
          ),
          const VerticalDivider(width: 1),
          Expanded(child: buildPath(coordinator)),
        ],
      ),
    );
  }
}

// Settings Routes
class GeneralSettingsRoute extends AppRoute {
  @override
  Type get layout => SettingsLayout;
  @override
  Uri toUri() => Uri.parse('/settings');

  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'General Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Managed by SettingsCoordinator — an independent '
          'Coordinator used as a RouteModule.',
          style: TextStyle(color: Colors.grey[600]),
        ),
        const SizedBox(height: 16),
        const ListTile(
          leading: Icon(Icons.language),
          title: Text('Language'),
          subtitle: Text('English'),
        ),
        const ListTile(
          leading: Icon(Icons.dark_mode),
          title: Text('Theme'),
          subtitle: Text('System'),
        ),
        const Divider(height: 32),
        Card(
          child: ListTile(
            leading: const Icon(Icons.shopping_bag, color: Colors.green),
            title: const Text('Go to Shop V2'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => coordinator.push(ShopHomeV2()),
          ),
        ),
      ],
    );
  }
}

class AccountSettingsRoute extends AppRoute {
  @override
  Type get layout => SettingsLayout;
  @override
  Uri toUri() => Uri.parse('/settings/account');

  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Account Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const ListTile(
          leading: Icon(Icons.email),
          title: Text('Email'),
          subtitle: Text('user@example.com'),
        ),
        const ListTile(
          leading: Icon(Icons.password),
          title: Text('Password'),
          subtitle: Text('••••••••'),
        ),
      ],
    );
  }
}

class PrivacySettingsRoute extends AppRoute {
  @override
  Type get layout => SettingsLayout;
  @override
  Uri toUri() => Uri.parse('/settings/privacy');

  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Privacy Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const ListTile(
          leading: Icon(Icons.security),
          title: Text('Data Privacy'),
          subtitle: Text('Manage how your data is used'),
        ),
        const ListTile(
          leading: Icon(Icons.location_on),
          title: Text('Location Services'),
          subtitle: Text('Enabled'),
        ),
      ],
    );
  }
}

// ============================================================================
// Main Coordinator — composes versioned coordinators as modules
// ============================================================================

class MainCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    MainRouteModule(this),
    ShopCoordinatorV1(this),
    ShopCoordinatorV2(this),
    SettingsCoordinator(this),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

// ============================================================================
// Root-level Routes
// ============================================================================

class MainRouteModule extends RouteModule<AppRoute> {
  MainRouteModule(super.coordinator);

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      _ => null,
    };
  }
}

class HomeRoute extends AppRoute with RouteRedirect<AppRoute> {
  @override
  Uri toUri() => Uri.parse('/');
  @override
  Widget build(
    covariant Coordinator<RouteUnique> coordinator,
    BuildContext context,
  ) => const SizedBox();

  /// Default redirect to V2 shop
  @override
  AppRoute redirect() => ShopHomeV2();
}

class NotFoundRoute extends AppRoute {
  NotFoundRoute({required this.uri});
  final Uri uri;

  @override
  Uri toUri() => Uri.parse('/not-found');

  @override
  Widget build(covariant MainCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Not Found')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text('Route not found: ${uri.path}'),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => coordinator.replace(ShopHomeV2()),
              child: const Text('Go to Shop V2'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Helper Widgets
// ============================================================================

class _SettingsNavTile extends StatelessWidget {
  const _SettingsNavTile({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: isActive ? Colors.purple : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.purple : Colors.black87,
        ),
      ),
      selected: isActive,
      selectedTileColor: Colors.purple.withValues(alpha: 0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}
