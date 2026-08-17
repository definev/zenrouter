## 3.0.0

### Breaking Changes

- **Route manifests now describe topology only.** `RouteManifestRoute` no
  longer duplicates query, guard, redirect, deferred-loading, or deep-link
  metadata from concrete route implementations.
- **Navigation operations moved out of `CoordinatorCore`** into composable
  capability mixins. `CoordinatorCore` is now a state container only
  (paths, URI parsing, layout-parent hooks).

  | Mixin | Capabilities |
  |-------|--------------|
  | `CoordinatorLayoutCore` | Layout-parent registration / hierarchy activation |
  | `CoordinatorNavigatable` | `navigate` |
  | `CoordinatorMutatable` | `push`, `pushSilently`, `pop`, `replace`, `pushReplacement`, `pushOrMoveToTop`, `tryPop` |
  | `CoordinatorRecoverable` | `recover`, `recoverUri`, `defineDeeplinkHandler` |

  Flutter `Coordinator` still mixes all of them — existing apps that extend
  `Coordinator` need no code changes. Custom `CoordinatorCore` subclasses must
  mix in the capabilities they need.

- **Route value hashing now follows Dart's equality contract.** Mutable path
  and result lifecycle state no longer contributes to `hashCode`;
  `RouteTarget.deepEquals` now means same lifecycle entry (reference identity).
- **`CoordinatorModular.defineModules` now returns `Iterable`** and snapshots
  its deterministic iteration order. Duplicate module runtime types throw.
- **`RouteResolution.data` is deprecated** in favor of the versioned
  `RouteResolution.hydration` payload. Legacy JSON-compatible data is wrapped
  automatically for migration.
- **`StackMutatable.pop` completes `onResult` and calls `onDidPop`.** Callers
  of `push` no longer depend on a later Flutter page callback. A second
  `completeOnResult` after `pop` throws. `onDidPop` is idempotent.

### New Features

- **Sealed layout kinds**: `RouteManifestLayoutKind` is a sealed class.
  Fixed children live on `indexed(childIds)` and `branched(childIds)`.
  Construct layouts with `RouteManifestLayout.stack/indexed/branched` so the
  ID type is inferred from the node id. JSON still uses `kind` plus
  `indexedChildIds` / `branchChildIds`.
- **Branched manifest layouts**: `RouteManifestLayoutKind.branched(...)`
  declares an ordered set of direct child layout roots and validates that
  every direct child belongs to the branch topology.
- **Declarative route graph** via the immutable, versioned `RouteManifest`,
  with deterministic URI matching, layout relationship validation, ambiguous
  pattern detection, composition, JSON serialization, and reverse routing.
- **Strongly typed manifest IDs** via `RouteManifest<I>` and
  `RouteIdCodec<I>`. `RouteManifestMatch.id` supports concise Dart object
  patterns while codecs keep strings isolated to the JSON seam.
- **Manifest seam for route modules** via `RouteModule.routeManifest` and
  `RouteManifestFragment`. `CoordinatorModular` automatically flattens nested
  fragments, validates the complete graph, preserves typed in-memory IDs, and
  composes fragment-scoped JSON codecs. Hand-written parser-only coordinators
  still default to `RouteManifest.empty` for compatibility.
- **Runtime Route Bindings** via the validated `RouteBindingRegistry`.
  `CoordinatorRouteBinding` and `RouteModuleBinding` provide manifest-backed
  URI parsing without handwritten parser switches while supporting sync,
  async, not-found, and heterogeneous typed-ID bindings.
  `deferredBindingFactory` / `deferredRouteNotFoundBinding` wrap any
  factory so a deferred library can load before a match or not-found route
  is created. `RouteBinding.deferred` uses the same wrapper.
  `RouteManifest.bind<T>` builds a registry while inferring its ID type from
  the manifest.
- **Shared contracts** `Navigatable<T>` and `Mutatable<T>` implemented by both
  stack paths and coordinator mixins. `Mutatable` includes `pushSilently` in
  addition to `push`, `pushOrMoveToTop`, and `pushReplacement`. `pop` stays
  off the shared contract because path and coordinator return types differ.
- **Internal `StackCommit` seam** so coordinators apply an already-resolved
  route without a second `RouteRedirect` pass. `pushReplacement` now falls
  back to `activateRoute` when the parent path is not mutatable (indexed or
  branched stacks).
- **`defineDeeplinkHandler`**: override built-in `DeeplinkStrategy` behaviour
  (`navigate` / `push` / `replace`). `custom` still uses
  `RouteDeepLink.deeplinkHandler`.
- **URI-based coordinator actions**: `navigateUri`, `pushUri`,
  `pushSilentlyUri`, `replaceUri`, `recoverUri`, `pushReplacementUri`, and
  `pushOrMoveToTopUri` parse a URI before delegating to the corresponding route
  operation. The same operations are also available on `Uri`
  (`uri.pushWith(coordinator)`, `uri.navigateWith(coordinator)`,
  `uri.replaceWith(coordinator)`, …).
