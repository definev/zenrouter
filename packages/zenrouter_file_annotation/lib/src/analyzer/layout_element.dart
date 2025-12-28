import '../annotations.dart';

/// Represents a parsed layout element from source code.
class LayoutElement {
  /// The class name (e.g., 'TabsLayout').
  final String className;

  /// The file path relative to routes directory.
  final String relativePath;

  /// The URI path for this layout.
  final List<String> pathSegments;

  /// The type of layout (stack or indexed).
  final LayoutType layoutType;

  /// For indexed layouts, the route types in order.
  final List<String> indexedRouteTypes;

  /// The parent layout type (if nested).
  final String? parentLayoutType;

  /// Creates a new layout element.
  ///
  /// The [className], [relativePath], [pathSegments], and [layoutType]
  /// are required. For indexed layouts, provide [indexedRouteTypes] to
  /// specify the route types in tab order. Set [parentLayoutType] if
  /// this layout is nested within another layout.
  LayoutElement({
    required this.className,
    required this.relativePath,
    required this.pathSegments,
    required this.layoutType,
    this.indexedRouteTypes = const [],
    this.parentLayoutType,
  });

  /// The URI path pattern for this layout.
  String get uriPattern {
    if (pathSegments.isEmpty) return '/';
    return '/${pathSegments.join('/')}';
  }

  /// The generated base class name (e.g., '_\$TabsLayout').
  String get generatedBaseClassName => '_\$$className';

  /// The generated path field name in Coordinator.
  String get pathFieldName {
    // Convert class name to camelCase path name
    // e.g., TabsLayout -> tabsPath, SettingsLayout -> settingsPath
    var name = className;
    if (name.endsWith('Layout')) {
      name = name.substring(0, name.length - 6);
    }
    // Convert to camelCase
    name = name[0].toLowerCase() + name.substring(1);
    return '${name}Path';
  }

  /// Create a copy with modified parentLayoutType.
  LayoutElement copyWith({String? parentLayoutType}) {
    return LayoutElement(
      className: className,
      relativePath: relativePath,
      pathSegments: pathSegments,
      layoutType: layoutType,
      indexedRouteTypes: indexedRouteTypes,
      parentLayoutType: parentLayoutType ?? this.parentLayoutType,
    );
  }
}
