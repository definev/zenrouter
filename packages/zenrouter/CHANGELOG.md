## 0.4.14
- **Breaking Change**: Don't allow `redirect` to return null anymore since it won't do anything.
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
