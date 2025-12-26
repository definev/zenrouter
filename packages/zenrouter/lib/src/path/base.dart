import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:zenrouter/src/internal/diff.dart';
import 'package:zenrouter/src/internal/equatable.dart';
import 'package:zenrouter/src/path/restoration.dart';
import 'package:zenrouter/zenrouter.dart';

part 'transition.dart';
part 'stack.dart';
part 'navigation.dart';
part 'indexed.dart';
part '../mixin/target.dart';
part '../mixin/guard.dart';

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

/// Mixin for stack paths that support mutable operations (push/pop).
///
/// Apply this mixin to [StackPath] subclasses that need push/pop navigation.
/// This provides standard implementations for:
/// - [push]: Add a route to the top
/// - [pushOrMoveToTop]: Add or promote existing route
/// - [pop]: Remove the top route (with guard support)
mixin StackMutatable<T extends RouteTarget> on StackPath<T> {
  /// Pushes a new route onto the stack.
  ///
  /// This handles redirects and sets up the route's path reference.
  /// Returns a future that completes when the route is popped with a result.
  ///
  /// **Error Handling:**
  /// Exceptions from [RouteRedirect.resolve] propagate to the caller.
  Future<R?> push<R extends Object>(T element) async {
    T target = await RouteRedirect.resolve(element, coordinator);
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
    T target = await RouteRedirect.resolve(element, coordinator);
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
  /// **Difference from [NavigationPath.remove]:**
  /// - [pop]: Respects [RouteGuard], removes only the top route, returns result
  /// - [remove]: Bypasses guards, removes at any index, no result
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
    element._resultValue = result;
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
  void remove(T element) {
    element._path = null;
    final removed = _stack.remove(element);
    if (removed) notifyListeners();
  }
}

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
///     required Coordinator coordinator,
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
abstract class StackPath<T extends RouteTarget> with ChangeNotifier {
  StackPath(this._stack, {this.debugLabel, Coordinator? coordinator})
    : _coordinator = coordinator;

  // coverage:ignore-start
  /// Creates a [NavigationPath] with an optional initial stack.
  static NavigationPath<T> navigationStack<T extends RouteTarget>([
    String? debugLabel,
    List<T>? stack,
  ]) => NavigationPath<T>._(debugLabel, stack);

  /// Creates an [IndexedStackPath] with a fixed list of routes.
  static IndexedStackPath<T> indexedStack<T extends RouteTarget>(
    List<T> stack, [
    String? debugLabel,
  ]) => IndexedStackPath<T>._(stack, debugLabel: debugLabel);
  // coverage:ignore-end

  /// A label for debugging purposes.
  final String? debugLabel;

  /// The internal mutable stack.
  final List<T> _stack;

  /// The coordinator this path is bound to.
  ///
  /// This creates a 1-1 relationship between path and coordinator,
  /// ensuring routes are managed correctly. Always use [createWith]
  /// factory constructors to bind paths to coordinators.
  final Coordinator? _coordinator;

  /// The coordinator this path belongs to.
  Coordinator? get coordinator => _coordinator;

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

  /// Clears all routes from this path.
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
      '${debugLabel ?? hashCode} [${runtimeType.toString().split('Path').first}]';
}
