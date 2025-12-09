import '../annotations.dart';

/// Represents a parsed route element from source code.
class RouteElement {
  /// The class name (e.g., 'AboutRoute').
  final String className;

  /// The file path relative to routes directory.
  final String relativePath;

  /// The URI path segments derived from file location.
  final List<String> pathSegments;

  /// Dynamic parameters extracted from [param] syntax.
  final List<RouteParameter> parameters;

  /// The layout type this route belongs to (if any).
  final String? parentLayoutType;

  /// Whether this route has RouteGuard mixin.
  final bool hasGuard;

  /// Whether this route has RouteRedirect mixin.
  final bool hasRedirect;

  /// The deep link strategy (if any).
  final DeeplinkStrategyType? deepLinkStrategy;

  /// Whether this route has RouteTransition mixin.
  final bool hasTransition;

  /// Expected query parameter names (if any).
  final List<String>? queries;

  RouteElement({
    required this.className,
    required this.relativePath,
    required this.pathSegments,
    required this.parameters,
    this.parentLayoutType,
    this.hasGuard = false,
    this.hasRedirect = false,
    this.deepLinkStrategy,
    this.hasTransition = false,
    this.queries,
  });

  /// The URI path pattern for this route.
  String get uriPattern {
    if (pathSegments.isEmpty) return '/';
    return '/${pathSegments.join('/')}';
  }

  /// The generated base class name (e.g., '_\$AboutRoute').
  String get generatedBaseClassName => '_\$$className';

  /// Whether this route has any dynamic parameters.
  bool get hasDynamicParameters => parameters.isNotEmpty;

  /// Whether this route expects query parameters.
  bool get hasQueries => queries != null && queries!.isNotEmpty;

  /// Create a copy with modified parentLayoutType.
  RouteElement copyWith({String? parentLayoutType}) {
    return RouteElement(
      className: className,
      relativePath: relativePath,
      pathSegments: pathSegments,
      parameters: parameters,
      parentLayoutType: parentLayoutType ?? this.parentLayoutType,
      hasGuard: hasGuard,
      hasRedirect: hasRedirect,
      deepLinkStrategy: deepLinkStrategy,
      hasTransition: hasTransition,
      queries: queries,
    );
  }
}

/// Represents a dynamic route parameter.
class RouteParameter {
  /// The parameter name (from [name] or [...name] syntax).
  final String name;

  /// The Dart type for this parameter.
  final String type;

  /// Whether this parameter is optional.
  final bool isOptional;

  /// Default value if optional.
  final String? defaultValue;

  /// Whether this is a rest parameter that captures multiple segments.
  final bool isRest;

  RouteParameter({
    required this.name,
    this.type = 'String',
    this.isOptional = false,
    this.defaultValue,
    this.isRest = false,
  });
}
