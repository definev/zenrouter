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
