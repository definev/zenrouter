# Advanced Patterns

Deep-dive reference for patterns beyond the core workflow. Read [SKILL.md](./SKILL.md) first.

---

## RouteManifestFragment

A fragment is one feature's contribution to the application graph. It validates
local shape and ID uniqueness. Parent links, indexed/branch children, cycles,
and ambiguous paths are validated only after `CoordinatorModular` (or
`RouteManifest.fromFragments`) composes the full graph.

Use a **complete** `RouteManifest` + `RouteModuleBinding` when every
`parentId` and indexed/branch child lives in that same module.

Override `routeManifestFragment` when the contribution points at a layout
declared by another module. Do **not** wrap that fragment in
`RouteManifest(...)` — construction validates parents immediately and will
throw. Prefer putting the child route in the module that owns the layout.
If the child must live elsewhere, contribute a fragment and parse locally:

```dart
enum SharedId { shell, account }

class ShellModule extends RouteModule<AppRoute> {
  ShellModule(super.coordinator);

  @override
  RouteManifestFragment<SharedId> get routeManifestFragment =>
      RouteManifestFragment(
        name: 'shell',
        idCodec: RouteIdCodec.enumValues(SharedId.values),
        layouts: [
          RouteManifestLayout.stack(id: SharedId.shell, path: '/account'),
        ],
      );

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) => null;
}

class AccountModule extends RouteModule<AppRoute> {
  AccountModule(super.coordinator);

  @override
  RouteManifestFragment<SharedId> get routeManifestFragment =>
      RouteManifestFragment(
        name: 'account',
        idCodec: RouteIdCodec.enumValues(SharedId.values),
        routes: [
          RouteManifestRoute(
            id: SharedId.account,
            path: '/account/profile',
            parentId: SharedId.shell, // owned by ShellModule
          ),
        ],
      );

  @override
  FutureOr<AppRoute?> parseRouteFromUri(Uri uri) =>
      switch (uri.pathSegments) {
        ['account', 'profile'] => AccountRoute(),
        _ => null,
      };
}
```

`CoordinatorModular.routeManifest` is `RouteManifest<Object>.fromFragments`
of `localRouteManifestFragment` plus every nested module fragment. IDs stay
their original runtime values (enums are not stringified).

Hand-composed apps without modules bind **after** `fromFragments` (the
composed graph is complete, so `RouteModuleBinding` on the coordinator is valid):

```dart
static final manifest = RouteManifest<Object>.fromFragments(
  name: 'app',
  fragments: [
    appShellManifestFragment,
    accountsManifestFragment,
  ],
);

@override
late final routeBindings = manifest.bind<AppRoute>(
  bindings: <RouteBinding<Object, AppRoute>>[
    RouteBinding<AppShellRouteId, AppRoute>(
      id: AppShellRouteId.home,
      create: (_) => HomeRoute(),
    ),
    RouteBinding<AccountsRouteId, AppRoute>(
      id: AccountsRouteId.profile,
      create: (match) =>
          ProfileRoute(id: match.pathParameters['profileId']!),
    ),
  ],
  notFound: NotFoundRoute.new,
);
```

---

## Typed IDs and RouteIdCodec

`RouteManifest<I>` IDs are domain values, not intrinsically strings.

| Style | `I` | When |
|:------|:----|:-----|
| Hand-written feature | enum (`ShopRouteId`) | Default for new modules |
| File generator | `String` (class name) | `@ZenRoute` projects |
| Composed app | `Object` | Union of feature-owned ID types |

`RouteIdCodec` is only required at the JSON seam (`encode` / `fromJson`).
Matching and `location()` never need it. Still attach
`RouteIdCodec.enumValues(MyId.values)` on handwritten fragments so tooling
and `manifest.encode()` work.

```dart
final decoded = RouteManifest<Object>.decode(manifest.encode());
```

When every composed fragment has a codec, non-String wire IDs are scoped by
fragment name. Homogeneous `String` graphs keep their existing wire IDs.

---

## Deferred Bindings

`RouteBinding.create` may be async. Use `RouteBinding.deferred` so a deferred
library loads before the factory runs:

```dart
RouteBinding.deferred(
  id: ShopRouteId.home,
  loadLibrary: shop_home.loadLibrary,
  create: (_) => shop_home.ShopHomeRoute(),
);

notFound: deferredRouteNotFoundBinding(
  loadLibrary: missing.loadLibrary,
  create: (uri) => missing.NotFoundRoute(uri),
);
```

File-based coordinators emit this automatically when `deferredImport: true`.

---

## Coordinator as Module

