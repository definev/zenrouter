# Modular coordinator

Split URI parsing and paths across `RouteModule`s. A single coordinator
is enough for a small app. See [Getting Started](getting-started.md).

```
AppCoordinator          notFoundRoute
  ├─ AuthModule         /login, /register
  └─ ShopModule         /shop, /shop/products/:id
```

The root mixes `CoordinatorModular` only. `defineModules` order is match
order; first non-null wins.

## Module

Each module implements `parseRouteFromUri` and returns `null` for URLs
it does not own.

```dart
class ShopModule extends RouteModule<AppRoute> {
  ShopModule(super.coordinator);

  late final shopStack = NavigationPath<AppRoute>.createWith(
    label: 'shop',
    coordinator: coordinator,
  )..bindLayout(ShopLayout.new);

  @override
  List<StackPath> get paths => [shopStack];

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      ['shop'] => ShopHomeRoute(),
      ['shop', 'products', final id] => ProductRoute(id: id),
      _ => null,
    };
  }
}
```

`coordinator` is the root coordinator.

```dart
class ShopLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(covariant AppCoordinator c) =>
      c.getModule<ShopModule>().shopStack;

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: buildPath(coordinator),
    );
  }
}
```

## Root

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Iterable<RouteModule<AppRoute>> defineModules() => [
    AuthModule(this),
    ShopModule(this),
  ];

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri);
}
```

`defineModules` is snapshotted once. Do not return a rebuilt list on
every access. Duplicate module runtime types throw.

```dart
MaterialApp.router(routerConfig: AppCoordinator())
```

## getModule

```dart
final shop = coordinator.getModule<ShopModule>();
shop.shopStack.push(ProductRoute(id: '123'));
```

Throws if the type is not in `defineModules`. Prefer
`coordinator.push` / `pushUri` so redirects still run.

## Restorable converters

```dart
@override
void init() {
  super.init();
  defineRestorableConverter('book_detail', BookDetailConverter.new);
}
```

Do not use the deprecated `defineConverter` hook.

## RouteModuleBinding

Preferred for new modules. The module owns a `RouteManifest` instead of
a `parseRouteFromUri` switch: matching, `location()`, and the composed
Graph tab stay in sync, and URI conflicts fail when the root joins
fragments.

Do not mix `RouteModuleBinding` onto the **root** `CoordinatorModular`
class; both override `parseRouteFromUri`. Put bindings on child modules.

Module bindings omit `notFound` so later modules can match.

```dart
enum ShopRouteId { layout, home, product }

class ShopModule extends RouteModule<AppRoute>
    with RouteModuleBinding<AppRoute, ShopRouteId> {
  ShopModule(super.coordinator);

  static final manifest = RouteManifest<ShopRouteId>(
    name: 'shop',
    idCodec: RouteIdCodec.enumValues(ShopRouteId.values),
    routes: [
      RouteManifestRoute(
        id: ShopRouteId.home,
        path: '/shop',
        parentId: ShopRouteId.layout,
      ),
      RouteManifestRoute(
        id: ShopRouteId.product,
        path: '/shop/products/:id',
        parentId: ShopRouteId.layout,
      ),
    ],
    layouts: [
      RouteManifestLayout.stack(id: ShopRouteId.layout, path: '/shop'),
    ],
  );

  @override
  late final routeBindings = manifest.bind<AppRoute>(
    bindings: [
      RouteBinding(id: ShopRouteId.home, create: (_) => ShopHomeRoute()),
      RouteBinding(
        id: ShopRouteId.product,
        create: (match) => ProductRoute(id: match.pathParameters['id']!),
      ),
    ],
  );

  late final shopStack = NavigationPath<AppRoute>.createWith(
    label: 'shop',
    coordinator: coordinator,
  )..bindLayout(ShopLayout.new);

  @override
  List<StackPath> get paths => [shopStack];
}
```

`toUri()` uses `ShopModule.manifest.location(...)`.
`CoordinatorModular.routeManifest` is the composed graph.

If a route's `parentId` lives in another module, do not wrap that
fragment in `RouteManifest(...)` (parents are validated immediately).
Expose `routeManifestFragment` instead:

```dart
class AccountModule extends RouteModule<AppRoute> {
  AccountModule(super.coordinator);

  @override
  RouteManifestFragment<AccountRouteId> get routeManifestFragment =>
      RouteManifestFragment(
        name: 'account',
        idCodec: RouteIdCodec.enumValues(AccountRouteId.values),
        routes: [
          RouteManifestRoute(
            id: AccountRouteId.profile,
            path: '/account/profile',
            parentId: AuthRouteId.shell,
          ),
        ],
      );
}
```

Prefer declaring the child in the module that owns the layout.

## See also

- [Coordinator as RouteModule](coordinator-as-module.md)
- [Layouts](route-layout.md)
- [`main_coordinator_module.dart`](../../example/lib/main_coordinator_module.dart)
