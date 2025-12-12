import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:dart_style/dart_style.dart';
import 'package:glob/glob.dart';

import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

typedef FileImportPath = (String path, bool isDeferred);

/// Generator that produces the aggregated Coordinator and route infrastructure.
///
/// This generator runs after all individual route generators and produces:
/// - The AppRoute base class
/// - The AppCoordinator class with parseRouteFromUri
/// - Navigation path definitions
/// - Layout registrations
/// - Type-safe navigation extensions
class CoordinatorGenerator implements Builder {
  /// Global deferred import configuration.
  /// When true, all routes will use deferred imports unless explicitly disabled.
  final bool globalDeferredImport;

  CoordinatorGenerator({this.globalDeferredImport = false});

  // Cached regex patterns for performance
  static final _annotationRegex = RegExp(r'@ZenCoordinator\s*\(([^)]+)\)');
  static final _nameMatchSingleQuote = RegExp(r"name:\s*'([^']+)'");
  static final _nameMatchDoubleQuote = RegExp(r'name:\s*"([^"]+)"');
  static final _routeBaseMatchSingleQuote = RegExp(r"routeBase:\s*'([^']+)'");
  static final _routeBaseMatchDoubleQuote = RegExp(r'routeBase:\s*"([^"]+)"');
  static final _classMatchRoute = RegExp(r'class\s+(\w+Route)\s+extends');
  static final _classMatchLayout = RegExp(r'class\s+(\w+Layout)\s+extends');
  static final _queriesMatch = RegExp(r'queries:\s*\[([^\]]+)\]');
  static final _queriesContentMatch = RegExp(r"'([^']+)'");

  @override
  final buildExtensions = const {
    r'$lib$': ['routes/routes.zen.dart'],
  };

  @override
  Future<void> build(BuildStep buildStep) async {
    // Collect all route and layout information from generated files
    final routes = <RouteInfo>[];
    final layouts = <LayoutInfo>[];
    String? customNotFoundRoutePath;
    // Map to track which routes come from which files
    final routeFileMap = <String, String>{};

    // Default coordinator configuration
    String coordinatorName = 'AppCoordinator';
    String routeBaseName = 'AppRoute';

    // Single pass: Process all files at once (performance optimization)
    final routeFiles = Glob('lib/routes/**.dart');
    await for (final input in buildStep.findAssets(routeFiles)) {
      if (input.path.contains('.g.dart')) continue;
      if (input.path.contains('.zen.dart')) continue;

      final relativePath = input.path.replaceFirst('lib/routes/', '');
      final fileName = relativePath.split('/').last;
      final content = await buildStep.readAsString(input);

      // Check for @ZenCoordinator annotation
      if (fileName == '_coordinator.dart') {
        if (content.contains('@ZenCoordinator')) {
          final config = _parseCoordinatorConfig(content);
          if (config != null) {
            coordinatorName = config['name'] ?? coordinatorName;
            routeBaseName = config['routeBase'] ?? routeBaseName;
          }
        }
        continue;
      }

      // Check for custom NotFoundRoute
      if (content.contains('class NotFoundRoute') &&
          content.contains('extends $routeBaseName')) {
        customNotFoundRoutePath = input.path;
        // Don't add NotFoundRoute to routes list - it's handled specially
        continue;
      }

      // Parse route info from file content and path
      final info = _parseRouteInfo(input.path, content);
      if (info != null) {
        if (info is RouteInfo) {
          // Store file path for error reporting
          info.filePath = input.path;
          routes.add(info);
          // Track which file this route comes from
          routeFileMap[info.className] = relativePath;
        } else if (info is LayoutInfo) {
          layouts.add(info);
          // Track layout files too
          routeFileMap[info.className] = relativePath;
        }
      }
    }

    // Only generate if we found routes
    if (routes.isEmpty && layouts.isEmpty) {
      return;
    }

    // Build the route tree
    final tree = _buildRouteTree(routes, layouts);

    // Validate and enforce IndexedStack routes to be non-deferred
    // This must happen BEFORE we build allFilePaths
    _validateRouteConflicts(tree.routes);
    _validateIndexedStackDeferredImports(tree.routes, tree.layouts);

    // Now build allFilePaths with correct deferred import flags
    final allFilePaths = <FileImportPath>[];
    for (final route in routes) {
      final relativePath = routeFileMap[route.className];
      if (relativePath != null) {
        final fileName = relativePath.split('/').last;
        // Skip private files except _layout
        if (!fileName.startsWith('_')) {
          allFilePaths.add((relativePath, route.hasDeferredImport));
        }
      }
    }
    for (final layout in layouts) {
      final relativePath = routeFileMap[layout.className];
      if (relativePath != null) {
        final fileName = relativePath.split('/').last;
        // Include _layout files
        if (fileName == '_layout.dart') {
          allFilePaths.add((relativePath, false));
        }
      }
    }

    // Generate coordinator code
    final output = _generateCoordinatorCode(
      tree,
      customNotFoundRoutePath,
      allFilePaths,
      coordinatorName,
      routeBaseName,
      routeFileMap,
    );

    // Get language version for formatting
    // Try to resolve from _coordinator.dart, otherwise use latest
    LibraryElement? lib;
    try {
      final coordinatorId = AssetId(
        buildStep.inputId.package,
        'lib/routes/_coordinator.dart',
      );
      if (await buildStep.canRead(coordinatorId)) {
        lib = await buildStep.resolver.libraryFor(
          coordinatorId,
          allowSyntaxErrors: true,
        );
      }
    } catch (_) {
      // Ignore errors, will use latest language version
    }

    // Format the generated code
    final formattedOutput = _formatOutput(lib, output);

    // Write output - path is relative to lib/ since we use $lib$ trigger
    final outputId = AssetId(
      buildStep.inputId.package,
      'lib/routes/routes.zen.dart',
    );
    await buildStep.writeAsString(outputId, formattedOutput);
  }

