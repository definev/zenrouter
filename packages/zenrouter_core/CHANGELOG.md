## 3.0.0

### Breaking Changes

- **Navigation operations moved out of `CoordinatorCore`** into composable
  capability mixins. `CoordinatorCore` is now a state container only
  (paths, URI parsing, layout-parent hooks).

  | Mixin | Capabilities |
  |-------|--------------|
  | `CoordinatorLayoutCore` | Layout-parent registration / hierarchy activation |
  | `CoordinatorNavigatable` | `navigate` |
  | `CoordinatorMutatable` | `push`, `pop`, `replace`, `pushReplacement`, `pushOrMoveToTop`, `tryPop` |
  | `CoordinatorRecoverable` | `recover`, `recoverRouteFromUri`, `defineDeeplinkHandler` |

  Flutter `Coordinator` still mixes all of them — existing apps that extend
  `Coordinator` need no code changes. Custom `CoordinatorCore` subclasses must
  mix in the capabilities they need.

- **Route value hashing now follows Dart's equality contract.** Mutable path
  and result lifecycle state no longer contributes to `hashCode`;
  `RouteTarget.deepEquals` now means same lifecycle entry (reference identity).
- **`CoordinatorModular.defineModules` now returns `Iterable`** and snapshots
  its deterministic iteration order. Duplicate module runtime types throw.

### New Features

- **Shared contracts** `Navigatable<T>` and `Mutatable<T>` implemented by both
  stack paths and coordinator mixins.
- **`defineDeeplinkHandler`**: override built-in `DeeplinkStrategy` behaviour
  (`navigate` / `push` / `replace`). `custom` still uses
  `RouteDeepLink.deeplinkHandler`.
- **`recoverRouteFromUri`**: convenience on `CoordinatorRecoverable` (parses
  then recovers; throws if `parseRouteFromUri` returns null).
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

## 2.2.0

### Breaking Changes

- **`GuardRule` contract renamed** for coordinator-optional use. The 2.1.0 methods are removed:

  | Removed (2.1.0) | Replacement |
  |-----------------|-------------|
  | `canPop(route)` | `canPopRule(route)` / `canPopRuleWith(coordinator, route)` |
  | `canPopListenable(route)` | `canPopListenableRule(route)` / `canPopListenableRuleWith(coordinator, route)` |
  | `guard(coordinator, route)` | `guardRule(route)` / `guardRuleWith(coordinator, route)` |

  Migration:

  ```dart
  // Before (2.1.0)
  class UnsavedChangesRule extends GuardRule<AppRoute> {
    @override
    bool canPop(AppRoute route) => !route.hasUnsavedChanges;

    @override
    FutureOr<bool?> guard(CoordinatorCore c, AppRoute route) async { /* ... */ }
  }

  // After (2.2.0) — route-only
  class UnsavedChangesRule extends GuardRule<AppRoute> {
    @override
    bool canPopRule(AppRoute route) => !route.hasUnsavedChanges;

    @override
    FutureOr<bool?> guardRule(AppRoute route) async { /* ... */ }
  }

  // After (2.2.0) — needs coordinator (dialogs, app state)
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

## 2.1.0

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
