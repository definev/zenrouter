// ignore_for_file: invalid_use_of_protected_member

part of 'base.dart';

/// Mixin for stack paths that support mutable operations (push/pop).
///
/// Apply this mixin to [StackPath] subclasses that need push/pop navigation.
/// This provides standard implementations for:
/// - [push]: Add a route to the top
/// - [pushReplacement]: Pop the top route and push a new one
/// - [pushOrMoveToTop]: Add or promote existing route
/// - [pop]: Remove the top route (with guard support)
/// - [remove]: Remove a specific route from the stack
mixin StackMutatable<T extends RouteTarget> on StackPath<T>
    implements StackNavigatable<T> {
  /// Pushes a new route onto the stack.
  ///
  /// This handles redirects and sets up the route's path reference.
  /// Returns a future that completes when the route is popped with a result.
  ///
  /// **Error Handling:**
  /// Exceptions from [RouteRedirect.resolve] propagate to the caller.
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

  /// Pops the current route and pushes a new route in its place.
  ///
  /// This is useful for replacing the current screen without adding to the
  /// navigation history. The new route takes the place of the popped route.
  ///
  /// **Behavior based on stack state:**
  /// - **Empty stack:** Pushes the new route normally
  /// - **Single element:** Completes the active route with [result], resets
  ///   the stack, then pushes the new route
  /// - **Multiple elements:** Pops the top route (respecting [RouteGuard]),
  ///   waits for the pop animation, then pushes the new route
  ///
  /// **Parameters:**
  /// - [element]: The new route to push after popping
  /// - [result]: Optional result to pass to the popped route's push future
  ///
  /// **Returns:**
  /// - A [Future] that completes with the result when the new route is popped
  /// - `null` if redirect resolution returns null or guard blocks the pop
  ///
  /// **Error Handling:**
  /// Exceptions from [RouteRedirect.resolve] propagate to the caller.
  /// If a [RouteGuard] blocks the pop, returns `null` without pushing.
  Future<R?> pushReplacement<R extends Object, RO extends Object>(
    T element, {
    RO? result,
  }) async {
    T? target = await RouteRedirect.resolve(element, coordinator);
    if (target == null) return null;

    final activeRoute = this.activeRoute;
    if (activeRoute case final activeRoute?) {
      // Manually complete the active route since it is the only one on the stack
      if (stack.length == 1) {
        activeRoute.completeOnResult(result, coordinator);
        reset();
        return push(target);
      }

      final popped = await pop(result);
      // Pop is prevented by guard
      if (popped == null || !popped) return null;
      // Wait the pop animation to finish
      // ignore: invalid_use_of_visible_for_testing_member
      await activeRoute.onResult.future;
      return push(target);
    }

    // If the active route is null => push normal
    return push(target);
  }

  /// Pushes a route to the top of the stack, or moves it if already present.
  ///
  /// If the route is already in the stack, it's moved to the top.
  /// If not, it's added to the top. Follows redirects like [push].
  ///
  /// Useful for tab navigation where you want to switch to a tab
  /// without duplicating it in the stack.
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

  /// Removes the top route from the navigation stack.
  ///
  /// **Difference from [remove] on concrete path implementations:**
  /// - [pop]: Respects [RouteGuard], removes only the top route, returns result
  /// - [remove]: Bypasses guards, can remove at any index, returns no result
  ///
  /// **Return values:**
  /// - `true`: Pop was successful
  /// - `false`: Guard cancelled the pop (route remains on stack)
  /// - `null`: Stack was empty (nothing to pop)
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

  /// Removes a specific route from the stack at any position.
  ///
  /// **Difference from [pop]:**
  /// - [remove]: Bypasses guards, can remove at any index, no result returned
  /// - [pop]: Respects [RouteGuard], only removes top route, returns result
  ///
  /// **When to use:**
  /// - Removing routes that were force-closed by the system
  /// - Cleaning up routes during navigation state changes
  /// - Internal framework operations
  ///
  /// **Avoid when:**
  /// - User-initiated back navigation (use [pop] instead)
  /// - You need to respect guards
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
      // Pop until we reach the target route
      while (stack.length > routeIndex + 1) {
        final allowPop = await pop();
        if (allowPop == null || !allowPop) {
          // Guard blocked navigation or stack is empty - restore the URL
          notifyListeners();
          return;
        }
      }

      final existingRoute = stack[routeIndex];
      existingRoute.onUpdate(target);
      notifyListeners();

      /// If routes differ by hash code, discard the incoming route
      if (!existingRoute.deepEquals(target)) {
        target.onDiscard();
      }
    } else {
      await push(target);
    }
  }
}
