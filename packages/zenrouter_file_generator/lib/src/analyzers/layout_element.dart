import 'package:source_gen/source_gen.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

/// Parse a LayoutElement from an annotated class.
LayoutElement? layoutElementFromAnnotatedElement(
  String className,
  ConstantReader annotation,
  String filePath,
  String routesDir, {
  String? parentLayoutType,
}) {
  // Extract relative path from routes directory
  final relativePath = _extractRelativePath(filePath, routesDir);
  if (relativePath == null) return null;

  // Parse path segments using shared parser (removes _layout from path)
  final segments = PathParser.parseLayoutPath(relativePath);

  // Read layout type
  final typeReader = annotation.read('type');
  final typeIndex = typeReader.read('index').intValue;
  final layoutType = LayoutType.values[typeIndex];

  // Read indexed routes if present
  final indexedRoutes = <String>[];
  final routesReader = annotation.read('routes');
  if (!routesReader.isNull) {
    for (final routeReader in routesReader.listValue) {
      final typeValue = routeReader.toTypeValue();
      if (typeValue != null) {
        indexedRoutes.add(typeValue.getDisplayString());
      }
    }
  }

  final branchLayouts = <String>[];
  final branchesReader = annotation.read('branches');
  if (!branchesReader.isNull) {
    for (final branchReader in branchesReader.listValue) {
      final typeValue = branchReader.toTypeValue();
      if (typeValue != null) {
        branchLayouts.add(typeValue.getDisplayString());
      }
    }
  }

  return LayoutElement(
    className: className,
    relativePath: relativePath,
    pathSegments: segments,
    layoutType: layoutType,
    indexedRouteTypes: indexedRoutes,
    branchLayoutTypes: branchLayouts,
    parentLayoutType: parentLayoutType,
  );
}

String? _extractRelativePath(String filePath, String routesDir) {
  // Normalize paths
  final normalizedFile = filePath.replaceAll('\\', '/');
  final normalizedRoutes = routesDir.replaceAll('\\', '/');

  // Find the routes directory in the path
  final routesIndex = normalizedFile.indexOf(normalizedRoutes);
  if (routesIndex == -1) return null;

  // Get path after routes directory
  var relative = normalizedFile.substring(
    routesIndex + normalizedRoutes.length,
  );
  if (relative.startsWith('/')) {
    relative = relative.substring(1);
  }

  // Remove .dart extension
  if (relative.endsWith('.dart')) {
    relative = relative.substring(0, relative.length - 5);
  }

  return relative;
}
