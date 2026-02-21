// ignore_for_file: invalid_use_of_protected_member, invalid_use_of_visible_for_testing_member

import 'dart:async';

import 'package:meta/meta.dart' show protected, mustCallSuper;
import 'package:zenrouter_core/src/coordinator/base.dart';
import 'package:zenrouter_core/src/internal/reactive.dart';
import 'package:zenrouter_core/src/mixin/guard.dart';
import 'package:zenrouter_core/src/mixin/redirect.dart';
import 'package:zenrouter_core/src/mixin/target.dart';
import 'package:zenrouter_core/src/path/navigatable.dart';

part 'mutatable.dart';

/// A type-safe identifier for [StackPath] types.
///
/// Each [StackPath] subclass defines a unique [PathKey] used for:
/// - Registering layout builders in [CoordinatorCore]
/// - Looking up the appropriate builder when rendering pages
extension type const PathKey(String key) {}

/// A container managing a stack of [RouteTarget]s for navigation.
///
/// [StackPath] is the core abstraction for navigation stacks in ZenRouter.
/// It holds a list of routes and notifies listeners when the stack changes.
///
/// ## Role in Navigation Flow
///
/// Routes are pushed onto and popped from paths during navigation:
/// 1. When [CoordinatorCore.push] is called, the route is added to a path
/// 2. The path notifies listeners, causing UI rebuild
/// 3. When [StackMutatable.pop] is called, the route is removed
/// 4. [RouteTarget.onDidPop] is called, completing the route's lifecycle
///
/// ## Types of Paths
///
/// - [NavigationPath]: Mutable stack for standard push/pop navigation
/// - [IndexedStackPath]: Fixed stack for tab-based navigation
abstract class StackPath<T extends RouteTarget> with ListenableObject {
  StackPath(this._stack, {this.debugLabel, CoordinatorCore? coordinator})
    : _proxyCoordinator = coordinator?.isRouteModule == true
          ? coordinator
          : null,
      _coordinator = coordinator?.isRouteModule == true
          ? coordinator?.coordinator
          : coordinator;

  /// A label for debugging purposes.
  final String? debugLabel;

  /// The internal mutable stack.
  final List<T> _stack;

  @protected
  void bindStack(List<T> stack) {
    _stack.clear();
    for (final route in stack) {
      route.isPopByPath = false;
      route.bindStackPath(this);
      _stack.add(route);
    }
  }

  /// The coordinator this path is bound to.
  ///
  /// When this path is created with a route module coordinator,
  /// this field holds the parent/root coordinator of that module.
  final CoordinatorCore? _coordinator;

  /// The proxy coordinator for this path.
  ///
  /// When this path is created with a route module coordinator,
  /// this field holds the original (nested/module) coordinator,
  /// while [_coordinator] points to its parent/root coordinator.
  final CoordinatorCore? _proxyCoordinator;

  /// The coordinator this path belongs to.
  CoordinatorCore? get coordinator => _coordinator;

  /// The proxy coordinator for this path.
  ///
  /// For module paths, this is the original module coordinator that
  /// created the path (the "nested" coordinator); [coordinator]
  /// then refers to its parent/root coordinator.
  CoordinatorCore? get proxyCoordinator => _proxyCoordinator;

  /// The currently active route in this stack.
  ///
  /// For [NavigationPath], this is the top of the stack.
  /// For [IndexedStackPath], this is the route at [activeIndex].
  T? get activeRoute;

  /// The unique key identifying this path type.
  ///
  /// Used by [RouteLayout.buildPath] to look up the appropriate builder.
  /// Each [StackPath] subclass should define a unique static [PathKey].
  PathKey get pathKey;

  /// The current navigation stack as an unmodifiable list.
  ///
  /// The first element is the bottom of the stack (first route),
  /// and the last element is the top of the stack (current route).
  List<T> get stack => List.unmodifiable(_stack);

  @protected
  /// Clears all routes from this path.
  ///
  /// **Important:** Guards are NOT consulted. Use this for forced resets
  /// like logout or app restart. For user-initiated back navigation,
  /// use [StackMutatable.pop] which respects guards.
  void clear() {
    for (final route in _stack) {
      route.completeOnResult(null, null, true);
      route.clearStackPath();
    }
    _stack.clear();
  }

  /// Reset stack of this path.
  ///
  /// **Important:** Guards are NOT consulted. Use this for forced resets
  /// like logout or app restart. For user-initiated back navigation,
  /// use [StackMutatable.pop] which respects guards.
  @mustCallSuper
  void reset();

  /// Activates a specific route in the stack.
  ///
  /// **Behavior varies by implementation:**
  /// - [NavigationPath]: Resets stack and pushes this route
  /// - [IndexedStackPath]: Switches to the route's index
  ///
  /// **Error Handling:**
  /// - [IndexedStackPath] throws [StateError] if route not in stack
  Future<void> activateRoute(T route);

  @override
  String toString() =>
      '${debugLabel ?? hashCode} [${proxyCoordinator ?? coordinator} | $pathKey]';
}
