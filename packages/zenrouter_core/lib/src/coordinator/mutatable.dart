part of 'base.dart';

/// Mixin for coordinators that support push/pop/replace stack mutations.
///
/// Compose with [CoordinatorLayoutCore] (and optionally [CoordinatorNavigatable])
/// to build a coordinator with only the capabilities you need.
mixin CoordinatorMutatable<T extends RouteUri> on CoordinatorLayoutCore<T>
    implements Mutatable<T> {
  /// Clears all paths and sets a single route as the new state.
  Future<void> replace(T route) async {
    T? target = await RouteRedirect.resolve(route, this);
    if (target == null) return;

    recordHistoryIntent(NavigationHistoryIntent.replace);

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
  }

  /// Adds a route to the navigation stack.
  ///
  /// Resolves redirects, ensures layout hierarchy is active, then pushes to path.
  /// Returns a future that completes when the route is popped with a result.
  @override
  Future<R?> push<R extends Object>(T route) async {
    T? target = await RouteRedirect.resolve(route, this);
    if (target == null) return null;

    recordHistoryIntent(NavigationHistoryIntent.push);

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
        return parentPath.push(target);
      default:
        await parentPath.activateRoute(target);
        return null;
    }
  }

  /// Adds a route and completes once the stack mutation is committed.
  ///
  /// Unlike [push], this method does not wait for the route to be popped and
  /// does not return a pop result. Router/deep-link integrations should use
  /// this method when they need to await navigation completion.
  Future<void> pushSilently(T route) async {
    final target = await RouteRedirect.resolve(route, this);
    if (target == null) return;

    recordHistoryIntent(NavigationHistoryIntent.push);

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
        await parentPath.pushSilently(target);
      default:
        await parentPath.activateRoute(target);
    }
  }

  /// Pushes a route to the top, or moves it to top if already in stack.
  ///
  /// Useful for tab navigation to switch without duplicating entries.
  @override
  Future<void> pushOrMoveToTop(T route) async {
    final target = await RouteRedirect.resolve(route, this);
    if (target == null) return;

    recordHistoryIntent(NavigationHistoryIntent.push);

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
  }

  /// Replaces the current route with a new one.
  ///
  /// Pops the current route (respecting guards) then pushes the new route.
  @override
  Future<R?> pushReplacement<R extends Object, RO extends Object>(
    T route, {
    RO? result,
  }) async {
    final target = await RouteRedirect.resolve(route, this);
    if (target == null) return null;

    recordHistoryIntent(NavigationHistoryIntent.replace);

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
        if (popped == null || !popped) return null;
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

    if (parentPath case StackMutatable parentPath) {
      return parentPath.pushReplacement(target, result: result);
    }

    return null;
  }

  /// Pops from the nearest eligible path with at least two entries.
  ///
  /// Only the deepest mutatable path is popped. Unlike the previous
  /// multi-path behavior, nested shells are not popped together with
  /// their child stacks in a single call.
  Future<void> pop([Object? result]) async {
    final dynamicPaths = activePaths.whereType<StackMutatable>().toList();

    for (var i = dynamicPaths.length - 1; i >= 0; i--) {
      final path = dynamicPaths[i];
      if (path.stack.length >= 2) {
        final popped = await path.pop(result);
        if (popped == true) {
          recordHistoryIntent(NavigationHistoryIntent.replace);
        }
        return;
      }
    }
  }

  /// Attempts to pop from the nearest eligible path.
  ///
  /// Returns true if pop succeeded, false if blocked by guard, null if no path eligible.
  Future<bool?> tryPop([Object? result]) async {
    final mutatablePaths = activePaths.whereType<StackMutatable>().toList();

    for (var i = mutatablePaths.length - 1; i >= 0; i--) {
      final path = mutatablePaths[i];
      if (path.stack.length >= 2) {
        final popped = await path.pop(result);
        if (popped == true) {
          recordHistoryIntent(NavigationHistoryIntent.replace);
        }
        return popped;
      }
    }

    return null;
  }
}
