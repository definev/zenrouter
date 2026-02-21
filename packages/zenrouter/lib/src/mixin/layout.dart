import 'package:flutter/widgets.dart';
import 'package:zenrouter/zenrouter.dart';

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
  // coverage:ignore-start
  @Deprecated(
    'Use `coordinator.defineLayoutParent` or `bindLayout` in the corresponding [StackPath] instead.\n'
    'If you want to use this method, you must provide a [Coordinator] instance to the [RouteLayout.defineLayout] method.\n'
    'Example: `OLD: RouteLayout.defineLayout(ShopLayout, ShopLayout.new);`\n'
    '         `NEW: defineLayoutParent(ShopLayout.new);`',
  )
  /// Define a host [RouteLayout] for [StackPath].
  ///
  /// Use this to define how a specific layout type should be built.
  static void defineLayout<T extends RouteLayout>(
    Coordinator coordinator,
    Object layoutKey, // Not used, kept for backward compatibility
    RouteLayoutConstructor constructor,
  ) => coordinator.defineLayoutParent(constructor);

  /// Registers a custom layout builder.
  ///
  /// Use this to define how a specific layout type should be built.
  @Deprecated('Use `coordinator.defineLayoutBuilder` instead.')
  static void definePath(
    Coordinator coordinator,
    PathKey key,
    RouteLayoutBuilder builder,
  ) => coordinator.defineLayoutBuilder(key, builder);
  // coverage:ignore-end

  /// Route restoration reflection table.
  static RouteLayout deserialize(
    Map<String, dynamic> value, {
    required RouteLayoutParentConstructor createLayoutParent,
    required DecodeLayoutKeyCallback decodeLayoutKey,
  }) {
    final key = value['value'] as String;
    final layoutKey = decodeLayoutKey(key);
    return createLayoutParent(layoutKey) as RouteLayout;
  }

  static Widget buildRoot(Coordinator coordinator) {
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
  Widget buildPath(covariant Coordinator coordinator) {
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
  Widget build(covariant CoordinatorCore coordinator, BuildContext context) =>
      buildPath(coordinator as Coordinator);

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
