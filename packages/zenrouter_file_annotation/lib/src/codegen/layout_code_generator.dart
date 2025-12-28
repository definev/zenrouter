import 'package:zenrouter_file_annotation/zenrouter_file_annotation.dart';

/// Configuration for layout code generation.
class LayoutCodeConfig {
  /// The base route class name (e.g., 'AppRoute').
  final String routeBase;

  /// The coordinator class name (e.g., 'AppCoordinator').
  final String coordinatorName;

  /// Creates a new layout code generation configuration.
  ///
  /// The [routeBase] and [coordinatorName] default to `'AppRoute'` and
  /// `'AppCoordinator'` respectively if not specified.
  const LayoutCodeConfig({
    this.routeBase = 'AppRoute',
    this.coordinatorName = 'AppCoordinator',
  });
}

/// Shared utility for generating layout base class code.
///
/// This class is used by both `LayoutGenerator` (build_runner) and
/// `ZenLayoutMacro` (macro_kit) to ensure consistent code generation.
class LayoutCodeGenerator {
  const LayoutCodeGenerator._();

  /// Generate the layout base class code.
  ///
  /// Returns the generated Dart code as a String.
  static String generate(LayoutElement layout, LayoutCodeConfig config) {
    final buffer = StringBuffer();
    final routeBase = config.routeBase;
    final coordinatorName = config.coordinatorName;

    final pathType =
        layout.layoutType == LayoutType.indexed
            ? 'IndexedStackPath<$routeBase>'
            : 'NavigationPath<$routeBase>';

    // Generate class declaration
    buffer.writeln('/// Generated base class for ${layout.className}.');
    buffer.writeln('///');
    buffer.writeln('/// URI: ${layout.uriPattern}');
    buffer.writeln('/// Path type: ${layout.layoutType.name}');
    if (layout.parentLayoutType != null) {
      buffer.writeln('/// Parent layout: ${layout.parentLayoutType}');
    }
    buffer.writeln(
      'abstract class ${layout.generatedBaseClassName} extends $routeBase with RouteLayout<$routeBase> {',
    );
    buffer.writeln();

    // Generate constructor
    buffer.writeln('  ${layout.generatedBaseClassName}();');
    buffer.writeln();

    // Generate parent layout getter if nested
    if (layout.parentLayoutType != null) {
      buffer.writeln('  @override');
      buffer.writeln('  Type? get layout => ${layout.parentLayoutType};');
      buffer.writeln();
    }

    // Generate resolvePath method
    buffer.writeln('  @override');
    buffer.writeln(
      '  $pathType resolvePath(covariant $coordinatorName coordinator) =>',
    );
    buffer.writeln('      coordinator.${layout.pathFieldName};');
    buffer.writeln();

    // Generate toUri method
    buffer.writeln('  @override');
    buffer.writeln('  Uri toUri() => Uri.parse(\'${layout.uriPattern}\');');
    buffer.writeln();

    // Generate props for equality
    buffer.writeln('  @override');
    buffer.writeln('  List<Object?> get props => [];');

    buffer.writeln('}');

    return buffer.toString();
  }
}
