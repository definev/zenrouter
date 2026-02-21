# Recipe: Route Versioning with Coordinator-as-RouteModule

## Problem

You need to maintain multiple versions of a feature's routes in the same app. For example, you're rolling out a redesigned Shop experience (V2) while keeping the legacy Shop (V1) available for users who haven't migrated yet. Each version has its own routes, layouts, and UI—but they need to coexist and allow cross-version navigation.

## Solution Overview

Since `Coordinator<T>` implements `RouteModule<T>`, you can create separate coordinators for each API version and compose them as modules in a single parent. Each coordinator owns its own:

- **URI prefix** (`/v1/shop/...` vs `/v2/shop/...`)
- **Navigation paths** (isolated stacks)
- **Layouts** (different UI per version)
- **Route parsing logic**

This gives you full isolation between versions while sharing the same parent coordinator for cross-version navigation.

## Complete Code Example

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

// ============================================================================
// Route Base
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

// ============================================================================
// Shop V1 — Deprecated version
// ============================================================================

class ShopCoordinatorV1 extends Coordinator<AppRoute> {
  ShopCoordinatorV1(this._parent);
  final MainCoordinator _parent;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  late final NavigationPath<AppRoute> shopV1Stack = NavigationPath.createWith(
    label: 'shop-v1',
    coordinator: this,
  )..bindLayout(ShopV1Layout.new);

  @override
  List<StackPath> get paths => [...super.paths, shopV1Stack];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['v1', 'shop'] => ShopHomeV1(),
      ['v1', 'shop', 'products'] => ProductListV1(),
      ['v1', 'shop', 'cart'] => CartV1(),
      _ => null,
    };
  }
}

// V1 Layout — shows deprecation banner
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
          MaterialBanner(
            padding: const EdgeInsets.all(12),
            backgroundColor: Colors.orange[100],
            leading: const Icon(Icons.warning_amber, color: Colors.orange),
            content: const Text('This version is deprecated. Migrate to V2.'),
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
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 0,
        selectedItemColor: Colors.grey[700],
        onTap: (i) => switch (i) {
          0 => coordinator.push(ShopHomeV1()),
          1 => coordinator.push(ProductListV1()),
          2 => coordinator.push(CartV1()),
          _ => null,
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Products'),
          BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        ],
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
  Widget build(covariant MainCoordinator c, BuildContext ctx) =>
      const Center(child: Text('Shop Home (V1)'));
}

class ProductListV1 extends AppRoute {
  @override
  Type get layout => ShopV1Layout;
  @override
  Uri toUri() => Uri.parse('/v1/shop/products');
  @override
  Widget build(covariant MainCoordinator c, BuildContext ctx) =>
      const Center(child: Text('Products (V1)'));
}

class CartV1 extends AppRoute {
  @override
  Type get layout => ShopV1Layout;
  @override
  Uri toUri() => Uri.parse('/v1/shop/cart');
  @override
  Widget build(covariant MainCoordinator c, BuildContext ctx) =>
      const Center(child: Text('Cart (V1)'));
}

// ============================================================================
// Shop V2 — Current version
// ============================================================================

class ShopCoordinatorV2 extends Coordinator<AppRoute> {
  ShopCoordinatorV2(this._parent);
  final MainCoordinator _parent;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;

  late final NavigationPath<AppRoute> shopV2Stack = NavigationPath.createWith(
    label: 'shop-v2',
    coordinator: this,
  )..bindLayout(ShopV2Layout.new);

  @override
  List<StackPath> get paths => [...super.paths, shopV2Stack];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['v2', 'shop'] => ShopHomeV2(),
      ['v2', 'shop', 'products'] => ProductListV2(),
      ['v2', 'shop', 'products', final id] => ProductDetailV2(id: id),
      ['v2', 'shop', 'cart'] => CartV2(),
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
          // Cross-version navigation
          TextButton.icon(
            icon: const Icon(Icons.history, color: Colors.white70),
            label: const Text('V1', style: TextStyle(color: Colors.white70)),
            onPressed: () => coordinator.replace(ShopHomeV1()),
          ),
        ],
      ),
      body: Row(
        children: [
          NavigationRail(
            selectedIndex: 0,
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
  Widget build(covariant MainCoordinator c, BuildContext ctx) =>
      const Center(child: Text('Shop Home (V2)'));
}

class ProductListV2 extends AppRoute {
  @override
  Type get layout => ShopV2Layout;
  @override
  Uri toUri() => Uri.parse('/v2/shop/products');
  @override
  Widget build(covariant MainCoordinator c, BuildContext ctx) =>
      const Center(child: Text('Products (V2)'));
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
  Widget build(covariant MainCoordinator c, BuildContext ctx) =>
      Center(child: Text('Product $id (V2)'));
}

class CartV2 extends AppRoute {
  @override
  Type get layout => ShopV2Layout;
  @override
  Uri toUri() => Uri.parse('/v2/shop/cart');
  @override
  Widget build(covariant MainCoordinator c, BuildContext ctx) =>
      const Center(child: Text('Cart (V2)'));
}

// ============================================================================
// Main Coordinator
// ============================================================================

class MainCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    MainRouteModule(this),
    ShopCoordinatorV1(this),
    ShopCoordinatorV2(this),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}

class MainRouteModule extends RouteModule<AppRoute> {
  MainRouteModule(super.coordinator);

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRedirect(),
      _ => null,
    };
  }
}