  /// Format the generated Dart code using dart_style.
  String _formatOutput(LibraryElement? library, String code) {
    try {
      final languageVersion =
          library?.languageVersion.effective ??
          DartFormatter.latestLanguageVersion;
      final formatter = DartFormatter(languageVersion: languageVersion);
      return formatter.format(code);
    } catch (e) {
      // If formatting fails, return the unformatted code
      // This ensures generation doesn't fail due to formatting issues
      return code;
    }
  }

  /// Parse @ZenCoordinator annotation from _coordinator.dart file.
  ///
  /// Returns a map with 'name' and 'routeBase' keys, or null if not found.
  Map<String, String>? _parseCoordinatorConfig(String content) {
    if (!content.contains('@ZenCoordinator')) {
      return null;
    }

    // Extract annotation parameters
    final annotationMatch = _annotationRegex.firstMatch(content);

    if (annotationMatch == null) {
      // Use defaults if annotation exists but has no parameters
      return {'name': 'AppCoordinator', 'routeBase': 'AppRoute'};
    }

    final params = annotationMatch.group(1)!;
    final config = <String, String>{};

    // Parse name parameter - supports both single and double quotes
    final nameMatchSingle = _nameMatchSingleQuote.firstMatch(params);
    final nameMatchDouble = _nameMatchDoubleQuote.firstMatch(params);
    if (nameMatchSingle != null) {
      config['name'] = nameMatchSingle.group(1)!;
    } else if (nameMatchDouble != null) {
      config['name'] = nameMatchDouble.group(1)!;
    }

    // Parse routeBase parameter - supports both single and double quotes
    final routeBaseMatchSingle = _routeBaseMatchSingleQuote.firstMatch(params);
    final routeBaseMatchDouble = _routeBaseMatchDoubleQuote.firstMatch(params);
    if (routeBaseMatchSingle != null) {
      config['routeBase'] = routeBaseMatchSingle.group(1)!;
    } else if (routeBaseMatchDouble != null) {
      config['routeBase'] = routeBaseMatchDouble.group(1)!;
    }

    return config.isEmpty ? null : config;
  }

  Object? _parseRouteInfo(String path, String content) {
    // Extract relative path from routes directory
    final relativePath = path.replaceFirst('lib/routes/', '');

    // Skip private files except _layout
    final fileName = relativePath.split('/').last;
    if (fileName.startsWith('_') && !fileName.startsWith('_layout')) {
      return null;
    }

    // Check if it's a layout file
    if (fileName == '_layout.dart') {
      return _parseLayoutFromContent(relativePath, content);
    }

    // Check for @ZenRoute annotation
    if (content.contains('@ZenRoute')) {
      return _parseRouteFromContent(relativePath, content);
    }

    return null;
  }

