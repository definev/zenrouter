# Modular Coordinator Guide

> **Split your coordinator into independent, reusable modules**

The Modular Coordinator pattern enables you to organize routes by domain or feature, making large applications more maintainable and allowing teams to work independently on different parts of your app.

## What is Modular Coordinator?

`CoordinatorModular` is a mixin that extends `Coordinator` with the ability to delegate route management to multiple `RouteModule` instances. Each module handles a specific subset of routes, paths, layouts, and converters.

**Key concepts:**
- **RouteModule**: A self-contained unit that handles routes for a specific domain
- **CoordinatorModular**: Aggregates modules and delegates route parsing
- **Module Isolation**: Each module manages its own paths and layouts independently

### When to Use Modular Coordinator

✅ **Use when:**
- Building large applications with many routes
- Working with multiple teams on different features
- You want to organize routes by domain (auth, shop, settings, etc.)
- You need to reuse route modules across applications
- Your `parseRouteFromUri` method is becoming too large

❌ **Don't use when:**
- Your app has fewer than ~10 routes
- All routes belong to a single domain
- You prefer a single, centralized route parser

---

## Quick Start

### Step 1: Create Your Route Modules

Each module extends `RouteModule` and handles routes for a specific domain:

```dart
// lib/modules/auth_module.dart
class AuthModule extends RouteModule<AppRoute> {
  AuthModule(super.coordinator);

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['auth', 'login'] => LoginRoute(),
      ['auth', 'register'] => RegisterRoute(),
      _ => null, // Not handled by this module
    };
  }

  @override
  void defineLayout() {
    // Register auth-specific layouts
    RouteLayout.defineLayout(AuthLayout, AuthLayout.new);
  }
}

// lib/modules/shop_module.dart
class ShopModule extends RouteModule<AppRoute> {
  ShopModule(super.coordinator);

  // Module can define its own navigation paths
  late final NavigationPath<AppRoute> shopPath = NavigationPath.createWith(
    label: 'shop',
    coordinator: coordinator,
  );

  @override
  List<StackPath> get paths => [shopPath];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['shop'] => ShopHomeRoute(),
      ['shop', 'products', final id] => ProductRoute(id: id),
      ['shop', 'cart'] => CartRoute(),
      _ => null,
    };
  }

  @override
  void defineLayout() {
    RouteLayout.defineLayout(ShopLayout, ShopLayout.new);
  }
}
```

### Step 2: Create Your Modular Coordinator

Use the `CoordinatorModular` mixin and implement `defineModules`:

```dart
// lib/coordinator.dart
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  
  @override
  Set<RouteModule<AppRoute>> defineModules() {
    return {
      AuthModule(this),
      ShopModule(this),
      SettingsModule(this),
    };
  }

  @override
  AppRoute notFoundRoute(Uri uri) {
    return NotFoundRoute(uri: uri);
  }
}
```

### Step 3: Use in Your App

The coordinator works exactly like a regular coordinator:

```dart
final coordinator = AppCoordinator();

MaterialApp.router(
  routerConfig: coordinator,
)
```

**That's it!** Routes are now parsed by modules in order until one matches.

---

## How Route Parsing Works

When `parseRouteFromUri` is called, the coordinator:

1. **Iterates through modules** in the order they appear in `defineModules`
2. **Calls each module's `parseRouteFromUri`** until one returns a non-null route
3. **Returns the first match** found
4. **Calls `notFoundRoute`** if all modules return null

**Example flow:**

```dart
// URI: /shop/products/123
coordinator.parseRouteFromUri(Uri.parse('/shop/products/123'));

// 1. AuthModule.parseRouteFromUri() → returns null (not handled)
// 2. ShopModule.parseRouteFromUri() → returns ProductRoute(id: '123') ✅
// 3. Returns ProductRoute immediately (doesn't check SettingsModule)
```

**Important:** Module order matters! The first module that returns a non-null route wins.

---

## Complete Example

Here's a full example showing multiple modules with layouts and paths:

```dart
// ============================================================================
// Route Base
// ============================================================================

abstract class AppRoute extends RouteTarget with RouteUnique {}

// ============================================================================
// Auth Module
// ============================================================================

class AuthModule extends RouteModule<AppRoute> {
  AuthModule(super.coordinator);

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['login'] => LoginRoute(),
      ['register'] => RegisterRoute(),
      _ => null,
    };
  }
}

class LoginRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/login');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: ElevatedButton(
          onPressed: () => coordinator.replace(ShopHomeRoute()),
          child: const Text('Login'),
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
      body: const Center(child: Text('Register Page')),
    );
  }
}

// ============================================================================
// Shop Module
// ============================================================================

class ShopModule extends RouteModule<AppRoute> {
  ShopModule(super.coordinator);

  late final NavigationPath<AppRoute> shopPath = NavigationPath.createWith(
    label: 'shop',
    coordinator: coordinator,
  );

  @override
  List<StackPath> get paths => [shopPath];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['shop'] => ShopHomeRoute(),
      ['shop', 'products', final id] => ProductRoute(id: id),
      _ => null,
    };
  }

  @override
  void defineLayout() {
    RouteLayout.defineLayout(ShopLayout, ShopLayout.new);
  }
}

class ShopLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) {
    final shopModule = coordinator.getModule<ShopModule>() as ShopModule;
    return shopModule.shopPath;
  }

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: buildPath(coordinator),
    );
  }
}

class ShopHomeRoute extends AppRoute {
  @override
  Type get layout => ShopLayout;

  @override
  Uri toUri() => Uri.parse('/shop');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return ListView(
      children: [
        ListTile(
          title: const Text('Product 1'),
          onTap: () => coordinator.push(ProductRoute(id: '1')),
        ),
      ],
    );
  }
}

class ProductRoute extends AppRoute {
  ProductRoute({required this.id});
  final String id;

  @override
  Type get layout => ShopLayout;

  @override
  Uri toUri() => Uri.parse('/shop/products/$id');

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Product $id')),
      body: Center(child: Text('Product Detail: $id')),
    );
  }

  @override
  List<Object?> get props => [id];
}

// ============================================================================
// Coordinator
// ============================================================================

class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  
  @override
  Set<RouteModule<AppRoute>> defineModules() {
    return {
      AuthModule(this),
      ShopModule(this),
    };
  }

  @override
  AppRoute notFoundRoute(Uri uri) {
    return NotFoundRoute(uri: uri);
  }
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
      body: Center(child: Text('Route not found: ${uri.path}')),
    );
  }
}
```

---

## Accessing Modules

Use `getModule()` to access module-specific functionality:

```dart
final coordinator = AppCoordinator();

// Access a specific module
final shopModule = coordinator.getModule<ShopModule>();

// Use module-specific paths
shopModule.shopPath.push(ProductRoute(id: '123'));

// Access module properties
final shopPath = shopModule.shopPath;
```

**Use case:** When you need to navigate within a specific module's path or access module-specific functionality.

---

## Module Responsibilities

Each module can handle:

### 1. Route Parsing

Override `parseRouteFromUri` to handle specific URI patterns:

```dart
@override
FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
  return switch (uri.pathSegments) {
    ['my', 'route'] => MyRoute(),
    _ => null, // Let other modules handle it
  };
}
```

**Best practice:** Return `null` for routes you don't handle. This allows other modules to process them.

### 2. Navigation Paths

Override `paths` to provide paths for nested navigation:

```dart
late final NavigationPath<AppRoute> myPath = NavigationPath.createWith(
  label: 'my-module',
  coordinator: coordinator,
);

@override
List<StackPath> get paths => [myPath];
```

**Important:** Always use `.createWith()` to bind paths to the coordinator.

### 3. Layout Registration

Override `defineLayout` to register layouts:

```dart
@override
void defineLayout() {
  RouteLayout.defineLayout(MyLayout, MyLayout.new);
}
```

### 4. Converter Registration

Override `defineConverter` to register restorable converters:

```dart
@override
void defineConverter() {
  RestorableConverter.defineConverter(
    MyRoute,
    (json) => MyRoute.fromJson(json),
    (route) => route.toJson(),
  );
}
```

---

## Module Order Matters

Modules are checked in the order they appear in the `Set` returned by `defineModules`. This allows you to:

- **Prioritize certain modules** (e.g., admin routes checked before public routes)
- **Handle route conflicts** (first module wins)
- **Create fallback chains** (specific modules before general ones)

**Example: Admin routes take precedence**

```dart
@override
Set<RouteModule<AppRoute>> defineModules() {
  return {
    AdminModule(this),    // Checked first
    PublicModule(this),   // Checked second
  };
}
```

If both modules could handle `/users`, AdminModule wins because it's checked first.

---

## Path Aggregation