class HomeRedirect extends AppRoute with RouteRedirect<AppRoute> {
  @override
  Uri toUri() => Uri.parse('/');
  @override
  AppRoute redirect() => ShopHomeV2(); // Default to latest version
  @override
  Widget build(covariant Coordinator c, BuildContext ctx) => const SizedBox();
}

class NotFoundRoute extends AppRoute {
  NotFoundRoute({required this.uri});
  final Uri uri;
  @override
  Uri toUri() => Uri.parse('/not-found');
  @override
  Widget build(covariant Coordinator c, BuildContext ctx) =>
      Center(child: Text('Not found: ${uri.path}'));
}
```

## Step-by-Step Explanation

### 1. Create Versioned Coordinators

Each version is a full `Coordinator` with its own paths and layouts:

```dart
class ShopCoordinatorV1 extends Coordinator<AppRoute> {
  ShopCoordinatorV1(this._parent);
  final MainCoordinator _parent;

  @override
  CoordinatorModular<AppRoute> get coordinator => _parent;     // ← Link to parent

  late final shopV1Stack = NavigationPath.createWith(
    label: 'shop-v1',
    coordinator: this,   // ← Auto-resolves to root coordinator
  );
  // ...
}
```

**Key points:**
- Override `coordinator` to return the parent
- Pass `this` when creating paths — the framework auto-resolves the root coordinator
- Use unique labels (`shop-v1`, `shop-v2`) to avoid conflicts

### 2. Version-specific URI prefixes

Each version owns its own URI namespace:

```dart
// V1 handles /v1/shop/...
['v1', 'shop'] => ShopHomeV1(),
['v1', 'shop', 'products'] => ProductListV1(),

// V2 handles /v2/shop/...
['v2', 'shop'] => ShopHomeV2(),
['v2', 'shop', 'products', final id] => ProductDetailV2(id: id),
```

### 3. Version-specific Layouts

Each version can have a completely different UI:

- **V1**: `BottomNavigationBar` + deprecation `MaterialBanner`
- **V2**: `NavigationRail` sidebar (modern design)

### 4. Cross-Version Navigation

Navigate between versions using the parent coordinator:

```dart
// V1 → V2: "Switch to V2" button in deprecation banner
coordinator.replace(ShopHomeV2());

// V2 → V1: "V1" button in app bar
coordinator.replace(ShopHomeV1());
```

### 5. Default Redirect

The root route redirects to the latest version:

```dart
class HomeRedirect extends AppRoute with RouteRedirect<AppRoute> {
  @override
  AppRoute redirect() => ShopHomeV2(); // Default to V2
}
```

## Advanced Variations

### Feature Flags

Conditionally include versions based on feature flags:

```dart
@override
Set<RouteModule<AppRoute>> defineModules() {
  final modules = <RouteModule<AppRoute>>{
    ShopCoordinatorV2(this),
  };

  if (featureFlags.enableLegacyShop) {
    modules.add(ShopCoordinatorV1(this));
  }

  return modules;
}
```

### Gradual Migration

Route V1 URIs to V2 handlers using redirects:

```dart
class ShopV1Redirect extends AppRoute with RouteRedirect<AppRoute> {
  @override
  Uri toUri() => Uri.parse('/v1/shop');
  @override
  AppRoute redirect() => ShopHomeV2();
}
```

### Three or More Versions

The pattern scales to any number of versions:

```dart
Set<RouteModule<AppRoute>> defineModules() => {
  ShopCoordinatorV1(this),   // Legacy
  ShopCoordinatorV2(this),   // Current
  ShopCoordinatorV3(this),   // Canary/beta
};
```

## Common Gotchas

> [!WARNING]
> **Use unique path labels** for each version. Duplicate labels will cause state restoration conflicts. Use prefixes like `shop-v1`, `shop-v2`.

> [!TIP]
> **V2-exclusive features** (like product detail with `:id`) don't need V1 equivalents. Each version is independently defined.

> [!NOTE]
> **Module order in `defineModules`** determines parsing priority. If V1 and V2 have overlapping URI patterns, the first will win. Using version prefixes (`/v1/`, `/v2/`) avoids this entirely.

## Related Recipes

- [Bottom Navigation](bottom-navigation.md) — Tab navigation within a version
- [Authentication Flow](authentication-flow.md) — Guards that work across versions
- [404 Handling](404-handling.md) — Handling unknown versioned routes

## See Also

- [Coordinator as RouteModule Guide](../guides/coordinator-as-module.md) — In-depth guide
- [Coordinator Modular Guide](../guides/coordinator-modular.md) — Regular RouteModule pattern
- **Example code**: `packages/zenrouter/example/lib/main_coordinator_module.dart`
