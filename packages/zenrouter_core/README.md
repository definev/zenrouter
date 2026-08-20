# zenrouter_core

[![pub package](https://img.shields.io/pub/v/zenrouter_core.svg)](https://pub.dev/packages/zenrouter_core)
[![Test](https://github.com/definev/zenrouter/actions/workflows/test.yml/badge.svg)](https://github.com/definev/zenrouter/actions/workflows/test.yml)
[![codecov](https://codecov.io/gh/definev/zenrouter/graph/badge.svg?flag=zenrouter_core)](https://app.codecov.io/gh/definev/zenrouter?flag=zenrouter_core)

**The graph, without Flutter.**

Routing engine for [zenrouter](https://pub.dev/packages/zenrouter). Same model on a server, in tests, or behind any UI.

Flutter apps should depend on `zenrouter`, which re-exports this package.

## Install

```yaml
dependencies:
  zenrouter_core: ^3.0.0-beta.1
```

## RouteTarget

A destination. Identity is `runtimeType` + `props`.

```dart
class ProfileRoute extends RouteTarget {
  ProfileRoute({required this.userId});
  final int userId;

  @override
  List<Object?> get props => [userId];
}
```

## StackPath

A stack of `RouteTarget`s. `StackMutatable` adds `push`, `pop`, `navigate`, `pushReplacement`, `pushOrMoveToTop`, `replaceAll`.

```dart
path.stack;
path.activeRoute;
```

## CoordinatorCore

Holds paths and implements `parseRouteFromUri`. Navigation methods live on mixins. Flutter `Coordinator` mixes all of them.

| Mixin | Methods |
|-------|---------|
| `CoordinatorLayoutCore` | Layout-parent activation |
| `CoordinatorNavigatable` | `navigate` |
| `CoordinatorMutatable` | `push`, `pop`, `replace`, `pushReplacement`, `pushOrMoveToTop`, `tryPop` |
| `CoordinatorRecoverable` | `recover`, `recoverUri`, `defineDeeplinkHandler` |

```dart
class HeadlessCoordinator extends CoordinatorCore<AppRoute>
    with CoordinatorLayoutCore<AppRoute>, CoordinatorMutatable<AppRoute> {
  @override
  Future<AppRoute?> parseRouteFromUri(Uri uri) async { /* ... */ }
}
```

Nested mutations publish one `NavigationCommit`. `uri.pushWith(coordinator)` parses, then delegates.

## Route mixins

| Mixin | Role |
|-------|------|
| `RouteUri` | URI identity + layout child |
| `RouteGuard` | `popGuard` / `popGuardWith` |
| `RouteRedirect` | Replace the route before push |
| `RouteDeepLink` | `replace` / `navigate` / `push` / `custom` |
| `RouteLayoutParent` / `RouteLayoutChild` | Nested shells (`layoutKey` is `Object`) |
| `RouteRedirectRule` / `RouteGuardRule` | Composable rule chains |
| `RouteNotFound` | 404; keep the requested URI |

## CoordinatorModular

```dart
class AppCoordinator extends CoordinatorCore<AppRoute>
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

Each module implements `parseRouteFromUri` and returns `null` for URLs it does not own. First non-null wins.

## RouteManifest

Recommended for new coordinators. The graph is IDs, URI patterns, and layout parents. Matching and `location()` share the same pattern, so `toUri()` cannot drift from the parser. Construction rejects duplicate IDs, unknown parents, cycles, and equally specific overlapping paths.

Parser-only coordinators keep `RouteManifest.empty`.

```dart
enum AppRouteId { home, profile }

final manifest = RouteManifest<AppRouteId>(
  name: 'app',
  idCodec: RouteIdCodec.enumValues(AppRouteId.values),
  routes: [
    RouteManifestRoute(id: AppRouteId.home, path: '/'),
    RouteManifestRoute(
      id: AppRouteId.profile,
      path: '/profiles/:profileId',
    ),
  ],
);

final uri = manifest.location(
  AppRouteId.profile,
  pathParameters: {'profileId': '42'},
);
```

`:name` is one segment. `...:name` is a catch-all. Query and fragment are not in the pattern.

Layouts: `RouteManifestLayout.stack` / `.indexed` / `.branched`. Indexed children must be direct children. Branched children must be layouts.

`fromFragments` composes module fragments and validates the complete graph. `encode()` / `decode()` use `RouteIdCodec`.

## RouteBinding

The manifest has no widgets. A binding is the factory from a match to a `RouteTarget`. Bind every route ID; do not bind layouts.

```dart
late final routeBindings = manifest.bind<AppRoute>(
  bindings: [
    RouteBinding(id: AppRouteId.home, create: (_) => HomeRoute()),
    RouteBinding(
      id: AppRouteId.profile,
      create: (match) => ProfileRoute(match.pathParameters['profileId']!),
    ),
  ],
  notFound: NotFoundRoute.new,
);
```

`RouteModuleBinding` sets `routeManifest` and `parseRouteFromUri` from `routeBindings`. Standalone registries pass `notFound`. Child modules omit it. `RouteBinding.deferred` loads a library first.

Do not mix `RouteModuleBinding` and `CoordinatorModular` on the same class. A contribution that references a foreign layout should expose `routeManifestFragment`, not a complete `RouteManifest`.

This graph is what the DevTools Graph tab renders.

## Route resolution

`CoordinatorCore` implements `RouteResolver`. Override `resolveRoute` for SSR (`RouteRequest` → matched / redirect / not-found / error). `RouteNotFound` keeps the requested URI and reports 404.

## Migrating from 2.x

`parseRouteFromUri` is unchanged. A manifest is optional.

| Deprecated | Replacement |
|------------|-------------|
| `defineLayout()` | Flutter: `..bindLayout(...)` on the path. Headless: `defineLayoutParentConstructor` in `init()` |
| `defineConverter()` | `defineRestorableConverter(...)` in `init()` |

Custom `CoordinatorCore` subclasses must mix in the capabilities they call. `Equatable.internalProps` is removed. `pop()` completes `onResult`. `defineModules` returns `Iterable`.

[Migration guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/MIGRATION_GUIDE.md#300-manifests-capability-mixins-and-lifecycle)

## Custom renderer

1. Extend `RouteTarget`.
2. Extend `CoordinatorCore` with the mixins you need.
3. Implement `parseRouteFromUri`.
4. Render the active `StackPath`.
5. Feed links and back through `recoverUri` / `tryPop`.

Flutter implements 4–5 in [`zenrouter`](https://pub.dev/packages/zenrouter).
