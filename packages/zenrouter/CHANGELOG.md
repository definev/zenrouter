## 0.3.0
- Breaking change: Change return of `Coordinator.push()` from `Future<dynamic>` to `Future<T?>`
- Fix `NavigationStack` rerender page everytime `path` updated. Resolve [#10](https://github.com/definev/zenrouter/issues/10).

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
