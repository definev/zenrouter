import 'dart:async';

import 'package:meta/meta.dart';
import 'package:zenrouter_core/src/coordinator/base.dart';
import 'package:zenrouter_core/src/mixin/guard.dart';
import 'package:zenrouter_core/src/path/base.dart';

import '../internal/equatable.dart';

/// The base class for all navigation destinations in the application.
///
/// Every screen, dialog, or navigable component extends this class.
/// It provides the fundamental infrastructure for the routing system.
///
/// ## Role in Navigation Flow
///
/// Routes go through the following lifecycle:
///
/// 1. **Creation**: Route instance is constructed with parameters
/// 2. **Redirect Resolution**: [RouteRedirect.resolve] is called if applicable
/// 3. **Path Binding**: Route is assigned to a [StackPath]
/// 4. **Build**: The route's interface is created (e.g. widget for widget-based routers or web page for web routers)
/// 5. **Active**: Route is visible and handling interactions
/// 6. **Pop Request**: User or system requests navigation away
/// 7. **Guard Check**: [RouteGuard.popGuard] is consulted - if it returns false, pop is aborted
/// 8. **Pop Completion**: [onDidPop] is called, result is delivered
/// 9. **Cleanup**: Route is removed from path, state is cleared
abstract class RouteTarget extends Equatable {
  final Completer<Object?> _onResult = Completer();

  @protected
  @visibleForTesting
  Completer<Object?> get onResult => _onResult;

  /// The [StackPath] containing this route.
  ///
  /// Set when the route is pushed, cleared when popped.
  /// Used internally to verify correct path management.
  StackPath? _path;

  /// The [StackPath] that contains this route.
  StackPath? get stackPath => _path;

  /// Binds the route to a path.
  ///
  /// Called internally when the route is pushed onto a path.
  @protected
  void bindStackPath(StackPath path) => _path = path;

  /// Clears the path binding.
  ///
  /// Called internally when the route is removed from a path.
  @protected
  void clearStackPath() => _path = null;

  Object? _resultValue;

  /// The result value passed when this route was popped.
  Object? get resultValue => _resultValue;

  @protected
  void bindResultValue(Object? value) => _resultValue = value;

  /// Whether the pop was initiated by the path mechanism.
  ///
  /// When `true`, pop was called programmatically.
  /// When `false`, pop was initiated externally (back button, system).
  bool isPopByPath = false;

  @override
  List<Object?> get internalProps => [runtimeType, _path, _onResult];

  /// Properties used for equality comparison.
  ///
  /// Override to include route parameters. Two routes are equal
  /// if they have the same type and equal [props].
  @override
  List<Object?> get props => [];

  /// Checks deep equality with another route.
  bool deepEquals(RouteTarget other) => hashCode == other.hashCode;

  /// Called when the route is popped from the navigation stack.
  ///
  /// This is invoked during navigation cleanup. The route is removed
  /// from its path and its result is completed.
  @mustCallSuper
  void onDidPop(Object? result, covariant CoordinatorCore? coordinator) {
    onDiscard();

    if (isPopByPath == false && _path?.stack.contains(this) == true) {
      if (_path case StackMutatable path) {
        path.remove(this, discard: false);
      }
    }

    clearStackPath();
  }

  /// Completes the route's result future.
  ///
  /// Called when the route is popped with a result value.
  void completeOnResult(
    Object? result,
    covariant CoordinatorCore? coordinator, [
    bool failSilent = false,
  ]) {
    if (failSilent && _onResult.isCompleted) return;
    _onResult.complete(result);
    _resultValue = result;
  }

  /// Called when the route is discarded without being displayed.
  ///
  /// This occurs when a route is redirected away or navigation is cancelled.
  /// Differs from [onDidPop] which is called when the route is removed from stack.
  @mustCallSuper
  void onDiscard() {
    completeOnResult(null, null, true);
  }

  /// Called when this route is updated with state from a new route instance.
  ///
  /// When navigating to a route that already exists in the stack, instead of
  /// pushing a duplicate, this method is called to transfer state from the
  /// new route to the existing one. This enables scenarios like updating
  /// query parameters or refreshing data without rebuilding the widget.
  @mustCallSuper
  void onUpdate(covariant RouteTarget newRoute) {}
}