  RouteInfo? _parseRouteFromContent(String relativePath, String content) {
    // Extract class name
    final classMatch = _classMatchRoute.firstMatch(content);
    if (classMatch == null) return null;

    final className = classMatch.group(1)!;

    // Parse path segments using shared parser
    final (segments, params, isIndex, fileName) = PathParser.parsePath(
      relativePath,
    );

    // Check for mixins
    final hasGuard = content.contains('guard: true');
    final hasRedirect = content.contains('redirect: true');
    final hasTransition = content.contains('transition: true');

    // Check for explicit deferredImport annotation
    bool hasDeferredImport;
    if (content.contains('deferredImport: false')) {
      // Explicitly disabled - respect annotation
      hasDeferredImport = false;
    } else if (content.contains('deferredImport: true')) {
      // Explicitly enabled - respect annotation
      hasDeferredImport = true;
    } else {
      // No explicit annotation - use global config
      hasDeferredImport = globalDeferredImport;
    }

    DeeplinkStrategyType? deepLink;
    if (content.contains('.replace')) {
      deepLink = DeeplinkStrategyType.replace;
    } else if (content.contains('.push')) {
      deepLink = DeeplinkStrategyType.push;
    } else if (content.contains('.custom')) {
      deepLink = DeeplinkStrategyType.custom;
    }

    // Parse query parameter names from annotation
    List<String>? queries;
    final queriesMatch = _queriesMatch.firstMatch(content);
    if (queriesMatch != null) {
      final queriesList = queriesMatch.group(1)!;
      queries =
          _queriesContentMatch
              .allMatches(queriesList)
              .map((m) => m.group(1)!)
              .toList();
    }

    return RouteInfo(
      className: className,
      pathSegments: segments,
      parameters: params,
      hasGuard: hasGuard,
      hasRedirect: hasRedirect,
      deepLinkStrategy: deepLink,
      hasTransition: hasTransition,
      hasDeferredImport: hasDeferredImport,
      isIndexFile: isIndex,
      originalFileName: fileName,
      queries: queries,
    );
  }

  LayoutInfo? _parseLayoutFromContent(String relativePath, String content) {
    // Extract class name
    final classMatch = _classMatchLayout.firstMatch(content);
    if (classMatch == null) return null;

    final className = classMatch.group(1)!;

    // Parse path segments using shared parser
    final segments = PathParser.parseLayoutPath(relativePath);

    // Determine layout type
    final isIndexed = content.contains('LayoutType.indexed');
    final layoutType = isIndexed ? LayoutType.indexed : LayoutType.stack;

    // Extract indexed routes if present (can be Route or Layout types)
    final indexedRoutes = <String>[];
    if (isIndexed) {
      final routesMatch = RegExp(r'routes:\s*\[([^\]]+)\]').firstMatch(content);
      if (routesMatch != null) {
        final routesList = routesMatch.group(1)!;
        // Match both Route and Layout types
        final routeTypes = RegExp(
          r'(\w+(?:Route|Layout))',
        ).allMatches(routesList);
        for (final match in routeTypes) {
          indexedRoutes.add(match.group(1)!);
        }
      }
    }

    return LayoutInfo(
      className: className,
      pathSegments: segments,
      layoutType: layoutType,
      indexedRouteTypes: indexedRoutes,
    );
  }

  RouteTreeInfo _buildRouteTree(
    List<RouteInfo> routes,
    List<LayoutInfo> layouts,
  ) {
    // Resolve parent layouts for routes
    for (final route in routes) {
      String? parentLayout;
      int maxMatchLength = 0;

      for (final layout in layouts) {
        if (_isPathPrefix(layout.pathSegments, route.pathSegments) &&
            layout.pathSegments.length > maxMatchLength) {
          parentLayout = layout.className;
          maxMatchLength = layout.pathSegments.length;
        }
      }

      route.parentLayoutType = parentLayout;
    }

    // Resolve parent layouts for layouts
    for (final layout in layouts) {
      String? parentLayout;
      int maxMatchLength = 0;

      for (final other in layouts) {
        if (other.className == layout.className) continue;
        if (_isPathPrefix(other.pathSegments, layout.pathSegments) &&
            other.pathSegments.length > maxMatchLength) {
          parentLayout = other.className;
          maxMatchLength = other.pathSegments.length;
        }
      }

      layout.parentLayoutType = parentLayout;
    }

    return RouteTreeInfo(routes: routes, layouts: layouts);
  }

