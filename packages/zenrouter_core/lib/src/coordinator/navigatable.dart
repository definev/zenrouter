part of 'base.dart';

/// Mixin for coordinators that support smart history navigation.
///
/// Compose with [CoordinatorLayoutCore] (and optionally [CoordinatorMutatable])
/// to build a coordinator with only the capabilities you need.
mixin CoordinatorNavigatable<T extends RouteUri> on CoordinatorLayoutCore<T>
    implements Navigatable<T> {
  /// Navigates to a route with smart history handling.
  ///
  /// If route exists in stack, pops back to it. Otherwise pushes new route.
  /// Used for browser back/forward navigation.
  @override
  Future<void> navigate(T route) => runNavigationTransaction(() async {
    final target = await RouteRedirect.resolve(route, this);
    if (target == null) return;

    final parentLayout = target.resolveParentLayout(this);
    if (parentLayout != null) {
      await prepareParentLayoutList(
        parentLayout,
        strategy: _ResolveLayoutStrategy.pushToTop,
      );
    }

    final parentPath = parentLayout?.resolvePath(this) ?? root;

    assert(
      parentPath is StackNavigatable,
      'ZenRouter: parentPath (${parentPath.pathKey.key}) does not implement '
      'StackNavigatable. The navigate() call for route $route will have no '
      'effect on the navigation stack or browser history.',
    );

    if (parentPath case StackNavigatable parentPath) {
      final intent = switch (parentPath) {
        StackMutatable() when parentPath.stack.contains(target) =>
          NavigationHistoryIntent.replace,
        _ => NavigationHistoryIntent.push,
      };
      recordHistoryIntent(intent);
      await parentPath.navigate(target);
    }
  });
}
