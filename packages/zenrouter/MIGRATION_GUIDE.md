# Migration Guide

This guide outlines the changes and steps required to migrate to the latest version of `zenrouter`.

**Latest:** [3.0.0](#300-manifests-capability-mixins-and-lifecycle) — route manifests, capability mixins, page identity, and `pop()` completing results.

---

## 3.0.0: Manifests, capability mixins, and lifecycle

Requires `zenrouter_core` 3.0.0. Apps that only `extend Coordinator` keep compiling. Read this section if you subclass `CoordinatorCore`, type `PageCallback`, call `completeOnResult` after `pop`, or override `defineModules`.

### Typical Flutter app (`extends Coordinator`)

`Coordinator` still mixes `CoordinatorLayoutCore`, `CoordinatorNavigatable`, `CoordinatorMutatable`, `CoordinatorRecoverable`, plus Flutter layout / restoration / transitions.

Prefer `await coordinator.pushOrMoveToTop(...)` when sequencing. The method was already `async`; the return type is now `Future<void>`.

`defineLayout` and `defineConverter` are **deprecated** but still invoked from `init()` for compatibility:

| Deprecated | Replacement |
| :--- | :--- |
| `defineLayout()` + `defineLayoutParent(...)` | `NavigationPath.createWith(...)..bindLayout(Layout.new)` |
| `defineConverter()` + `defineRestorableConverter(...)` | Same call inside `init()` (`super.init()` first) |

### Custom `CoordinatorCore` subclasses

#### Changes

Navigation operations moved off `CoordinatorCore` into capability mixins:

| Mixin | Capabilities |
|-------|--------------|
| `CoordinatorLayoutCore` | Layout-parent registration / hierarchy activation |
| `CoordinatorNavigatable` | `navigate` |
| `CoordinatorMutatable` | `push`, `pushSilently`, `pop`, `replace`, `pushReplacement`, `pushOrMoveToTop`, `tryPop` |
| `CoordinatorRecoverable` | `recover`, `recoverUri`, `defineDeeplinkHandler` |

URI helpers (`navigateUri`, `pushUri`, …) are an extension on `CoordinatorRecoverable`. The same operations are also available on `Uri` (`uri.pushWith(coordinator)`, `uri.navigateWith(coordinator)`, `uri.replaceWith(coordinator)`, …).

#### Migration

Mix in only what you need. A push/pop coordinator:

```dart
class HeadlessCoordinator extends CoordinatorCore<AppRoute>
    with CoordinatorLayoutCore<AppRoute>, CoordinatorMutatable<AppRoute> {
  // parseRouteFromUri, root, ...
}
```

A full analogue of Flutter `Coordinator`:

```dart
class AppCore extends CoordinatorCore<AppRoute>
    with
        CoordinatorLayoutCore<AppRoute>,
        CoordinatorNavigatable<AppRoute>,
        CoordinatorMutatable<AppRoute>,
        CoordinatorRecoverable<AppRoute> {}
```

`CoordinatorView.initialUri` requires `CoordinatorNavigatable`. In debug it asserts; in release it skips navigation instead of casting.

### `defineModules` returns `Iterable`

#### Changes

- **Before**: `List<RouteModule<T>> defineModules()`
- **After**: `Iterable<RouteModule<T>> defineModules()` — snapshotted once at init. Duplicate module **runtime types** throw.

#### Migration

Existing `=> [AuthModule(this), ShopModule(this)]` bodies still work. Do not return a lazily rebuilt list on every access; the mixin snapshots the iterable once.

### `PageCallback` key type

#### Changes

- **Before**: `PageCallback` received `ValueKey<RouteTarget>`
- **After**: `LocalKey` (`ObjectKey` of the stack entry)

Equal semantic routes can coexist in an imperative `NavigationStack` without duplicate Navigator keys. The imperative stack diffs pages by **identity**. `DeclarativeNavigationStack` still diffs by `==`.

#### Migration

Only custom page builders that named the key type need a change:

```dart
// Before
PageCallback<AppRoute> callback = (context, ValueKey<RouteTarget> routeKey, child) {
  return MaterialPage(key: routeKey, child: child);
};

// After
PageCallback<AppRoute> callback = (context, LocalKey routeKey, child) {
  return MaterialPage(key: routeKey, child: child);
};
```

### `pop()` completes the route result

#### Changes

`StackMutatable.pop` now completes `onResult` and calls `onDidPop` immediately. Callers of `push` / `pushUri` no longer wait for a later Flutter `PopScope` callback. `onDidPop` is idempotent if the page callback also fires.

#### Migration

Remove a second `completeOnResult` after `pop`. It now throws `Bad state: Future already completed`:

```dart
// Before (2.x / early 3.0 headless tests)
await coordinator.pop('done');
route.completeOnResult(route.resultValue, coordinator);

// After
await coordinator.pop('done');
expect(await pushFuture, 'done');
```

### Equality and `deepEquals`

#### Changes

- `==` / `hashCode` use `runtimeType` + `props` only. Path binding and the result completer are not hashed.
- `RouteTarget.deepEquals` is **reference identity** (same lifecycle entry), not a deep value compare.
- `Equatable.internalProps` is **removed**. It was unused by equality and hashing.

#### Migration

Do not put mutable lifecycle state in `props`. Delete any `internalProps` overrides — they no longer compile. If you compared `deepEquals` for “same screen, same params”, use `==` instead.

### Deprecated `RouteResolution.data`

Use `hydration?.data`. Passing legacy `data:` still wraps it in a `RouteHydrationPayload`. Do not pass both `hydration` and `data`.

### Optional: manifests and bindings

3.0 adds `RouteManifest`, `RouteBindingRegistry`, `CoordinatorRouteBinding`, and `RouteModuleBinding`. Hand-written `parseRouteFromUri` coordinators keep working with `RouteManifest.empty`. Adopt the manifest seam when you want validated topology, reverse routing, or codegen-free URI parsing.

Indexed manifest children must be **direct** children of that layout (`parentId` matches). Branched children must be layouts declared on the parent.

### Browser back and pop guards

A traversal that a `RouteGuard` blocks now **replaces** the current history entry with the app URI when it differs from the engine URI. Flutter's `RouteInformationReportingType.none` still reports to the engine and would otherwise **push** a new entry, looping the back button.

No app code change. Custom `RouteInformationProvider` subclasses that remapped `traverse` → `none` unconditionally should use the same URI-compare rule as `CoordinatorRouteInformationProvider.resolveReportingType`.

---

## 2.1.0: CoordinatorView & layout builder API

### Adopting `CoordinatorView` (optional)

2.1.0 adds [`CoordinatorView`](doc/guides/coordinator-view.md) for embedding a standalone coordinator **without** `MaterialApp.router`. No migration is required unless you want this pattern.

**App root (unchanged — recommended for web / single-surface apps):**

```dart
MaterialApp.router(routerConfig: appCoordinator)
```

**Embedded surface (new):**

```dart
MaterialApp(
  home: CoordinatorView<AppRoute>(
    coordinator: miniAppCoordinator,
    initialUri: Uri.parse('/dashboard'),
  ),
)
```

| Concern | `routerConfig` | `CoordinatorView` |
|---------|----------------|-------------------|
| Browser URL / back button | Automatic | Host must handle |
| `initialUri` | Platform + parser | Once, when `root.stack` is empty |
| Ongoing deep links | `setNewRoutePath` | Call `coordinator.navigate(...)` explicitly |

See [CoordinatorView Guide](doc/guides/coordinator-view.md) for pitfalls, parallel panels, and mini-app hosts.

---

### `layoutBuilder` moved to `CoordinatorLayout`

#### Changes

- **Before**: `layoutBuilder` was declared on the `Coordinator` class.
- **After**: `layoutBuilder` lives on the [`CoordinatorLayout`](lib/src/coordinator/layout.dart) mixin (via [`CoordinatorLayoutBuilder`](lib/src/coordinator/layout.dart)).

#### Migration

If you override `layoutBuilder`, keep overriding it on your coordinator class — `Coordinator` still mixes in `CoordinatorLayout`. No import or call-site changes are needed for typical apps.

**Before and after (same for `extends Coordinator`):**

```dart
class AppCoordinator extends Coordinator<AppRoute> {
  @override
  Widget layoutBuilder(BuildContext context) {
    return RouteLayout.buildRoot(this);
  }
}
```

Only update code that referenced `layoutBuilder` as a member **defined on `Coordinator` itself** in documentation, implements clauses, or custom abstractions that extended `CoordinatorCore` without `CoordinatorLayout`. Those types must now mix in or implement `CoordinatorLayoutBuilder`.

---

### `RouteLayoutBuilder` first parameter: `CoordinatorCore`

#### Changes

- **Before**: `Widget Function(Coordinator coordinator, StackPath<T> path, RouteLayout<T>? layout)`
- **After**: `Widget Function(CoordinatorCore coordinator, StackPath<T> path, RouteLayout<T>? layout)`

#### Migration

Update custom layout builders registered with `defineLayoutBuilder` (or copies of `kDefaultLayoutBuilderTable`). Cast when you need Flutter-specific APIs:

**Before:**

```dart
coordinator.defineLayoutBuilder(
  NavigationPath.key,
  (Coordinator coordinator, path, layout) {
    return NavigationStack(
      path: path as NavigationPath<AppRoute>,
      coordinator: coordinator,
      // ...
    );
  },
);
```

**After:**

```dart
coordinator.defineLayoutBuilder(
  NavigationPath.key,
  (CoordinatorCore coordinatorCore, path, layout) {
    final coordinator = coordinatorCore as Coordinator;
    return NavigationStack(
      path: path as NavigationPath<AppRoute>,
      coordinator: coordinator,
      // ...
    );
  },
);
```

If your builder only uses `coordinator.root`, `getLayoutBuilder`, or other members on `CoordinatorCore` / `CoordinatorLayout`, no cast is required.

**Default builders (`NavigationPath` / `IndexedStackPath`):** [`kDefaultLayoutBuilderTable`](lib/src/coordinator/layout.dart) still require a Flutter **`Coordinator`**, not an arbitrary `CoordinatorCore`. In debug builds, passing the wrong type triggers an `assert` with a link to [route-layout.md — default layout builders](doc/guides/route-layout.md#default-layout-builders-require-coordinator). Register `defineLayoutBuilder` if you use a custom core type.

#### Rationale

Layout builders are shared infrastructure; the narrower parameter type matches `RouteLayout.buildRoot` and allows future embed hosts that implement `CoordinatorLayoutBuilder` without full `RouterConfig`.

---

### `RouteLayout.buildRoot` parameter: `CoordinatorLayout`

#### Changes

- **Before**: `RouteLayout.buildRoot(Coordinator coordinator)`
- **After**: `RouteLayout.buildRoot(CoordinatorLayout coordinator)`

#### Migration

Pass `this` from any class that mixes in `CoordinatorLayout` (including `Coordinator`). Update helpers that accepted `Coordinator` only for `buildRoot`:

**Before:**

```dart
Widget buildAppShell(Coordinator coordinator) => RouteLayout.buildRoot(coordinator);
```

**After:**

```dart
Widget buildAppShell(CoordinatorLayout coordinator) => RouteLayout.buildRoot(coordinator);
```

`Coordinator` satisfies `CoordinatorLayout`; existing `layoutBuilder` overrides that delegate to `RouteLayout.buildRoot(this)` continue to work unchanged.

---

### `CoordinatorLayoutBuilder` mixin

#### Changes

- **New**: `CoordinatorLayoutBuilder<T extends RouteUri>` declares `Widget layoutBuilder(BuildContext context)`.
- **New**: [`CoordinatorView`](lib/src/coordinator/view.dart) takes `CoordinatorLayoutBuilder<T> coordinator` instead of requiring full `Coordinator` / `RouterConfig`.

#### Migration

No action required unless you build custom embed widgets. Prefer typing embed APIs against `CoordinatorLayoutBuilder<T>` rather than `Coordinator<T>` when URL sync and `Router` are not needed.

---

## Path Constructors

The constructors for `NavigationPath` and `IndexedStackPath` have been updated to provide better clarity and type safety, especially when binding to a `Coordinator`.

### Changes

- **Deprecated**: The default unnamed constructors `NavigationPath(...)` and `IndexedStackPath(...)`.
- **New**: `create` factory constructor for creating paths with optional arguments.
- **New**: `createWith` factory constructor for creating paths that are explicitly bound to a `Coordinator`.

### Migration

Replace direct constructor calls with `create` or `createWith`:

**Before:**
```dart
final path = NavigationPath(
  'root',
  [],
  coordinator,
);
```

**After (Standard):**
```dart
final path = NavigationPath.create(
  label: 'root',
  stack: [],
  coordinator: coordinator,
);
```

**After (With explicit Coordinator):**
```dart
late final path = NavigationPath.createWith(
  coordinator: this,
  label: 'root',
  stack: [],
);
```

Same applies to `IndexedStackPath`.

### Rationale

Deeply integrating paths with their coordinator using `createWith` provides several benefits:

1.  **Coordinator Awareness**: The path explicitly knows which coordinator it belongs to, enabling features like `popGuardWith` to verify that operations are happening in the correct context.
2.  **Safety**: Prevents a path from being used detached from its coordinator, which could lead to silent failures or incorrect state management.
3.  **Strict Binding**: The `late final ... = ... .createWith(coordinator: this, ...)` pattern ensures that the path and coordinator are 1:1 linked from the moment of creation, avoiding race conditions or initialization order issues.

### Trade-offs

*   **Coupling**: This approach tightly couples instances of `StackPath` to a specific `Coordinator`. While this is by design, it means paths are less "standalone".
*   **Testing**: Unit testing individual paths in isolation now requires providing a mock or dummy `Coordinator` if you use `createWith`, whereas previously they could be tested as simple data containers.
*   **Initialization**: Requires using `late final` variables in the `Coordinator` to handle the circular reference (Coordinator needs Path, Path needs Coordinator). Exceptions during initialization might be harder to debug if not careful.

**Why it is worth it:**
When using `createWith`, you are explicitly creating a path intended to work *with* a Coordinator. Therefore, this coupling is intentional and necessary. It guarantees that the path always has access to the correct context for advanced features like guards and redirects, making the system more robust and preventing common configuration errors.

## Path Layout Builder: `defineLayoutBuilder()`

The `RouteLayout.definePath()` static method has been deprecated and replaced by the instance method `coordinator.defineLayoutBuilder()`.

### Changes

- **Deprecated**: The static method `RouteLayout.definePath(coordinator, key, builder)`.
- **New**: The instance method `coordinator.defineLayoutBuilder(key, builder)`.

### Migration

Replace calls to the static `RouteLayout.definePath` with the `defineLayoutBuilder` method on your coordinator instance.

**Before:**
```dart
// Static definition
RouteLayout.definePath(
  NavigationPath.key,
  (coordinator, path, layout) => CustomNavigationStack(...),
);
```

**After:**
```dart
// Instance definition
coordinator.defineLayoutBuilder(
  NavigationPath.key,
  (coordinator, path, layout) => CustomNavigationStack(...),
);
```

### Rationale

Moving `defineLayoutBuilder` to the `Coordinator` instance solves a critical architectural issue by **avoiding global state**:

1. **Scoped State**: Layout builders are now scoped to the specific `Coordinator` instance rather than sitting in a static global context. This ensures that multiple coordinators (e.g., in testing or advanced architectures) do not interfere with each other's custom layout builders.
2. **Lifecycle Management**: By associating the builder table with the coordinator, it automatically cleans up when the coordinator is disposed, preventing memory leaks.

## Layout Registration: `bindLayout()`

The layout registration API has been simplified from `defineLayout()` to `bindLayout()`.

### Changes

- **Deprecated**: `defineLayout()` method with `RouteLayout.defineLayout()` calls.
- **New**: `bindLayout()` method on `StackPath` for inline layout registration.

### Migration

**Before (using defineLayout):**
```dart
class AppCoordinator extends Coordinator<AppRoute> {
  late final NavigationPath<AppRoute> homeStack = NavigationPath.createWith(
    label: 'home',
    coordinator: this,
  )..bindLayout(HomeLayout.new);
}
```

**After (using bindLayout):**
```dart
class AppCoordinator extends Coordinator<AppRoute> {
  late final NavigationPath<AppRoute> homeStack = NavigationPath.createWith(
    label: 'home',
    coordinator: this,
  )..bindLayout(HomeLayout.new);  // Register inline!

  // No need to override defineLayout() when using bindLayout
}
```

Both approaches work, but `bindLayout()` is recommended for new code.

### Benefits

- **More concise**: Single line instead of separate method override
- **Collocated**: Path creation and layout registration in one place
- **Less boilerplate**: No need to override `defineLayout()`

## RouteGuard API

The `RouteGuard` mixin has been enhanced to support coordinator validation during pop operations.

### Changes

- **New**: `popGuardWith(Coordinator coordinator)` method.
  - This method is called by the framework when a pop is attempted.
  - It asserts that the route's path is associated with the correct coordinator.
  - It internally calls `popGuard()`.

- **Existing**: `popGuard()` remains the place to implement your custom guard logic.

### Migration

If you are manually calling `popGuard` in your custom logic or tests, consider using `popGuardWith` if you have access to the coordinator to benefit from the additional checks.

No changes are needed for existing `popGuard` implementations unless you are overriding the default behavior significantly.

## RouteRedirect API

The `RouteRedirect` mixin has been updated similarly to `RouteGuard`.

### Changes

- **New**: `redirectWith(Coordinator coordinator)` method.
  - Called by the framework during route resolution.
  - Helps ensuring the path belongs to the correct coordinator context.
  - Internally calls `redirect()`.

- **Existing**: `redirect()` remains the place to implement your redirect logic.

## parseRouteFromUri Return Type

The return type of `parseRouteFromUri` has been changed to support nullable returns.

### Changes

- **Before**: `FutureOr<T> parseRouteFromUri(Uri uri)`
- **After**: `FutureOr<T?> parseRouteFromUri(Uri uri)`

### Migration

For most coordinators, no changes are needed. The nullable return is primarily for nested coordinators (route modules) that want to indicate "this URI doesn't belong to me".

```dart
// Before
@override
FutureOr<AppRoute> parseRouteFromUri(Uri uri) { ... }

// After - return null to let parent handle unrecognized URIs
@override
FutureOr<AppRoute?> parseRouteFromUri(Uri uri) { ... }
```

## Internal Properties (`internalProps`)

> Removed in 3.0.0. See [Equality and `deepEquals`](#equality-and-deepequals).

`internalProps` was added in 0.4.0 as a second property list on `Equatable` / `RouteTarget`. It never participated in `==` or `hashCode` in 3.0 and has been deleted. Put route parameters in `props` only.