  bool _isPathPrefix(List<String> prefix, List<String> path) {
    if (prefix.length >= path.length) return false;
    for (var i = 0; i < prefix.length; i++) {
      if (prefix[i].startsWith(':') || path[i].startsWith(':')) continue;
      if (prefix[i] != path[i]) return false;
    }
    return true;
  }

  /// Validate routes for duplicates and throw descriptive errors.
  ///
  /// Checks for duplicate routes (same path pattern).
  /// Note: Static routes can coexist with dynamic routes - they will be
  /// automatically ordered correctly (static before dynamic) by the sorting logic.
  void _validateRouteConflicts(List<RouteInfo> routes) {
    final pathPatterns = <String, List<RouteInfo>>{};

    // Group routes by path pattern
    for (final route in routes) {
      final pattern = route.pathSegments.join('/');
      pathPatterns.putIfAbsent(pattern, () => []).add(route);
    }

    // Check for duplicate routes (same path pattern)
    for (final entry in pathPatterns.entries) {
      if (entry.value.length > 1) {
        final duplicates = entry.value;
        final filePaths = duplicates
            .map((r) => r.filePath ?? 'unknown')
            .join(', ');
        final classNames = duplicates.map((r) => r.className).join(', ');
        throw ArgumentError(
          'Duplicate route pattern detected: /${entry.key}\n'
          'Found ${duplicates.length} routes with the same path:\n'
          '  Classes: $classNames\n'
          '  Files: $filePaths\n'
          'Please ensure each route has a unique path pattern.',
        );
      }
    }
  }

  /// Validate that routes in IndexedStack layouts cannot be deferred imports.
  ///
  /// IndexedStack displays one child at a time but keeps all children in the
  /// widget tree, so they must be available immediately and cannot use
  /// deferred imports.
  ///
  /// This method also enforces hasDeferredImport = false for these routes,
  /// overriding both annotation and global config.
  void _validateIndexedStackDeferredImports(
    List<RouteInfo> routes,
    List<LayoutInfo> layouts,
  ) {
    // Check each IndexedStack layout
    for (final layout in layouts) {
      if (layout.layoutType == LayoutType.indexed) {
        // Check each route type listed in the IndexedStack
        for (final routeType in layout.indexedRouteTypes) {
          RouteInfo? route;
          for (final r in routes) {
            if (r.className == routeType) {
              route = r;
              break;
            }
          }
          if (route == null) {
            continue;
          }

          // Force deferred import to false for IndexedStack routes
          // This overrides both annotation and global config
          if (route.hasDeferredImport) {
            route.hasDeferredImport = false;
          }
        }
      }
    }
  }

  String _getAliasImport(String path) {
    // Performance optimization: single-pass character iteration instead of 7 replaceAll calls
    final buffer = StringBuffer();
    for (var i = 0; i < path.length; i++) {
      final char = path[i];
      switch (char) {
        case '.':
          if (i + 2 < path.length && path.substring(i, i + 3) == '...') {
            buffer.write('_');
            i += 2; // Skip the next two dots
          } else if (i + 4 < path.length &&
              path.substring(i, i + 5) == '.dart') {
            // Skip .dart extension at end
            i += 4;
          } else {
            buffer.write(char);
          }
        case '/':
        case '[':
        case '(':
          buffer.write('_');
        case ']':
        case ')':
        case '-':
          // Skip these characters
          break;
        default:
          buffer.write(char);
      }
    }
    return buffer.toString();
  }

  String _wrapDeferredImportLoad(String importPath, String instance) {
    final aliasImport = _getAliasImport(importPath);
    return 'await () async { await $aliasImport.loadLibrary(); return $aliasImport.$instance; }()';
  }

