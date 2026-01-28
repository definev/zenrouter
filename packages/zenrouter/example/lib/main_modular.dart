import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';
import 'package:zenrouter_devtools/zenrouter_devtools.dart';

// ============================================================================
// Main App Entry Point
// ============================================================================

void main() {
  runApp(const ModularApp());
}

class ModularApp extends StatelessWidget {
  const ModularApp({super.key});

  static final coordinator = AppCoordinator();

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'ZenRouter Modular Coordinator Example',
      restorationScopeId: 'modular_coordinator',
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
  }
}

// ============================================================================
// Route Base Class
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

// ============================================================================
// Auth Module - Handles authentication routes
// ============================================================================

class AuthModule extends RouteModule<AppRoute> {
  AuthModule(super.coordinator);

  // Auth module doesn't define any paths (uses root path)
  @override
  List<StackPath> get paths => [];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['login'] => LoginRoute(),
      ['register'] => RegisterRoute(),
      _ => null, // Not handled by this module
    };
  }

  @override
  void defineLayout() {
    // Auth module doesn't define layouts
  }
}

// Auth Routes
class LoginRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/login');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Login Page', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => coordinator.replace(ShopHomeRoute()),
              child: const Text('Login & Go to Shop'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => coordinator.push(RegisterRoute()),
              child: const Text('Go to Register'),
            ),
          ],
        ),
      ),
    );
  }
}

class RegisterRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/register');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Register')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('Register Page', style: TextStyle(fontSize: 24)),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => coordinator.pop(),
              child: const Text('Back to Login'),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================================
// Shop Module - Handles shop/product routes with nested navigation
// ============================================================================

class ShopModule extends RouteModule<AppRoute> {
  ShopModule(super.coordinator);

  // Shop module defines its own navigation path
  late final NavigationPath<AppRoute> shopStack = NavigationPath.createWith(
    label: 'shop',
    coordinator: coordinator,
  );

  @override
  List<StackPath> get paths => [shopStack];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['shop'] => ShopHomeRoute(),
      ['shop', 'products'] => ProductListRoute(),
      ['shop', 'products', final id] => ProductDetailRoute(id: id),
      ['shop', 'cart'] => CartRoute(),
      _ => null, // Not handled by this module
    };
  }

  @override
  void defineLayout() {
    // Register shop layout
    RouteLayout.defineLayout(ShopLayout, ShopLayout.new);
  }
}

// Shop Layout - Provides navigation shell for shop routes
class ShopLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) {
    final shopModule = coordinator.getModule<ShopModule>() as ShopModule;
    return shopModule.shopStack;
  }

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop'), backgroundColor: Colors.green),
      body: buildPath(coordinator),
      bottomNavigationBar: ListenableBuilder(
        listenable: resolvePath(coordinator),
        builder: (context, _) {
          return Container(
            color: Colors.grey[200],
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _ShopNavButton(
                  icon: Icons.home,
                  label: 'Home',
                  isActive: coordinator.activePath.stack.last is ShopHomeRoute,
                  onTap: () => coordinator.push(ShopHomeRoute()),
                ),
                _ShopNavButton(
                  icon: Icons.shopping_bag,
                  label: 'Products',
                  isActive:
                      coordinator.activePath.stack.last is ProductListRoute,
                  onTap: () => coordinator.push(ProductListRoute()),
                ),
                _ShopNavButton(
                  icon: Icons.shopping_cart,
                  label: 'Cart',
                  isActive: coordinator.activePath.stack.last is CartRoute,
                  onTap: () => coordinator.push(CartRoute()),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Shop Routes
class ShopHomeRoute extends AppRoute {
  @override
  Type get layout => ShopLayout;

  @override
  Uri toUri() => Uri.parse('/shop');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Shop Home',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Card(
          child: ListTile(
            leading: const Icon(Icons.shopping_bag),
            title: const Text('View Products'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => coordinator.push(ProductListRoute()),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.shopping_cart),
            title: const Text('View Cart'),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () => coordinator.push(CartRoute()),
          ),
        ),
      ],
    );
  }
}

class ProductListRoute extends AppRoute {
  @override
  Type get layout => ShopLayout;

  @override
  Uri toUri() => Uri.parse('/shop/products');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Products',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        _ProductCard(
          title: 'Product 1',
          onTap: () => coordinator.push(ProductDetailRoute(id: '1')),
        ),
        _ProductCard(
          title: 'Product 2',
          onTap: () => coordinator.push(ProductDetailRoute(id: '2')),
        ),
        _ProductCard(
          title: 'Product 3',
          onTap: () => coordinator.push(ProductDetailRoute(id: '3')),
        ),
      ],
    );
  }
}

class ProductDetailRoute extends AppRoute {
  ProductDetailRoute({required this.id});

  final String id;

  @override
  Type get layout => ShopLayout;

  @override
  Uri toUri() => Uri.parse('/shop/products/$id');

  @override
  List<Object?> get props => [id];

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product $id')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Product Detail $id', style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => coordinator.pop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class CartRoute extends AppRoute {
  @override
  Type get layout => ShopLayout;

  @override
  Uri toUri() => Uri.parse('/shop/cart');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Shopping Cart',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const Card(
          child: ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('Item 1'),
            subtitle: Text('\$19.99'),
          ),
        ),
        const Card(
          child: ListTile(
            leading: Icon(Icons.shopping_cart),
            title: Text('Item 2'),
            subtitle: Text('\$29.99'),
          ),
        ),
      ],
    );
  }
}

// ============================================================================
// Settings Module - Handles settings routes with nested navigation
// ============================================================================

