import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

/// Configuration for route code generation.
class RouteCodeConfig {
  /// The base route class name (e.g., 'AppRoute').
  final String routeBase;

  const RouteCodeConfig({this.routeBase = 'AppRoute'});
}

/// Shared utility for generating route base class code.
///
/// This class is used by both `RouteGenerator` (build_runner) and
/// `ZenRouteMacro` (macro_kit) to ensure consistent code generation.
class RouteCodeGenerator {
  const RouteCodeGenerator._();

  /// Generate the route base class code.
  ///
  /// Returns the generated Dart code as a String.
  static String generate(RouteElement route, RouteCodeConfig config) {
    final buffer = StringBuffer();
    final routeBase = config.routeBase;

    // Build mixin list
    final mixins = <String>[];
    if (route.hasGuard) mixins.add('RouteGuard');
    if (route.hasRedirect) mixins.add('RouteRedirect<$routeBase>');
    if (route.deepLinkStrategy != null) mixins.add('RouteDeepLink');
    if (route.hasTransition) mixins.add('RouteTransition');
    if (route.hasQueries) mixins.add('RouteQueryParameters');

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

    // Generate queryNotifier field for query parameters (overrides mixin)
    if (route.hasQueries) {
      buffer.writeln('  @override');
      buffer.writeln(
        '  late final ValueNotifier<Map<String, String>> queryNotifier;',
      );
      buffer.writeln();
    }

    // Generate constructor
    if (route.hasDynamicParameters) {
      final paramsList = route.parameters
          .map((p) => 'required this.${p.name}')
          .join(', ');
      if (route.hasQueries) {
        buffer.writeln(
          '  ${route.generatedBaseClassName}({$paramsList, Map<String, String> queries = const {}}) : queryNotifier = ValueNotifier(queries);',
        );
      } else {
        buffer.writeln('  ${route.generatedBaseClassName}({$paramsList});');
      }
    } else {
      if (route.hasQueries) {
        buffer.writeln(
          '  ${route.generatedBaseClassName}({Map<String, String> queries = const {}}) : queryNotifier = ValueNotifier(queries);',
        );
      } else {
        buffer.writeln('  ${route.generatedBaseClassName}();');
      }
    }
    buffer.writeln();

    // query() method is inherited from RouteQueryParameter mixin

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

    // Generate props for equality (path params only, NOT queries)
    // Queries are intentionally excluded so that updating query params
    // doesn't trigger route changes - same path = same route identity
    buffer.writeln('  @override');
    if (route.hasDynamicParameters) {
      final propsItems = route.parameters.map((p) => p.name).join(', ');
      buffer.writeln('  List<Object?> get props => [$propsItems];');
    } else {
      buffer.writeln('  List<Object?> get props => [];');
    }

    // Generate deep link strategy getter if needed
    if (route.deepLinkStrategy != null) {
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln(
        '  DeeplinkStrategy get deeplinkStrategy => DeeplinkStrategy.${route.deepLinkStrategy!.name};',
      );
    }

    // Generate query selector helpers
    if (route.hasQueries && route.queries != null) {
      for (final query in route.queries!) {
        // Skip invalid query names or wildcards
        if (query == '*' || !_isValidQueryParam(query)) continue;

        final camelCaseName = _toCamelCase(query);
        buffer.writeln();
        buffer.writeln('  Widget ${camelCaseName}Builder<T>({');
        buffer.writeln(
          '    required T Function(String? $camelCaseName) selector,',
        );
        buffer.writeln(
          '    required Widget Function(BuildContext, T $camelCaseName) builder,',
        );
        buffer.writeln('  }) => selectorBuilder<T>(');
        buffer.writeln(
          '    selector: (queries) => selector(queries[\'$query\']),',
        );
        buffer.writeln(
          '    builder: (context, $camelCaseName) => builder(context, $camelCaseName),',
        );
        buffer.writeln('  );');
      }
    }

    buffer.writeln('}');

    return buffer.toString();
  }

  static bool _isValidQueryParam(String name) {
    if (name.isEmpty) return false;
    if (name == '*') return false;

    for (var i = 0; i < name.length; i++) {
      final char = name.codeUnitAt(i);
      // Allow A-Z, a-z, 0-9, _, -
      if (!((char >= 65 && char <= 90) || // A-Z
          (char >= 97 && char <= 122) || // a-z
          (char >= 48 && char <= 57) || // 0-9
          char == 95 || // _
          char == 45)) {
        // -
        return false;
      }
    }
    return true;
  }

  static String _toCamelCase(String str) {
    if (str.isEmpty) return str;

    // First, split on underscores and hyphens
    final delimiterParts = str.split(RegExp(r'[_\-]+'));

    // Then, for each part, also split on uppercase letters (PascalCase/camelCase)
    final allParts = <String>[];
    for (final part in delimiterParts) {
      if (part.isEmpty) continue;
      // Split on uppercase letters using lookahead to preserve the uppercase letter
      // e.g., "SortOrder" -> ["Sort", "Order"], "sortOrder" -> ["sort", "Order"]
      final camelParts = part.split(RegExp(r'(?=[A-Z])'));
      for (final camelPart in camelParts) {
        if (camelPart.isNotEmpty) {
          allParts.add(camelPart);
        }
      }
    }

    if (allParts.isEmpty) return str;

    final buffer = StringBuffer();
    // First part is lower case
    buffer.write(allParts.first.toLowerCase());

    // Subsequent parts are capitalized
    for (var i = 1; i < allParts.length; i++) {
      final part = allParts[i];
      if (part.isNotEmpty) {
        buffer.write(part[0].toUpperCase());
        if (part.length > 1) {
          buffer.write(part.substring(1).toLowerCase());
        }
      }
    }
    return buffer.toString();
  }

  static String _generateUriTemplate(RouteElement route) {
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
