import 'package:flutter/widgets.dart';
import 'package:zenrouter/src/coordinator/base.dart';
import 'package:zenrouter/src/mixin/layout.dart';
import 'package:zenrouter/src/path/indexed.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

/// Base mixin for unique routes in the application.
///
/// Most routes should mix this in. It provides integration with the [Coordinator]
/// and layout system.
mixin RouteUnique on RouteTarget implements RouteIdentity {
  /// The type of layout that wraps this route.
  ///
  /// Return the type of the [RouteLayout] subclass that should contain this route.
  Type? get layout => null;

  @override
  Object? get parentLayoutKey => layout;

  /// Creates an instance of the layout for this route.
  ///
  /// This uses the registered constructor from [RouteLayout.layoutConstructorTable].
  RouteLayout createLayout(covariant Coordinator coordinator) {
    final constructor = createParentLayout(coordinator);
    if (constructor == null) {
      throw UnimplementedError(
        'Missing constructor for the [$parentLayoutKey] layout. '
        'You can define a constructor by calling `bindLayout` in the corresponding [StackPath].\n'
        'Alternatively, you can define a constructor for this layout by calling [defineRouteLayout] '
        'in the [defineLayout] function of [${coordinator.runtimeType}].',
      );
    }
    return constructor as RouteLayout;
  }

  /// Resolves the active layout instance for this route.
  ///
  /// Checks if an instance of the required layout is already active in the
  /// coordinator. If so, returns it. Otherwise, creates a new one.
  RouteLayout? resolveLayout(covariant CoordinatorCore coordinator) {
    final resolvedPath = resolveParentLayout(coordinator);

    // Validate that routes using IndexedStackPath are in the initial stack
    // Using assert with closure to ensure all validation logic is removed in production
    assert(() {
      final p = resolvedPath?.resolvePath(coordinator);
      if (p is IndexedStackPath) {
        final path = p as IndexedStackPath;
        final routeInStack = path.stack.any(
          (r) => r.runtimeType == runtimeType,
        );
        if (!routeInStack) {
          throw AssertionError(
            'Route [$runtimeType] uses an IndexedStackPath layout but is not present in the initial stack.\n'
            'IndexedStackPath: ${path.debugLabel ?? 'unlabeled'}\n'
            'Current stack: ${path.stack.map((r) => r.runtimeType).toList()}\n\n'
            'Fix: Add an instance of [$runtimeType] to the IndexedStackPath when creating it:\n'
            '  IndexedStackPath.createWith(\n'
            '    [...existing routes..., $runtimeType()],\n'
            '    coordinator: this,\n'
            '    label: \'${path.debugLabel ?? 'your-label'}\',\n'
            '  )',
          );
        }
      }
      return true;
    }());

    return resolvedPath == null ? null : resolvedPath as RouteLayout;
  }

  late final _proxy = RouteLayoutChild.proxy(this);

  @override
  RouteLayoutParent<RouteTarget>? createParentLayout(coordinator) =>
      _proxy.createParentLayout(coordinator);

  @override
  RouteLayoutParent<RouteTarget>? resolveParentLayout(coordinator) =>
      _proxy.resolveParentLayout(coordinator);

  /// Builds the widget for this route.
  Widget build(covariant Coordinator coordinator, BuildContext context);
}
