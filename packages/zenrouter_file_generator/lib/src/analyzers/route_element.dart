import 'package:source_gen/source_gen.dart';
import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

/// Parse a RouteElement from an annotated class.
RouteElement? routeElementFromAnnotatedElement(
  String className,
  ConstantReader annotation,
  String filePath,
  String routesDir, {
  String? parentLayoutType,
}) {
  // Extract relative path from routes directory
  final relativePath = _extractRelativePath(filePath, routesDir);
  if (relativePath == null) return null;

  // Parse path segments and parameters using shared parser
  final (segments, paramInfos, _, _) = PathParser.parsePath(relativePath);
  // Convert ParamInfo to RouteParameter
  final params =
      paramInfos
          .map(
            (p) => switch (p.isRest) {
              true => RouteParameter(
                name: p.name,
                type: 'List<String>',
                isRest: true,
              ),
              false => RouteParameter(
                name: p.name,
                type: 'String',
                isRest: false,
              ),
            },
          )
          .toList();

  // Read annotation values
  final guard = annotation.read('guard').boolValue;
  final redirect = annotation.read('redirect').boolValue;
  final transition = annotation.read('transition').boolValue;
  final deferredImport = annotation.read('deferredImport').boolValue;

  DeeplinkStrategyType? deepLink;
  final deepLinkReader = annotation.read('deepLink');
  if (!deepLinkReader.isNull) {
    final enumIndex = deepLinkReader.read('index').intValue;
    deepLink = DeeplinkStrategyType.values[enumIndex];
  }

  // Read query parameter names
  List<String>? queries;
  final queriesReader = annotation.read('queries');
  if (!queriesReader.isNull) {
    final queriesList = queriesReader.listValue;
    queries = queriesList.map((e) => e.toStringValue()!).toList();
  }

  return RouteElement(
    className: className,
    relativePath: relativePath,
    pathSegments: segments,
    parameters: params,
    parentLayoutType: parentLayoutType,
    hasGuard: guard,
    hasRedirect: redirect,
    deepLinkStrategy: deepLink,
    hasTransition: transition,
    hasDeferredImport: deferredImport,
    queries: queries,
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
