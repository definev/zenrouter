import 'package:zenrouter_core/src/coordinator/base.dart';
import 'package:zenrouter_core/src/mixin/layout.dart';
import 'package:zenrouter_core/src/mixin/target.dart';

mixin RouteIdentity on RouteTarget {
  Uri toUri();

  Type? get layout;
  
  /// Creates an instance of the layout for this route.
  ///
  /// This uses the registered constructor from [RouteLayout.layoutConstructorTable].
  RoutePath? createLayout(covariant CoordinatorCore coordinator) {
    final constructor = RoutePath.routePathConstructorTable[layout];
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
  RoutePath? resolveLayout(covariant CoordinatorCore coordinator) {
    if (layout == null) return null;
    final layouts = coordinator.activeLayouts;
    if (layouts.isEmpty && layout == null) return null;

    // Find existing layout or create new one
    RoutePath? resolvedLayout;
    for (var i = layouts.length - 1; i >= 0; i -= 1) {
      final l = layouts[i];
      if (l.runtimeType == layout) {
        resolvedLayout = l;
        break;
      }
    }
    return resolvedLayout ??= createLayout(coordinator);
  }
}
