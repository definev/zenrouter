import 'package:build/build.dart';
import 'package:source_gen/source_gen.dart';

import 'generators/route_generator.dart';
import 'generators/layout_generator.dart';
import 'generators/coordinator_generator.dart';

/// Builder for generating individual route base classes.
///
/// Processes @ZenRoute and @ZenLayout annotations to generate
/// _$RouteName and _$LayoutName base classes.
Builder zenRouteBuilder(BuilderOptions options) {
  final native = _isNative(options);
  return SharedPartBuilder([
    RouteGenerator(native: native),
    LayoutGenerator(),
  ], 'zen_route');
}

/// Builder for generating the aggregated Coordinator.
///
/// Scans all routes in lib/routes/ and generates:
/// - AppRoute base class
/// - AppCoordinator class
/// - Navigation paths
/// - Type-safe navigation extensions
///
/// Configurable options in `build.yaml`:
/// - `platform`: `flutter` (default) or `dartnative`.
/// - `deferredImport`: Global deferred import setting (default: false)
/// - `outputFile`: Output filename (default: 'routes.zen.dart')
Builder zenCoordinatorBuilder(BuilderOptions options) {
  final native = _isNative(options);
  final globalDeferredImport =
      options.config['deferredImport'] as bool? ?? false;
  final outputFile =
      options.config['outputFile'] as String? ?? 'routes.zen.dart';
  return CoordinatorGenerator(
    native: native,
    globalDeferredImport: globalDeferredImport,
    outputFile: outputFile,
  );
}

bool _isNative(BuilderOptions options) {
  final platform = options.config['platform'] as String? ?? 'flutter';
  if (platform != 'flutter' && platform != 'dartnative') {
    throw ArgumentError.value(
      platform,
      'platform',
      'Expected flutter or dartnative',
    );
  }
  return platform == 'dartnative';
}
