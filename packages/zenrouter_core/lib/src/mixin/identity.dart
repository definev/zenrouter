import 'package:zenrouter_core/src/coordinator/base.dart';
import 'package:zenrouter_core/src/mixin/path.dart';
import 'package:zenrouter_core/src/mixin/target.dart';

mixin RouteIdentity on RouteTarget {
  Uri toUri();

  Object? get parentRoutePathKey;

  /// Creates an instance of the layout for this route.
  ///
  /// This uses the registered constructor from [RouteLayout.layoutConstructorTable].
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
}
