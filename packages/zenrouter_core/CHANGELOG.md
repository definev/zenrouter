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