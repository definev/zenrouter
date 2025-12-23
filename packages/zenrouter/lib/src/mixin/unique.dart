import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

/// Base mixin for unique routes in the application.
///
/// Most routes should mix this in. It provides integration with the [Coordinator]
/// and layout system.
mixin RouteUnique on RouteTarget {
  /// The type of layout that wraps this route.
  ///
  /// Return the type of the [RouteLayout] subclass that should contain this route.
  Type? get layout => null;

  /// Creates an instance of the layout for this route.
  ///
  /// This uses the registered constructor from [RouteLayout.layoutConstructorTable].
  RouteLayout? createLayout(covariant Coordinator coordinator) {
    final constructor = RouteLayout.layoutConstructorTable[layout];
    if (constructor == null) {
      throw UnimplementedError(
        '$this: Missing RouteLayout constructor for [$layout] must define by calling [RouteLayout.defineLayout] in [defineLayout] function at [${coordinator.runtimeType}]',
      );
    }
    return constructor();
  }

  /// Resolves the active layout instance for this route.
  ///
  /// Checks if an instance of the required layout is already active in the
  /// coordinator. If so, returns it. Otherwise, creates a new one.
  RouteLayout? resolveLayout(covariant Coordinator coordinator) {
    if (layout == null) return null;
    final layouts = coordinator.activeLayouts;
    if (layouts.isEmpty && layout == null) return null;

    // Find existing layout or create new one
    RouteLayout? resolvedLayout;
    for (var i = layouts.length - 1; i >= 0; i -= 1) {
      final l = layouts[i];
      if (l.runtimeType == layout) {
        resolvedLayout = l;
        break;
      }
    }
    resolvedLayout ??= createLayout(coordinator);

    // Validate that routes using IndexedStackPath are in the initial stack
    // Using assert with closure to ensure all validation logic is removed in production
    assert(() {
      final path = resolvedLayout!.resolvePath(coordinator);
      if (path is IndexedStackPath) {
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

    return resolvedLayout;
  }

  /// Builds the widget for this route.
  Widget build(covariant Coordinator coordinator, BuildContext context);

  /// Returns the URI representation of this route.
  Uri toUri();

  @override
  @mustCallSuper
  void onDidPop(
    Object? result,
    covariant Coordinator<RouteUnique>? coordinator,
  ) => super.onDidPop(result, coordinator);
}
