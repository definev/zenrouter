# Coordinator as RouteModule

`Coordinator<T>` implements `RouteModule<T>`. A child coordinator can be
registered in a parent's `defineModules()` like any other module.

Typical uses:

- An existing standalone coordinator (legacy app or package)
- A feature that itself has sub-modules
- Two versions of a feature (Shop V1 and Shop V2)

For a new feature with a few routes, use
[`RouteModule`](coordinator-modular.md).

The child does not own a separate browser history. Its routes join the
parent graph.

## Nested CoordinatorModular

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
  Iterable<RouteModule<AppRoute>> defineModules() => [
    ShopProductsModule(this),
    ShopReviewsModule(this),
  ];

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri);
}
```

Overriding `coordinator` marks the child as a module. It does not create
a second root stack. Paths use the root coordinator.

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Iterable<RouteModule<AppRoute>> defineModules() => [
    AuthModule(this),
    ShopCoordinator(this),
  ];

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri);
}
```

Parsing walks shop's sub-modules, then returns `null` so the parent can
try the next sibling. Nested `notFoundRoute` is unused.

Spread `super.paths` so inner module paths are included.

Do not mix `RouteModuleBinding` on this grouping coordinator.
`CoordinatorModular` already implements `parseRouteFromUri`. Put
bindings on inner modules.

## Wrapper

Keep the original coordinator independent. Subclass it to set
`coordinator` and optionally strip a prefix:

```dart
class ShopCoordinator extends Coordinator<AppRoute>
    with RouteModuleBinding<AppRoute, ShopRouteId> {
  // manifest, bindings, paths
}

class ShopCoordinatorModule extends ShopCoordinator {
  ShopCoordinatorModule(this.coordinator);

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
```

`/v1/shop/products/1` is forwarded as `/shop/products/1`.

```dart
@override
Iterable<RouteModule<AppRoute>> defineModules() => [
  ShopCoordinatorModule(this),
  SettingsModule(this),
];
```

## Parallel versions

```dart
class ShopV1Module extends ShopCoordinatorV1 {
  ShopV1Module(this.coordinator);
  @override
  final CoordinatorModular<AppRoute> coordinator;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) =>
      switch (uri.pathSegments) {
        ['v1', ...final rest] =>
          super.parseRouteFromUri(uri.replace(pathSegments: rest)),
        _ => null,
      };
}

class ShopV2Module extends ShopCoordinatorV2 {
  ShopV2Module(this.coordinator);
  @override
  final CoordinatorModular<AppRoute> coordinator;

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) =>
      switch (uri.pathSegments) {
        ['v2', ...final rest] =>
          super.parseRouteFromUri(uri.replace(pathSegments: rest)),
        _ => null,
      };
}
```

Give V1 and V2 distinct path labels (`shop-v1`, `shop-v2`).

Runnable sample:
[`main_coordinator_module.dart`](../../example/lib/main_coordinator_module.dart).

## See also

- [Modular coordinator](coordinator-modular.md)
- [Layouts](route-layout.md)
- [Route versioning](../recipes/route-versioning.md)
