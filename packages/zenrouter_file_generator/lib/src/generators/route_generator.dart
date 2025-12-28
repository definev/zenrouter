import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zenrouter_file_generator/src/analyzers/route_element.dart';

import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

/// Generator for individual route files.
///
/// Generates the `_$RouteName` base class for each @ZenRoute annotated class.
class RouteGenerator extends GeneratorForAnnotation<ZenRoute> {
  // Cached regex patterns for performance
  static final _routeBaseMatchSingleQuote = RegExp(r"routeBase:\s*'([^']+)'");
  static final _routeBaseMatchDoubleQuote = RegExp(r'routeBase:\s*"([^"]+)"');
  static final _classMatchLayout = RegExp(r'class\s+(\w+Layout)\s+extends');

  // Cache coordinator config to avoid re-reading the file for every route
  static String? _cachedRouteBase;
  static bool _configLoaded = false;
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@ZenRoute can only be applied to classes.',
        element: element,
      );
    }

    final filePath = buildStep.inputId.path;
    final routesDir = 'lib/routes';

    // Use element.name for the class name
    final className = element.name!;

    // Get coordinator config for route base name
    final routeBase = await _getRouteBaseName(buildStep, routesDir);

    // Find parent layout by scanning for _layout.dart files
    final parentLayout = await _findParentLayout(
      buildStep,
      filePath,
      routesDir,
    );

    final routeElement = routeElementFromAnnotatedElement(
      className,
      annotation,
      filePath,
      routesDir,
      parentLayoutType: parentLayout,
    );

    if (routeElement == null) {
      throw InvalidGenerationSourceError(
        'Route file must be inside lib/routes directory.',
        element: element,
      );
    }

    return _generateRouteBaseClass(routeElement, annotation, routeBase);
  }

  /// Get the route base name from _coordinator.dart or use default.
  Future<String> _getRouteBaseName(
    BuildStep buildStep,
    String routesDir,
  ) async {
    // Performance optimization: cache the coordinator config
    if (_configLoaded) {
      return _cachedRouteBase ?? 'AppRoute';
    }

    final coordinatorGlob = Glob('$routesDir/_coordinator.dart');
    await for (final asset in buildStep.findAssets(coordinatorGlob)) {
      final content = await buildStep.readAsString(asset);
      // Parse routeBase from @ZenCoordinator annotation
      final routeBaseMatchSingle = _routeBaseMatchSingleQuote.firstMatch(
        content,
      );
      final routeBaseMatchDouble = _routeBaseMatchDoubleQuote.firstMatch(
        content,
      );
      if (routeBaseMatchSingle != null) {
        _cachedRouteBase = routeBaseMatchSingle.group(1)!;
        _configLoaded = true;
        return _cachedRouteBase!;
      } else if (routeBaseMatchDouble != null) {
        _cachedRouteBase = routeBaseMatchDouble.group(1)!;
        _configLoaded = true;
        return _cachedRouteBase!;
      }
    }
    _configLoaded = true;
    _cachedRouteBase = 'AppRoute'; // Default
    return _cachedRouteBase!;
  }

  /// Find the closest parent _layout.dart file and extract the layout class name.
  Future<String?> _findParentLayout(
    BuildStep buildStep,
    String filePath,
    String routesDir,
  ) async {
    // Get the directory path of the current file
    final normalizedPath = filePath.replaceAll('\\', '/');
    final routesIndex = normalizedPath.indexOf(routesDir);
    if (routesIndex == -1) return null;

    // Get the relative path within routes directory
    var relativePath = normalizedPath.substring(routesIndex + routesDir.length);
    if (relativePath.startsWith('/')) {
      relativePath = relativePath.substring(1);
    }

    // Split into directory parts
    final parts = relativePath.split('/');
    if (parts.isEmpty) return null;

    // Remove the file name to get directory parts
    parts.removeLast();

    // Search from innermost to outermost directory for _layout.dart
    while (parts.isNotEmpty) {
      final layoutPath = '$routesDir/${parts.join('/')}/_layout.dart';
      // Escape parentheses in glob patterns - they are special characters
      final escapedPath = _escapeGlobPattern(layoutPath);
      final layoutGlob = Glob(escapedPath);

      await for (final asset in buildStep.findAssets(layoutGlob)) {
        // Found a layout file, extract the class name
        final content = await buildStep.readAsString(asset);
        final classMatch = _classMatchLayout.firstMatch(content);
        if (classMatch != null) {
          return classMatch.group(1);
        }
      }

      // Move to parent directory
      parts.removeLast();
    }

    // Check root _layout.dart
    final rootLayoutGlob = Glob('$routesDir/_layout.dart');
    await for (final asset in buildStep.findAssets(rootLayoutGlob)) {
      final content = await buildStep.readAsString(asset);
      final classMatch = _classMatchLayout.firstMatch(content);
      if (classMatch != null) {
        return classMatch.group(1);
      }
    }

    return null;
  }

  /// Escape special glob characters in a path.
  String _escapeGlobPattern(String path) {
    return path.replaceAll('(', '[(]').replaceAll(')', '[)]');
  }

  String _generateRouteBaseClass(
    RouteElement route,
    ConstantReader annotation,
    String routeBase,
  ) {
    return RouteCodeGenerator.generate(
      route,
      RouteCodeConfig(routeBase: routeBase),
    );
  }
}
