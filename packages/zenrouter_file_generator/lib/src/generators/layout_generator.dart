import 'package:analyzer/dart/element/element.dart';
import 'package:build/build.dart';
import 'package:glob/glob.dart';
import 'package:source_gen/source_gen.dart';
import 'package:zenrouter_file_generator/src/analyzers/layout_element.dart';

import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

/// Generator for layout files.
///
/// Generates the `_$LayoutName` base class for each @ZenLayout annotated class.
class LayoutGenerator extends GeneratorForAnnotation<ZenLayout> {
  // Cached regex patterns for performance
  static final _routeBaseMatchSingleQuote = RegExp(r"routeBase:\s*'([^']+)'");
  static final _routeBaseMatchDoubleQuote = RegExp(r'routeBase:\s*"([^"]+)"');
  static final _nameMatchSingleQuote = RegExp(r"name:\s*'([^']+)'");
  static final _nameMatchDoubleQuote = RegExp(r'name:\s*"([^"]+)"');
  static final _classMatchLayout = RegExp(r'class\s+(\w+Layout)\s+extends');

  // Cache coordinator config to avoid re-reading the file for every layout
  static ({String routeBase, String coordinatorName})? _cachedConfig;
  static bool _configLoaded = false;
  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    if (element is! ClassElement) {
      throw InvalidGenerationSourceError(
        '@ZenLayout can only be applied to classes.',
        element: element,
      );
    }

    final filePath = buildStep.inputId.path;
    final routesDir = 'lib/routes';

    // Use element.name for the class name
    final className = element.name!;

    // Get coordinator config for route base and coordinator names
    final config = await _getCoordinatorConfig(buildStep, routesDir);

    // Find parent layout by scanning for _layout.dart files in parent directories
    final parentLayout = await _findParentLayout(
      buildStep,
      filePath,
      routesDir,
    );

    final layoutElement = layoutElementFromAnnotatedElement(
      className,
      annotation,
      filePath,
      routesDir,
      parentLayoutType: parentLayout,
    );

    if (layoutElement == null) {
      throw InvalidGenerationSourceError(
        'Layout file must be inside lib/routes directory.',
        element: element,
      );
    }

    return _generateLayoutBaseClass(layoutElement, config);
  }

  /// Get coordinator configuration from _coordinator.dart.
  Future<({String routeBase, String coordinatorName})> _getCoordinatorConfig(
    BuildStep buildStep,
    String routesDir,
  ) async {
    // Performance optimization: cache the coordinator config
    if (_configLoaded) {
      return _cachedConfig ??
          (routeBase: 'AppRoute', coordinatorName: 'AppCoordinator');
    }

    String routeBase = 'AppRoute';
    String coordinatorName = 'AppCoordinator';

    final coordinatorGlob = Glob('$routesDir/_coordinator.dart');
    await for (final asset in buildStep.findAssets(coordinatorGlob)) {
      final content = await buildStep.readAsString(asset);

      // Parse routeBase
      final routeBaseMatchSingle = _routeBaseMatchSingleQuote.firstMatch(
        content,
      );
      final routeBaseMatchDouble = _routeBaseMatchDoubleQuote.firstMatch(
        content,
      );
      if (routeBaseMatchSingle != null) {
        routeBase = routeBaseMatchSingle.group(1)!;
      } else if (routeBaseMatchDouble != null) {
        routeBase = routeBaseMatchDouble.group(1)!;
      }

      // Parse coordinator name
      final nameMatchSingle = _nameMatchSingleQuote.firstMatch(content);
      final nameMatchDouble = _nameMatchDoubleQuote.firstMatch(content);
      if (nameMatchSingle != null) {
        coordinatorName = nameMatchSingle.group(1)!;
      } else if (nameMatchDouble != null) {
        coordinatorName = nameMatchDouble.group(1)!;
      }
    }

    _cachedConfig = (routeBase: routeBase, coordinatorName: coordinatorName);
    _configLoaded = true;
    return _cachedConfig!;
  }

  /// Find the closest parent _layout.dart file (in PARENT directories only).
  /// Unlike routes, layouts should only look at parent directories, not same directory.
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

    // Remove the file name (_layout.dart) to get directory parts
    parts.removeLast();

    // For layouts, we skip the current directory and only look at parents
    if (parts.isNotEmpty) {
      parts.removeLast(); // Skip current directory
    }

    // Search from innermost parent to outermost for _layout.dart
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

  String _generateLayoutBaseClass(
    LayoutElement layout,
    ({String routeBase, String coordinatorName}) config,
  ) {
    return LayoutCodeGenerator.generate(
      layout,
      LayoutCodeConfig(
        routeBase: config.routeBase,
        coordinatorName: config.coordinatorName,
      ),
    );
  }
}
