## 2.0.0

🎉 **Major Release - Core Architecture & Layouts**

### 🚀 New Features

- **`zenrouter_core` Package**: Extracted all platform-independent core routing types (`RouteTarget`, `CoordinatorCore`, `StackPath`, and route mixins) into a new dedicated package.
- **Composable Redirects**: You can use `RouteRedirectRule` as `RouteRedirect` to allow composable, testable redirect logic via multiple rules (e.g., `StopRedirect`, `ContinueRedirect`, `RedirectTo`).
- **Route Identity updates**: Introduced `RouteUri` abstract class (and `RouteUnique`) to centralize URI-based identity for coordinator-managed routes.

### ⚠️ Breaking Changes

- **Layout Binding Refactoring**: The global `RouteLayout.defineLayout` has been removed. You must now bind layouts to paths using the `StackPath.bindLayout()` cascade syntax (e.g., `NavigationPath.createWith(...)..bindLayout(HomeLayout.new)`), or use `defineLayoutParent()` / `defineLayoutBuilder()` inside the coordinator.
- **Core Mixins Relocated**: Core routing types have been consolidated under `zenrouter_core`. The main package still exports them, but any explicit deep imports to old paths must be updated.
- **RouteLayout.definePath Deprecated**: Deprecated `RouteLayout.definePath` in favor of `coordinator.defineLayoutBuilder`.

### 📖 Documentation

- **Architecture Overview**: Completely redesigned READMEs to highlight the layered architecture and paradigm decisions.
- **API Reference**: Rewrote coordinator, mixins, and navigation paths API references from source.

## 1.2.0

### 🐞 Fixes
- **Fix**: Regression error when using `RouteRedirectRule` inside `IndexedStackPath` (Thanks to @obenkucuk)

### 🚀 New Features

#### Coordinator as RouteModule — Nested Coordinators
- `Coordinator` now implements `RouteModule<T>`, enabling any coordinator to be nested inside a `CoordinatorModular` by overriding the `coordinator` getter.
- Unlocks **route versioning** (V1/V2 side by side), multi-team modular architectures, and deeply nested coordinator hierarchies.
- Auto-detected `isRouteModule` flag controls root path creation vs parent inheritance.
- See [Guide](doc/guides/coordinator-as-module.md) & `example/lib/main_coordinator_module.dart`

### ⚠️ Breaking Changes

- **`Coordinator.parseRouteFromUri`** signature changed from `FutureOr<T>` to `FutureOr<T?>`. Child coordinators return `null` for unrecognized URIs; standalone coordinators are guarded by assertions.
- **`CoordinatorModular.parseRouteFromUri`** returns `null` instead of `notFoundRoute` when the coordinator is itself a nested module.

### 📖 Documentation

- **New Guide**: [Coordinator as RouteModule](doc/guides/coordinator-as-module.md)
- **New Recipe**: [Route Versioning](doc/recipes/route-versioning.md)

## 1.1.0

- BREAKING CHANGE: Remove `coordinator` from `defineModules`, use `this` getter instead.
- Feat: Enforce `getModule` method return exact type.

## 1.0.0

🎉 **Major Release - Production Ready**

### 🚀 New Features

#### CoordinatorModular - Modular Route Management
- Split route management across independent modules by domain/feature
- `CoordinatorModular` mixin + `RouteModule` base class
- Perfect for large apps with team collaboration
- See [Guide](doc/guides/coordinator-modular.md) & `example/lib/main_modular.dart`

```dart
class AppCoordinator extends Coordinator<AppRoute>
    with CoordinatorModular<AppRoute> {
  @override
  Set<RouteModule<AppRoute>> defineModules() => {
    AuthModule(this),
    ShopModule(this),
  };
}
```

#### RouteRedirectRule - Composable Redirect Logic
- Reusable, chainable redirect rules (auth → feature flags → logging)
- `RedirectResult` sealed class with `Stop`/`Continue`/`RedirectTo` variants
- Async support for API calls, database queries

```dart
class ProtectedRoute extends AppRoute
    with RouteRedirect, RouteRedirectRule {
  @override
  List<RedirectRule> get redirectRules => [
    AuthenticationRule(),
    PermissionRule(permission: 'admin'),
  ];
}
```