- **`markNeedRebuild`** on `CoordinatorCore`.
- **`CoordinatorMutatable.pushOrMoveToTop`** now returns `Future<void>`
  (aligned with `StackMutatable`).
- **Commit-only navigation** via `pushSilently`, allowing Router/deep-link code
  to await stack commitment without waiting for a later pop result.
- **Atomic declarative stack replacement** via `StackMutatable.replaceAll`,
  preserving retained route lifecycles and emitting one committed state.
- **Navigation history intent** (`push`, `replace`, `traverse`, `automatic`)
  is recorded in core and consumed by platform history adapters.
- **Adapter-neutral route resolution**: `RouteRequest`, `RouteResolver`, and
  typed match/redirect/not-found/error outcomes with status, headers, and
  hydration data.
- **Atomic coordinator transactions**: nested mutations publish one
  `NavigationCommit`; concurrent top-level mutations serialize without being
  mistaken for nested work. `isInNavigationTransaction` lets paths notify
  synchronously inside a transaction so multi-path `reset` does not leak extra
  commits. Sequential `await` of coordinator mutations restores queue idle in
  the transaction `finally` and serializes overlapping work on a side
  Completer, so the caller's future has no extra listeners. The trailing
  microtask drain runs only when no path has already notified synchronously.
- **Cooperative route cancellation** via `RouteCancellationToken`, propagated
  across redirect requests and kept distinct from typed 500 failures.
- **Redirect continuation semantics** for 301, 302, 303, 307, and 308,
  including method/body/header handling and relative-location resolution.
- **Versioned hydration envelope** via `RouteHydrationPayload`, with immutable
  JSON-compatible data, schema validation, and encode/decode support.

## 2.3.0

### Breaking Changes

- **`GuardRule` contract renamed** for coordinator-optional use. The 2.1.0 methods are removed:

  | Removed (2.2.0) | Replacement |
  |-----------------|-------------|
  | `canPop(route)` | `canPopRule(route)` / `canPopRuleWith(coordinator, route)` |
  | `canPopListenable(route)` | `canPopListenableRule(route)` / `canPopListenableRuleWith(coordinator, route)` |
  | `guard(coordinator, route)` | `guardRule(route)` / `guardRuleWith(coordinator, route)` |

  Migration:

  ```dart
  // Before (2.2.0)
  class UnsavedChangesRule extends GuardRule<AppRoute> {
    @override
    bool canPop(AppRoute route) => !route.hasUnsavedChanges;

    @override
    FutureOr<bool?> guard(CoordinatorCore c, AppRoute route) async { /* ... */ }
  }

  // After (2.3.0) — route-only
  class UnsavedChangesRule extends GuardRule<AppRoute> {
    @override
    bool canPopRule(AppRoute route) => !route.hasUnsavedChanges;

    @override
    FutureOr<bool?> guardRule(AppRoute route) async { /* ... */ }
  }

  // After (2.3.0) — needs coordinator (dialogs, app state)
  class UnsavedChangesRule extends GuardRule<AppRoute> {
    @override
    bool canPopRule(AppRoute route) => !route.hasUnsavedChanges;

    @override
    FutureOr<bool?> guardRuleWith(CoordinatorCore c, AppRoute route) async { /* ... */ }
  }
  ```

  Each `*With` method defaults to its non-`With` counterpart. `guardRule` defaults to `null` (continue chain).

### New Features

- **`RouteGuard.canPopWith` / `canPopListenableWith`**: Coordinator-aware PopScope hints (default to `canPop` / `canPopListenable`).
- **`RouteGuardRule.popGuard`**: Now runs the `guardRule` chain (no coordinator), matching `popGuardWith` → `guardRuleWith`.

## 2.2.0

### New Features

- **`GuardRule` / `RouteGuardRule`**: Composable pop-guard chains (first non-null `bool` wins), mirroring `RedirectRule` / `RouteRedirectRule`.
- **`RouteGuard.canPop` / `canPopListenable`**: Sync PopScope hint plus optional `ListenableMixin` invalidation when leave-safety changes.
- **`ListenableMixin`**: Subscribe-only reactive surface (with `ListenableMixin.merge`); `ListenableObject` now implements it.

### Breaking Changes

- **`CoordinatorCore.pop`**: Pops only the nearest eligible stack path. Nested shells are no longer popped together with child stacks in a single call.
- **`RouteRedirect.resolve`**: Throws `StateError` when a redirect returns a different route type (previously silently ignored).

## 2.0.3

- chore: make `RedirectRule` can be const

## 2.0.2

- Fix `CoordinatorModular.getModule` now correctly resolves the coordinator itself by registering `runtimeType: this` in `_allModules`, enabling `getModule<MyCoordinator>()` to work at any level of the hierarchy.

## 2.0.1

- Fix `CoordinatorModular` edge case cascading dispose and prevent duplicate definitions.

## 2.0.0

- Extract core function from `zenrouter` package
