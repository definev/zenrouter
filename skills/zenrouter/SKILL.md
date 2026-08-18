---
name: zenrouter
description: >
  Implement and extend routing with zenrouter's Coordinator, RouteManifest,
  and RouteBinding APIs. Use when adding a route, feature module, layout,
  redirect, guard, nested coordinator, deep link, or programmatic navigation.
  Triggers on: route, router, routing, coordinator, CoordinatorModular,
  RouteModule, RouteModuleBinding, RouteManifest,
  RouteManifestFragment, RouteBinding, RouteBindingRegistry, NavigationPath,
  IndexedStackPath, BranchedStackPath, RouteLayout, parentId, parentLayoutKey,
  layoutKey, bindLayout, RouteUnique, RouteNotFound, parseRouteFromUri, push,
  pop, replace, navigate, recover, recoverUri, location, deep link, toUri,
  zenrouter, @ZenRoute, @ZenLayout, @ZenCoordinator.
---

# ZenRouter Skill

This project uses [zenrouter](https://pub.dev/packages/zenrouter). Coordinator
apps declare static topology in a **RouteManifest** and map IDs to
**RouteTarget** constructors with **RouteBinding**. For new graphs, do not
write a `parseRouteFromUri` switch.

> **Deep-dive references** — read these only when you need the specific topic:
>
> | File | When to read |
> |:-----|:-------------|
> | [ADVANCED.md](./ADVANCED.md) | Fragments, typed IDs, deferred bindings, Coordinator-as-Module, tabs/branches, redirect/guard rules |
> | [MIXIN.md](./MIXIN.md) | `RouteGuard`, `RouteRedirect`, `RouteDeepLink`, `RouteTransition`, `RouteQueryParameters`, `RouteRestorable` |
> | [NAVIGATION.md](./NAVIGATION.md) | `push` vs `navigate` vs `replace`, plus URI helpers (`pushUri`, `recoverUri`) |

---

## Before you edit

Inspect the repo, then follow **one** style:

| What you see | What to do |
|:-------------|:-----------|
| `@ZenRoute` / `@ZenLayout` / `routes.zen.dart` | File-based. Add an annotated file under `lib/routes/`. Run `dart run build_runner build`. **Never** edit `*.g.dart` or `routes.zen.dart`. |
| `RouteModuleBinding` | Manifest-bound. Add a manifest node, a binding, and a route class. |
| `parseRouteFromUri` switch and no binding mixin | Parser-era. Add a switch case. Do **not** migrate onto a manifest unless asked. |

Import `package:zenrouter/zenrouter.dart` (re-exports `zenrouter_core`).

---

## Mental model

| Layer | Owns | Must not own |
|:------|:-----|:-------------|
| `RouteManifest` | IDs, URI patterns, `parentId`, layout kinds | Widgets, constructors, `BuildContext` |
| `RouteBinding` | ID → `RouteTarget` factory from `RouteManifestMatch` | Topology, matching order |
| `RouteTarget` | `build()`, `layout`, redirects, guards | URI matching |

Matching and `manifest.location(...)` share the same pattern. `toUri()` must
delegate to that helper — never hand-build a parallel path string.

---

## Key Types

| Type | Purpose |
|:-----|:--------|
| `RouteTarget` + `RouteUnique` | Presentation route; required for Flutter coordinator routes |
| `RouteManifest<I>` | Immutable graph of routes + layouts; owns matching and reverse routing |
| `RouteManifestFragment<I>` | One module's contribution; composed by `CoordinatorModular` |
| `RouteBinding<I, T>` | Adapter from a matched ID to a `RouteTarget` |
| `RouteBindingRegistry<I, T>` | Validated complete set of bindings for one manifest |
| `RouteModuleBinding<T, I>` | Mixin on `RouteModule` / Coordinator — `parseRouteFromUri` = `routeBindings.resolve` |
| `Coordinator<T>` | Flutter hub: paths, layouts, `MaterialApp.router` |
| `CoordinatorModular<T>` | Delegates parsing to modules and composes their fragments |
| `RouteModule<T>` | One feature's paths, layouts, and (via binding) URI parsing |
| `NavigationPath<T>` | Mutable stack; one per layout group |
| `IndexedStackPath<T>` / `BranchedStackPath<T>` | Tabs / stateful-shell branches — see [ADVANCED.md](./ADVANCED.md) |
| `RouteLayout<T>` | Shell that wraps child routes |
| `RouteNotFound` | Marker mixin — not-found route keeps the requested URI |

---

## Patterns

Every manifest path starts with `/` and has no query or fragment.

| Pattern | Matches | Binding reads |
|:--------|:--------|:--------------|
| `/shop` | `/shop` | — |
| `/products/:id` | `/products/42` | `match.pathParameters['id']!` |
| `/docs/...:slugs` | `/docs`, `/docs/a/b` | `match.restParameters['slugs']!` (`List<String>`) |
| `/docs/...:slugs/:id` | `/docs/a/b/start` | rest `slugs` + path `id` |

- `:name` — one segment. `...:name` — zero or more segments. At most one rest parameter.
- Parameter names: `^[A-Za-z_][A-Za-z0-9_]*$`. No duplicate names in one pattern.
- More literal segments win. A rest pattern loses to a non-rest pattern. Equal-specificity overlaps fail construction.

Query strings are **not** part of the pattern. Read `match.uri.queryParameters` in the binding if needed.

---

## 1. Route Base Type

```dart
abstract class AppRoute extends RouteTarget with RouteUnique {
  @override
  Widget build(covariant Coordinator coordinator, BuildContext context);
}
```

---

## 2. Single Coordinator

Use when the app is one graph (no feature modules). Mix
`RouteModuleBinding` and **do not** override `parseRouteFromUri`.

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

  static const location = AppCoordinatorLocation();

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

final class AppCoordinatorLocation {
  const AppCoordinatorLocation();

  Uri get home => AppCoordinator.manifest.location(AppRouteId.home);

  Uri product(String id) => AppCoordinator.manifest.location(
    AppRouteId.product,
    pathParameters: {'id': id},
  );
}

// Wire up:
MaterialApp.router(routerConfig: AppCoordinator())
```

**Rules:**
- Every `RouteManifestRoute` must have exactly one binding. Layout IDs must not be bound.
- `notFound` is required on a standalone registry so unmatched URIs still produce a route. That class mixes `RouteNotFound`.
- Hand-written IDs are enums plus `RouteIdCodec.enumValues`. Generated file-based IDs are class-name strings.

---

## 3. Modular Features

Split parsing across `RouteModule`s with `RouteModuleBinding`. The app
coordinator mixes **only** `CoordinatorModular` — never also
`RouteModuleBinding` (the two both override `parseRouteFromUri`).

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
        create: (match) => ProductDetailRoute(id: match.pathParameters['id']!),
      ),
    ],
    // no notFound — unmatched URIs must return null so other modules can claim them
  );

  late final shopStack = NavigationPath<AppRoute>.createWith(
    coordinator: coordinator, // inherited field = root coordinator
    label: 'shop',
  )..bindLayout(ShopLayout.new);

  @override
  List<StackPath> get paths => [shopStack];
}

class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Iterable<RouteModule<AppRoute>> defineModules() => [
    AuthModule(this),
    ShopModule(this),
  ];

  @override
  AppRoute notFoundRoute(Uri uri) => NotFoundRoute(uri: uri);
}
```

**Rules:**
- Module order in `defineModules()` is matching order. Duplicate module **runtime types** throw.
- `defineModules()` is snapshotted once — return a fixed iterable, not a rebuilt factory.
- A module binding must omit `notFound`. Only the root `notFoundRoute` (or a standalone registry's `notFound`) handles misses.
- Use inherited `coordinator` in `NavigationPath.createWith`.
- `bindLayout(LayoutClass.new)` takes the constructor, not an instance.
- `CoordinatorModular` composes every module `routeManifestFragment` and validates the full graph (cross-module `parentId`, cycles, ambiguous paths).
- Do **not** override `parseRouteFromUri` on the modular coordinator.

A module that only *references* a layout declared by another module must
override `routeManifestFragment` instead of a self-contained `RouteManifest`.
See [Fragments](./ADVANCED.md#routemanifestfragment) in ADVANCED.md.

> Nested feature groups: [Coordinator as Module](./ADVANCED.md#coordinator-as-module).

---

## 4. Route Definition

```dart
class ShopHomeRoute extends AppRoute {
  @override
  Type? get layout => ShopLayout;

  @override
  Uri toUri() => ShopModule.manifest.location(ShopRouteId.home);

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return ShopHomePage(
      onProductTap: (id) => coordinator.push(ProductDetailRoute(id: id)),
    );
  }
}

class ProductDetailRoute extends AppRoute {
  ProductDetailRoute({required this.id});
  final String id;

  @override
  List<Object?> get props => [id];

  @override
  Type? get layout => ShopLayout;

  @override
  Uri toUri() => ShopModule.manifest.location(
    ShopRouteId.product,
    pathParameters: {'id': id},
  );

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) =>
      ProductDetailPage(id: id);
}

class NotFoundRoute extends AppRoute with RouteNotFound {
  NotFoundRoute(this.uri);
  final Uri uri;

  @override
  Uri toUri() => uri;

  @override
  List<Object?> get props => [uri];

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) =>
      NotFoundPage(uri: uri);
}
```

**Rules:**
- `layout` / `parentLayoutKey` is the **runtime** shell — the `RouteLayout` `Type` (default `layoutKey` is `runtimeType`).
- Manifest `parentId` is the **static** parent ID (`ShopRouteId.layout` or `'ShopLayout'`). It is not the same value as `layout`; they must refer to the same shell.
- Override `props` for every constructor parameter.
- Prefer a `location` helper on the coordinator when one exists (`coordinator.location.product(id)`).

> Redirect-only routes: [RedirectRule](./ADVANCED.md#redirectrule).

---

## 5. Layout

```dart
class ShopLayout extends AppRoute with RouteLayout<AppRoute> {
  @override
  StackPath<AppRoute> resolvePath(covariant AppCoordinator coordinator) =>
      coordinator.getModule<ShopModule>().shopStack;

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Shop')),
      body: buildPath(coordinator),
    );
  }
}
```

**Rules:**
- Call `buildPath(coordinator)` — do **not** call `super.build()`.
- `resolvePath` returns the exact path that was `bindLayout`-ed.
- Declare the same layout in the manifest (`RouteManifestLayout.stack` / `.indexed` / `.branched`) and at runtime (`bindLayout`).
- Tabs and stateful shells: [IndexedStackPath](./ADVANCED.md#indexedstackpath-tab-navigation) / [BranchedStackPath](./ADVANCED.md#branchedstackpath-stateful-shell-navigation).

---

## 6. Navigation

```dart
coordinator.push(ProductDetailRoute(id: '42'));
coordinator.navigate(ShopHomeRoute());
coordinator.replace(SettingsRoute());
coordinator.pop();

// Same graph, no RouteTarget instance:
await coordinator.location.product('42').recoverWith(coordinator);
await coordinator.pushUri(ShopModule.manifest.location(
  ShopRouteId.product,
  pathParameters: {'id': '42'},
));
```

Redirect rules run on every navigation call.

> Method choice and URI helpers: [NAVIGATION.md](./NAVIGATION.md).

---

## 7. File-Based Routes

When the project already uses `zenrouter_file_generator`:

```dart
// lib/routes/shop/products/[id].dart  →  /shop/products/:id
@ZenRoute()
class ProductIdRoute extends _$ProductIdRoute {
  ProductIdRoute({required super.id});

  @override
  Widget build(covariant AppCoordinator coordinator, BuildContext context) =>
      ProductPage(id: id);
}
```

| File | URL |
|:-----|:----|
| `index.dart` | `/path` |
| `about.dart` | `/path/about` |
| `[id].dart` | `/path/:id` |
| `[...slugs]/` | `/path/*` |
| `_layout.dart` | layout only |
| `(group)/` | layout group, **not** a URL segment |
| `shop.products.[id].dart` | `/shop/products/:id` (dot nesting) |

`@ZenLayout(type: LayoutType.stack|indexed|branched)` on `_layout.dart`.
Generated `AppCoordinator` already mixes `RouteModuleBinding<AppRoute, String>`
and exposes `AppCoordinator.location` / `pushProductId(id)`.

---

## 8. File Structure (hand-written)

```
lib/src/router/
├── coordinator.dart          ← Root Coordinator or Coordinator-as-Module
├── route.dart                ← Base route type (e.g. AppRoute)
├── _public.dart              ← Barrel: public routes + rules
├── rules/
│   ├── auth_required.dart
│   └── force_redirect.dart
└── routes/
    ├── (auth)/               ← Layout group (not a URI segment)
    │   ├── _layout.dart
    │   ├── sign_in.dart      ← /sign-in
    │   └── forgot_password.dart
    ├── (dashboard)/
    │   ├── _layout.dart
    │   ├── _index.dart
    │   └── transactions/
    │       ├── _index.dart   ← /transactions
    │       └── [id].dart     ← /transactions/:id
    │   └── blog/
    │       ├── _layout.dart
    │       └── [...slug].dart ← /blog/...:slug
    └── not_found.dart
```

Keep the file name, manifest `path`, and `location` helper in lockstep.
`rules/` holds reusable `RedirectRule`s.

---

## 9. Naming

### Route classes

| Pattern | Example | When |
|:--------|:--------|:-----|
| `<Feature>Route` | `SignInRoute` | Standard page |
| `<Feature>DetailRoute` | `TransactionDetailRoute` | `[id]` / `:id` page |
| `<Feature>IndexRoute` | `DashboardIndexRoute` | Index / redirect-only |
| `<Feature>Tab` | `HomeTab` | Indexed-stack tab |
| `NotFoundRoute` | `NotFoundRoute` | 404; mix in `RouteNotFound` |

### Layout, module, rule, and ID types

| Pattern | Example | When |
|:--------|:--------|:-----|
| `<Feature>Layout` | `ShopLayout` | Shell |
| `<Feature>Module` | `ShopModule` | `RouteModule` |
| `<Feature>Coordinator` | `ShopCoordinator` | Coordinator-as-Module |
| `<Feature>RouteId` | `ShopRouteId` | Hand-written manifest IDs (enum) |
| `<Condition>Rule` | `AuthRequiredRule` | Redirect / guard rule |

### URIs and labels

Kebab-case segments. Singular resource details (`/transaction/:id`).
`NavigationPath` labels: `'auth'`, `'dashboard'`, `'shop-products'`.

---

## 10. Adding a Feature: Checklist

**File-based:** add the annotated file → `build_runner` → navigate via generated `pushX` / `location`.

**Manifest-bound:**

1. Add an ID to the feature enum (or a `RouteManifestRoute` with the generated class-name string).
2. Add the pattern (and `parentId` if it lives under a layout).
3. Add a `RouteBinding` that reads `pathParameters` / `restParameters`.
4. Create the route class: `layout`, `toUri()` via `manifest.location`, `props`, `build()`.
5. Export from `_public.dart` if other features navigate to it.
6. **New layout?** `RouteManifestLayout.*` + `NavigationPath`/`IndexedStackPath`/`BranchedStackPath` + `bindLayout` + `RouteLayout` class + `paths`.
7. **New module?** `RouteModule` + `RouteModuleBinding`, register in `defineModules()`.
8. **Feature group with sub-modules?** [Coordinator-as-Module](./ADVANCED.md#coordinator-as-module).

---

## Common Mistakes

| Mistake | Fix |
|:--------|:----|
| `parseRouteFromUri` switch on new work | Use `RouteModuleBinding` |
| Mixing `RouteModuleBinding` with `CoordinatorModular` | Modular root uses only `CoordinatorModular`; child modules use `RouteModuleBinding` |
| Module binding sets `notFound` | Omit it so other modules can match |
| Binding a layout ID, or leaving a route unbound | Bind every `RouteManifestRoute`; never bind a layout |
| `toUri()` via `Uri.parse('/…')` | `manifest.location(id, pathParameters: …)` |
| `parentId` / `layout` disagree | Manifest `parentId` and runtime `layout` must name the same shell |
| Overriding `parseRouteFromUri` on a binding or modular coordinator | Don't — the mixin owns it |
| Forgetting `...super.paths` | Always spread `super.paths` |
| File-based: editing `routes.zen.dart` | Add a source file; regenerate |
| Parser-era coordinator: rewriting onto a manifest unasked | Add a switch case instead |