When a feature group itself has sub-modules, use a `Coordinator<T>` with
`CoordinatorModular<T>` and override `coordinator` to point at the parent.
Keep destinations on child `RouteModuleBinding` modules — do not mix
`RouteModuleBinding` onto this grouping coordinator.

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
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}
```

Register in the parent's `defineModules()`:

```dart
@override
Iterable<RouteModule<AppRoute>> defineModules() => [
  AuthModule(this),
  ShopCoordinator(this),
];
```

**Rules:**
- Overriding `coordinator` sets `isRouteModule = true` — the child does not
  create its own root `NavigationPath`.
- Always spread `super.paths` so child module paths are included.
- Access sibling modules via `coordinator.getModule<OtherModule>()`.
- Parsing walks sub-modules then, because `isRouteModule` is true, returns
  `null` so the parent can try the next sibling. `notFoundRoute` on a nested
  coordinator is unused.

---

## RouteModule

`RouteModule<T>` encapsulates a feature's routes, paths, layouts, and
restorable converters. Prefer `RouteModuleBinding` so URI parsing comes from
the module manifest. Parser-era modules may keep a hand-written
`parseRouteFromUri` and optionally expose topology via `routeManifest` /
`routeManifestFragment`.

### API

```dart
abstract class RouteModule<T extends RouteUri> {
  RouteModule(CoordinatorModular<T> coordinator);

  /// Always points to the root coordinator (even when nested).
  final CoordinatorModular<T> coordinator;

  List<StackPath> get paths; // default: []

  RouteManifest<Object> get routeManifest; // default: RouteManifest.empty
  RouteManifestFragment<Object> get routeManifestFragment; // default: routeManifest.fragment

  FutureOr<T?> parseRouteFromUri(Uri uri);
}
```

`RouteModuleBinding` overrides `routeManifest` and `parseRouteFromUri` from
`routeBindings`.

### Layouts

Bind the layout on the path with `bindLayout`. Do **not** override the
deprecated `defineLayout` hook:

```dart
late final settingsPath = NavigationPath<AppRoute>.createWith(
  label: 'settings',
  coordinator: coordinator,
)..bindLayout(SettingsLayout.new);
```

Headless `CoordinatorCore` code without Flutter `bindLayout` can still
register a constructor in `init()`:

```dart
@override
void init() {
  super.init();
  defineLayoutParentConstructor(SettingsLayout, (_) => SettingsLayout());
}
```

### Converters

Register restorable converters in `init()`:

```dart
@override
void init() {
  super.init();
  defineRestorableConverter('book_detail', BookDetailConverter.new);
}
```

### Rules

| Rule | Why |
|:-----|:----|
| Register layouts with `bindLayout` | `defineLayout` is deprecated |
| Register converters in `init()` | `defineConverter` is deprecated |
| `getModule<T>()` throws `TypeError` if `T` is missing | Register the module in `defineModules()` first |
| Cross-module `parentId` uses a fragment | A complete `RouteManifest` cannot see foreign IDs |

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
  Uri toUri() => ShopModule.manifest.location(ShopRouteId.home);

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

## GuardRule

Composable pop guards applied via `RouteGuardRule<T>` mixin on a route.

Prefer **route-only** methods when no coordinator is needed. Override the
`With` variants when dialogs or shared app state require a coordinator
(defaults delegate to the non-`With` methods).

### Writing a rule

```dart
class UnsavedChangesRule extends GuardRule<AppRoute> {
  @override
  bool canPopRule(AppRoute route) =>
      route is! EditableRoute || !route.hasUnsavedChanges;

  @override
  ListenableMixin? canPopListenableRule(AppRoute route) =>
      route is EditableRoute ? route.dirty.toListenableMixin() : null;

  @override
  Future<bool?> guardRuleWith(
    covariant AppCoordinator coordinator,
    AppRoute route,
  ) async {
    if (route is! EditableRoute || !route.hasUnsavedChanges) {
      return null; // not applicable — next rule
    }
    return showDiscardDialog(coordinator.context); // true allow / false block
  }
}
```

| `bool?` (`guardRule` / `guardRuleWith`) | Meaning |
|:----------------------------------------|:--------|
| `null` | Pass to next rule |
| `true` | Allow pop; stops chain |
| `false` | Block pop; stops chain |

| Sync `canPopRule` | Meaning |
|:------------------|:--------|
| `true` (default) | This rule does not force intercept |
| `false` | Force `PopScope` intercept |

Rules are evaluated in list order; first non-`null` result wins. If every rule returns `null`, the pop is allowed. `RouteGuardRule.canPop` is `true` only when every rule's `canPopRule` is `true`.

### Applying rules to a route

```dart
class EditorRoute extends AppRoute with RouteGuardRule<AppRoute> {
  @override
  Uri toUri() => AppCoordinator.manifest.location(AppRouteId.editor);

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) =>
      const SizedBox.shrink();

  @override
  List<GuardRule<AppRoute>> get guardRules => [
    UnsavedChangesRule(),
    ConfirmLeaveRule(),
  ];
}
```

Full multi-rule sample (upload + unsaved + audit + reactive `canPop`):
[`example/lib/main_guard_rules.dart`](../../packages/zenrouter/example/lib/main_guard_rules.dart)
· [recipe](../../packages/zenrouter/doc/recipes/route-guard-rules.md)

---

## IndexedStackPath (Tab Navigation)

Declare fixed children on the **kind**, and keep the same ordered list in the
runtime path.

```dart
enum TabsRouteId { layout, home, shop, profile }