All module paths are automatically aggregated into the coordinator's `paths`:

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  // ... defineModules ...

  // Paths automatically include:
  // - coordinator.root (from super.paths)
  // - shopModule.shopPath (from ShopModule)
  // - settingsModule.settingsPath (from SettingsModule)
}
```

You can access all paths through `coordinator.paths`, and they're all available for state restoration.

---

## Best Practices

### ✅ Do

- **Return null** when a module doesn't handle a route
- **Use descriptive module names** (AuthModule, ShopModule, not Module1, Module2)
- **Keep modules focused** on a single domain or feature
- **Use `.createWith()`** for all paths to ensure proper binding
- **Provide unique labels** for paths (required for state restoration)
- **Order modules logically** (specific before general, admin before public)

### ❌ Don't

- **Don't handle routes outside your domain** (return null instead)
- **Don't create circular dependencies** between modules
- **Don't access other modules directly** (use `getModule()` instead)
- **Don't forget to return null** for unhandled routes
- **Don't create paths without binding** to the coordinator

---

## Advanced Patterns

### Module with Multiple Paths

A module can manage multiple paths:

```dart
class ShopModule extends RouteModule<AppRoute> {
  ShopModule(super.coordinator);

  late final NavigationPath<AppRoute> productsPath = NavigationPath.createWith(
    label: 'products',
    coordinator: coordinator,
  );

  late final NavigationPath<AppRoute> cartPath = NavigationPath.createWith(
    label: 'cart',
    coordinator: coordinator,
  );

  @override
  List<StackPath> get paths => [productsPath, cartPath];
}
```

### Module with Async Parsing

Modules can use async parsing for dynamic route resolution:

```dart
@override
Future<AppRoute?> parseRouteFromUri(Uri uri) async {
  if (uri.pathSegments.first == 'dynamic') {
    // Fetch data from API
    final data = await fetchRouteData(uri);
    return DynamicRoute(data: data);
  }
  return null;
}
```

### Module with Conditional Registration

Register modules conditionally:

```dart
@override
Set<RouteModule<AppRoute>> defineModules() {
  final modules = <RouteModule<AppRoute>>{
    AuthModule(this),
    ShopModule(this),
  };

  // Add admin module only if user is admin
  if (userService.isAdmin) {
    modules.add(AdminModule(coordinator));
  }

  return modules;
}
```

---

## Troubleshooting

### Error: "TypeError: type 'X' is not a subtype of type 'Y'"

**Problem:** Trying to access a module that wasn't registered.

**Solution:** Ensure the module is included in `defineModules`:

```dart
@override
Set<RouteModule<AppRoute>> defineModules() {
  return {
    MyModule(this), // ✅ Must be included
  };
}
```

### Routes Not Being Parsed

**Check:**
1. Module is included in `defineModules`
2. Module's `parseRouteFromUri` returns non-null for the route
3. Module appears before other modules that might handle the same route
4. Route URI matches the pattern in the module

**Debug tip:** Add logging to see which modules are checked:

```dart
@override
FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
  print('AuthModule checking: ${uri.path}');
  return switch (uri.pathSegments) {
    ['auth', 'login'] => LoginRoute(),
    _ => null,
  };
}
```

### Path Not Found

**Problem:** Module path not accessible or not aggregated.

**Solution:**
1. Ensure path is returned in module's `paths` getter
2. Use `.createWith()` to bind path to coordinator
3. Check that module is registered in `defineModules`

### Layout Not Registered

**Problem:** Layout constructor not found.

**Solution:** Register layout in module's `defineLayout`:

```dart
@override
void defineLayout() {
  RouteLayout.defineLayout(MyLayout, MyLayout.new); // ✅ Required
}
```

---

## Comparison: Regular vs Modular Coordinator

| Aspect | Regular Coordinator | Modular Coordinator |
|--------|-------------------|---------------------|
| **Route Parsing** | Single `parseRouteFromUri` method | Delegated to modules |
| **Code Organization** | All routes in one place | Routes organized by module |
| **Team Collaboration** | Requires coordination | Teams work independently |
| **Scalability** | Becomes unwieldy with many routes | Scales well with many routes |
| **Reusability** | Routes tied to coordinator | Modules can be reused |
| **Complexity** | Simpler for small apps | Better for large apps |

**Migration:** You can migrate from regular to modular coordinator incrementally by extracting routes into modules one at a time.

---

## Next Steps

- **See [route-layout.md](./route-layout.md)** for creating nested navigation layouts
- **See [state-restoration.md](./state-restoration.md)** for persisting navigation state
- **See [query-parameters.md](./query-parameters.md)** for handling URL parameters
- **Check example code** in `packages/zenrouter/example/lib/main_modular.dart`
- **Read API docs** for [RouteModule](../api/coordinator.md#routemodule) and [CoordinatorModular](../api/coordinator.md#coordinatormodular)

---

**Need help?** File an issue at [github.com/definev/zenrouter/issues](https://github.com/definev/zenrouter/issues)
