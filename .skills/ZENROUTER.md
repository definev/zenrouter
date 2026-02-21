# ZenRouter Advanced Patterns

Agent skill for working with ZenRouter's Coordinator pattern, StackPath, RouteTarget mixins, RouteModule, and State Restoration.

## Coordinator Basics

### Creating a Coordinator

```dart
abstract class AppRoute extends RouteTarget with RouteUnique {}

class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['profile'] => ProfileRoute(),
      ['post', final id] => PostRoute(id: id),
      _ => NotFoundRoute(uri: uri),
    };
  }
}
```

### paths Getter

Register all StackPaths managed by the coordinator. Use `...super.paths` to include root:

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  late final homeIndexed = IndexedStackPath<AppRoute>.createWith(
    [FeedTab(), ProfileTab()],
    coordinator: this,
    label: 'home',
  )..bindLayout(HomeLayout.new);
  late final feedStack = NavigationPath<AppRoute>.createWith(
    coordinator: this,
    label: 'feed',
  )..bindLayout(FeedLayout.new);

  @override
  List<StackPath<RouteTarget>> get paths => [
    ...super.paths,  // Includes root path
    homeIndexed,
    feedStack,
  ];
}
```

### Wiring to MaterialApp

```dart
final appCoordinator = AppCoordinator();

MaterialApp.router(
  routerConfig: appCoordinator,
)
```

---

## StackPath Types

### NavigationPath (Mutable Stack)

For push/pop navigation:

```dart
late final mainStack = NavigationPath<AppRoute>.createWith(
  coordinator: this,
  label: 'main',
  stack: [HomeRoute()],  // Optional initial routes
);
```

Methods: `push()`, `pop()`, `pushOrMoveToTop()`, `pushReplacement()`, `remove()`, `reset()`

### IndexedStackPath (Tabs)

For index-based navigation (fixed routes):

```dart
late final tabPath = IndexedStackPath<AppRoute>.createWith(
  [HomeTab(), ProfileTab(), SettingsTab()],
  coordinator: this,
  label: 'tabs',
);
```

Methods: `goToIndexed()`, `activateRoute()`

### bindLayout

Register a layout for routes in this path:

```dart
late final profileStack = NavigationPath<AppRoute>.createWith(
  coordinator: this,
  label: 'profile',
)..bindLayout(ProfileLayout.new);
```

---

## Route Mixins

### RouteUnique (Required for Coordinator)

```dart
class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Type? get layout => HomeLayout;  // Optional: parent layout

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Home')),
      body: Center(child: Text('Home Page')),
    );
  }
}
```

### RouteLayout (Nested Navigation)

```dart
class HomeLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(AppCoordinator coordinator) =>
      coordinator.homeStack;

  @override
  Type? get layout => null;  // Parent layout

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: buildPath(coordinator),  // Renders nested routes
      bottomNavigationBar: BottomNavigationBar(...),
    );
  }
}

// Child route specifies layout
class ProfileRoute extends AppRoute {
  @override
  Type? get layout => HomeLayout;
}
```

Register layout in Coordinator:

```dart
@override
void defineLayout() {
  RouteLayout.defineLayout(HomeLayout, HomeLayout.new);
}
```

### RouteGuard (Prevent Navigation)

```dart
class EditFormRoute extends AppRoute with RouteUnique, RouteGuard {
  bool hasUnsavedChanges = false;

  @override
  Future<bool> popGuard() async {
    if (!hasUnsavedChanges) return true;

    final result = await showDialog<bool>(...);
    return result ?? false;
  }
}
```

### RouteRedirect (Conditional Routing)

```dart
class DashboardRoute extends AppRoute with RouteUnique, RouteRedirect<AppRoute> {
  @override
  Future<AppRoute?> redirect() async {
    final isLoggedIn = await authService.checkAuth();
    if (!isLoggedIn) {
      return LoginRoute(redirectTo: '/dashboard');
    }
    return this;
  }
}
```

### RouteRedirectRule (Composable Redirects)

```dart
// Define reusable rules
class AuthRule extends RedirectRule<AppRoute> {
  @override
  FutureOr<RedirectResult<AppRoute>> redirectResult(
    Coordinator coordinator,
    AppRoute route,
  ) async {
    if (!AuthService.isAuthenticated) {
      return RedirectResult.redirectTo(LoginRoute());
    }
    return const RedirectResult.continueRedirect();
  }
}

