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
/// [PathKey] is used to register and look up layout builders in
/// [RouteLayout.definePath]. Each [StackPath] subclass should have
/// a unique static [PathKey].
///
/// **Built-in keys:**
/// - [NavigationPath.key]: `PathKey('NavigationPath')`
/// - [IndexedStackPath.key]: `PathKey('IndexedStackPath')`
///
/// **Custom path example:**
/// ```dart
/// class ModalPath<T extends RouteTarget> extends StackPath<T>
///     with StackMutatable<T> {
///   static const key = PathKey('ModalPath');
///
///   @override
///   PathKey get pathKey => key;
/// }
/// ```
extension type const PathKey(String key) {}

/// A stack-based container for managing navigation history.
///
/// A [StackPath] holds a list of [RouteTarget]s and manages their lifecycle.
/// It notifies listeners when the stack changes.
///
/// ## Built-in Implementations
///
/// - **[NavigationPath]**: Mutable stack with push/pop for standard navigation
/// - **[IndexedStackPath]**: Fixed stack for indexed navigation (tabs)
///
/// ## Creating Custom Stack Paths
///
/// To create a custom stack path (e.g., for modals, sheets, or custom navigation):
///
/// ```dart
/// class ModalPath<T extends RouteTarget> extends StackPath<T>
///     with StackMutatable<T> {
///   // 1. Define a unique PathKey
///   static const key = PathKey('ModalPath');
///
///   ModalPath._(
///     super.stack, {
///     super.debugLabel,
///     super.coordinator,
///   });
///
///   factory ModalPath.createWith({
///     required CoordinatorCore coordinator,
///     required String label,
///   }) => ModalPath._([], debugLabel: label, coordinator: coordinator);
///
///   // 2. Return the key
///   @override
///   PathKey get pathKey => key;
///
///   @override
///   T? get activeRoute => _stack.lastOrNull;
///
///   @override
///   void reset() {
///     for (final route in _stack) {
///       route.completeOnResult(null, null, true);
///     }
///     _stack.clear();
///   }
///
///   @override
///   Future<void> activateRoute(T route) async {
///     reset();
///     push(route);
///   }
/// }
/// ```
///
/// Then register a builder in your coordinator's [defineLayout]:
/// ```dart
/// @override
/// void defineLayout() {
///   RouteLayout.definePath(
///     ModalPath.key,
///     (coordinator, path, layout) => ModalStack(path: path as ModalPath),
///   );
/// }
/// ```
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
