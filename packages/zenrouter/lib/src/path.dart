import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'diff.dart';
import 'coordinator.dart';
import 'equaltable_utils.dart';

part 'mixin.dart';
part 'stack.dart';
part 'transition.dart';

/// Mixin for stack paths that support mutable operations (push/pop).
///
/// This provides standard implementations for [push], [pushOrMoveToTop], and [pop].
mixin StackMutatable<T extends RouteTarget> on StackPath<T> {
  /// Pushes a new route onto the stack.
  ///
  /// This handles redirects and sets up the route's path reference.
  /// Returns a future that completes when the route is popped with a result.
  Future<R?> push<R extends Object>(T element) async {
    T target = await RouteRedirect.resolve(element);
    target.isPopByPath = false;
    target._path = this;
    _stack.add(target);
    notifyListeners();
    return target._onResult.future as Future<R?>;
  }

  /// Pushes a route to the top of the stack, or moves it if already present.
  ///
  /// If the route is already in the stack, it's moved to the top.
  /// If not, it's added to the top. Follows redirects like [push].
  ///
  /// Useful for tab navigation where you want to switch to a tab
  /// without duplicating it in the stack.
  Future<void> pushOrMoveToTop(T element) async {
    T target = await RouteRedirect.resolve(element);
    target.isPopByPath = false;
    target._path = this;
    final index = _stack.indexOf(target);
    if (_stack.isNotEmpty && index == _stack.length - 1) {
      element._onResult = _stack.last._onResult;
      return;
    }

    if (index != -1) {
      final removed = _stack.removeAt(index);

      /// Complete the result future to prevent the route from being popped.
      removed.completeOnResult(null, null, true);
    }
    _stack.add(target);
    notifyListeners();
  }

  /// Removes the top route from the navigation stack.
  ///
  /// Returns `true` if the pop was successful, `false` if the guard cancelled it,
  /// or `null` if the stack was empty.
  Future<bool?> pop([Object? result]) async {
    if (_stack.isEmpty) {
      return null;
    }
    final last = _stack.last;
    if (last is RouteGuard) {
      final canPop = await last.popGuard();
      if (!canPop) return false;
    }

    final element = _stack.removeLast();
    element.isPopByPath = true;
    element._resultValue = result;
    notifyListeners();
    return true;
  }
}

/// A stack-based container for managing navigation history.
///
/// A [StackPath] holds a list of [RouteTarget]s and manages their lifecycle.
/// It notifies listeners when the stack changes.
abstract class StackPath<T extends RouteTarget> extends ChangeNotifier {
  StackPath._(this._stack, {this.debugLabel});

  /// Creates a [NavigationPath] with an optional initial stack.
  static NavigationPath<T> navigationStack<T extends RouteTarget>([
    String? debugLabel,
    List<T>? stack,
  ]) => NavigationPath<T>(debugLabel, stack);

  /// Creates an [IndexedStackPath] with a fixed list of routes.
  static IndexedStackPath<T> indexedStack<T extends RouteTarget>(
    List<T> stack, [
    String? debugLabel,
  ]) => IndexedStackPath<T>(stack, debugLabel);

  /// A label for debugging purposes.
  final String? debugLabel;

  /// The internal mutable stack.
  final List<T> _stack;

  /// The currently active route in this stack.
  T? get activeRoute;

  /// The current navigation stack as an unmodifiable list.
  ///
  /// The first element is the bottom of the stack (first route),
  /// and the last element is the top of the stack (current route).
  List<T> get stack => List.unmodifiable(_stack);

  /// Reset all routes from the navigation stack.
  ///
  /// This force clears the entire navigation history. Guards are NOT consulted.
  @mustCallSuper
  void reset();

  /// Activates a specific route in the stack.
  ///
  /// The behavior depends on the implementation (e.g., switching tab index
  /// or resetting stack to just this route).
  Future<void> activateRoute(T route);

  @override
  String toString() =>
      '${debugLabel ?? hashCode} [${runtimeType.toString().replaceAll('Path', '')}]';
}

/// A mutable stack path for standard navigation.
///
/// Supports pushing and popping routes. Used for the main navigation stack
/// and modal flows.
class NavigationPath<T extends RouteTarget> extends StackPath<T>
    with StackMutatable<T> {
  NavigationPath([String? debugLabel, List<T>? stack])
    : super._(stack ?? [], debugLabel: debugLabel);

  /// Removes a specific route from the stack (at any position).
  ///
  /// Guards are NOT consulted. Use with caution.
  void remove(T element) {
    element._path = null;
    _stack.remove(element);
    notifyListeners();
  }

  @override
  void reset() {
    for (final route in _stack) {
      route.completeOnResult(null, null, true);
    }
    _stack.clear();
  }

  @override
  T? get activeRoute => _stack.lastOrNull;

  @override
  Future<void> activateRoute(T route) async {
    reset();
    push(route);
  }
}

/// A fixed stack path for indexed navigation (like tabs).
///
/// Routes are pre-defined and cannot be added or removed. Navigation switches
/// the active index.
class IndexedStackPath<T extends RouteTarget> extends StackPath<T> {
  IndexedStackPath(super.stack, [String? debugLabel])
    : assert(stack.isNotEmpty, 'Read-only path must have at least one route'),
      super._(debugLabel: debugLabel) {
    for (final path in stack) {
      /// Set the output of every route to null since this cannot pop
      path.completeOnResult(null, null);
    }
  }

  int _activeIndex = 0;

  /// The index of the currently active path in the stack.
  @Deprecated('Use `activeIndex` insteads. This will be removed in 1.0.0')
  int get activePathIndex => _activeIndex;

  /// The index of the currently active path in the stack.
  int get activeIndex => _activeIndex;

  @override
  T get activeRoute => stack[activeIndex];

  /// Switches the active route to the one at [index].
  ///
  /// Handles guards on the current route and redirects on the new route.
  Future<void> goToIndexed(int index) async {
    if (index >= stack.length) throw StateError('Index out of bounds');
    final oldIndex = _activeIndex;
    final oldRoute = stack[oldIndex];
    if (oldRoute is RouteGuard) {
      final canPop = await (oldRoute as RouteGuard).popGuard();
      if (!canPop) return;
    }
    var newRoute = stack[index];
    while (newRoute is RouteRedirect<T>) {
      final redirectTo = await (newRoute as RouteRedirect<T>).redirect();
      if (redirectTo == null) return;
      newRoute = redirectTo;
    }

    _activeIndex = index;
    notifyListeners();
  }

  @override
  Future<void> activateRoute(T route) async {
    final index = stack.indexOf(route);
    route.completeOnResult(null, null, true);
    if (index == -1) throw StateError('Route not found');
    await goToIndexed(index);
  }

  @override
  void reset() {
    _activeIndex = 0;
  }
}

/// Callback that builds a [Page] from a route and child widget.
typedef PageCallback<T extends RouteTarget> =
    Page<void> Function(BuildContext context, ValueKey<T> route, Widget child);
