A route graph should scale along the same boundaries as the application. One Coordinator can remain the application boundary while feature modules contribute validated graph fragments, paths, bindings, and screens.

## Recognize the scaling problem

A single parser or manifest file becomes risky when:

- every feature team edits the same switch;
- route IDs are globally coordinated by convention;
- layouts and paths live far from the feature that owns them;
- a feature cannot be tested without constructing the entire app;
- an embedded surface needs navigation but must not own the root `Router`.

The solution is not multiple unrelated routers. Keep one composed public graph and divide authorship.

## Route modules

A `RouteModule` contributes parsing and paths to a root Coordinator. It returns `null` for URIs it does not own:

```dart
class ShopModule extends RouteModule<AppRoute>
    with RouteModuleBinding<AppRoute, ShopRouteId> {
  ShopModule(super.coordinator);

  static final manifest = RouteManifest<ShopRouteId>(
    name: 'shop',
    idCodec: RouteIdCodec.enumValues(ShopRouteId.values),
    routes: [
      RouteManifestRoute(id: ShopRouteId.home, path: '/shop'),
      RouteManifestRoute(
        id: ShopRouteId.product,
        path: '/shop/products/:id',
      ),
    ],
  );

  @override
  late final routeBindings = manifest.bind<AppRoute>(
    bindings: [
      RouteBinding(id: ShopRouteId.home, create: (_) => ShopHomeRoute()),
      RouteBinding(
        id: ShopRouteId.product,
        create: (match) => ProductRoute(
          match.pathParameters['id']!,
        ),
      ),
    ],
  );
}
```

Module registries omit a not-found target so later modules can match. The root owns the final not-found policy.

## Compose modules at the root

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Iterable<RouteModule<AppRoute>> defineModules() => [
    AuthModule(this),
    ShopModule(this),
    KnowledgeBaseModule(this),
  ];

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri);
}
```

The module list is snapshotted. Do not rebuild it on every access. Duplicate module runtime types are rejected.

Do not mix `RouteModuleBinding` onto the same root class as `CoordinatorModular`; both own `parseRouteFromUri`. Bind manifests on child modules and let the root dispatch.

## Manifest fragments

Modules can expose `RouteManifestFragment`s and the root can compose them into one validated topology:

```dart
final manifest = RouteManifest.fromFragments(
  name: 'app',
  fragments: [
    shellFragment,
    authFragment,
    shopFragment,
    knowledgeBaseFragment,
  ],
);
```

Each fragment validates its local shape and ID uniqueness. Root composition validates cross-feature parents, fixed child lists, branch roots, cycles, and URI conflicts.

This is where a conflict between `/teams/:id` and another feature's equivalent dynamic pattern should fail—not after one module happens to parse first in production.

## Feature-owned paths

A module may own a layout path while using the root Coordinator for transactions:

```dart
late final shopPath = NavigationPath<AppRoute>.createWith(
  label: 'shop',
  coordinator: coordinator,
)..bindLayout(ShopLayout.new);

@override
List<StackPath> get paths => [shopPath];
```

The root collects module paths. Routes can resolve the module when their layout needs its path:

```dart
coordinator.getModule<ShopModule>().shopPath
```

Prefer `coordinator.push` or URI operations for navigation so redirects, layouts, commits, and history remain centralized.

## Nested Coordinators

A nested Coordinator is appropriate when a feature has a coherent internal graph and lifecycle, not merely a folder of routes. It can continue URI resolution to a parent or collaborate through explicit module boundaries.

Keep public URLs composed at the owning application boundary. Two Coordinators should not both claim browser history for the same surface.

## Embed with CoordinatorView

`CoordinatorView` renders a Coordinator inside host-owned UI without installing another application-root `RouterConfig`:

```dart
CoordinatorView<AppRoute>(
  coordinator: knowledgeBaseCoordinator,
  initialUri: Uri.parse('/knowledge/getting-started'),
)
```

Use it for desktop panes, mini-apps, and incrementally migrated features. It builds the Coordinator layout and can apply an initial URI when the root is empty. It does not provide browser URL synchronization, system `popRoute`, or application-root restoration; the host owns those responsibilities.

## Test module contracts

Test a module manifest and bindings without the whole application, then add composition tests that prove:

- every fragment ID remains unique after encoding;
- public URI patterns do not conflict;
- cross-feature layout parents exist;
- every leaf route has one binding;
- the root not-found route receives locations no module owns.

## Failure modes

**Module order hides conflicts.** Prefer composed manifest validation over relying on first-match switches.

**Every folder becomes a nested Coordinator.** Ownership becomes fragmented and host/browser behavior unclear. Use modules for contributions and nested Coordinators for real lifecycle boundaries.

**Feature constructs the root Coordinator.** Dependency direction reverses. The application owns composition; features contribute fragments and modules.

**CoordinatorView is treated as another browser router.** It is an embedded renderer. The host remains responsible for external navigation integration.

## Checkpoint

Move one vertical slice—its manifest nodes, bindings, path, and layout—into a feature module. Compose it back and prove the same public URLs, targets, and layouts still resolve. The graph changed ownership, not behavior.

Next, **See what the router sees** uses DevTools to inspect both static topology and runtime navigation flow.
