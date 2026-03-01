# Advanced Patterns

Deep-dive reference for patterns beyond the core workflow. Read [SKILL.md](./SKILL.md) first.

---

## Coordinator as Module

When a feature group itself has sub-modules, use a `Coordinator<T>` with
`CoordinatorModular<T>` and override `coordinator` to point to the parent:

```dart
class ShopCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  ShopCoordinator(this.coordinator);
  @override
  final CoordinatorModular<AppRoute> coordinator;

  late final shopStack = NavigationPath<AppRoute>.createWith(
    label: 'shop',
    coordinator: coordinator,
  )..bindLayout(ShopLayout.new);

  @override
  List<StackPath> get paths => [...super.paths, shopStack];

  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    ShopProductsModule(this),
    ShopReviewsModule(this),
  };

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}
```

Register in the parent's `defineModules()`:

```dart
@override
Set<RouteModule<AppRoute>> defineModules() => {
  AuthModule(this),
  ShopCoordinator(this),   // ← Coordinator-as-Module
};
```

**Rules:**
- Overriding `coordinator` sets `isRouteModule = true` — prevents the child from
  creating its own root `NavigationPath`.
- Always spread `super.paths` so child module paths are included.
- Access sibling modules via `coordinator.getModule<OtherModule>()`.

---

## RouteModule

`RouteModule<T>` encapsulates a feature's routes, navigation paths, layouts, and
restorable converters. The coordinator delegates to modules in order — first
non-null result from `parseRouteFromUri` wins.

### API

```dart
abstract class RouteModule<T extends RouteUri> {
  RouteModule(CoordinatorModular<T> coordinator);

  /// Always points to the root coordinator (even when nested).
  final CoordinatorModular<T> coordinator;

  /// Navigation paths owned by this module. Default: [].
  List<StackPath> get paths;

  /// Return the matching route or null for unrecognised URIs.
  FutureOr<T?> parseRouteFromUri(Uri uri);

  /// Register layout constructors (called once during coordinator init).
  void defineLayout() {}

  /// Register restorable converters (called once during coordinator init).
  void defineConverter() {}
}
```

### Minimal module

```dart
class AuthModule extends RouteModule<AppRoute> {
  AuthModule(super.coordinator);

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => switch (uri.pathSegments) {
    ['auth', 'login'] => AuthLoginRoute(),
    ['auth', 'register'] => AuthRegisterRoute(),
    _ => null,
  };
}
```

### Module with NavigationPath + Layout

```dart
class ShopModule extends RouteModule<AppRoute> {
  ShopModule(super.coordinator);

  late final shopStack = NavigationPath<AppRoute>.createWith(
    coordinator: coordinator,
    label: 'shop',
  )..bindLayout(ShopLayout.new);

  @override
  List<StackPath> get paths => [shopStack];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => switch (uri.pathSegments) {
    ['shop'] => ShopHomeRoute(),
    ['shop', 'products', final id] => ProductDetailRoute(id: id),
    _ => null,
  };
}
```

### Async parsing

`parseRouteFromUri` can return `Future<T?>` for routes that need async
resolution (e.g. lazy loading):

```dart
@override
Future<AppRoute?> parseRouteFromUri(Uri uri) async {
  final route = await _lazyLoadRoute(uri);
  return switch (route) {
    final route? => route,
    _ => null,
  };
}
```

### defineLayout

Override to register layout constructors via `defineLayoutParentConstructor`.
Called automatically during coordinator construction — do **not** call manually:

```dart
@override
void defineLayout() {
  coordinator.defineLayoutParentConstructor(
    SettingsLayout,
    () => SettingsLayout(),
  );
}
```

> [!TIP]
> Using `bindLayout(LayoutClass.new)` on a `NavigationPath` is the preferred
> shorthand — it registers the constructor for you. Override `defineLayout`
> only when you need layouts not tied to a specific path.

### defineConverter

Override to register `RestorableConverter`s for state restoration:

```dart
@override
void defineConverter() {
  RestorableConverter.defineConverter(
    'book_detail',
    BookDetailConverter.new,
  );
}
```

### Accessing sibling modules

Use `coordinator.getModule<T>()` to access another module's paths or
functionality. This is most common in layout `resolvePath`:

```dart
class ShopLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(covariant AppCoordinator coordinator) =>
      coordinator.getModule<ShopModule>().shopStack;

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) =>
      Scaffold(body: buildPath(coordinator));
}
```

### Rules

| Rule | Why |
|:-----|:----|
| Always return `null` for unrecognised URIs | So other modules can claim them |
| Use the inherited `coordinator` field for `NavigationPath<T>.createWith` | It always refers to the root coordinator that owns the navigation state |
| Module order in `defineModules()` matters | First non-null `parseRouteFromUri` wins |
| `defineLayout` / `defineConverter` are called once | During coordinator construction — do not call them manually |
| `getModule<T>()` throws `TypeError` if `T` is not registered | Make sure the target module is in `defineModules()` |

