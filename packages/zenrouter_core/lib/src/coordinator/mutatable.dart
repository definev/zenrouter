part of 'base.dart';

/// Mixin for coordinators that support push/pop/replace stack mutations.
///
/// Compose with [CoordinatorLayoutCore] (and optionally [CoordinatorNavigatable])
/// to build a coordinator with only the capabilities you need.
mixin CoordinatorMutatable<T extends RouteUri> on CoordinatorLayoutCore<T>
    implements Mutatable<T> {
  /// Clears all paths and sets a single route as the new state.
  Future<void> replace(T route) => runNavigationTransaction(() async {
    final target = await RouteRedirect.resolve(route, this);
    if (target == null) return;

    for (final path in paths) {
      path.reset();
    }

    final parentLayout = target.resolveParentLayout(this);
    if (parentLayout != null) {
      await prepareParentLayoutList(
        parentLayout,
        strategy: _ResolveLayoutStrategy.override,
      );
    }

    final parentPath = parentLayout?.resolvePath(this) ?? root;
    await parentPath.activateRoute(target);
  }, historyIntent: NavigationHistoryIntent.replace);

  /// Adds a route to the navigation stack.
  ///
  /// Resolves redirects, ensures layout hierarchy is active, then pushes to path.
  /// Returns a future that completes when the route is popped with a result.
  @override
  Future<R?> push<R extends Object>(T route) async {
    T? committedRoute;
    await runNavigationTransaction(() async {
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
      switch (parentPath) {
        case final StackMutatable<T> mutablePath:
          committedRoute = mutablePath.commitResolvedRoute(target);
        default:
          await parentPath.activateRoute(target);
      }
    }, historyIntent: NavigationHistoryIntent.push);

    if (committedRoute == null) return null;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    return await committedRoute!.onResult.future as R?;
  }

  /// Adds a route and completes once the stack mutation is committed.
  ///
  /// Unlike [push], this method does not wait for the route to be popped and
  /// does not return a pop result. Router/deep-link integrations should use
  /// this method when they need to await navigation completion.
  Future<void> pushSilently(T route) => runNavigationTransaction(() async {
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
    switch (parentPath) {
      case final StackMutatable<T> mutablePath:
        mutablePath.commitResolvedRoute(target);
      default:
        await parentPath.activateRoute(target);
    }
  }, historyIntent: NavigationHistoryIntent.push);

  /// Pushes a route to the top, or moves it to top if already in stack.
  ///
  /// Useful for tab navigation to switch without duplicating entries.
  @override
  Future<void> pushOrMoveToTop(T route) => runNavigationTransaction(() async {
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

    switch (parentPath) {
      case StackMutatable():
        await parentPath.pushOrMoveToTop(target);
      default:
        await parentPath.activateRoute(target);
    }
  }, historyIntent: NavigationHistoryIntent.push);

  /// Replaces the current route with a new one.
  ///
  /// Pops the current route (respecting guards) then pushes the new route.
  @override
  Future<R?> pushReplacement<R extends Object, RO extends Object>(
    T route, {
    RO? result,
  }) async {
    T? committedRoute;
    await runNavigationTransaction(() async {
      final target = await RouteRedirect.resolve(route, this);
      if (target == null) return;

      final parentLayout = target.resolveParentLayout(this);
      final parentPath = parentLayout?.resolvePath(this) ?? root;

      final currentPath = activePath;
      final currentRoute = currentPath.activeRoute;
      if (currentPath case StackMutatable activePath
          when currentRoute != null && activePath != parentPath) {
        if (activePath.stack.length == 1) {
          currentRoute.completeOnResult(result, this);
          activePath.reset();
        } else {
          final popped = await activePath.pop(result);
          if (popped == null || !popped) return;
          // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
          await currentRoute.onResult.future;
        }
      }

      if (parentLayout != null) {
        await prepareParentLayoutList(
          parentLayout,
          strategy: _ResolveLayoutStrategy.pushToTop,
        );
      }

      if (parentPath case final StackMutatable<T> mutablePath) {
        committedRoute = await mutablePath.commitResolvedReplacement(
          target,
          result: result,
        );
      }
    }, historyIntent: NavigationHistoryIntent.replace);

    if (committedRoute == null) return null;
    // ignore: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member
    return await committedRoute!.onResult.future as R?;
  }

  /// Pops from the nearest eligible path with at least two entries.
  ///
  /// Only the deepest mutatable path is popped. Unlike the previous
  /// multi-path behavior, nested shells are not popped together with
  /// their child stacks in a single call.
  Future<void> pop([Object? result]) => runNavigationTransaction(() async {
    final dynamicPaths = activePaths.whereType<StackMutatable>().toList();

    for (var i = dynamicPaths.length - 1; i >= 0; i--) {
      final path = dynamicPaths[i];
      if (path.stack.length >= 2) {
        await path.pop(result);
        return;
      }
    }
  }, historyIntent: NavigationHistoryIntent.replace);

  /// Attempts to pop from the nearest eligible path.
  ///
  /// Returns true if pop succeeded, false if blocked by guard, null if no path eligible.
  Future<bool?> tryPop([Object? result]) => runNavigationTransaction(() async {
    final mutatablePaths = activePaths.whereType<StackMutatable>().toList();

    for (var i = mutatablePaths.length - 1; i >= 0; i--) {
      final path = mutatablePaths[i];
      if (path.stack.length >= 2) {
        return path.pop(result);
      }
    }

    return null;
  }, historyIntent: NavigationHistoryIntent.replace);
}
