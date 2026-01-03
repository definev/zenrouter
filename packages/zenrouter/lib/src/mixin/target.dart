import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zenrouter/src/internal/equatable.dart';
import 'package:zenrouter/zenrouter.dart';

/// The base class for all navigation targets (routes).
///
/// A [RouteTarget] represents a destination in the app. It can hold state
/// and parameters. Every screen, dialog, or navigable destination should
/// extend this class.
///
/// ## Route Lifecycle
///
/// Routes go through distinct phases during their lifetime:
///
/// ```
/// ┌─────────────────────────────────────────────────────────────────────┐
/// │                        ROUTE LIFECYCLE                              │
/// ├─────────────────────────────────────────────────────────────────────┤
/// │  1. CREATION        → Route instance created (constructor called)   │
/// │  2. REDIRECT CHECK  → RouteRedirect.redirect() called if applicable │
/// │  3. PATH BINDING    → Route assigned to a StackPath (_path set)     │
/// │  4. BUILD           → build() called to create the widget           │
/// │  5. ACTIVE          → Route is visible and receiving interactions   │
/// │  6. POP REQUEST     → User/system requests pop (guard consulted)    │
/// │  7. POP COMPLETION  → onDidPop() + completeOnResult() called        │
/// │  8. CLEANUP         → Route removed from path, _path set to null    │
/// └─────────────────────────────────────────────────────────────────────┘
/// ```
///
/// ## Internal State
///
/// Routes maintain internal state managed by the framework:
/// - **`_path`**: The [StackPath] containing this route. Set during push.
/// - **`_onResult`**: A [Completer] that resolves when the route is popped.
/// - **`_resultValue`**: The result passed to [pop] before [onDidPop] is called.
/// - **`isPopByPath`**: Whether the pop was initiated by [StackPath.pop].
///
/// ## Result Handling
///
/// Routes can return a result when popped:
/// ```dart
/// // Pushing with result
/// final result = await coordinator.push<String>(SelectColorRoute());
/// print('Selected: $result');
///
/// // Popping with result (in route or widget)
/// coordinator.pop('blue');
/// ```
///
/// ## Equality
///
/// Override [props] to include route parameters in equality checks:
/// ```dart
/// class ProductRoute extends RouteTarget with RouteUnique {
///   final String productId;
///   ProductRoute(this.productId);
///
///   @override
///   List<Object?> get props => [productId];
/// }
/// ```
abstract class RouteTarget extends Equatable {
  /// Converts [RouteTarget] to primitive data
  ///
  /// This is called by Flutter's restoration framework when the app is being
  /// killed.
  ///
  /// Built-in Types supports:
  /// - [RouteLayout] - Serialize [RouteLayout]
  /// - [RouteRestorable] - Call custom `serialize` method
  /// - [RouteUnique] - Leverage `toUri` for serialization
  static Object serialize(RouteTarget value) => switch (value) {
    RouteLayout() => value.serialize(),
    RouteRestorable() => value.serialize(),
    RouteUnique() => value.toUri().toString(),
    _ => throw UnimplementedError(),
  };

  /// Converts saved primitive data back into a route object.
  ///
  /// This is called by Flutter's restoration framework when the app is being
  /// restored. It receives the data that was previously returned by [toPrimitives]
  /// and reconstructs the route stack.
  static T? deserialize<T extends RouteTarget>(
    Object value, {
    required RouteUriParserSync? parseRouteFromUri,
  }) => switch (value) {
    String() => parseRouteFromUri!(Uri.parse(value)) as T,
    Map() when value['type'] == 'layout' =>
      RouteLayout.deserialize(value.cast()) as T,
    Map() =>
      RouteRestorable.deserialize(
            value.cast(),
            parseRouteFromUri: parseRouteFromUri,
          )
          as T,
    // coverage:ignore-start
    _ => null,
    // coverage:ignore-end
  };

  /// Completer that resolves when this route is popped.
  ///
  /// The future completes with the result passed to [completeOnResult].
  /// This is set fresh each time the route is pushed.
  final Completer<Object?> _onResult = Completer();

  @protected
  @visibleForTesting
  /// The completer for the result of the route.
  /// DO NOT USE THIS MANUALLY. USE [completeOnResult] instead.
  Completer<Object?> get onResult => _onResult;

  /// The [StackPath] that currently contains this route.
  ///
  /// This is set when the route is pushed onto a path and cleared when popped.
  /// Used internally to ensure routes are managed by the correct path.
  StackPath? _path;