  String _generateCoordinatorCode(
    RouteTreeInfo tree,
    String? customNotFoundRoutePath,
    List<FileImportPath> allFilePaths,
    String coordinatorName,
    String routeBaseName,
    Map<String, String> routeFileMap,
  ) {
    final deferredImports = allFilePaths.where((f) => f.$2);

    final buffer = StringBuffer();

    // Header
    buffer.writeln('// GENERATED CODE - DO NOT MODIFY BY HAND');
    buffer.writeln('// ignore_for_file: type=lint');
    buffer.writeln();
    // Only import Material if we're generating the default NotFoundRoute
    if (customNotFoundRoutePath == null) {
      buffer.writeln("import 'package:flutter/material.dart';");
    }
    buffer.writeln("import 'package:zenrouter/zenrouter.dart';");
    buffer.writeln();

    // Import all route and layout files using relative paths
    final imports = <(String path, bool isDeferred)>{};
    for (final filePath in allFilePaths) {
      imports.add(filePath);
    }
    // Import custom NotFoundRoute if it exists (may already be in allFilePaths)
    if (customNotFoundRoutePath != null) {
      final relativePath = customNotFoundRoutePath.replaceFirst(
        'lib/routes/',
        '',
      );
      imports.add((relativePath, false));
    }
    final sortedImports =
        imports.toList()..sort((a, b) => a.$1.compareTo(b.$1));
    for (final import in sortedImports) {
      if (import.$2 == true) {
        final aliasImport = _getAliasImport(import.$1);
        buffer.writeln("import '${import.$1}' deferred as $aliasImport;");
      } else {
        buffer.writeln("import '${import.$1}';");
      }
    }
    buffer.writeln();

    buffer.writeln("export 'package:zenrouter/zenrouter.dart';");
    // Export all route and layout files using relative paths
    for (final export in sortedImports.where((i) => i.$2 == false)) {
      buffer.writeln("export '${export.$1}';");
    }
    buffer.writeln();

    // Generate route base class
    buffer.writeln('/// Base class for all routes in this application.');
    buffer.writeln(
      'abstract class $routeBaseName extends RouteTarget with RouteUnique {}',
    );
    buffer.writeln();

    // Generate Coordinator
    buffer.writeln('/// Generated coordinator managing all routes.');
    buffer.writeln(
      'class $coordinatorName extends Coordinator<$routeBaseName> {',
    );

    // Generate navigation paths for layouts
    for (final layout in tree.layouts) {
      final pathFieldName = _getPathFieldName(layout.className);
      final pathName = layout.className.replaceAll('Layout', '');
      if (layout.layoutType == LayoutType.indexed) {
        final routeInstances = layout.indexedRouteTypes
            .map((r) => '$r()')
            .join(', ');
        buffer.writeln(
          '  final IndexedStackPath<$routeBaseName> $pathFieldName = IndexedStackPath([',
        );
        buffer.writeln('    $routeInstances,');
        buffer.writeln("  ], '$pathName');");
      } else {
        buffer.writeln(
          "  final NavigationPath<$routeBaseName> $pathFieldName = NavigationPath('$pathName');",
        );
      }
    }
    buffer.writeln();

    // Generate paths getter
    buffer.writeln('  @override');
    buffer.write('  List<StackPath> get paths => [root');
    for (final layout in tree.layouts) {
      buffer.write(', ${_getPathFieldName(layout.className)}');
    }
    buffer.writeln('];');
    buffer.writeln();

    // Generate defineLayout
    buffer.writeln('  @override');
    buffer.writeln('  void defineLayout() {');
    for (final layout in tree.layouts) {
      buffer.writeln(
        '    RouteLayout.defineLayout(${layout.className}, () => ${layout.className}());',
      );
    }
    buffer.writeln('  }');
    buffer.writeln();

    // Generate parseRouteFromUri
    buffer.writeln('  @override');
    if (deferredImports.isNotEmpty) {
      buffer.writeln(
        '  Future<$routeBaseName> parseRouteFromUri(Uri uri) async {',
      );
    } else {
      buffer.writeln('  $routeBaseName parseRouteFromUri(Uri uri) {');
    }
    buffer.writeln('    return switch (uri.pathSegments) {');

    // Validate routes for conflicts before sorting
    // Validate routes for duplicates (static/dynamic conflicts are allowed)
    _validateRouteConflicts(tree.routes);
    // Validate that routes in IndexedStack layouts cannot be deferred imports
    _validateIndexedStackDeferredImports(tree.routes, tree.layouts);

    // Sort routes by specificity (more segments first, static before dynamic)
    // This ensures static routes come before dynamic routes, allowing both to coexist
    // Performance optimization: use pre-computed route characteristics
    final sortedRoutes = List<RouteInfo>.from(tree.routes)..sort((a, b) {
      // 1. Routes with rest params go last
      if (a.hasRestParams && !b.hasRestParams) return 1; // a goes after b
      if (!a.hasRestParams && b.hasRestParams) return -1; // a goes before b

      // 2. More static segments first (cached)
      if (a.staticSegmentCount != b.staticSegmentCount) {
        return b.staticSegmentCount - a.staticSegmentCount;
      }

      // 3. More total segments first
      final segmentDiff = b.pathSegments.length - a.pathSegments.length;
      if (segmentDiff != 0) return segmentDiff;

      // 4. Static segments before dynamic (cached)
      return a.dynamicSegmentCount - b.dynamicSegmentCount;
    });

    // Root route
    final rootRoute =
        sortedRoutes.where((r) => r.pathSegments.isEmpty).firstOrNull;
    if (rootRoute != null) {
      final routeInstance =
          rootRoute.hasQueries
              ? '${rootRoute.className}(queries: uri.queryParameters)'
              : '${rootRoute.className}()';
      if (rootRoute.hasDeferredImport) {
        final relativePath = routeFileMap[rootRoute.className] ?? 'index.dart';
        buffer.writeln(
          '      [] => ${_wrapDeferredImportLoad(relativePath, routeInstance)},',
        );
      } else {
        buffer.writeln('      [] => $routeInstance,');
      }
    }

    // Other routes
    for (final route in sortedRoutes) {
      if (route.pathSegments.isEmpty) continue;

      final pattern = _generateSwitchPattern(route);
      final constructor = _generateConstructor(route);
      buffer.writeln('      $pattern => $constructor,');
    }

    // Default not found
    buffer.writeln(
      '      _ => NotFoundRoute(uri: uri, queries: uri.queryParameters),',
    );
    buffer.writeln('    };');
    buffer.writeln('  }');

    buffer.writeln('}');
    buffer.writeln();

    // Generate NotFoundRoute only if custom one doesn't exist
    if (customNotFoundRoutePath == null) {
      buffer.writeln('/// Default not found route.');
      buffer.writeln(
        '/// You can customize this by creating your own NotFoundRoute class.',
      );
      buffer.writeln('class NotFoundRoute extends $routeBaseName {');
      buffer.writeln('  final Uri uri;');
      buffer.writeln('  final Map<String, String> queries;');
      buffer.writeln();
      buffer.writeln(
        '  NotFoundRoute({required this.uri, this.queries = const {}});',
      );
      buffer.writeln();
      buffer.writeln('  /// Get a query parameter by name.');
      buffer.writeln('  /// Returns null if the parameter is not present.');
      buffer.writeln('  String? query(String name) => queries[name];');
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln("  Uri toUri() => Uri.parse('/not-found');");
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln('  List<Object?> get props => [uri, queries];');
      buffer.writeln();
      buffer.writeln('  @override');
      buffer.writeln(
        '  Widget build(covariant $coordinatorName coordinator, BuildContext context) {',
      );
      buffer.writeln('    return Scaffold(');
      buffer.writeln("      appBar: AppBar(title: const Text('Not Found')),");
      buffer.writeln('      body: Center(');
      buffer.writeln('        child: Column(');
      buffer.writeln('          mainAxisAlignment: MainAxisAlignment.center,');
      buffer.writeln('          children: [');
      buffer.writeln(
        '            const Icon(Icons.error_outline, size: 64, color: Colors.red),',
      );
      buffer.writeln('            const SizedBox(height: 16),');
      buffer.writeln("            Text('Route not found: \${uri.path}'),");
      buffer.writeln('          ],');
      buffer.writeln('        ),');
      buffer.writeln('      ),');
      buffer.writeln('    );');
      buffer.writeln('  }');
      buffer.writeln('}');
      buffer.writeln();
    }

    // Generate type-safe navigation extension
    buffer.writeln('/// Type-safe navigation extension methods.');
    buffer.writeln('extension ${coordinatorName}Nav on $coordinatorName {');
    for (final route in tree.routes) {
      final baseMethodName = _getBaseMethodName(route.className);
      final (params, args) = _buildMethodParams(route);
      final deferredImportPath =
          route.hasDeferredImport
              ? route.filePath!.replaceFirst('lib/routes/', '')
              : null;

      // Generate push method
      _writeNavMethod(
        buffer,
        baseMethodName,
        'push',
        route.className,
        params,
        args,
        deferredImportPath: deferredImportPath,
        generic: 'T extends Object',
        returnType: 'Future<T?>',
      );

      // Generate replace method
      _writeNavMethod(
        buffer,
        baseMethodName,
        'replace',
        route.className,
        params,
        args,
        deferredImportPath: deferredImportPath,
        returnType: 'Future<void>',
      );

      // Generate recoverFromUri method
      _writeRecoverMethod(
        buffer,
        baseMethodName,
        route.className,
        params,
        args,
        deferredImportPath: deferredImportPath,
      );
    }
    buffer.writeln('}');

    return buffer.toString();
  }