static final manifest = RouteManifest<TabsRouteId>(
  name: 'tabs',
  idCodec: RouteIdCodec.enumValues(TabsRouteId.values),
  routes: [
    RouteManifestRoute(
      id: TabsRouteId.home,
      path: '/tabs/home',
      parentId: TabsRouteId.layout,
    ),
    RouteManifestRoute(
      id: TabsRouteId.shop,
      path: '/tabs/shop',
      parentId: TabsRouteId.layout,
    ),
    RouteManifestRoute(
      id: TabsRouteId.profile,
      path: '/tabs/profile',
      parentId: TabsRouteId.layout,
    ),
  ],
  layouts: [
    RouteManifestLayout.indexed(
      id: TabsRouteId.layout,
      path: '/tabs',
      childIds: [TabsRouteId.home, TabsRouteId.shop, TabsRouteId.profile],
    ),
  ],
);

late final tabStack = IndexedStackPath<AppRoute>.createWith(
  coordinator: this,
  label: 'main-tabs',
  [HomeTab(), ShopTab(), ProfileTab()],
)..bindLayout(TabBarLayout.new);

@override
List<StackPath> get paths => [...super.paths, tabStack];

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

Every indexed `childId` must be a **direct** child (`parentId` equals the
layout id).

---

## BranchedStackPath (Stateful Shell Navigation)

Use `BranchedStackPath` when every fixed destination is a layout root with its
own child `NavigationPath`. Branch switching retains each branch's depth.

```dart
enum ShellRouteId { shell, homeBranch, settingsBranch }

RouteManifestLayout.branched(
  id: ShellRouteId.shell,
  path: '/',
  childIds: [ShellRouteId.homeBranch, ShellRouteId.settingsBranch],
);
RouteManifestLayout.stack(
  id: ShellRouteId.homeBranch,
  path: '/home',
  parentId: ShellRouteId.shell,
);
RouteManifestLayout.stack(
  id: ShellRouteId.settingsBranch,
  path: '/settings',
  parentId: ShellRouteId.shell,
);

late final branches = BranchedStackPath<AppRoute>.createWith(
  [HomeBranchLayout(), SettingsBranchLayout()],
  coordinator: this,
  label: 'app-branches',
)..bindLayout(AppShellLayout.new);

await branches.goToBranch(1);
```

Each branch entry must implement `RouteLayoutParent`. Every direct child of a
branched layout must be one of the declared branch layouts — leaf routes cannot
sit directly under the shell. Register every branch's child path in
`Coordinator.paths`.

---

## Parameter Routes

Files wrapped in `[]` / `[...]` are a naming convention. The source of truth
is the manifest pattern.

| File | Pattern | Binding |
|:-----|:--------|:--------|
| `transactions/[id].dart` | `/transaction/:id` | `match.pathParameters['id']!` |
| `posts/[slug].dart` | `/blog/posts/:slug` | `match.pathParameters['slug']!` |
| `users/[userId]/orders/[orderId].dart` | `/users/:userId/orders/:orderId` | both path parameters |
| `blog/[...slug].dart` | `/blog/...:slug` | `match.restParameters['slug']!` |
| `docs/[...slugs]/[id].dart` | `/docs/...:slugs/:id` | rest + path |

Named `:id` routes are in [SKILL.md §4](./SKILL.md#4-route-definition). Catch-all:

```dart
class BlogRoute extends AppRoute {
  BlogRoute({required this.slug});
  final List<String> slug;

  @override
  List<Object?> get props => [slug];

  @override
  Type? get layout => BlogLayout;

  @override
  Uri toUri() => BlogModule.manifest.location(
    BlogRouteId.article,
    restParameters: {'slug': slug},
  );

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) =>
      BlogPage(slug: slug);
}

RouteBinding(
  id: BlogRouteId.article,
  create: (match) => BlogRoute(slug: match.restParameters['slug']!),
);
```

---

## Manifest Construction Failures

These throw at coordinator/module init — fix the graph, do not catch them:

| Exception | Typical cause |
|:----------|:--------------|
| `RouteManifestValidationException` | Duplicate IDs, unknown `parentId`, indexed child not a direct child, branch child not a layout, parent cycle, equally specific overlapping paths |
| `RouteBindingValidationException` | Duplicate binding, unknown ID, binding a layout, unbound route |
| `ArgumentError` on `RoutePattern` | Path missing `/`, contains `?`/`#`, empty segments, bad/duplicate parameter names, two rest params |

`CoordinatorModular` validates after flattening every fragment, so a
cross-module `parentId` that looks fine in isolation still fails if the
target layout was never contributed.