class SettingsModule extends RouteModule<AppRoute> {
  SettingsModule(super.coordinator);

  // Settings module defines its own navigation path
  late final NavigationPath<AppRoute> settingsStack = NavigationPath.createWith(
    label: 'settings',
    coordinator: coordinator,
  );

  @override
  List<StackPath> get paths => [settingsStack];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['settings'] => GeneralSettingsRoute(),
      ['settings', 'account'] => AccountSettingsRoute(),
      ['settings', 'privacy'] => PrivacySettingsRoute(),
      ['settings', 'notifications'] => NotificationsSettingsRoute(),
      _ => null, // Not handled by this module
    };
  }

  @override
  void defineLayout() {
    // Register settings layout
    RouteLayout.defineLayout(SettingsLayout, SettingsLayout.new);
  }
}

// Settings Layout - Provides navigation shell for settings routes
class SettingsLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) {
    final settingsModule =
        coordinator.getModule<SettingsModule>() as SettingsModule;
    return settingsModule.settingsStack;
  }

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: BackButton(onPressed: () => coordinator.tryPop()),
        title: const Text('Settings'),
        backgroundColor: Colors.purple,
      ),
      body: Row(
        children: [
          // Sidebar navigation
          Container(
            width: 200,
            color: Colors.grey[200],
            child: ListView(
              padding: const EdgeInsets.all(8),
              children: [
                _SettingsNavItem(
                  icon: Icons.settings,
                  label: 'General',
                  route: GeneralSettingsRoute(),
                  coordinator: coordinator,
                ),
                _SettingsNavItem(
                  icon: Icons.person,
                  label: 'Account',
                  route: AccountSettingsRoute(),
                  coordinator: coordinator,
                ),
                _SettingsNavItem(
                  icon: Icons.lock,
                  label: 'Privacy',
                  route: PrivacySettingsRoute(),
                  coordinator: coordinator,
                ),
                _SettingsNavItem(
                  icon: Icons.notifications,
                  label: 'Notifications',
                  route: NotificationsSettingsRoute(),
                  coordinator: coordinator,
                ),
              ],
            ),
          ),
          // Settings content
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
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'General Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
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
  Widget build(AppCoordinator coordinator, BuildContext context) {
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
  Widget build(AppCoordinator coordinator, BuildContext context) {
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
        ),
        const ListTile(
          leading: Icon(Icons.location_on),
          title: Text('Location Services'),
        ),
      ],
    );
  }
}

class NotificationsSettingsRoute extends AppRoute {
  @override
  Type get layout => SettingsLayout;

  @override
  Uri toUri() => Uri.parse('/settings/notifications');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Notification Settings',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        const ListTile(
          leading: Icon(Icons.notifications_active),
          title: Text('Push Notifications'),
          trailing: Switch(value: true, onChanged: null),
        ),
        const ListTile(
          leading: Icon(Icons.email),
          title: Text('Email Notifications'),
          trailing: Switch(value: false, onChanged: null),
        ),
      ],
    );
  }
}

// ============================================================================
// Main Coordinator - Uses ModularCoordinator mixin
// ============================================================================

class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute>, CoordinatorDebug {
  @override
  Set<RouteModule<AppRoute>> defineModules(
    CoordinatorModular<AppRoute> coordinator,
  ) => {
    AuthModule(coordinator),
    ShopModule(coordinator),
    SettingsModule(coordinator),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);

  @override
  List<AppRoute> get debugRoutes => [
    LoginRoute(),
    RegisterRoute(),
    ShopHomeRoute(),
    ProductListRoute(),
    ProductDetailRoute(id: '1'),
    CartRoute(),
    GeneralSettingsRoute(),
    AccountSettingsRoute(),
    PrivacySettingsRoute(),
    NotificationsSettingsRoute(),
    NotFoundRoute(uri: Uri.parse('/not-found')),
  ];
}

// ============================================================================
// Not Found Route
// ============================================================================

class AppModule extends RouteModule<AppRoute> {
  AppModule(super.coordinator);

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['not-found'] => NotFoundRoute(uri: uri),
      [] => HomeRoute(),
      _ => null,
    };
  }
}

class HomeRoute extends AppRoute with RouteRedirect<AppRoute> {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) => SizedBox();

  @override
  AppRoute redirect() => LoginRoute();
}

class NotFoundRoute extends AppRoute {
  NotFoundRoute({required this.uri});

  final Uri uri;

  @override
  Uri toUri() => Uri.parse('/not-found');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
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
            ElevatedButton(
              onPressed: () => coordinator.replace(ShopHomeRoute()),
              child: const Text('Go to Shop'),
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

class _ShopNavButton extends StatelessWidget {
  const _ShopNavButton({
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
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          color: isActive ? Colors.green[100] : Colors.transparent,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? Colors.green[700] : Colors.grey),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isActive ? Colors.green[700] : Colors.grey,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const Icon(Icons.shopping_bag),
        title: Text(title),
        trailing: const Icon(Icons.arrow_forward),
        onTap: onTap,
      ),
    );
  }
}

class _SettingsNavItem extends StatelessWidget {
  const _SettingsNavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.coordinator,
  });

  final IconData icon;
  final String label;
  final AppRoute route;
  final AppCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final isActive =
        coordinator.activePath.stack.last.runtimeType == route.runtimeType;
    return ListTile(
      leading: Icon(icon, color: isActive ? Colors.purple : Colors.grey),
      title: Text(
        label,
        style: TextStyle(
          fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
          color: isActive ? Colors.purple : Colors.black,
        ),
      ),
      selected: isActive,
      onTap: () => coordinator.push(route),
    );
  }
}