  String _getPathFieldName(String className) {
    var name = className;
    if (name.endsWith('Layout')) {
      name = name.substring(0, name.length - 6);
    }
    name = name[0].toLowerCase() + name.substring(1);
    return '${name}Path';
  }

  String _generateSwitchPattern(RouteInfo route) {
    final parts = route.pathSegments
        .map((segment) {
          if (segment.startsWith('...:')) {
            final paramName = segment.substring(4);
            return '...final $paramName';
          }
          if (segment.startsWith(':')) {
            final paramName = segment.substring(1);
            return 'final $paramName';
          }
          return "'$segment'";
        })
        .join(', ');

    return '[$parts]';
  }

  String _generateConstructor(RouteInfo route) {
    final args = <String>[];
    String routeInstance = '';

    // Add path parameters
    for (final param in route.parameters) {
      args.add('${param.name}: ${param.name}');
    }

    // Add query parameters only if route expects them
    if (route.hasQueries) {
      args.add('queries: uri.queryParameters');
    }

    if (args.isEmpty) {
      routeInstance = '${route.className}()';
    } else {
      routeInstance = '${route.className}(${args.join(', ')})';
    }

    final relativePath = route.filePath!.replaceFirst('lib/routes/', '');

    if (route.hasDeferredImport) {
      return _wrapDeferredImportLoad(relativePath, routeInstance);
    }
    return routeInstance;
  }