### ⚠️ Breaking Changes

**Removed deprecated APIs:**
- `RouteLayout.buildPrimitivePath` → Use `RouteLayout.buildPath`
- `RouteLayout.layoutBuilderTable` → Use `RouteLayout.buildPath`
- `RouteLayout.navigationPath`/`indexedStackPath` → Use `NavigationPath.key`/`IndexedStackPath.key`
- `routerDelegateWithInitialRoute` → Use `RouteRedirect` in `IndexRoute`

See [Migration Guide](MIGRATION_GUIDE.md) for details.

### 📦 What's Included

- ✅ Stable API surface
- ✅ Full test coverage (48 new tests: 33 modular + 15 redirect rule)
- ✅ Comprehensive documentation with guides

---

## 0.4.20

* **Fix**: back gesture failed in android

## 0.4.19

* **Fix**: Blank screen when using `Coordinator` as `routerConfig` (due to unset `routerInformationProvider`).
* **Feat**: Added `initialRoutePath` property to `Coordinator`.
* **Feat**: Added `NavigatorObserverListGetter` typedef for passing external observers. ([View Guide](https://github.com/definev/zenrouter/blob/main/packages/zenrouter/doc/guides/navigator-observers.md#passing-observers-from-outside))

## 0.4.18
- **Feat**: Add `pushReplacement` method in `StackMutatable`.
- **Feat**: `Coordinator` now implements `RouterConfig` so you can use it with `MaterialApp.router` more easily.
  - ```dart
    MaterialApp.router(
      // New way
      routerConfig: coordinator,
      // Old way
      routerDelegate: coordinator.routerDelegate,
      routeInformationParser: coordinator.routeInformationParser,
    );
    ```
- **Deprecate**: `routerDelegateWithInitialRoute` is deprecated, you can simulate the same behavior by using `RouteRedirect` in `IndexRoute`.

## 0.4.17
- ZenRouter officially achieved 100% test coverage 🚀
- **Docs**: Added migration guides from other packages (go_router, auto_route, and Navigator 1.0/2.0)
- **Docs**: Added recipes for common use cases
- **Docs**: Added quick links section to make the docs easier to navigate

## 0.4.16
- **Fix**: Future already completed bug when pushing the same route with `pushOrMoveToTop`.

## 0.4.15
- **Feat**: Add `onUpdate` method to `RouteTarget` for handling in-place route updates when navigating to the same route with different state.
- **Feat**: Add `bindLayout` method to `StackPath` as a convenient alternative for layout registration. (See [RouteLayout Guide](doc/guides/route-layout.md))

## 0.4.14
- **Breaking Change**: Don't allow `redirect` to return null anymore since it doesn't do anything.
- **Feat**: Add `mustCallSuper` to `paths` getter (Thanks @mrgnhnt96)
- **Feat**: Add `discard` parameter to `remove` method for controlling discarding behavior.
- **Fix**: Memory leak when pushing `RouteQueryParameters` in `IndexedStackPath`.
- **Fix**: Memory leak when discard route in `RouteRedirect`.

## 0.4.13
- **Fix**: Ensure `navigate` method is compatible with `RouteRedirect`.

## 0.4.12
- **Feat**: Introduce new `StackNavigatable` mixin for `StackPath` to handle custom logic when receiving a `navigate` command. (Back/Forward button on the browser)
- **Fix**: `navigate` clear all history that occurred when pushing a custom layout.

## 0.4.11
- **Feat**: Expose `stackPath` in `RouteTarget` and expose `protected` method for developer create custom `stackPath`.
- **Feat**: Add `onDiscard` to handle discarding phase in `RouteTarget`.

## 0.4.10
- **Chore**: Fix analyzer warnings

## 0.4.9
- **Chore**: Standardize `serialize` and `deserialize` for supported `RouteTarget` type

## 0.4.8
- **Feat**: Introduce new state restoration with `RouteRestoration` mixin. Support state restoration by default if `restorationScopeId` is provided in `MaterialApp.router` and using `Coordinator` pattern.
- **Fix**: Resolve bug in `recover` method where `RouteRedirect` was ignored.

## 0.4.7
- **Docs**: Update README

## 0.4.6
- **Docs**: Update README and add screenshots

## 0.4.5
- **Feat**: Add `RouteQueryParameters` mixin for targeted query parameter updates using `ValueNotifier`.
- **Fix**: Ensure `path` is set for `RouteTarget` when initial `IndexedStackPath`.
- **Fix**: Ensure `layout` is resolve correct if they under deeper stack.
- **Refactor**: Refactor folder structure and test folder structure to be more organized.

## 0.4.4
- **Feat**: New ZenRoute Logo!
- **Docs**: Improve document and update outdate example

## 0.4.3
- **Feat**: Add `CoordinatorNavigatorObserver` mixin to provide a list of observers for the coordinator's navigator.
- **Breaking Change**: Complete redesign [RouteLayout] builder to be more flexible and powerful.
  - Deprecate static method `RouteLayout.buildPrimitivePath` and use `buildPath` function instead.
  - Add ability to define new [StackPath] using `RouteLayout.definePath`. You can create custom behavior path builder. (Eg: RecoverableHistoryStack like unrouter)

## 0.4.2
- **Feat**: Add `transitionStrategy` to `Coordinator` for default stack transition setup
- **Fix**: Ensure when [Navigator.pop] called sync new stack with [NavigationPath]

## 0.4.1
- **Fix**: Ensure [Coordinator.routeDelegate] initialize once
- **Improvement**: Add [IndexedStackPathBuilder] for improve performance for rendering [IndexedStackPath]

## 0.4.0
- **Breaking Change**: Deprecated default constructors for `NavigationPath` and `IndexedStackPath`. Use `NavigationPath.create`/`createWith` and `IndexedStackPath.create`/`createWith` instead.
- **Breaking Change**: Introduced `internalProps` to `RouteTarget` for better deep equality and hash code generation.
- **Feat**: Added `popGuardWith` to `RouteGuard` and `redirectWith` to `RouteRedirect` for coordinator-aware mixin logic.
- **Feat**: Added strict path-coordinator binding support via `createWith` factories.
- **Docs**: Added comprehensive [Migration Guide](MIGRATION_GUIDE.md).
- **Feat**: Added `routerDelegateWithInitalRoute` to `Coordinator`.
- **Feat**: Enhanced `setInitialRoutePath` to correctly handle initial routes vs deep links.

## 0.3.2
- Add `navigate` function: A smarter alternative to `push` that handles browser history restoration by popping to existing routes instead of duplicating them.

## 0.3.1
- Allow `parseRouteFromUri` to return `Future` for implementing deferred import/async route parsing

## 0.3.0
- Breaking change: Change return of `Coordinator.push()` from `Future<dynamic>` to `Future<T?>`
- Fix `NavigationStack` rerender page everytime `path` updated. Resolve [#10](https://github.com/definev/zenrouter/issues/10).
- Feat: Add `recover` function

## 0.2.3
- Update `activePathIndex` to `activeIndex` in `IndexedStackPath`
- Update document for detailed, hand-written example of Coordinator pattern

## 0.2.2
- Expose pop result in Coordinator
- **Fix memory leak**: Complete route result futures when routes are removed via `pushOrMoveToTop`
- **Fix memory leak**: Complete intermediate route futures during `RouteRedirect.resolve` chain

## 0.2.1
- Standardize how to access primitive path layout builder
    - Define using `definePrimitivePath`
    - Build using `buildPrimitivePath`

## 0.2.0
- BREAKING: Rename `activeHostPaths` to `activeLayoutPaths` to reflect correct concept.

## 0.1.2
- Update homepage link

## 0.1.1
- Fix broken document link by update it to github link

## 0.1.1
- Fix broken document link

## 0.1.0

- Initial release of ZenRouter.
- Unified Navigator 1.0 and 2.0 support.
- Coordinator pattern for centralized navigation logic.
- Support for both Declarative and Imperative navigation paradigms.
- Route mixins: `RouteGuard`, `RouteRedirect`, `RouteDeepLink`.
- Optimized Myers diff algorithm for efficient stack updates.
- Type-safe routing with `RouteUnique`.
