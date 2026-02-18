import 'package:flutter/widgets.dart';
import 'package:zenrouter/src/coordinator/base.dart';
import 'package:zenrouter/src/mixin/layout.dart';
import 'package:zenrouter/src/path/indexed.dart';
import 'package:zenrouter_core/zenrouter_core.dart';

/// Base mixin for unique routes in the application.
///
/// Most routes should mix this in. It provides integration with the [Coordinator]
/// and layout system.
mixin RouteUnique on RouteTarget implements RouteUri {
  @override
  Uri get identifier => toUri();

  /// The type of layout that wraps this route.
  ///
  /// Return the type of the [RouteLayout] subclass that should contain this route.
  Type? get layout => null;

  @override
  Object? get parentLayoutKey => layout;

  // coverage:ignore-start
  /// Creates an instance of the layout for this route.
  @Deprecated('Use `createParentLayout` instead.')
  RouteLayout createLayout(covariant Coordinator coordinator) =>
      createParentLayout(coordinator);
  // coverage:ignore-end

  @override
  RouteLayout createParentLayout(covariant CoordinatorCore coordinator) {
    final constructor = _proxy.createParentLayout(coordinator);

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

  // coverage:ignore-start
  /// Resolves the parent layout for this route.
  ///
  /// Checks if an instance of the required layout is already active in the
  /// coordinator. If so, returns it. Otherwise, creates a new one.
  @Deprecated('use `resolveParentLayout` instead.')
  RouteLayout? resolveLayout(covariant CoordinatorCore coordinator) =>
      resolveParentLayout(coordinator);
  // coverage:ignore-end

  late final _proxy = RouteLayoutChild.proxy(this);

  @override
  RouteLayout? resolveParentLayout(coordinator) {
    final layout = _proxy.resolveParentLayout(coordinator) as RouteLayout?;

    // Validate that routes using IndexedStackPath are in the initial stack
    // Using assert with closure to ensure all validation logic is removed in production
    assert(() {
      final p = layout?.resolvePath(coordinator);
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

    return layout;
  }

  /// Builds the widget for this route.
  Widget build(covariant CoordinatorCore coordinator, BuildContext context);
}