class PermissionRule extends RedirectRule<AppRoute> {
  final String permission;
  PermissionRule(this.permission);

  @override
  FutureOr<RedirectResult<AppRoute>> redirectResult(
    Coordinator coordinator,
    AppRoute route,
  ) async {
    final user = await AuthService.getCurrentUser();
    if (user?.hasPermission(permission) != true) {
      return RedirectResult.redirectTo(UnauthorizedRoute());
    }
    return const RedirectResult.continueRedirect();
  }
}

// Use in route
class AdminRoute extends AppRoute with RouteRedirect, RouteRedirectRule {
  @override
  List<RedirectRule> get redirectRules => [
    AuthRule(),
    PermissionRule('admin'),
  ];
}
```

Result types:
- `RedirectResult.redirectTo(route)` - Redirect to new route
- `RedirectResult.continueRedirect()` - Continue to next rule
- `RedirectResult.stop()` - Cancel navigation

### RouteDeepLink (Custom Deep Link Handling)

```dart
class ProductRoute extends AppRoute with RouteUnique, RouteDeepLink {
  final String productId;

  ProductRoute(this.productId);

  @override
  Uri toUri() => Uri.parse('/product/$productId');

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;

  @override
  Future<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) async {
    // 1. Ensure we're on correct tab
    coordinator.replace(ShopTab());

    // 2. Load product data
    final product = await productService.load(productId);

    // 3. Navigate to product
    coordinator.push(this);

    // 4. Track analytics
    analytics.logDeepLink(uri);
  }
}
```

Strategies: `replace` (default), `push`, `custom`

### RouteTransition (Custom Animations)

```dart
class FadeRoute extends AppRoute with RouteUnique, RouteTransition {
  @override
  Uri toUri() => Uri.parse('/fade');

  @override
  StackTransition<T> transition<T extends RouteUnique>(
    CoordinatorCore coordinator,
  ) {
    return StackTransition.custom(
      builder: (context) => build(coordinator as Coordinator, context),
      pageBuilder: (context, key, child) => PageRouteBuilder(
        settings: RouteSettings(name: key.toString()),
        pageBuilder: (context, animation, secondaryAnimation) => child,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }
}
```

Built-in transitions: `StackTransition.material()`, `StackTransition.cupertino()`, `StackTransition.sheet()`, `StackTransition.dialog()`

### RouteQueryParameters (URL Query Support)

```dart
class SearchRoute extends AppRoute with RouteUnique, RouteQueryParameters {
  late final ValueNotifier<Map<String, String>> queryNotifier;

  SearchRoute({Map<String, String> queries = const {}})
      : queryNotifier = ValueNotifier(queries);

  @override
  Uri toUri() => Uri.parse('/search').replace(query: queries);

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Rebuilds only when 'query' changes
          selectorBuilder(
            selector: (q) => q['query'] ?? '',
            builder: (context, query) => Text('Search: $query'),
          ),
          ElevatedButton(
            onPressed: () {
              updateQueries(coordinator, queries: {'query': 'flutter'});
            },
            child: const Text('Search'),
          ),
        ],
      ),
    );
  }
}
```

---

## RouteModule & CoordinatorModular

### Basic Module

```dart
class AuthModule extends RouteModule<AppRoute> {
  AuthModule(super.coordinator);

  late final authPath = NavigationPath.createWith(
    label: 'auth',
    coordinator: coordinator,
  )..bindLayout(AuthLayout.new);

  @override
  List<StackPath> get paths => [authPath];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['login'] => LoginRoute(),
      ['register'] => RegisterRoute(),
      _ => null,  // Let other modules handle
    };
  }
}
```

### Modular Coordinator

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {

  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    AuthModule(this),
    ShopModule(this),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}
```

### Accessing Modules