  /// The [StackPath] that currently contains this route.
  StackPath? get stackPath => _path;

  /// Binds the route to a path.
  ///
  /// This is called internally when the route is pushed onto a path.
  /// Useful when you want to create your custom [StackPath].
  @protected
  void bindStackPath(StackPath path) => _path = path;

  /// Clears the path binding.
  ///
  /// This is called internally when the route is removed from a path.
  @protected
  void clearStackPath() => _path = null;

  /// The result value to be returned when this route is popped.
  ///
  /// This is set by [StackPath.pop] before [onDidPop] is called, allowing
  /// the widget tree to access the result during disposal.
  Object? _resultValue;

  /// The result value to be returned when this route is popped.
  Object? get resultValue => _resultValue;

  @protected
  void bindResultValue(Object? value) => _resultValue = value;

  /// Whether this route was popped by the path mechanism.
  ///
  /// When `true`, the pop was initiated by [NavigationPath.pop] or similar.
  /// When `false`, the pop was initiated by the system (e.g., back button).
  ///
  /// This is used internally to prevent double removal from the stack.
  bool isPopByPath = false;

  /// Internal properties that are hardcoded and cannot be ignored.
  ///
  /// These are used for identity checks within the framework. Do not override.
  /// See [props] for user-defined equality properties.
  @override
  List<Object?> get internalProps => [runtimeType, _path, _onResult];

  /// The list of properties used for equality comparison.
  ///
  /// Override this to include route parameters in equality checks.
  /// Two routes are equal if they have the same type and equal [props].
  ///
  /// **Example:**
  /// ```dart
  /// class UserRoute extends RouteTarget with RouteUnique {
  ///   final int userId;
  ///   UserRoute(this.userId);
  ///
  ///   @override
  ///   List<Object?> get props => [userId];
  /// }
  /// ```
  @override
  List<Object?> get props => [];

  /// Deep equality check for routes.
  ///
  /// This is used to determine if two routes are identical.
  bool deepEquals(RouteTarget other) => hashCode == other.hashCode;

  @mustCallSuper
  void onDidPop(Object? result, covariant Coordinator? coordinator) {
    onDiscard();

    /// Handle force pop from navigator
    if (isPopByPath == false && _path?.stack.contains(this) == true) {
      if (_path case StackMutatable path) {
        path.remove(this, discard: false);
      }
    }

    clearStackPath();
  }

  /// Completes the route's result future.
  ///
  /// This is called when the route is popped with a result.
  void completeOnResult(
    Object? result,
    covariant Coordinator? coordinator, [
    bool failSilent = false,
  ]) {
    if (failSilent && _onResult.isCompleted) return;
    _onResult.complete(result);
    _resultValue = result;
  }

  /// Call when the route is discarded.
  ///
  /// That is difference with [onDidPop], [onDidPop] called when route is removed from stack.
  /// [onDiscard] called when route isn't in any path yet but it is in the process of being removed.
  @mustCallSuper
  void onDiscard() {
    completeOnResult(null, null, true);
  }

  /// Called when this route is updated with state from a new route instance.
  ///
  /// When navigation occurs and a route with the same identity already exists
  /// in the stack, instead of pushing a duplicate, the existing route's
  /// [onUpdate] method is called with the new route instance as a parameter.
  /// This allows you to transfer state from the new route to the existing one.
  ///
  /// **Common use cases:**
  /// - Updating query parameters without rebuilding the route
  /// - Refreshing route data when navigating to the same screen
  /// - Syncing state between duplicate route instances
  ///
  /// **Example:**
  /// ```dart
  /// class ProductRoute extends RouteTarget with RouteUnique {
  ///   ProductRoute(this.id, {this.highlightReview});
  ///
  ///   final String id;
  ///   String? highlightReview;
  ///
  ///   @override
  ///   void onUpdate(covariant ProductRoute newRoute) {
  ///     super.onUpdate(newRoute);
  ///     // Transfer the new highlight state to this existing route
  ///     highlightReview = newRoute.highlightReview;
  ///   }
  ///
  ///   @override
  ///   List<Object?> get props => [id]; // highlightReview not in props
  /// }
  /// ```
  ///
  /// **Parameters:**
  /// - [newRoute]: The new route instance being navigated to with potentially updated state.
  ///
  /// **Important:** Always call `super.onUpdate(newRoute)` if you override this.
  @mustCallSuper
  void onUpdate(covariant RouteTarget newRoute) {}
}
