// ignore_for_file: invalid_use_of_protected_member

part of 'base.dart';

/// Mixin for stack paths that support mutable navigation operations.
///
/// Provides push/pop functionality for navigating between routes.
/// This mixin is applied to paths that need dynamic navigation.
mixin StackMutatable<T extends RouteTarget> on StackPath<T>
    implements StackNavigatable<T> {
  /// Adds a new route to the top of the stack.
  ///
  /// Resolves redirects via [RouteRedirect.resolve] before pushing.
  /// Returns a future that completes when the popped route provides a result.
  Future<R?> push<R extends Object>(T element) async {
    T? target = await RouteRedirect.resolve(element, coordinator);
    if (target == null) return null;

    target.isPopByPath = false;
    target.bindStackPath(this);
    _stack.add(target);
    notifyListeners();
    // ignore: invalid_use_of_visible_for_testing_member
    return await target.onResult.future as R?;
  }

  /// Replaces the current route with a new one.
  ///
  /// Behavior depends on stack state:
  /// - Empty stack: Pushes the new route normally
  /// - Single element: Completes active route, resets, then pushes new route
  /// - Multiple elements: Pops top route (respecting guards), then pushes new route
  ///
  /// Returns null if redirect resolution fails or guard blocks the pop.
  Future<R?> pushReplacement<R extends Object, RO extends Object>(
    T element, {
    RO? result,
  }) async {
    T? target = await RouteRedirect.resolve(element, coordinator);
    if (target == null) return null;

    final activeRoute = this.activeRoute;
    if (activeRoute case final activeRoute?) {
      if (stack.length == 1) {
        activeRoute.completeOnResult(result, coordinator);
        activeRoute.onDiscard();
        reset();
        return push(target);
      }

      final popped = await pop(result);
      if (popped == null || !popped) return null;
      // ignore: invalid_use_of_visible_for_testing_member
      await activeRoute.onResult.future;
      return push(target);
    }

    return push(target);
  }

  /// Adds a route to the top, or moves it to the top if already in stack.
  ///
  /// If the route exists in the stack, it's moved to the top position.
  /// If not, it's pushed as a new entry. Useful for tab navigation.
  Future<void> pushOrMoveToTop(T element) async {
    T? target = await RouteRedirect.resolve(element, coordinator);
    if (target == null) return;

    target.isPopByPath = false;
    target.bindStackPath(this);
    final index = _stack.indexOf(target);
    if (_stack.isNotEmpty && index == _stack.length - 1) {
      final last = _stack.last;
      last.onUpdate(target);
      if (!last.deepEquals(target)) {
        target.onDiscard();
        target.clearStackPath();
      }
      return;
    }

    if (index != -1) {
      final removed = _stack.removeAt(index);
      if (!removed.deepEquals(target)) {
        removed.onDiscard();
        removed.clearStackPath();
      }
    }
    _stack.add(target);
    notifyListeners();
  }

  /// Removes the top route from the stack.
  ///
  /// Consults [RouteGuard] before removing. Unlike [remove], this only
  /// operates on the top route and respects guard logic.
  ///
  /// Returns:
  /// - `true`: Pop completed successfully
  /// - `false`: Guard blocked the pop
  /// - `null`: Stack was empty
  Future<bool?> pop([Object? result]) async {
    if (_stack.isEmpty) {
      return null;
    }
    final last = _stack.last;
    if (last is RouteGuard) {
      final canPop = await switch (coordinator) {
        null => last.popGuard(),
        final coordinator => last.popGuardWith(coordinator),
      };
      if (!canPop) return false;
    }

    final element = _stack.removeLast();
    element.isPopByPath = true;
    element.bindResultValue(result);
    notifyListeners();
    return true;
  }

  /// Removes a specific route from any position in the stack.
  ///
  /// Unlike [pop], this bypasses guards and operates on any index.
  /// Used for system-initiated removals or forced cleanup.
  void remove(T element, {bool discard = true}) {
    final removed = _stack.remove(element);
    if (removed) {
      if (discard) element.onDiscard();
      element.clearStackPath();
      notifyListeners();
    }
  }

  @override
  Future<void> navigate(T route) async {
    T? target = await RouteRedirect.resolve(route, coordinator);
    if (target == null) return;

    final routeIndex = stack.indexOf(target);
    if (routeIndex != -1) {
      while (stack.length > routeIndex + 1) {
        final allowPop = await pop();
        if (allowPop == null || !allowPop) {
          notifyListeners();
          return;
        }
      }

      final existingRoute = stack[routeIndex];
      existingRoute.onUpdate(target);
      notifyListeners();

      if (!existingRoute.deepEquals(target)) {
        target.onDiscard();
      }
    } else {
      await push(target);
    }
  }
}
