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