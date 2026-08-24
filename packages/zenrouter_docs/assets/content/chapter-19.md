ZenRouter 3.0 can be adopted incrementally. A typical Flutter app that only extends `Coordinator` keeps the full common capability set, and handwritten `parseRouteFromUri` remains supported. Migrate one vertical slice and compare observable contracts before removing old code.

## Pin and baseline

Pin the prerelease and run the existing suite before changing APIs:

```yaml
dependencies:
  zenrouter: ^3.0.0-beta.1
```

Record for each public flow:

- accepted URI and generated location;
- active path and route sequence;
- back behavior and result completion;
- restoration payload;
- redirects, guards, and not-found behavior.

This baseline prevents a compile-successful migration from silently changing product behavior.

## Adopt manifests without rewriting screens

Handwritten parsing still works. The first high-value migration is to place one feature's patterns in a manifest and add bindings that construct the existing route classes:

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with RouteModuleBinding<AppRoute, AppRouteId> {
  static final manifest = RouteManifest<AppRouteId>(
    name: 'app',
    idCodec: RouteIdCodec.enumValues(AppRouteId.values),
    routes: [
      RouteManifestRoute(id: AppRouteId.home, path: '/'),
      RouteManifestRoute(
        id: AppRouteId.product,
        path: '/products/:id',
      ),
    ],
  );

  @override
  late final routeBindings = manifest.bind<AppRoute>(
    bindings: [
      RouteBinding(id: AppRouteId.home, create: (_) => HomeRoute()),
      RouteBinding(
        id: AppRouteId.product,
        create: (match) => ProductRoute(
          match.pathParameters['id']!,
        ),
      ),
    ],
    notFound: NotFoundRoute.new,
  );
}
```

Do not also override `parseRouteFromUri` on that class. `RouteModuleBinding` supplies manifest-backed parsing.

## Replace deprecated hooks

| Older shape | 3.0 direction |
| --- | --- |
| `defineLayout()` + parent registration | `NavigationPath.createWith(...)..bindLayout(Layout.new)` |
| `defineConverter()` hook | `defineRestorableConverter(...)` inside `init()` after `super.init()` |
| handwritten reverse URI helpers | manifest or generated `coordinator.location.*` |
| global parser switch for all features | module manifests and composed fragments |

Deprecated hooks may still run for compatibility, but moving ownership beside the path or converter makes lifecycle and tests explicit.

## Update navigation lifecycle assumptions

`pushOrMoveToTop` returns `Future<void>`. Await it when later work depends on the committed stack:

```dart
await coordinator.pushOrMoveToTop(SettingsRoute());
```

`pop()` now completes the pushed route's result and calls `onDidPop` immediately. Remove manual second completion:

```dart
final resultFuture = coordinator.push<String>(EditorRoute());
await coordinator.pop('saved');
expect(await resultFuture, 'saved');
```

Calling `completeOnResult` afterward throws because the future is already complete.

## Equality and page identity

Route value equality uses `runtimeType` and `props`. Mutable path binding and result completers are not hashed. Remove `internalProps` overrides; that API is gone.

Imperative stacks use page-entry identity, so equal semantic routes may coexist after repeated pushes. Declarative stacks still diff route values by equality. Custom `PageCallback` implementations should accept `LocalKey`, not `ValueKey<RouteTarget>`.

## Custom CoordinatorCore types

Flutter's `Coordinator` still composes layout, navigate, mutate, recover, restoration, and transitions. Custom headless cores now choose capability mixins:

```dart
class AppCore extends CoordinatorCore<AppRoute>
    with
        CoordinatorLayoutCore<AppRoute>,
        CoordinatorNavigatable<AppRoute>,
        CoordinatorMutatable<AppRoute>,
        CoordinatorRecoverable<AppRoute> {}
```

Only custom `CoordinatorCore` subclasses need this explicit composition.

## Modular changes

`defineModules` returns `Iterable<RouteModule<T>>` and is snapshotted once. Existing list literals still work. Duplicate module runtime types fail during initialization.

Prefer manifest-backed child modules for new work. Keep `CoordinatorModular` on the root and `RouteModuleBinding` on children rather than mixing both parser owners onto one class.

## Browser and guard behavior

Blocked browser traversal restores the current application URI using replacement semantics when required, avoiding back-button loops. Custom route-information providers that remap traversal should follow the current URI comparison behavior.

## Staged rollout

1. Pin 3.0 and make the existing suite green.
2. Update removed/changed signatures and lifecycle assumptions.
3. Bind layouts and converters through their new ownership seams.
4. Move one feature to a manifest and binding registry.
5. Add round-trip and commit assertions for that feature.
6. Compose feature fragments only after local graphs are stable.
7. Remove the old parser branch when every legacy URI still resolves.

## Checkpoint

One migrated feature accepts all previous public links, generates the same canonical locations, preserves back/results/restoration behavior, and has manifest round-trip tests. Only then choose the next vertical slice.

Next, **Coming from another router** maps familiar concepts to ZenRouter without performing a syntax-only port.
