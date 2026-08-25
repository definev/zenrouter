<div align="center">

<img alt="ZenRouter Logo" src="https://raw.githubusercontent.com/definev/zenrouter/main/assets/zenrouter_light_solid.png">

**Type-safe navigation for Flutter apps.**

[![pub package](https://img.shields.io/pub/v/zenrouter.svg)](https://pub.dev/packages/zenrouter)
[![Test](https://github.com/definev/zenrouter/actions/workflows/test.yml/badge.svg)](https://github.com/definev/zenrouter/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/definev/zenrouter/graph/badge.svg?flag=zenrouter)](https://app.codecov.io/gh/definev/zenrouter?flag=zenrouter)

</div>

---

Define each screen as a type and compose routes as a graph. That gives you
type-safe navigation, deep linking, browser back-button support, and a clear
view of how screens connect.

## Install

3.0 is a prerelease. `flutter pub add zenrouter` still resolves 2.x.

```yaml
dependencies:
  zenrouter: ^3.0.0-beta.1
```

## Which style

```
Need deep linking, URL sync, or the browser back button?
│
├─ YES → Coordinator
│
└─ NO → Is the stack derived from state?
       │
       ├─ YES → Declarative
       │
       └─ NO  → Imperative
```

| | Imperative | Declarative | Coordinator |
|---|:---:|:---:|:---:|
| Control | `path.push` / `pop` | Rebuild a route list | `coordinator.push` / URI |
| Web / deep links | | | Yes |

## Imperative

```dart
final path = NavigationPath<AppRoute>.create();

NavigationStack(
  path: path,
  resolver: (route) => StackTransition.material(route.build(context)),
);

path.push(ProfileRoute());
path.pop();
```

[Example](example/lib/main_imperative.dart) ·
[Guide](doc/paradigms/imperative.md)

## Declarative

`NavigationStack.declarative` diffs the list (Myers) and applies the minimum push/pop set. Override `props` on parameterized routes.

```dart
NavigationStack.declarative(
  routes: [
    for (final page in pages) PageRoute(page),
  ],
  resolver: (route) => StackTransition.material(...),
);
```

[Example](example/lib/main_declrative.dart) ·
[Guide](doc/paradigms/declarative.md)

## Coordinator

`Coordinator` is `RouterConfig`. Routes mix `RouteUnique` and implement `toUri()`. `parseRouteFromUri` turns a URI into a route.

```dart
abstract class AppRoute extends RouteTarget with RouteUnique {}

class HomeRoute extends AppRoute {
  @override
  Uri toUri() => Uri.parse('/');

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      body: ListTile(
        title: const Text('Product 42'),
        onTap: () => coordinator.push(ProductRoute(id: '42')),
      ),
    );
  }
}

class AppCoordinator extends Coordinator<AppRoute> {
  @override
  AppRoute parseRouteFromUri(Uri uri) {
    return switch (uri.pathSegments) {
      [] => HomeRoute(),
      ['products', final id] => ProductRoute(id: id),
      _ => NotFoundRoute(uri),
    };
  }
}

MaterialApp.router(routerConfig: AppCoordinator())
```

```dart
coordinator.push(ProductRoute(id: '42'));
coordinator.navigate(HomeRoute());
coordinator.replace(HomeRoute());
coordinator.pop();
await coordinator.pushUri(Uri.parse('/products/42'));
```

| Method | Behavior |
|--------|----------|
| `push` | Push onto the resolved stack |
| `navigate` | Pop to an existing equal route, or push |
| `replace` | Reset to a single route |
| `recover` / `recoverUri` | Deep-link entry (`RouteDeepLink`) |

`build` is typed to your coordinator subclass.

[Example](example/lib/main_coordinator.dart) ·
[Coordinator guide](doc/paradigms/coordinator/coordinator.md)

New Coordinator apps should declare a [RouteManifest](#routemanifest) instead of growing that `switch`.

## Layouts

A `RouteLayout` owns a `StackPath`. Bind the constructor on the path and set `layout` on children.

```dart
late final shopStack = NavigationPath<AppRoute>.createWith(
  label: 'shop',
  coordinator: this,
)..bindLayout(ShopLayout.new);

class ShopHomeRoute extends AppRoute {
  @override
  Type? get layout => ShopLayout;
}
```

| Path | Use |
|------|-----|
| `NavigationPath` | Nested stack |
| `IndexedStackPath` | Tabs |
| `BranchedStackPath` | Tabs that keep their own stacks |

[Layouts](doc/guides/route-layout.md)

## Route mixins

| Mixin | Role |
|-------|------|
| `RouteUnique` | URI identity; required on Coordinator routes |
| `RouteLayout` | Shell; `resolvePath` + `buildPath` |
| `RouteGuard` | `popGuard` / `popGuardWith` |
| `RouteRedirect` | Replace the route before it is pushed |
| `RouteDeepLink` | Deep-link strategy |
| `RouteTransition` | Per-route page transition |
| `RouteRestorable` | State after process death |
| `RouteNotFound` | Keep the requested URI; resolve as 404 |

## DevTools

```bash
flutter pub add zenrouter_devtools
```

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorDebug<AppRoute> {}
```

The overlay inspects stacks and can push a URI. Off in release (`debugEnabled` defaults to `kDebugMode`).

## RouteManifest

The recommended way to declare Coordinator routes in 3.0.

A `parseRouteFromUri` switch and each route's `toUri()` are two copies of the same paths. They drift. Overlaps (`/products/new` vs `/products/:id`) fail when a user hits the link, not when you ship. Layouts have no check that the shell in code matches the URL tree.

`RouteManifest` is the URI graph. `RouteBinding` is the only place that constructs a `RouteTarget`. Matching, reverse URLs, and the DevTools Graph tab all read that graph.

| Benefit | What it replaces |
|---------|------------------|
| One pattern for match and `location()` | `switch` + `Uri.parse` in every `toUri()` |
| Invalid graph fails at startup | Broken link found in production |
| Typed `pathParameters` / `restParameters` | Manual `uri.pathSegments` indexing |
| Feature fragments compose into one graph | One giant parser |
| Graph tab (topology + observed flow) | Guessing the tree from stack dumps |

`parseRouteFromUri` still works. Use a manifest for new graphs.

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with RouteModuleBinding<AppRoute, AppRouteId> {
  static final manifest = RouteManifest<AppRouteId>(
    name: 'app',
    idCodec: RouteIdCodec.enumValues(AppRouteId.values),
    routes: [
      RouteManifestRoute(id: AppRouteId.home, path: '/'),
      RouteManifestRoute(id: AppRouteId.product, path: '/products/:id'),
    ],
  );

  @override
  late final routeBindings = manifest.bind<AppRoute>(
    bindings: [
      RouteBinding(id: AppRouteId.home, create: (_) => HomeRoute()),
      RouteBinding(
        id: AppRouteId.product,
        create: (match) => ProductRoute(id: match.pathParameters['id']!),
      ),
    ],
    notFound: NotFoundRoute.new,
  );
}
```

The manifest has no widgets. `RouteBinding` is the factory from a match to a screen. `RouteModuleBinding` implements `parseRouteFromUri`. Bind every `RouteManifestRoute`; do not bind layout IDs.

```dart
Uri toUri() => AppCoordinator.manifest.location(
  AppRouteId.product,
  pathParameters: {'id': id},
);
```

`:id` is one segment. `...:slugs` is a catch-all (`match.restParameters['slugs']`). Query strings are not part of the pattern.

With a manifest, also declare layouts as `RouteManifestLayout` and set `parentId` on children. A non-empty `routeManifest` enables the Graph tab in DevTools (topology + observed flow).

[`zenrouter_file_generator`](https://pub.dev/packages/zenrouter_file_generator) emits a coordinator, manifest, and bindings from `lib/routes/`.

[Getting Started](doc/guides/getting-started.md#routemanifest) ·
[Manifest example](example/lib/main_route_manifest.dart)

## Migrating from 2.x

Apps that `extend Coordinator` still compile. `parseRouteFromUri` is unchanged.

| Deprecated | Replacement |
|------------|-------------|
| `defineLayout()` | `NavigationPath.createWith(...)..bindLayout(ShopLayout.new)` |
| `defineConverter()` | `defineRestorableConverter(...)` in `init()` |
| `createLayout` / `resolveLayout` | `createParentLayout` / `resolveParentLayout` |

[Migration guide](MIGRATION_GUIDE.md#300-manifests-capability-mixins-and-lifecycle)

## Documentation

- [Getting Started](doc/guides/getting-started.md)
- [Imperative](doc/paradigms/imperative.md) ·
  [Declarative](doc/paradigms/declarative.md) ·
  [Coordinator](doc/paradigms/coordinator/coordinator.md)
- [Layouts](doc/guides/route-layout.md) ·
  [Modular coordinator](doc/guides/coordinator-modular.md)
- [Recipes](doc/recipes/)
- [From go_router](doc/migration/from-go-router.md) ·
  [From auto_route](doc/migration/from-auto-route.md)

## Packages

| Package | Role |
|---------|------|
| [`zenrouter`](https://pub.dev/packages/zenrouter) | Flutter `Coordinator`, `NavigationStack`, restoration |
| [`zenrouter_core`](https://pub.dev/packages/zenrouter_core) | `RouteTarget`, `CoordinatorCore`, paths, mixins, `RouteManifest` |
| [`zenrouter_devtools`](https://pub.dev/packages/zenrouter_devtools) | Overlay, Graph tab |
| [`zenrouter_file_generator`](https://pub.dev/packages/zenrouter_file_generator) | File-based codegen |

## License

Apache 2.0. [LICENSE](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/LICENSE)

[definev](https://github.com/definev)
