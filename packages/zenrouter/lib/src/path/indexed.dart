// ignore_for_file: invalid_use_of_protected_member

import 'package:flutter/widgets.dart';
import 'package:zenrouter/src/coordinator/base.dart';
import 'package:zenrouter/src/path/restoration.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

/// A fixed stack path for indexed navigation (like tabs).
///
/// Routes are pre-defined and cannot be added or removed. Navigation switches
/// the active index.
class IndexedStackPath<T extends RouteTarget> extends StackPath<T>
    with StackNavigatable<T>, RestorablePath<T, int, int>, ChangeNotifier {
  IndexedStackPath._(super.stack, {super.debugLabel, super.coordinator})
    : assert(stack.isNotEmpty, 'Read-only path must have at least one route'),
      super() {
    for (final path in stack) {
      /// Set the output of every route to null since this cannot pop
      path.completeOnResult(null, null);
      path.bindStackPath(this);
    }
  }

  /// Creates an [IndexedStackPath] with a fixed list of routes.
  ///
  /// This is the standard way to create a fixed stack for indexed navigation.
  factory IndexedStackPath.create(
    List<T> stack, {
    String? label,
    Coordinator? coordinator,
  }) => IndexedStackPath._(stack, debugLabel: label, coordinator: coordinator);

  /// Creates an [IndexedStackPath] associated with a [Coordinator].
  ///
  /// This constructor binds the path to a specific coordinator, allowing it to
  /// interact with the coordinator for navigation actions.
  factory IndexedStackPath.createWith(
    List<T> stack, {
    required Coordinator coordinator,
    required String label,
  }) => IndexedStackPath._(stack, debugLabel: label, coordinator: coordinator);

  /// The key used to identify this type in [RouteLayout.definePath].
  static const key = PathKey('IndexedStackPath');

  /// IndexedStackPath key. This is used to identify this type in [RouteLayout.definePath].
  @override
  PathKey get pathKey => key;

  int _activeIndex = 0;

  /// The index of the currently active path in the stack.
  int get activeIndex => _activeIndex;

  @override
  T get activeRoute => stack[activeIndex];

  /// Switches the active route to the one at [index].
  ///
  /// Handles guards on the current route and redirects on the new route.
  Future<void> goToIndexed(int index) async {
    if (index >= stack.length || index < 0) {
      throw StateError('Index out of bounds');
    }

    /// Ignore already active index
    if (index == _activeIndex) return;

    final oldIndex = _activeIndex;
    final oldRoute = stack[oldIndex];
    if (oldRoute is RouteGuard) {
      final guard = oldRoute as RouteGuard;
      final canPop = await switch (coordinator) {
        null => guard.popGuard(),
        final coordinator => guard.popGuardWith(coordinator),
      };
      if (!canPop) return;
    }
    var newRoute = stack[index];
    while (newRoute is RouteRedirect) {
      final routeRedirect = newRoute as RouteRedirect;
      final redirectTo = await switch (coordinator) {
        null => routeRedirect.redirect(),
        final coordinator => routeRedirect.redirectWith(coordinator),
      };
      assert(
        redirectTo == null || redirectTo is T,
        'Redirected route must be the same type as the stack route',
      );
      if (redirectTo == null) return;
      if (identical(redirectTo, newRoute)) break;
      newRoute = redirectTo as T;
    }

    final newIndex = stack.indexOf(newRoute);
    // Not found
    if (newIndex == -1) return;
    _activeIndex = newIndex;
    notifyListeners();
  }

  @override
  Future<void> activateRoute(T route) async {
    final index = stack.indexOf(route);
    if (index == -1) {
      route.onDiscard();
      throw StateError('Route not found');
    }

    final indexRoute = stack[index];

    /// Update the existing route with new state
    indexRoute.onUpdate(route);

    if (!indexRoute.deepEquals(route)) {
      route.onDiscard();
    }

    if (index == _activeIndex) return;
    await goToIndexed(index);
  }

  @override
  void reset() {
    _activeIndex = 0;
    notifyListeners();
  }

  @override
  void restore(int data) {
    assert(data >= 0 && data < stack.length, 'Index out of bounds');
    _activeIndex = data;
  }

  @override
  int serialize() => _activeIndex;

  @override
  int deserialize(int data) => data;

  @override
  Future<void> navigate(T route) async {
    final routeIndex = stack.indexOf(route);
    if (routeIndex == -1) {
      // Route not found in IndexedStackPath - restore the URL to current state
      notifyListeners();
      return;
    }
    await activateRoute(route);
  }
}
