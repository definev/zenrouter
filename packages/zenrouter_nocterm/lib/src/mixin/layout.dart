import 'package:nocterm/nocterm.dart';
import 'package:zenrouter_core/zenrouter_core.dart';
import 'package:zenrouter_nocterm/src/coordinator/base.dart';
import 'package:zenrouter_nocterm/src/mixin/unique.dart';

typedef DecodeLayoutKeyCallback = Object Function(String key);

/// Mixin for routes that define a layout structure.
///
/// A layout is a route that wraps other routes, such as a shell or a tab bar.
/// It defines how its children are displayed and managed.
///
/// ## Role in Navigation Flow
///
/// [RouteLayout] creates nested navigation hierarchies:
/// 1. Acts as a parent container for child routes
/// 2. Provides a [StackPath] via [resolvePath] for its children
/// 3. Builds the nested navigation UI via [buildPath]
/// 4. Coordinates with coordinator for layout parent construction
///
/// Layouts enable:
/// - Shell routes with nested navigation
/// - Tab bars with multiple navigation stacks
/// - Drawer navigation with main content area
mixin RouteLayout<T extends RouteUnique> on RouteUnique
    implements RouteLayoutParent<T> {
  static Component buildRoot(Coordinator coordinator) {
    final rootPathKey = coordinator.root.pathKey;

    final routeLayoutBuilder = coordinator.getLayoutBuilder(rootPathKey);
    // coverage:ignore-start
    if (routeLayoutBuilder == null) {
      throw UnimplementedError(
        'No layout builder provided for [${rootPathKey.key}]. If you extend the [StackPath] class, you must register it via [defineLayoutBuilder] to use [RouteLayout.buildRoot].',
      );
    }
    // coverage:ignore-end

    return routeLayoutBuilder(coordinator, coordinator.root, null);
  }

  /// Build the layout for this route.
  Component buildPath(covariant Coordinator coordinator) {
    final path = resolvePath(coordinator);

    final routeLayoutBuilder = coordinator.getLayoutBuilder(path.pathKey);
    if (routeLayoutBuilder == null) {
      throw UnimplementedError(
        'No layout builder provided for [${path.pathKey.key}]. If you extend the [StackPath] class, you must register it via [defineLayoutBuilder] to use [RouteLayout.buildPath].',
      );
    }

    return routeLayoutBuilder(coordinator, path, this);
  }

  @override
  Component build(
    covariant CoordinatorCore coordinator,
    BuildContext context,
  ) => buildPath(coordinator as Coordinator);

  Map<String, dynamic> serialize() => {
    'type': 'layout',
    'value': layoutKey.toString(),
  };

  /// Resolves the stack path for this layout.
  ///
  /// This determines which [StackPath] this layout manages.
  @override
  StackPath<RouteUnique> resolvePath(covariant CoordinatorCore coordinator);

  @override
  Object get layoutKey => runtimeType;

  /// RouteLayout does not use a URI.
  @override
  Uri toUri() => Uri(pathSegments: ['__layout', layoutKey.toString()]);

  late final _proxy = RouteLayoutParent.proxy(this);

  @override
  void onDidPop(Object? result, covariant CoordinatorCore? coordinator) {
    super.onDidPop(result, coordinator);
    _proxy.onDidPop(result, coordinator);
  }

  @override
  operator ==(Object other) => _proxy == other;

  @override
  int get hashCode => _proxy.hashCode;
}
