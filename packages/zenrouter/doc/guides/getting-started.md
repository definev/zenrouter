# Getting Started

Pick a navigation style and follow that section to the end before
opening another.

## Install

```bash
flutter pub add zenrouter
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
| Typical use | Flows, onboarding | Wizards, state-driven stacks | Web, large apps |

You can mix them later (for example a coordinator app with an
imperative modal). Start with one.

## Imperative

```dart
import 'package:flutter/material.dart';
import 'package:zenrouter/zenrouter.dart';

sealed class AppRoute extends RouteTarget {
  Widget build(BuildContext context);
}

class HomeRoute extends AppRoute {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: ElevatedButton(
          onPressed: () => path.push(ProfileRoute()),
          child: const Text('Profile'),
        ),
      ),
    );
  }
}

class ProfileRoute extends AppRoute {
  @override
  Widget build(BuildContext context) {
    return Scaffold(appBar: AppBar(title: const Text('Profile')));
  }
}

final path = NavigationPath<AppRoute>.create();

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: NavigationStack(
        path: path,
        defaultRoute: HomeRoute(),
        resolver: (route) => StackTransition.material(route.build(context)),
      ),
    );
  }
}
```

```dart
path.push(ProfileRoute());
path.navigate(HomeRoute());
path.pop();
```

[Imperative guide](../paradigms/imperative.md) ·
[Example](../../example/lib/main_imperative.dart)

## Declarative

Rebuild the route list from state. ZenRouter diffs it (Myers) and
applies the minimum operations. Parameterized routes must override
`props`.

```dart
class PageRoute extends RouteTarget {
  PageRoute(this.pageNumber);
  final int pageNumber;

  @override
  List<Object?> get props => [pageNumber];
}

NavigationStack.declarative(
  routes: [
    for (final n in pages) PageRoute(n),
  ],
  resolver: (route) => StackTransition.material(
    PageScreen(pageNumber: (route as PageRoute).pageNumber),
  ),
);
```

[Declarative guide](../paradigms/declarative.md) ·
[Example](../../example/lib/main_declrative.dart)

## Coordinator

`Coordinator` is `RouterConfig`. Routes mix `RouteUnique` and implement
`toUri()`. Implement `parseRouteFromUri` to map a URI to a route.

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

class ProductRoute extends AppRoute {
  ProductRoute({required this.id});
  final String id;

  @override
  List<Object?> get props => [id];

  @override
  Uri toUri() => Uri.parse('/products/$id');

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(appBar: AppBar(title: Text('Product $id')));
  }
}

class NotFoundRoute extends AppRoute with RouteNotFound {
  NotFoundRoute(this.uri);
  final Uri uri;

  @override
  Uri toUri() => uri;

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(body: Center(child: Text('No route matches $uri')));
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

void main() {
  runApp(MaterialApp.router(routerConfig: AppCoordinator()));
}
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
| `recover` / `recoverUri` | Deep-link entry |
| `pushUri` / `navigateUri` | Parse, then push or navigate |

[Coordinator guide](../paradigms/coordinator/coordinator.md) ·
[Example](../../example/lib/main_coordinator.dart)

New Coordinator apps should declare a
[RouteManifest](#routemanifest) instead of growing that `switch`.

## Layouts

A layout is a shell that stays on screen while its children change.
This is independent of how you parse URIs.

```dart
late final shopStack = NavigationPath<AppRoute>.createWith(
  label: 'shop',
  coordinator: this,
)..bindLayout(ShopLayout.new);

@override
List<StackPath> get paths => [...super.paths, shopStack];

class ShopLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  NavigationPath<AppRoute> resolvePath(covariant AppCoordinator c) =>
      c.shopStack;

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: buildPath(coordinator),
    );
  }
}

class ShopHomeRoute extends AppRoute {
  @override
  Type? get layout => ShopLayout;
}
```

[Layouts](route-layout.md)

## DevTools

```bash
flutter pub add zenrouter_devtools
```

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorDebug<AppRoute> {}
```

Inspect stacks and push a URI. Off in release.

## RouteManifest

The recommended way to declare Coordinator routes in 3.0.

A `parseRouteFromUri` switch and each `toUri()` are two copies of the
same paths. They drift. Overlaps fail when a user opens the URL, not
when the app starts. Nested shells have no static check against the
URL tree.

`RouteManifest` is the graph (IDs, patterns, layout parents).
`RouteBinding` constructs the `RouteTarget`. Matching,
`manifest.location(...)`, and the DevTools Graph tab share that
declaration.

| Benefit | What it replaces |
|---------|------------------|
| One pattern for match and `location()` | `switch` + `Uri.parse` in every `toUri()` |
| Invalid graph fails at startup | Broken link found in production |
| Typed `pathParameters` / `restParameters` | Manual `uri.pathSegments` indexing |
| Feature fragments compose into one graph | One giant parser |
| Graph tab (topology + observed flow) | Guessing the tree from stack dumps |

`parseRouteFromUri` still works. Use a manifest for new graphs.

```dart
enum AppRouteId { home, product }

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

Do not also override `parseRouteFromUri` on this class.
`RouteModuleBinding` already implements it.

Use `manifest.location` in `toUri()`. Bind every `RouteManifestRoute`.
Do not bind layout IDs. A standalone registry needs `notFound`
(`RouteNotFound`).

| Pattern | Matches | Binding |
|---------|---------|---------|
| `/shop` | `/shop` | — |
| `/products/:id` | `/products/42` | `match.pathParameters['id']` |
| `/docs/...:slugs` | `/docs`, `/docs/a/b` | `match.restParameters['slugs']` |

Query strings are not in the pattern. Read
`match.uri.queryParameters` or use
[RouteQueryParameters](query-parameters.md).

Layouts on a manifest: `RouteManifestLayout` plus `parentId` on
children, matching the same shell as `layout` / `bindLayout`.

A non-empty `routeManifest` enables the Graph tab in DevTools.

[`zenrouter_file_generator`](https://pub.dev/packages/zenrouter_file_generator)
generates this coordinator, manifest, and bindings from `lib/routes/`.

[Manifest example](../../example/lib/main_route_manifest.dart)

## Migrating from 2.x

`extend Coordinator` and `parseRouteFromUri` are unchanged.

| Deprecated | Replacement |
|------------|-------------|
| `defineLayout()` | `..bindLayout(ShopLayout.new)` on the path |
| `defineConverter()` | `defineRestorableConverter(...)` in `init()` |
| `createLayout` / `resolveLayout` | `createParentLayout` / `resolveParentLayout` |

[Migration guide](../../MIGRATION_GUIDE.md#300-manifests-capability-mixins-and-lifecycle)

## See also

- [Layouts](route-layout.md)
- [Modular coordinator](coordinator-modular.md)
- [Query parameters](query-parameters.md)
- [Recipes](../recipes/)
- [From go_router](../migration/from-go-router.md)
