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
  Object? get parentRoutePathKey => layout;

  /// Creates an instance of the layout for this route.
  ///
  /// This uses the registered constructor from [RouteLayout.layoutConstructorTable].
  RouteLayout? createLayout(covariant Coordinator coordinator) =>
      createRoutePath(coordinator) as RouteLayout?;

  /// Creates an instance of the layout for this route.
  ///
  /// This uses the registered constructor from [RouteLayout.layoutConstructorTable].
  @override
  RoutePath? createRoutePath(covariant CoordinatorCore coordinator) {
    final routePathKey = parentRoutePathKey;
    final constructor = RoutePath.routePathConstructorTable[routePathKey];
    if (constructor == null) {
      throw UnimplementedError(
        '$this: Missing RouteLayout constructor for [$routePathKey] must define by calling [RouteLayout.defineLayout] in [defineLayout] function at [${coordinator.runtimeType}]',
      );
    }
    return constructor();
  }

  /// Resolves the active layout instance for this route.
  ///
  /// Checks if an instance of the required layout is already active in the
  /// coordinator. If so, returns it. Otherwise, creates a new one.
  @override
  RoutePath? resolveRoutePath(covariant CoordinatorCore coordinator) {
    final routePathKey = parentRoutePathKey;
    if (routePathKey == null) return null;
    // ignore: invalid_use_of_protected_member
    final routePathList = coordinator.activeRoutePaths;

    // Find existing layout or create new one
    RoutePath? resolvedRoutePath;
    for (var i = routePathList.length - 1; i >= 0; i -= 1) {
      final routePath = routePathList[i];
      if (routePath.routePathKey == routePathKey) {
        resolvedRoutePath = routePath;
        break;
      }
    }

    return resolvedRoutePath ??= createRoutePath(coordinator);
  }

  /// Resolves the active layout instance for this route.
  ///
  /// Checks if an instance of the required layout is already active in the
  /// coordinator. If so, returns it. Otherwise, creates a new one.
  RouteLayout? resolveLayout(covariant Coordinator coordinator) {
    final resolvedPath = resolveRoutePath(coordinator);

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

  /// Builds the widget for this route.
  Widget build(covariant Coordinator coordinator, BuildContext context);
}
