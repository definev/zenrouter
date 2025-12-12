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
    final buffer = StringBuffer();

    // Build mixin list
    final mixins = <String>[];
    if (route.hasGuard) mixins.add('RouteGuard');
    if (route.hasRedirect) mixins.add('RouteRedirect<$routeBase>');
    if (route.deepLinkStrategy != null) mixins.add('RouteDeepLink');
    if (route.hasTransition) mixins.add('RouteTransition');

    final mixinStr = mixins.isNotEmpty ? ' with ${mixins.join(', ')}' : '';

    // Generate class declaration
    buffer.writeln('/// Generated base class for ${route.className}.');
    buffer.writeln('///');
    buffer.writeln('/// URI: ${route.uriPattern}');
    if (route.parentLayoutType != null) {
      buffer.writeln('/// Layout: ${route.parentLayoutType}');
    }
    buffer.writeln(
      'abstract class ${route.generatedBaseClassName} extends $routeBase$mixinStr {',
    );

    // Generate constructor parameters for dynamic segments
    if (route.hasDynamicParameters) {
      for (final param in route.parameters) {
        buffer.writeln('  /// Dynamic parameter from path segment.');
        buffer.writeln('  final ${param.type} ${param.name};');
        buffer.writeln();
      }
    }

    // Generate queries field for query parameters (only if declared)
    if (route.hasQueries) {
      buffer.writeln('  /// Query parameters from the URI.');
      buffer.writeln('  final Map<String, String> queries;');
      buffer.writeln();
    }

    // Generate constructor
    if (route.hasDynamicParameters) {
      final paramsList = route.parameters
          .map((p) => 'required this.${p.name}')
          .join(', ');
      if (route.hasQueries) {
        buffer.writeln(
          '  ${route.generatedBaseClassName}({$paramsList, this.queries = const {}});',
        );
      } else {
        buffer.writeln('  ${route.generatedBaseClassName}({$paramsList});');
      }
    } else {
      if (route.hasQueries) {
        buffer.writeln(
          '  ${route.generatedBaseClassName}({this.queries = const {}});',
        );
      } else {
        buffer.writeln('  ${route.generatedBaseClassName}();');
      }
    }
    buffer.writeln();

    // Generate query() method to get individual query parameters (only if declared)
    if (route.hasQueries) {
      buffer.writeln('  /// Get a query parameter by name.');
      buffer.writeln('  /// Returns null if the parameter is not present.');
      buffer.writeln('  String? query(String name) => queries[name];');
      buffer.writeln();
    }

    // Generate layout getter if route has a parent layout
    if (route.parentLayoutType != null) {
      buffer.writeln('  @override');
      buffer.writeln('  Type? get layout => ${route.parentLayoutType};');
      buffer.writeln();
    }

    // Generate toUri method with query parameters (only if declared)
    buffer.writeln('  @override');
    if (route.hasQueries) {
      buffer.writeln('  Uri toUri() {');
      buffer.writeln(
        '    final uri = Uri.parse(\'${_generateUriTemplate(route)}\');',
      );
      buffer.writeln('    if (queries.isEmpty) return uri;');
      buffer.writeln('    return uri.replace(queryParameters: queries);');
      buffer.writeln('  }');
    } else {
      buffer.writeln(
        '  Uri toUri() => Uri.parse(\'${_generateUriTemplate(route)}\');',
      );
    }
    buffer.writeln();

    // Generate props for equality (include queries if declared)
    buffer.writeln('  @override');
    if (route.hasDynamicParameters) {
      final propsItems = route.parameters.map((p) => p.name).join(', ');
      if (route.hasQueries) {
        buffer.writeln('  List<Object?> get props => [$propsItems, queries];');
      } else {
        buffer.writeln('  List<Object?> get props => [$propsItems];');
      }
    } else {
      if (route.hasQueries) {
        buffer.writeln('  List<Object?> get props => [queries];');
      } else {
        buffer.writeln('  List<Object?> get props => [];');
      }
    }

    // Generate deep link strategy getter if needed
    if (route.deepLinkStrategy != null) {
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln(
        '  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.${route.deepLinkStrategy!.name};',
      );
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  String _generateUriTemplate(RouteElement route) {
    if (route.pathSegments.isEmpty) return '/';

    final segments = route.pathSegments
        .map((segment) {
          if (segment.startsWith('...:')) {
            // Rest parameter - interpolate
            final paramName = segment.substring(4);
            return '\${$paramName.join(\'/\')}';
          }
          if (segment.startsWith(':')) {
            // Dynamic parameter - interpolate
            final paramName = segment.substring(1);
            return '\$$paramName';
          }
          return segment;
        })
        .join('/');

    return '/$segments';
  }
}