  String _getBaseMethodName(String className) {
    // Convert HomeRoute -> Home
    var name = className;
    if (name.endsWith('Route')) {
      name = name.substring(0, name.length - 5);
    }
    return name;
  }

  (List<String> params, List<String> args) _buildMethodParams(RouteInfo route) {
    final params = <String>[];
    final args = <String>[];

    // Add path parameters
    for (final param in route.parameters) {
      switch (param.isRest) {
        case true:
          params.add('List<String> ${param.name}');
        case false:
          params.add('String ${param.name}');
      }
      args.add('${param.name}: ${param.name}');
    }

    // Add optional query parameters only if route expects them
    if (route.hasQueries) {
      params.add('[Map<String, String> queries = const {}]');
      args.add('queries: queries');
    }

    return (params, args);
  }

  void _writeNavMethod(
    StringBuffer buffer,
    String baseMethodName,
    String navMethod,
    String routeClassName,
    List<String> params,
    List<String> args, {
    String? generic,
    String returnType = 'Future<dynamic>',
    String? deferredImportPath,
  }) {
    final methodName = '$navMethod$baseMethodName';
    final paramsStr = params.join(', ');
    final argsStr = args.join(', ');

    final genericStr = generic != null ? '<$generic>' : '';

    String routeInstance = '';
    String arrowFunction = '';
    if (paramsStr.isNotEmpty) {
      routeInstance = '$routeClassName($argsStr)';
    } else {
      routeInstance = '$routeClassName()';
    }
    if (deferredImportPath != null) {
      arrowFunction = 'async =>';
      routeInstance = _wrapDeferredImportLoad(
        deferredImportPath,
        routeInstance,
      );
    } else {
      arrowFunction = '=>';
    }

    if (paramsStr.isEmpty) {
      buffer.writeln(
        '  $returnType $methodName$genericStr() $arrowFunction $navMethod($routeInstance);',
      );
    } else {
      buffer.writeln(
        '  $returnType $methodName$genericStr($paramsStr) $arrowFunction $navMethod($routeInstance);',
      );
    }
  }