```dart
final shopModule = coordinator.getModule<ShopModule>();
shopModule.shopPath.push(ProductRoute(id: '123'));
```

### Best Practices

- Return `null` for unhandled routes
- Use descriptive module names
- Order modules: specific before general

---

## Coordinator as Module

### Wrapper Pattern

```dart
// Feature Coordinator (standalone)
class ShopCoordinator extends Coordinator<AppRoute> {
  late final shopStack = NavigationPath.createWith(
    label: 'shop',
    coordinator: this,
  )..bindLayout(ShopLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, shopStack];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['shop'] => ShopHomeRoute(),
      ['shop', 'products', final id] => ProductRoute(id: id),
      _ => null,
    };
  }
}

// Module Wrapper
class ShopCoordinatorModule extends ShopCoordinator {
  ShopCoordinatorModule(this.coordinator);

  @override
  final CoordinatorModular<AppRoute> coordinator;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['v1', ...final rest] => super.parseRouteFromUri(
          uri.replace(pathSegments: rest),  // Strip 'v1' prefix
        ),
      _ => null,
    };
  }
}
```

### Register in Parent

```dart
class MainCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {

  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    ShopCoordinatorModule(this),
  };
}
```

### Versioning (V1/V2 Coexistence)

```dart
// V1 Wrapper
class ShopV1Module extends ShopCoordinatorV1 {
  ShopV1Module(super.coordinator);
  @override
  final CoordinatorModular<AppRoute> coordinator;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['v1', ...final rest] => super.parseRouteFromUri(
          uri.replace(pathSegments: rest),
        ),
      _ => null,
    };
  }
}

// V2 Wrapper
class ShopV2Module extends ShopCoordinatorV2 {
  ShopV2Module(super.coordinator);
  @override
  final CoordinatorModular<AppRoute> coordinator;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['v2', ...final rest] => super.parseRouteFromUri(
          uri.replace(pathSegments: rest),
        ),
      _ => null,
    };
  }
}

// Register both
@override
Set<RouteModule<AppRoute>> defineModules() => {
  ShopV1Module(this),
  ShopV2Module(this),
};
```

---

## Common Patterns

### Auth Flow

```dart
class ProtectedRoute extends AppRoute
    with RouteUnique, RouteGuard, RouteRedirect<AppRoute> {
  bool isDirty = false;

  @override
  Future<bool> popGuard() async =>
      !isDirty || await confirmDiscard();

  @override
  Future<AppRoute?> redirect() async =>
      await auth.check() ? this : LoginRoute();
}
```

### Bottom Navigation with Tabs

```dart
class MainLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(AppCoordinator c) => c.mainTabs;

  @override
  Widget build(AppCoordinator coordinator, BuildContext context) {
    final tabs = coordinator.mainTabs;
    return Scaffold(
      body: buildPath(coordinator),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: tabs.activePathIndex,
        onTap: (i) => coordinator.push(tabs.stack[i]),
        items: [...],
      ),
    );
  }
}
```

### Deep Link with Auth Check

```dart
class CheckoutRoute extends AppRoute with RouteUnique, RouteDeepLink {
  @override
  Uri toUri() => Uri.parse('/checkout');

  @override
  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.custom;

  @override
  Future<void> deeplinkHandler(AppCoordinator coordinator, Uri uri) async {
    if (!await auth.isLoggedIn()) {
      coordinator.replace(LoginRoute(redirectTo: uri.toString()));
      return;
    }
    coordinator.push(this);
  }
}
```

---

## Troubleshooting

### "UnimplementedError: This coordinator is standalone"

Cause: Using Coordinator as RouteModule without overriding `coordinator` getter.

Fix: Override in wrapper class:
```dart
@override
CoordinatorModular<AppRoute> get coordinator => _parent;
```

### "Type X is not a subtype of type Y"

Cause: Module not registered in `defineModules()`.

Fix: Add module to the set.

### Route Not Found

1. Check module's `parseRouteFromUri` returns non-null
2. Verify module order (first match wins)
3. Ensure route URI matches pattern

### Layout Not Registered

Fix: Call `RouteLayout.defineLayout()` in Coordinator's `defineLayout()` method.
