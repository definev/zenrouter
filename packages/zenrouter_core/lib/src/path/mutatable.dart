// ignore_for_file: invalid_use_of_protected_member

part of 'base.dart';

/// Mixin for stack paths that support mutable navigation operations.
///
/// Provides push/pop functionality for navigating between routes.
/// This mixin is applied to paths that need dynamic navigation.
///
/// Implements the shared [Mutatable] contract also used by
/// [CoordinatorMutatable].
mixin StackMutatable<T extends RouteTarget> on StackPath<T>
    implements StackNavigatable<T>, Mutatable<T>, StackCommit<T> {
  /// Replaces the entire stack as one observable mutation.
  ///
  /// Route instances retained by identity keep their lifecycle. Removed
  /// instances are discarded, while incoming instances are rebound to this
  /// path. This is intended for declarative adapters that must not expose an
  /// intermediate empty stack while applying a diff.
  void replaceAll(Iterable<T> routes) {
    final nextStack = List<T>.of(routes);
    final retainedRoutes = Set<T>.identity()..addAll(nextStack);

    for (final route in _stack) {
      if (retainedRoutes.contains(route)) continue;
      route.onDiscard();
      route.clearStackPath();
    }

    for (final route in nextStack) {
      route.isPopByPath = false;
      route.bindStackPath(this);
    }

    _stack
      ..clear()
      ..addAll(nextStack);
    notifyListeners();
  }

  /// Adds a new route to the top of the stack.
  ///
  /// Resolves redirects via [RouteRedirect.resolve] before pushing.
  /// Returns a future that completes when the popped route provides a result.
  @override
  Future<R?> push<R extends Object>(T element) async {
    final target = await commitRoute(element);
    if (target == null) return null;

    // ignore: invalid_use_of_visible_for_testing_member
    return await target.onResult.future as R?;
  }

  /// Resolves redirects and commits a route, returning the actual stack entry.
  @internal
  Future<T?> commitRoute(T element) async {
    final target = await RouteRedirect.resolve(element, coordinator);
    if (target == null) return null;
    return commitResolvedRoute(target);
  }

  /// Commits a route whose redirect and layout have already been resolved.
  @override
  @internal
  T commitResolvedRoute(T target) {
    _addRouteToStack(target);
    return target;
  }

  /// Adds a route to the stack without subscribing to its pop result.
  ///
  /// Same stack mutation as [push], but the returned future completes once
  /// the route is on the stack instead of when it is later popped.
  @override
  Future<void> pushSilently(T element) async {
    await commitRoute(element);
  }

  void _addRouteToStack(T target) {
    target.isPopByPath = false;
    target.bindStackPath(this);
    _stack.add(target);
    notifyListeners();
  }

  /// Replaces the current route with a new one.
  ///
  /// Behavior depends on stack state:
  /// - Empty stack: Pushes the new route normally
  /// - Single element: Completes active route, resets, then pushes new route
  /// - Multiple elements: Pops top route (respecting guards), then pushes new route
  ///
  /// Returns null if redirect resolution fails or guard blocks the pop.
  @override
  Future<R?> pushReplacement<R extends Object, RO extends Object>(
    T element, {
    RO? result,
  }) async {
    final target = await commitReplacement(element, result: result);
    if (target == null) return null;

    // ignore: invalid_use_of_visible_for_testing_member
    return await target.onResult.future as R?;
  }

  /// Resolves and commits a replacement without waiting for its later result.
  @internal
  Future<T?> commitReplacement<RO extends Object>(
    T element, {
    RO? result,
  }) async {
    final target = await RouteRedirect.resolve(element, coordinator);
    if (target == null) return null;
    return commitResolvedReplacement(target, result: result);
  }

  /// Commits an already-resolved replacement route.
  @override
  @internal
  Future<T?> commitResolvedReplacement<RO extends Object>(
    T target, {
    RO? result,
  }) async {
    final activeRoute = this.activeRoute;
    if (activeRoute case final activeRoute?) {
      if (stack.length == 1) {
        activeRoute.completeOnResult(result, coordinator);
        reset();
        return commitResolvedRoute(target);
      }

      final popped = await pop(result);
      if (popped == null || !popped) return null;
      return commitResolvedRoute(target);
    }

    return commitResolvedRoute(target);
  }

  /// Adds a route to the top, or moves it to the top if already in stack.
  ///
  /// If the route exists in the stack, it's moved to the top position.
  /// If not, it's pushed as a new entry. Useful for tab navigation.
  @override
  Future<void> pushOrMoveToTop(T element) async {
    T? target = await RouteRedirect.resolve(element, coordinator);
    if (target == null) return;
    commitResolvedMoveToTop(target);
  }

  /// Moves an already-resolved route to the top, or appends it.
  @override
  @internal
  void commitResolvedMoveToTop(T target) {
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
    // Complete and tear down here so push()/pushReplacement do not depend on
    // a later Flutter page callback. Awaiting onResult inside a transaction
    // hung headless and blocked the queue; skipping it left results pending
    // when pop+push landed in the same frame.
    element.completeOnResult(result, coordinator, true);
    element.onDidPop(result, coordinator);
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
    await commitResolvedNavigate(target);
  }

  /// Pops back to an already-resolved route, or commits it as a new entry.
  @override
  @internal
  Future<void> commitResolvedNavigate(T target) async {
    final routeIndex = _indexOfNavigateTarget(target);
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
      return;
    }

    commitResolvedRoute(target);
  }

  /// Prefers the same lifecycle entry over the first value-equal route.
  ///
  /// `navigate(existingInstance)` must pop back to that instance even when an
  /// earlier stack entry compares equal (empty `props`, shared path params).
  /// A newly parsed, value-equal instance still matches the first occupant.
  int _indexOfNavigateTarget(T target) {
    final identityIndex = _stack.indexWhere(
      (route) => route.deepEquals(target),
    );
    if (identityIndex != -1) return identityIndex;
    return _stack.indexOf(target);
  }
}