  void _writeRecoverMethod(
    StringBuffer buffer,
    String baseMethodName,
    String routeClassName,
    List<String> params,
    List<String> args, {
    String? deferredImportPath,
  }) {
    final methodName = 'recover$baseMethodName';
    final paramsStr = params.join(', ');
    final argsStr = args.join(', ');
    String routeInstance = '';
    if (paramsStr.isEmpty) {
      routeInstance = '$routeClassName()';
    } else {
      routeInstance = '$routeClassName($argsStr)';
    }

    if (deferredImportPath != null) {
      routeInstance = _wrapDeferredImportLoad(
        deferredImportPath,
        routeInstance,
      );
    }

    String arrowFunction = '';
    if (deferredImportPath != null) {
      arrowFunction = 'async =>';
    } else {
      arrowFunction = '=>';
    }

    if (paramsStr.isEmpty) {
      buffer.writeln(
        '  Future<void> $methodName() $arrowFunction recover($routeInstance);',
      );
    } else {
      buffer.writeln(
        '  Future<void> $methodName($paramsStr) $arrowFunction recover($routeInstance);',
      );
    }
  }
}

/// Simplified route info for coordinator generation.
class RouteInfo {
  final String className;
  final List<String> pathSegments;
  final List<ParamInfo> parameters;
  final bool hasGuard;
  final bool hasRedirect;
  final DeeplinkStrategyType? deepLinkStrategy;
  final bool hasTransition;
  bool hasDeferredImport;
  final bool isIndexFile;
  final String originalFileName;
  final List<String>? queries;
  String? parentLayoutType;
  String? filePath; // File path for error reporting

  // Cached path characteristics for performance (computed once during construction)
  late final bool _hasRestParams;
  late final int _staticSegmentCount;
  late final int _dynamicSegmentCount;

  RouteInfo({
    required this.className,
    required this.pathSegments,
    required this.parameters,
    this.hasGuard = false,
    this.hasRedirect = false,
    this.deepLinkStrategy,
    this.hasTransition = false,
    this.hasDeferredImport = false,
    this.isIndexFile = false,
    this.originalFileName = '',
    this.queries,
    this.parentLayoutType,
    this.filePath,
  }) {
    // Pre-compute path characteristics for faster sorting
    _hasRestParams = pathSegments.any((s) => s.startsWith('...:'));
    _staticSegmentCount =
        pathSegments
            .where((s) => !s.startsWith(':') && !s.startsWith('...'))
            .length;
    _dynamicSegmentCount =
        pathSegments
            .where((s) => s.startsWith(':') && !s.startsWith('...'))
            .length;
  }

  /// Whether this route expects query parameters.
  bool get hasQueries => queries != null && queries!.isNotEmpty;

  /// Cached: whether this route has rest parameters
  bool get hasRestParams => _hasRestParams;

  /// Cached: number of static segments
  int get staticSegmentCount => _staticSegmentCount;

  /// Cached: number of dynamic segments (excluding rest params)
  int get dynamicSegmentCount => _dynamicSegmentCount;
}

/// Simplified layout info for coordinator generation.
class LayoutInfo {
  final String className;
  final List<String> pathSegments;
  final LayoutType layoutType;
  final List<String> indexedRouteTypes;
  String? parentLayoutType;

  LayoutInfo({
    required this.className,
    required this.pathSegments,
    required this.layoutType,
    this.indexedRouteTypes = const [],
    this.parentLayoutType,
  });
}

/// Container for route tree info.
class RouteTreeInfo {
  final List<RouteInfo> routes;
  final List<LayoutInfo> layouts;

  RouteTreeInfo({required this.routes, required this.layouts});
}