---

## RedirectRule

Composable redirect guards applied via `RouteRedirectRule<T>` mixin on a route.

### Writing a rule

```dart
class AuthRequiredRule extends RedirectRule<AppRoute> {
  @override
  Future<RedirectResult<AppRoute>> redirectResult(
    covariant AppCoordinator coordinator,
    AppRoute route,
  ) async {
    if (route.parentLayoutKey == AuthLayout) {
      return const RedirectResult.continueRedirect();
    }
    final isLoggedIn = await authService.isLoggedIn();
    if (!isLoggedIn) {
      return RedirectResult.redirectTo(SignInRoute(next: route.toUri()));
    }
    return const RedirectResult.continueRedirect();
  }
}
```

| `RedirectResult` | Meaning |
|:-----------------|:--------|
| `.continueRedirect()` | Pass to next rule |
| `.redirectTo(route)` | Redirect to route; stops chain |
| `.stop()` | Cancel navigation entirely |

Rules are evaluated in list order; first non-`continueRedirect` result wins.

### Applying rules to a route

```dart
class ShopIndexRoute extends AppRoute with RouteRedirectRule<AppRoute> {
  @override
  Uri toUri() => Uri.parse('/shop');

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) =>
      const SizedBox.shrink();

  @override
  List<RedirectRule<AppRoute>> get redirectRules => [
    AuthRequiredRule(),
    ForceToShopHomeRule(),
  ];
}
```

---

## IndexedStackPath (Tab Navigation)

For tab-bar style navigation where all tabs stay alive:

```dart
// In coordinator / module:
late final tabStack = IndexedStackPath<AppRoute>.createWith(
  coordinator: this,
  label: 'main-tabs',
  [HomeTab(), ShopTab(), ProfileTab()],
)..bindLayout(TabBarLayout.new);

@override
List<StackPath> get paths => [...super.paths, tabStack];

// In layout:
class TabBarLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  IndexedStackPath<AppRoute> resolvePath(covariant AppCoordinator coordinator) =>
      coordinator.tabStack;

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: IndexedStackPathBuilder(
        path: coordinator.tabStack,
        coordinator: coordinator,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: coordinator.tabStack.activeIndex,
        onTap: coordinator.tabStack.activateAt,
        items: const [/* ... */],
      ),
    );
  }
}
```

---

## Named Parameter Routes

Files wrapped in `[]` represent dynamic URI segments. The name inside the brackets matches the parameter name used in `parseRouteFromUri` and `toUri()`:

| File | URI | parseRouteFromUri |
|:-----|:----|:------------------|
| `transactions/[id].dart` | `/transaction/:id` | `['transaction', final id] => TransactionDetailRoute(id: id)` |
| `posts/[slug].dart` | `/blog/posts/:slug` | `['blog', 'posts', final slug] => BlogPostRoute(slug: slug)` |
| `users/[userId]/orders/[orderId].dart` | `/users/:userId/orders/:orderId` | `['users', final userId, 'orders', final orderId] => ...` |

The route class inside `[id].dart` takes the parameter as a constructor argument and includes it in `props`:

```dart
// routes/(dashboard)/transactions/[id].dart
class TransactionDetailRoute extends AppRoute {
  TransactionDetailRoute({required this.id});
  final String id;

  @override
  List<Object?> get props => [id];

  @override
  Object? get parentLayoutKey => DashboardLayout;

  @override
  Uri toUri() => Uri.parse('/transaction/$id');

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) =>
      TransactionDetailPage(id: id);
}
```

---

## Catch-All Parameter Routes

Files wrapped in `[...]` capture all remaining URI segments as a list. The name inside indicates the parameter purpose:

| File | URI | parseRouteFromUri |
|:-----|:----|:------------------|
| `blog/[...slug].dart` | `/blog/*` | `['blog', ...final slug] => BlogRoute(slug: slug)` |
| `docs/[...path].dart` | `/docs/*` | `['docs', ...final path] => DocsRoute(path: path)` |

The route class inside `[...slug].dart` takes the segments as a `List<String>` constructor argument:

```dart
// routes/blog/[...slug].dart
class BlogRoute extends AppRoute {
  BlogRoute({required this.slug});
  final List<String> slug;

  @override
  List<Object?> get props => [slug];

  @override
  Object? get parentLayoutKey => BlogLayout;

  @override
  Uri toUri() => Uri.parse('/blog/${slug.join('/')}');

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) =>
      BlogPage(slug: slug);
}
```
